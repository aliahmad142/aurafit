from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import aiosqlite

from app.database import get_db
from app.services.auth_service import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: aiosqlite.Connection = Depends(get_db),
) -> dict:
    """
    FastAPI dependency that extracts and validates the JWT from
    the Authorization header, then fetches the corresponding user.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    payload = decode_token(token)
    if payload is None:
        raise credentials_exception

    # Only accept access tokens (not refresh tokens)
    if payload.get("type") != "access":
        raise credentials_exception

    user_id: int | None = payload.get("sub")
    if user_id is None:
        raise credentials_exception

    # Fetch user from database
    cursor = await db.execute(
        "SELECT id, name, email, plan_type, credits, plan_expires_at, created_at, referral_code FROM users WHERE id = ?",
        (int(user_id),),
    )
    row = await cursor.fetchone()
    if row is None:
        raise credentials_exception

    return {
        "id": row[0],
        "name": row[1],
        "email": row[2],
        "plan_type": row[3],
        "credits": row[4],
        "plan_expires_at": row[5],
        "created_at": row[6],
        "referral_code": row[7],
    }
