import pandas as pd
from pathlib import Path

from database_connection import get_connection


# ============================================================
# CONFIGURATION
# ============================================================

SCHEMA = "ecommerce"

PROJECT_ROOT = Path(__file__).resolve().parent.parent

PROCESSED_DIR = PROJECT_ROOT / "Data" / "Processed"

PROCESSED_DIR.mkdir(parents=True, exist_ok=True)


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


# ============================================================
# DATE COLUMNS
# ============================================================

DATE_COLUMNS = {
    "customers": [
        "customer_signup_date",
        "last_order_date"
    ],

    "products": [
        "product_launch_date"
    ],

    "marketing_campaigns": [
        "campaign_start_date",
        "campaign_end_date"
    ],

    "orders": [
        "order_date"
    ],

    "payments": [
        "payment_date"
    ],

    "shipments": [
        "dispatch_date",
        "expected_delivery_date",
        "actual_delivery_date"
    ],

    "returns": [
        "return_date"
    ],

    "customer_reviews": [
        "review_date"
    ]
}


# ============================================================
# LOAD DATA FROM POSTGRESQL
# ============================================================

def load_table(connection, table_name):

    query = f"""
        SELECT *
        FROM {SCHEMA}.{table_name};
    """

    dataframe = pd.read_sql_query(
        query,
        connection
    )

    return dataframe


# ============================================================
# STANDARDIZE COLUMN NAMES
# ============================================================

def standardize_column_names(dataframe):

    dataframe.columns = [
        column.strip().lower().replace(" ", "_")
        for column in dataframe.columns
    ]

    return dataframe


# ============================================================
# CLEAN TEXT COLUMNS
# ============================================================

def clean_text_columns(dataframe):

    text_columns = dataframe.select_dtypes(
        include=["object"]
    ).columns

    for column in text_columns:

        dataframe[column] = dataframe[column].apply(
            lambda value:
            value.strip()
            if isinstance(value, str)
            else value
        )

    return dataframe


# ============================================================
# CONVERT DATE COLUMNS
# ============================================================

def convert_date_columns(dataframe, table_name):

    columns = DATE_COLUMNS.get(
        table_name,
        []
    )

    for column in columns:

        if column in dataframe.columns:

            dataframe[column] = pd.to_datetime(
                dataframe[column],
                errors="coerce"
            )

    return dataframe


# ============================================================
# HANDLE CATEGORICAL NULL VALUES
# ============================================================

def handle_categorical_nulls(dataframe):

    categorical_columns = dataframe.select_dtypes(
        include=["object"]
    ).columns

    for column in categorical_columns:

        dataframe[column] = dataframe[column].fillna(
            "Unknown"
        )

    return dataframe


# ============================================================
# REMOVE EXACT DUPLICATES
# ============================================================

def remove_duplicates(dataframe):

    before = len(dataframe)

    dataframe = dataframe.drop_duplicates()

    after = len(dataframe)

    duplicates_removed = before - after

    return dataframe, duplicates_removed


# ============================================================
# DATA CLEANING FOR ONE TABLE
# ============================================================

def clean_table(dataframe, table_name):

    print(f"\nCleaning table: {table_name}")

    original_rows = len(dataframe)

    # 1. Standardize column names
    dataframe = standardize_column_names(
        dataframe
    )

    # 2. Clean text
    dataframe = clean_text_columns(
        dataframe
    )

    # 3. Convert dates
    dataframe = convert_date_columns(
        dataframe,
        table_name
    )

    # 4. Fill categorical NULLs
    dataframe = handle_categorical_nulls(
        dataframe
    )

    # 5. Remove exact duplicate rows
    dataframe, duplicates_removed = remove_duplicates(
        dataframe
    )

    final_rows = len(dataframe)

    print(
        f"  Original rows     : {original_rows:,}"
    )

    print(
        f"  Duplicates removed: {duplicates_removed:,}"
    )

    print(
        f"  Final rows        : {final_rows:,}"
    )

    return dataframe, duplicates_removed


# ============================================================
# SAVE PROCESSED DATA
# ============================================================

def save_processed_data(
    dataframe,
    table_name
):

    output_path = (
        PROCESSED_DIR /
        f"{table_name}_cleaned.csv"
    )

    dataframe.to_csv(
        output_path,
        index=False
    )

    print(
        f"  Saved             : {output_path}"
    )


# ============================================================
# CREATE CLEANING REPORT
# ============================================================

def create_cleaning_report(report):

    report_dataframe = pd.DataFrame(
        report
    )

    report_path = (
        PROCESSED_DIR /
        "data_cleaning_report.csv"
    )

    report_dataframe.to_csv(
        report_path,
        index=False
    )

    print(
        f"\nCleaning report saved:"
        f"\n{report_path}"
    )


# ============================================================
# MAIN PROGRAM
# ============================================================

def main():

    print("\n")
    print("=" * 65)
    print("INTELLIGENT BUSINESS ANALYTICS")
    print("DATA CLEANING & PREPARATION")
    print("=" * 65)

    connection = None

    cleaning_report = []

    try:

        # ----------------------------------------------------
        # CONNECT TO POSTGRESQL
        # ----------------------------------------------------

        connection = get_connection()

        print("\n✓ PostgreSQL connection successful")

        # ----------------------------------------------------
        # PROCESS EACH TABLE
        # ----------------------------------------------------

        for table_name in TABLES:

            dataframe = load_table(
                connection,
                table_name
            )

            cleaned_dataframe, duplicates_removed = clean_table(
                dataframe,
                table_name
            )

            # ------------------------------------------------
            # NULL COUNT AFTER CLEANING
            # ------------------------------------------------

            remaining_nulls = int(
                cleaned_dataframe.isnull().sum().sum()
            )

            # ------------------------------------------------
            # SAVE PROCESSED TABLE
            # ------------------------------------------------

            save_processed_data(
                cleaned_dataframe,
                table_name
            )

            # ------------------------------------------------
            # ADD TO REPORT
            # ------------------------------------------------

            cleaning_report.append({
                "table_name": table_name,
                "original_rows": len(dataframe),
                "final_rows": len(cleaned_dataframe),
                "duplicates_removed": duplicates_removed,
                "remaining_null_values": remaining_nulls
            })

        # ----------------------------------------------------
        # CREATE REPORT
        # ----------------------------------------------------

        create_cleaning_report(
            cleaning_report
        )

        print("\n" + "=" * 65)
        print("✓ DATA CLEANING COMPLETED SUCCESSFULLY")
        print("=" * 65)

    except Exception as error:

        print("\n" + "=" * 65)
        print("✗ DATA CLEANING FAILED")
        print("=" * 65)

        print(
            f"Error: {error}"
        )

    finally:

        if connection:
            connection.close()

            print(
                "\n✓ Database connection closed"
            )


# ============================================================
# RUN PROGRAM
# ============================================================

if __name__ == "__main__":
    main()