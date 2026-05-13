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
                referral_code TEXT UNIQUE,
                referred_by INTEGER,
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
        
        # Auto-migration for existing databases
        try:
            await db.execute("ALTER TABLE users ADD COLUMN reset_code TEXT")
        except:
            pass 
            
        try:
            await db.execute("ALTER TABLE users ADD COLUMN reset_code_expires_at TIMESTAMP")
        except:
            pass
            
        try:
            await db.execute("ALTER TABLE users ADD COLUMN referral_code TEXT")
        except:
            pass
            
        try:
            await db.execute("ALTER TABLE users ADD COLUMN referred_by INTEGER")
        except:
            pass

        # Create index after migration ensures column exists
        try:
            await db.execute("""
                CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code)
            """)
        except:
            pass

        # Backfill referral codes for existing users who don't have one
        import string, random
        cursor = await db.execute("SELECT id FROM users WHERE referral_code IS NULL")
        rows = await cursor.fetchall()
        for row in rows:
            for _ in range(10):
                code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
                try:
                    await db.execute(
                        "UPDATE users SET referral_code = ? WHERE id = ? AND referral_code IS NULL",
                        (code, row[0])
                    )
                    print(f"[OK] Backfilled referral code for user {row[0]}: {code}")
                    break
                except Exception:
                    continue
            
        await db.commit()
        print("[OK] Database initialized successfully.")
