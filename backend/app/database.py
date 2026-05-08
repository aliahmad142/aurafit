import aiosqlite
import os

DATABASE_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "app.db")


async def get_db():
    """Yield an aiosqlite connection for use in route handlers."""
    os.makedirs(os.path.dirname(DATABASE_PATH), exist_ok=True)
    async with aiosqlite.connect(DATABASE_PATH) as db:
        db.row_factory = aiosqlite.Row
        yield db


async def init_db():
    """Create tables if they don't exist yet."""
    os.makedirs(os.path.dirname(DATABASE_PATH), exist_ok=True)
    async with aiosqlite.connect(DATABASE_PATH) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                hashed_password TEXT NOT NULL,
                plan_type TEXT DEFAULT 'FREE', -- FREE, DAILY
                credits INTEGER DEFAULT 5,
                plan_expires_at TIMESTAMP,
                last_credit_reset TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                reset_code TEXT,
                reset_code_expires_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS favorites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                image_url TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)
        await db.execute("""
            CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)
        """)
        await db.commit()
        print("[OK] Database initialized successfully.")
