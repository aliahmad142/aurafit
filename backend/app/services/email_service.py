import os
from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType
from pydantic import EmailStr
from dotenv import load_dotenv

load_dotenv()

class EmailService:
    def __init__(self):
        self.conf = ConnectionConfig(
            MAIL_USERNAME=os.getenv("MAIL_USERNAME", ""),
            MAIL_PASSWORD=os.getenv("MAIL_PASSWORD", ""),
            MAIL_FROM=os.getenv("MAIL_FROM", "noreply@aurafit.ai"),
            MAIL_PORT=int(os.getenv("MAIL_PORT", 587)),
            MAIL_SERVER=os.getenv("MAIL_SERVER", "smtp.gmail.com"),
            MAIL_STARTTLS=True,
            MAIL_SSL_TLS=False,
            USE_CREDENTIALS=True,
            VALIDATE_CERTS=True,
        )
        self.fm = FastMail(self.conf)

    async def send_reset_password_email(self, email: str, token: str):
        html = f"""
        <html>
            <body style="font-family: 'Inter', sans-serif; background-color: #0B1020; color: #F8FAFC; padding: 40px;">
                <div style="max-width: 600px; margin: 0 auto; background-color: #151A2E; border-radius: 24px; padding: 40px; border: 1px solid rgba(255,255,255,0.1);">
                    <h1 style="color: #7C5CFF; margin-bottom: 24px;">Reset Your Password</h1>
                    <p style="font-size: 16px; line-height: 1.6; color: #94A3B8;">
                        Hello, <br><br>
                        We received a request to reset your AuraFit password. Use the token below to complete the process. This token will expire in 15 minutes.
                    </p>
                    <div style="background-color: #0B1020; border-radius: 12px; padding: 20px; margin: 32px 0; text-align: center; border: 1px solid #7C5CFF;">
                        <span style="font-size: 24px; font-weight: bold; letter-spacing: 4px; color: #F8FAFC;">{token}</span>
                    </div>
                    <p style="font-size: 14px; color: #94A3B8;">
                        If you didn't request this, you can safely ignore this email.
                    </p>
                    <hr style="border: none; border-top: 1px solid rgba(255,255,255,0.1); margin: 32px 0;">
                    <p style="font-size: 12px; color: #64748B; text-align: center;">
                        &copy; 2026 AuraFit AI. All rights reserved.
                    </p>
                </div>
            </body>
        </html>
        """
        message = MessageSchema(
            subject="AuraFit - Password Reset",
            recipients=[email],
            body=html,
            subtype=MessageType.html
        )
        await self.fm.send_message(message)

email_service = EmailService()
