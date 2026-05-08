import os
from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType
from pydantic import EmailStr
from dotenv import load_dotenv

load_dotenv()

class EmailService:
    def __init__(self):
        mail_user = os.getenv("MAIL_USERNAME", "")
        self.conf = ConnectionConfig(
            MAIL_USERNAME=mail_user,
            MAIL_PASSWORD=os.getenv("MAIL_PASSWORD", ""),
            MAIL_FROM=os.getenv("MAIL_FROM", mail_user), # Default to username for Gmail compatibility
            MAIL_PORT=int(os.getenv("MAIL_PORT", 587)),
            MAIL_SERVER=os.getenv("MAIL_SERVER", "smtp.gmail.com"),
            MAIL_STARTTLS=True,
            MAIL_SSL_TLS=False,
            USE_CREDENTIALS=True,
            VALIDATE_CERTS=True,
        )
        self.fm = FastMail(self.conf)

    async def send_reset_password_email(self, email: str, code: str):
        html = f"""
        <html>
            <body style="font-family: 'Inter', sans-serif; background-color: #0B1020; color: #F8FAFC; padding: 40px;">
                <div style="max-width: 600px; margin: 0 auto; background-color: #151A2E; border-radius: 24px; padding: 40px; border: 1px solid rgba(255,255,255,0.1);">
                    <h1 style="color: #7C5CFF; margin-bottom: 24px; text-align: center;">Reset Your Password</h1>
                    <p style="font-size: 16px; line-height: 1.6; color: #94A3B8; text-align: center;">
                        Hello, <br><br>
                        We received a request to reset your AuraFit password. Use the 6-character code below to complete the process. This code will expire in 15 minutes.
                    </p>
                    <div style="background-color: #0B1020; border-radius: 20px; padding: 32px; margin: 32px 0; text-align: center; border: 2px dashed #7C5CFF;">
                        <span style="font-size: 42px; font-weight: 900; letter-spacing: 12px; color: #F8FAFC; font-family: monospace;">{code}</span>
                    </div>
                    <p style="font-size: 14px; color: #94A3B8; text-align: center;">
                        If you didn't request this, you can safely ignore this email.
                    </p>
                    <hr style="border: none; border-top: 1px solid rgba(255,255,255,0.1); margin: 32px 0;">
                    <p style="font-size: 12px; color: #64748B; text-align: center;">
                        &copy; 2026 AuraFit AI. Powered by Railway.
                    </p>
                </div>
            </body>
        </html>
        """
        message = MessageSchema(
            subject="AuraFit - Password Reset Code",
            recipients=[email],
            body=html,
            subtype=MessageType.html
        )
        await self.fm.send_message(message)

email_service = EmailService()
