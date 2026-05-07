from fastapi import APIRouter, Depends, HTTPException, status
import aiosqlite

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
    decode_token,
)
from app.dependencies import get_current_user
from app.services.email_service import email_service
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

auth_router = APIRouter()


# ─── Helper ───────────────────────────────────────────────────────

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
    cursor = await db.execute(
        "INSERT INTO users (name, email, hashed_password) VALUES (?, ?, ?)",
        (body.name, body.email, hashed),
    )
    await db.commit()
    user_id = cursor.lastrowid

    # Fetch the created user
    cursor = await db.execute(
        "SELECT id, name, email, plan_type, credits, plan_expires_at, created_at FROM users WHERE id = ?", (user_id,)
    )
    row = await cursor.fetchone()
    user_dict = {
        "id": row[0], "name": row[1], "email": row[2], 
        "plan_type": row[3], "credits": row[4], 
        "plan_expires_at": row[5], "created_at": row[6]
    }

    print(f"[OK] New user registered: {body.email}")
    return _make_tokens(user_id, user_dict)


# ─── Login ────────────────────────────────────────────────────────

@auth_router.post("/login", response_model=TokenResponse)
async def login(body: UserLogin, db: aiosqlite.Connection = Depends(get_db)):
    """Authenticate a user and return tokens."""
    cursor = await db.execute(
        "SELECT id, name, email, hashed_password, plan_type, credits, plan_expires_at, created_at FROM users WHERE email = ?",
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
        "plan_expires_at": row[6], "created_at": row[7]
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
        "SELECT id, name, email, plan_type, credits, plan_expires_at, created_at FROM users WHERE id = ?",
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
        "plan_expires_at": row[5], "created_at": row[6]
    }
    return _make_tokens(row[0], user_dict)


# ─── Get Current User ────────────────────────────────────────────

@auth_router.get("/me", response_model=UserResponse)
async def get_me(current_user: dict = Depends(get_current_user)):
    """Return the currently authenticated user's profile."""
    return UserResponse(**current_user)


# ─── Forgot/Reset Password ──────────────────────────────────────

@auth_router.post("/forgot-password", response_model=MessageResponse)
async def forgot_password(body: ForgotPasswordRequest, db: aiosqlite.Connection = Depends(get_db)):
    """Request a password reset link (real email)."""
    cursor = await db.execute("SELECT id FROM users WHERE email = ?", (body.email,))
    if not await cursor.fetchone():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No account found with this email address."
        )

    token = create_reset_token(body.email)
    
    # Send real email
    try:
        await email_service.send_reset_password_email(body.email, token)
        print(f"[OK] Reset email sent to: {body.email}")
    except Exception as e:
        print(f"[ERROR] Failed to send email: {e}")
        # Still return 200 to avoid email harvesting, or 500 if you want to be explicit
        return {"message": "If an account with that email exists, a reset link has been sent."}
    
    return {"message": "Reset link has been sent to your email."}


@auth_router.post("/reset-password", response_model=MessageResponse)
async def reset_password(body: ResetPasswordRequest, db: aiosqlite.Connection = Depends(get_db)):
    """Reset password using a valid token."""
    payload = decode_token(body.token)
    if payload is None or payload.get("type") != "reset" or payload.get("sub") != body.email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired reset token",
        )

    hashed = hash_password(body.new_password)
    await db.execute(
        "UPDATE users SET hashed_password = ? WHERE email = ?",
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
            "SELECT id, name, email, plan_type, credits, plan_expires_at, created_at FROM users WHERE email = ?", 
            (email,)
        )
        row = await cursor.fetchone()
        
        if not row:
            # Create new user
            cursor = await db.execute(
                "INSERT INTO users (name, email, hashed_password) VALUES (?, ?, ?)",
                (name, email, "GOOGLE_AUTH_USER") # Placeholder password
            )
            await db.commit()
            user_id = cursor.lastrowid
            user_dict = {
                "id": user_id, "name": name, "email": email, 
                "plan_type": "FREE", "credits": 5, 
                "plan_expires_at": None, "created_at": None
            }
        else:
            user_id = row[0]
            user_dict = {
                "id": row[0], "name": row[1], "email": row[2],
                "plan_type": row[3], "credits": row[4],
                "plan_expires_at": row[5], "created_at": row[6]
            }
            
        print(f"[OK] Google Login: {email}")
        return _make_tokens(user_id, user_dict)
        
    except ValueError as e:
        # Invalid token
        raise HTTPException(status_code=401, detail=f"Invalid Google Token: {e}")
