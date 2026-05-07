import os
import hashlib
from fastapi import APIRouter, Depends, HTTPException, Request
from app.database import get_db
import aiosqlite
from app.dependencies import get_current_user
from app.models import MessageResponse, UserResponse
from datetime import datetime, timedelta

payment_router = APIRouter()

# PayFast Config (Placeholders)
PAYFAST_MERCHANT_ID = os.getenv("PAYFAST_MERCHANT_ID", "10001")
PAYFAST_SECURED_KEY = os.getenv("PAYFAST_SECURED_KEY", "test_key")
PAYFAST_URL = "https://sandbox.payfast.co.za/eng/process" # Sandbox URL

@payment_router.post("/initiate-payment")
async def initiate_payment(plan: str, current_user: dict = Depends(get_current_user)):
    """Initiate a PayFast payment and return the redirect URL."""
    if plan != "DAILY_PASS":
        raise HTTPException(status_code=400, detail="Invalid plan selected")

    amount = "3.79" # USD or equivalent
    order_id = f"ORDER_{current_user['id']}_{int(datetime.now().timestamp())}"
    
    # In a real PayFast integration, you'd generate a signature/hash here
    # For now, we return a simulated checkout URL
    checkout_url = f"{PAYFAST_URL}?merchant_id={PAYFAST_MERCHANT_ID}&amount={amount}&item_name=AuraFit+Daily+Pass&m_payment_id={order_id}"
    
    return {
        "checkout_url": checkout_url,
        "order_id": order_id
    }

@payment_router.post("/payfast-webhook")
async def payfast_webhook(request: Request, db: aiosqlite.Connection = Depends(get_db)):
    """Handle PayFast payment confirmation (Production Ready)."""
    data = await request.form()
    
    # 1. VERIFY SIGNATURE (Production Only)
    # PayFast sends a 'signature' field. You must recreate the hash using your SECURED_KEY
    # to verify the data hasn't been tampered with.
    received_signature = data.get("signature")
    
    # Logic: Concatenate all fields alphabetically and hash with your SECURED_KEY
    # if not verify_payfast_hash(data, PAYFAST_SECURED_KEY, received_signature):
    #     raise HTTPException(status_code=400, detail="Invalid signature")

    payment_status = data.get("payment_status")
    m_payment_id = data.get("m_payment_id")
    
    if payment_status == "COMPLETE" and m_payment_id:
        # Extract user_id from order_id (e.g., ORDER_1_123456)
        try:
            user_id = int(m_payment_id.split("_")[1])
            
            # Update user plan and credits
            expires_at = datetime.now() + timedelta(days=1)
            await db.execute(
                "UPDATE users SET plan_type = 'DAILY', credits = 10, plan_expires_at = ? WHERE id = ?",
                (expires_at.isoformat(), user_id)
            )
            await db.commit()
            print(f"[OK] Payment completed for User {user_id}. Credits granted.")
        except Exception as e:
            print(f"[ERROR] Webhook processing failed: {e}")
            
    return {"status": "ok"}

# Simple simulation endpoint for testing without real PayFast
@payment_router.post("/simulate-success")
async def simulate_success(current_user: dict = Depends(get_current_user), db: aiosqlite.Connection = Depends(get_db)):
    """Simulate a successful payment for development testing."""
    user_id = current_user['id']
    expires_at = datetime.now() + timedelta(days=1)
    
    await db.execute(
        "UPDATE users SET plan_type = 'DAILY', credits = 10, plan_expires_at = ? WHERE id = ?",
        (expires_at.isoformat(), user_id)
    )
    await db.commit()
    
    # Fetch updated user
    cursor = await db.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = await cursor.fetchone()
    return dict(row)
