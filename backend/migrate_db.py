import sqlite3
import os

DATABASE_PATH = os.path.join(os.path.dirname(__file__), "data", "app.db")

def migrate():
    if not os.path.exists(DATABASE_PATH):
        print("Database file not found. Nothing to migrate.")
        return

    conn = sqlite3.connect(DATABASE_PATH)
    cursor = conn.cursor()

    columns_to_add = [
        ("plan_type", "TEXT DEFAULT 'FREE'"),
        ("credits", "INTEGER DEFAULT 5"),
        ("plan_expires_at", "TIMESTAMP"),
        ("last_credit_reset", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
    ]

    for col_name, col_def in columns_to_add:
        try:
            print(f"Adding column {col_name}...")
            cursor.execute(f"ALTER TABLE users ADD COLUMN {col_name} {col_def}")
            conn.commit()
            print(f"[OK] Added {col_name}")
        except sqlite3.OperationalError:
            print(f"[SKIP] Column {col_name} already exists.")

    conn.close()
    print("\nMigration complete! You can now restart your backend.")

if __name__ == "__main__":
    migrate()
