from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, Form
import aiosqlite
import string
import random
from datetime import datetime, timedelta, timezone

from app.database import get_db
from app.models import (
    UserCreate,
    UserLogin,
    UserResponse,
    TokenResponse,
    TokenRefresh,
    MessageResponse,
    ForgotPasswordRequest,
    ResetPasswordRequest,
)
from app.services.auth_service import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    create_reset_token,
    generate_reset_code,
    decode_token,
)
from app.dependencies import get_current_user
from app.services.email_service import email_service
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

auth_router = APIRouter()


# ─── Helpers ──────────────────────────────────────────────────────

def _generate_referral_code(length: int = 8) -> str:
    """Generate a random alphanumeric referral code."""
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=length))


async def _get_unique_referral_code(db: aiosqlite.Connection) -> str:
    """Generate a referral code that doesn't already exist in the DB."""
    for _ in range(10):
        code = _generate_referral_code()
        cursor = await db.execute("SELECT id FROM users WHERE referral_code = ?", (code,))
        if not await cursor.fetchone():
            return code
    # Fallback: longer code
    return _generate_referral_code(12)


async def _apply_referral_bonus(db: aiosqlite.Connection, referral_code: str, new_user_id: int) -> None:
    """Credit +5 to both the referrer and the new user."""
    cursor = await db.execute(
        "SELECT id FROM users WHERE referral_code = ?", (referral_code,)
    )
    referrer = await cursor.fetchone()
    if referrer:
        referrer_id = referrer[0]
        # Credit referrer
        await db.execute(
            "UPDATE users SET credits = credits + 5 WHERE id = ?", (referrer_id,)
        )
        # Credit new user
        await db.execute(
            "UPDATE users SET credits = credits + 5, referred_by = ? WHERE id = ?",
            (referrer_id, new_user_id)
        )
        print(f"[OK] Referral bonus: +5 to user {referrer_id} and +5 to user {new_user_id}")


def _make_tokens(user_id: int, user_row: dict) -> TokenResponse:
    """Build a TokenResponse for a given user."""
    access = create_access_token(data={"sub": str(user_id)})
    refresh = create_refresh_token(data={"sub": str(user_id)})
    return TokenResponse(
        access_token=access,
        refresh_token=refresh,
        user=UserResponse(**user_row),
    )


# ─── Signup ───────────────────────────────────────────────────────

@auth_router.post("/signup", response_model=TokenResponse)
async def signup(body: UserCreate, db: aiosqlite.Connection = Depends(get_db)):
    """Register a new user and return tokens."""
    # Check if email already exists
    cursor = await db.execute("SELECT id FROM users WHERE email = ?", (body.email,))
    if await cursor.fetchone():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        )

    hashed = hash_password(body.password)
    referral_code = await _get_unique_referral_code(db)
    
    cursor = await db.execute(
        "INSERT INTO users (name, email, hashed_password, referral_code) VALUES (?, ?, ?, ?)",
        (body.name, body.email, hashed, referral_code),
    )
    await db.commit()
    user_id = cursor.lastrowid

    # Apply referral bonus if a code was provided
    if body.referral_code:
        await _apply_referral_bonus(db, body.referral_code.strip().upper(), user_id)
        await db.commit()

    # Fetch the created user
    cursor = await db.execute(
        "SELECT id, name, email, plan_type, credits, plan_expires_at, created_at, referral_code FROM users WHERE id = ?", (user_id,)
    )
    row = await cursor.fetchone()
    user_dict = {
        "id": row[0], "name": row[1], "email": row[2], 
        "plan_type": row[3], "credits": row[4], 
        "plan_expires_at": row[5], "created_at": row[6],
        "referral_code": row[7],
    }

    print(f"[OK] New user registered: {body.email}")
    return _make_tokens(user_id, user_dict)


# ─── Login ────────────────────────────────────────────────────────

@auth_router.post("/login", response_model=TokenResponse)
async def login(body: UserLogin, db: aiosqlite.Connection = Depends(get_db)):
    """Authenticate a user and return tokens."""
    cursor = await db.execute(
        "SELECT id, name, email, hashed_password, plan_type, credits, plan_expires_at, created_at, referral_code FROM users WHERE email = ?",
        (body.email,),
    )
    row = await cursor.fetchone()

    if not row or not verify_password(body.password, row[3]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    user_dict = {
        "id": row[0], "name": row[1], "email": row[2],
        "plan_type": row[4], "credits": row[5],
        "plan_expires_at": row[6], "created_at": row[7],
        "referral_code": row[8],
    }
    print(f"[OK] User logged in: {body.email}")
    return _make_tokens(row[0], user_dict)


# ─── Refresh Token ────────────────────────────────────────────────

@auth_router.post("/refresh", response_model=TokenResponse)
async def refresh_token(body: TokenRefresh, db: aiosqlite.Connection = Depends(get_db)):
    """Issue new tokens using a valid refresh token."""
    payload = decode_token(body.refresh_token)
    if payload is None or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    user_id = payload.get("sub")
    cursor = await db.execute(
        "SELECT id, name, email, plan_type, credits, plan_expires_at, created_at, referral_code FROM users WHERE id = ?",
        (int(user_id),),
    )
    row = await cursor.fetchone()
    if not row:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    user_dict = {
        "id": row[0], "name": row[1], "email": row[2],
        "plan_type": row[3], "credits": row[4],
        "plan_expires_at": row[5], "created_at": row[6],
        "referral_code": row[7],
    }
    return _make_tokens(row[0], user_dict)


# ─── Get Current User ────────────────────────────────────────────

@auth_router.get("/me", response_model=UserResponse)
async def get_me(current_user: dict = Depends(get_current_user)):
    """Return the currently authenticated user's profile."""
    return UserResponse(**current_user)


# ─── Forgot/Reset Password ──────────────────────────────────────

@auth_router.post("/forgot-password", response_model=MessageResponse)
async def forgot_password(
    body: ForgotPasswordRequest, 
    background_tasks: BackgroundTasks,
    db: aiosqlite.Connection = Depends(get_db)
):
    """Request a password reset code. Returns immediately while email sends in background."""
    cursor = await db.execute("SELECT id FROM users WHERE email = ?", (body.email,))
    if not await cursor.fetchone():
        # Generic message to avoid email harvesting
        return {"message": "If an account with that email exists, a reset code has been sent."}

    code = generate_reset_code()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
    
    # Store code in DB
    await db.execute(
        "UPDATE users SET reset_code = ?, reset_code_expires_at = ? WHERE email = ?",
        (code, expires_at.isoformat(), body.email)
    )
    await db.commit()
    
    # Send email in background to avoid API timeout
    async def send_mail_task():
        try:
            await email_service.send_reset_password_email(body.email, code)
            print(f"[OK] Reset code {code} sent to: {body.email}")
        except Exception as e:
            print(f"[ERROR] Background email failure: {e}")

    background_tasks.add_task(send_mail_task)
    
    return {"message": "Reset code has been sent to your email."}


@auth_router.post("/reset-password", response_model=MessageResponse)
async def reset_password(body: ResetPasswordRequest, db: aiosqlite.Connection = Depends(get_db)):
    """Reset password using a valid 6-character code."""
    cursor = await db.execute(
        "SELECT reset_code, reset_code_expires_at FROM users WHERE email = ?", 
        (body.email,)
    )
    row = await cursor.fetchone()
    
    if not row:
        raise HTTPException(status_code=404, detail="User not found")
        
    db_code = row[0]
    db_expiry = row[1]
    
    if not db_code or db_code != body.token: # 'token' field in request holds our 6-char code
        raise HTTPException(status_code=401, detail="Invalid reset code")
        
    # Check expiry
    expiry_dt = datetime.fromisoformat(db_expiry)
    if datetime.now(timezone.utc) > expiry_dt:
        raise HTTPException(status_code=401, detail="Reset code has expired")

    hashed = hash_password(body.new_password)
    await db.execute(
        "UPDATE users SET hashed_password = ?, reset_code = NULL, reset_code_expires_at = NULL WHERE email = ?",
        (hashed, body.email)
    )
    await db.commit()
    
    print(f"[OK] Password reset successful for: {body.email}")
    return {"message": "Password updated successfully. You can now log in."}


# ─── Google Login ──────────────────────────────────────────────

@auth_router.post("/google", response_model=TokenResponse)
async def google_login(body: dict, db: aiosqlite.Connection = Depends(get_db)):
    """Authenticate or register a user via Google ID Token."""
    token = body.get("id_token")
    if not token:
        raise HTTPException(status_code=400, detail="Missing ID Token")

    try:
        # Verify the token
        # Note: In production, you MUST provide the CLIENT_ID here
        idinfo = id_token.verify_oauth2_token(token, google_requests.Request())
        
        email = idinfo['email']
        name = idinfo.get('name', 'Google User')
        
        # Check if user exists
        cursor = await db.execute(
            "SELECT id, name, email, plan_type, credits, plan_expires_at, created_at, referral_code FROM users WHERE email = ?", 
            (email,)
        )
        row = await cursor.fetchone()
        
        if not row:
            # Create new user with referral code
            referral_code = await _get_unique_referral_code(db)
            cursor = await db.execute(
                "INSERT INTO users (name, email, hashed_password, referral_code) VALUES (?, ?, ?, ?)",
                (name, email, "GOOGLE_AUTH_USER", referral_code)
            )
            await db.commit()
            user_id = cursor.lastrowid
            user_dict = {
                "id": user_id, "name": name, "email": email, 
                "plan_type": "FREE", "credits": 5, 
                "plan_expires_at": None, "created_at": None,
                "referral_code": referral_code,
            }
        else:
            user_id = row[0]
            user_dict = {
                "id": row[0], "name": row[1], "email": row[2],
                "plan_type": row[3], "credits": row[4],
                "plan_expires_at": row[5], "created_at": row[6],
                "referral_code": row[7],
            }
            
        print(f"[OK] Google Login: {email}")
        return _make_tokens(user_id, user_dict)
        
    except ValueError as e:
        # Invalid token
        raise HTTPException(status_code=401, detail=f"Invalid Google Token: {e}")


# ─── Settings & Profile ──────────────────────────────────────────

@auth_router.post("/update-profile")
async def update_profile(
    name: str = Form(...),
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db)
):
    """Update the current user's name."""
    await db.execute(
        "UPDATE users SET name = ? WHERE id = ?",
        (name, current_user["id"])
    )
    await db.commit()
    return {"message": "Profile updated successfully", "name": name}

@auth_router.post("/change-password")
async def change_password(
    current_password: str = Form(...),
    new_password: str = Form(...),
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db)
):
    """Change user password."""
    # First verify current password
    cursor = await db.execute("SELECT hashed_password FROM users WHERE id = ?", (current_user["id"],))
    row = await cursor.fetchone()
    
    if not row or not verify_password(current_password, row[0]):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    
    # Update to new password
    hashed = hash_password(new_password)
    await db.execute("UPDATE users SET hashed_password = ? WHERE id = ?", (hashed, current_user["id"]))
    await db.commit()
    return {"message": "Password changed successfully"}

@auth_router.delete("/account")
async def delete_account(
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db)
):
    """Delete the user account and all related data."""
    # Delete history
    await db.execute("DELETE FROM history WHERE user_id = ?", (current_user["id"],))
    # Delete favorites
    await db.execute("DELETE FROM favorites WHERE user_id = ?", (current_user["id"],))
    # Delete user
    await db.execute("DELETE FROM users WHERE id = ?", (current_user["id"],))
    
    await db.commit()
    return {"message": "Account deleted successfully"}
