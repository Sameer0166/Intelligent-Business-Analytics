from database_connection import get_connection


# ============================================================
# CONFIGURATION
# ============================================================

SCHEMA = "ecommerce"

TABLES = [
    "customers",
    "products",
    "marketing_campaigns",
    "orders",
    "order_items",
    "payments",
    "shipments",
    "returns",
    "customer_reviews"
]

PRIMARY_KEYS = {
    "customers": "customer_id",
    "products": "product_id",
    "marketing_campaigns": "campaign_id",
    "orders": "order_id",
    "order_items": "order_item_id",
    "payments": "payment_id",
    "shipments": "shipment_id",
    "returns": "return_id",
    "customer_reviews": "review_id"
}

FOREIGN_KEYS = {
    "orders": [
        ("customer_id", "customers", "customer_id"),
        ("campaign_id", "marketing_campaigns", "campaign_id")
    ],

    "order_items": [
        ("order_id", "orders", "order_id"),
        ("product_id", "products", "product_id")
    ],

    "payments": [
        ("order_id", "orders", "order_id")
    ],

    "shipments": [
        ("order_id", "orders", "order_id")
    ],

    "returns": [
        ("order_id", "orders", "order_id"),
        ("customer_id", "customers", "customer_id"),
        ("product_id", "products", "product_id")
    ],

    "customer_reviews": [
        ("order_id", "orders", "order_id"),
        ("customer_id", "customers", "customer_id"),
        ("product_id", "products", "product_id")
    ]
}


# ============================================================
# 1. CHECK TABLE EXISTENCE
# ============================================================

def check_tables(cursor):
    print("\n" + "=" * 60)
    print("1. TABLE EXISTENCE CHECK")
    print("=" * 60)

    all_exist = True

    for table in TABLES:

        cursor.execute("""
            SELECT EXISTS (
                SELECT 1
                FROM information_schema.tables
                WHERE table_schema = %s
                AND table_name = %s
            );
        """, (SCHEMA, table))

        exists = cursor.fetchone()[0]

        if exists:
            print(f"✓ {table}")
        else:
            print(f"✗ {table} - NOT FOUND")
            all_exist = False

    return all_exist


# ============================================================
# 2. ROW COUNT CHECK
# ============================================================

def check_row_counts(cursor):
    print("\n" + "=" * 60)
    print("2. ROW COUNT CHECK")
    print("=" * 60)

    for table in TABLES:

        query = f"""
            SELECT COUNT(*)
            FROM {SCHEMA}.{table};
        """

        cursor.execute(query)

        row_count = cursor.fetchone()[0]

        print(f"{table:<25} : {row_count:,} rows")


# ============================================================
# 3. NULL VALUE CHECK
# ============================================================

def check_null_values(cursor):
    print("\n" + "=" * 60)
    print("3. NULL VALUE CHECK")
    print("=" * 60)

    for table in TABLES:

        # Get all columns
        cursor.execute("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = %s
            AND table_name = %s
            ORDER BY ordinal_position;
        """, (SCHEMA, table))

        columns = [row[0] for row in cursor.fetchall()]

        table_nulls = 0

        for column in columns:

            query = f"""
                SELECT COUNT(*)
                FROM {SCHEMA}.{table}
                WHERE "{column}" IS NULL;
            """

            cursor.execute(query)

            null_count = cursor.fetchone()[0]

            if null_count > 0:
                print(
                    f"⚠ {table}.{column} -> "
                    f"{null_count:,} NULL values"
                )

                table_nulls += null_count

        if table_nulls == 0:
            print(f"✓ {table} -> No NULL values")


# ============================================================
# 4. DUPLICATE PRIMARY KEY CHECK
# ============================================================

def check_duplicate_primary_keys(cursor):
    print("\n" + "=" * 60)
    print("4. DUPLICATE PRIMARY KEY CHECK")
    print("=" * 60)

    all_valid = True

    for table, primary_key in PRIMARY_KEYS.items():

        query = f"""
            SELECT "{primary_key}", COUNT(*)
            FROM {SCHEMA}.{table}
            GROUP BY "{primary_key}"
            HAVING COUNT(*) > 1;
        """

        cursor.execute(query)

        duplicates = cursor.fetchall()

        if not duplicates:
            print(f"✓ {table}.{primary_key} -> No duplicates")
        else:
            print(
                f"✗ {table}.{primary_key} -> "
                f"{len(duplicates)} duplicate values"
            )
            all_valid = False

    return all_valid


# ============================================================
# 5. FOREIGN KEY INTEGRITY CHECK
# ============================================================

def check_foreign_keys(cursor):
    print("\n" + "=" * 60)
    print("5. FOREIGN KEY INTEGRITY CHECK")
    print("=" * 60)

    all_valid = True

    for child_table, relationships in FOREIGN_KEYS.items():

        for child_column, parent_table, parent_column in relationships:

            query = f"""
                SELECT COUNT(*)
                FROM {SCHEMA}.{child_table} child
                LEFT JOIN {SCHEMA}.{parent_table} parent
                    ON child."{child_column}"
                    = parent."{parent_column}"
                WHERE child."{child_column}" IS NOT NULL
                AND parent."{parent_column}" IS NULL;
            """

            cursor.execute(query)

            orphan_count = cursor.fetchone()[0]

            relationship = (
                f"{child_table}.{child_column} → "
                f"{parent_table}.{parent_column}"
            )

            if orphan_count == 0:
                print(f"✓ {relationship}")
            else:
                print(
                    f"✗ {relationship} -> "
                    f"{orphan_count:,} orphan records"
                )
                all_valid = False

    return all_valid


# ============================================================
# 6. VALIDATION SUMMARY
# ============================================================

def print_summary(
    tables_valid,
    primary_keys_valid,
    foreign_keys_valid
):
    print("\n" + "=" * 60)
    print("6. VALIDATION SUMMARY")
    print("=" * 60)

    print(
        f"Table existence       : "
        f"{'PASS' if tables_valid else 'FAIL'}"
    )

    print(
        f"Primary key integrity : "
        f"{'PASS' if primary_keys_valid else 'FAIL'}"
    )

    print(
        f"Foreign key integrity : "
        f"{'PASS' if foreign_keys_valid else 'FAIL'}"
    )

    if (
        tables_valid
        and primary_keys_valid
        and foreign_keys_valid
    ):
        print("\n✓ DATA VALIDATION COMPLETED SUCCESSFULLY")
    else:
        print("\n⚠ DATA VALIDATION FOUND ISSUES")

    print("=" * 60)


# ============================================================
# MAIN PROGRAM
# ============================================================

def main():

    print("\n")
    print("=" * 60)
    print("INTELLIGENT BUSINESS ANALYTICS")
    print("AUTOMATED DATA VALIDATION")
    print("=" * 60)

    connection = None
    cursor = None

    try:

        # Connect to PostgreSQL
        connection = get_connection()
        cursor = connection.cursor()

        print("\n✓ PostgreSQL connection successful")

        # Run validation checks
        tables_valid = check_tables(cursor)

        check_row_counts(cursor)

        check_null_values(cursor)

        primary_keys_valid = check_duplicate_primary_keys(cursor)

        foreign_keys_valid = check_foreign_keys(cursor)

        # Final summary
        print_summary(
            tables_valid,
            primary_keys_valid,
            foreign_keys_valid
        )

    except Exception as error:

        print("\n✗ DATA VALIDATION FAILED")
        print(f"Error: {error}")

    finally:

        if cursor:
            cursor.close()

        if connection:
            connection.close()

        print("\n✓ Database connection closed")


# ============================================================
# RUN PROGRAM
# ============================================================

if __name__ == "__main__":
    main()