import sqlite3
import os

DATABASE_PATH = os.path.join(os.path.dirname(__file__), "data", "app.db")

def migrate():
    if not os.path.exists(DATABASE_PATH):
        print(f"Database file not found at {DATABASE_PATH}. init_db will create it with new columns.")
        return

    conn = sqlite3.connect(DATABASE_PATH)
    cursor = conn.cursor()

    columns_to_add = [
        ("reset_code", "TEXT"),
        ("reset_code_expires_at", "TIMESTAMP")
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
    print("\nMigration complete!")

if __name__ == "__main__":
    migrate()
