import os
import resend
from dotenv import load_dotenv

load_dotenv()

class EmailService:
    def __init__(self):
        # Initialize Resend with the API Key from environment variables
        resend.api_key = os.getenv("RESEND_API_KEY", "")
        # Resend default "from" address for unverified domains
        self.mail_from = os.getenv("MAIL_FROM", "onboarding@resend.dev")

    async def send_reset_password_email(self, email: str, code: str):
        """Sends a password reset email using the Resend REST API."""
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
                        &copy; 2026 AuraFit AI. Powered by Resend.
                    </p>
                </div>
            </body>
        </html>
        """
        
        try:
            params = {
                "from": self.mail_from,
                "to": [email],
                "subject": "AuraFit - Password Reset Code",
                "html": html,
            }
            # Note: Resend Python library is synchronous, but we'll call it within our async flow
            # For even better performance, we could use an async executor, 
            # but since we already use BackgroundTasks in the route, this is fine.
            resend.Emails.send(params)
            print(f"[OK] Email sent via Resend to {email}")
        except Exception as e:
            print(f"[ERROR] Resend failed: {e}")
            raise e

email_service = EmailService()
