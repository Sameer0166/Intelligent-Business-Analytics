from database_connection import get_connection

connection = get_connection()
cursor = connection.cursor()

cursor.execute("""
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'ecommerce'
    ORDER BY table_name;
""")

tables = cursor.fetchall()

print("\nTables in ecommerce schema:")
for table in tables:
    print("-", table[0])

cursor.close()
connection.close()