import os
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


# Load .env from the project root
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(env_path)


def get_connection():
    connection = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )

    return connection


if __name__ == "__main__":
    try:
        connection = get_connection()

        print("✅ PostgreSQL connection successful!")

        cursor = connection.cursor()
        cursor.execute("SELECT version();")

        version = cursor.fetchone()[0]
        print("PostgreSQL version:")
        print(version)

        cursor.close()
        connection.close()

        print("✅ Connection closed successfully.")

    except Exception as error:
        print("❌ Database connection failed!")
        print(error)