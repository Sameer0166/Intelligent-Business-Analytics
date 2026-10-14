import pandas as pd
from pathlib import Path


# ============================================================
# CONFIGURATION
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

PROCESSED_DIR = PROJECT_ROOT / "Data" / "Processed"

OUTPUT_DIR = PROJECT_ROOT / "Documentation" / "reports"

OUTPUT_DIR.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# LOAD CLEANED DATA
# ============================================================

def load_data():

    print("\n" + "=" * 65)
    print("LOADING CLEANED DATA")
    print("=" * 65)

    data = {}

    tables = [
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

    for table in tables:

        file_path = (
            PROCESSED_DIR /
            f"{table}_cleaned.csv"
        )

        data[table] = pd.read_csv(
            file_path
        )

        print(
            f"✓ {table:<25} "
            f"{len(data[table]):,} rows"
        )

    return data


# ============================================================
# PREPARE DATE COLUMNS
# ============================================================

def prepare_dates(data):

    date_columns = {
        "orders": ["order_date"],
        "payments": ["payment_date"],
        "shipments": [
            "dispatch_date",
            "expected_delivery_date",
            "actual_delivery_date"
        ],
        "returns": ["return_date"],
        "customer_reviews": ["review_date"],
        "marketing_campaigns": [
            "campaign_start_date",
            "campaign_end_date"
        ]
    }

    for table, columns in date_columns.items():

        for column in columns:

            if column in data[table].columns:

                data[table][column] = pd.to_datetime(
                    data[table][column],
                    errors="coerce"
                )

    return data


# ============================================================
# 1. EXECUTIVE KPIs
# ============================================================

def executive_kpis(data):

    orders = data["orders"]
    order_items = data["order_items"]

    total_orders = orders["order_id"].nunique()

    total_customers = (
        orders["customer_id"]
        .nunique()
    )

    total_revenue = (
        orders["final_amount"]
        .sum()
    )

    total_profit = (
        order_items["profit"]
        .sum()
    )

    average_order_value = (
        total_revenue / total_orders
        if total_orders > 0
        else 0
    )

    total_units = (
        order_items["quantity"]
        .sum()
    )

    result = pd.DataFrame({
        "metric": [
            "Total Orders",
            "Total Customers",
            "Total Revenue",
            "Total Profit",
            "Average Order Value",
            "Total Units Sold"
        ],

        "value": [
            total_orders,
            total_customers,
            round(total_revenue, 2),
            round(total_profit, 2),
            round(average_order_value, 2),
            total_units
        ]
    })

    print("\n" + "=" * 65)
    print("1. EXECUTIVE KPIs")
    print("=" * 65)

    print(result.to_string(index=False))

    return result


# ============================================================
# 2. MONTHLY SALES ANALYSIS
# ============================================================

def monthly_sales_analysis(data):

    orders = data["orders"].copy()

    orders["month"] = (
        orders["order_date"]
        .dt.to_period("M")
        .astype(str)
    )

    monthly = (
        orders
        .groupby("month")
        .agg(
            orders=("order_id", "nunique"),
            customers=("customer_id", "nunique"),
            revenue=("final_amount", "sum")
        )
        .reset_index()
    )

    monthly["average_order_value"] = (
        monthly["revenue"]
        / monthly["orders"]
    )

    monthly = monthly.round(2)

    output_path = (
        OUTPUT_DIR /
        "monthly_sales_analysis.csv"
    )

    monthly.to_csv(
        output_path,
        index=False
    )

    print("\n" + "=" * 65)
    print("2. MONTHLY SALES ANALYSIS")
    print("=" * 65)

    print(
        monthly.tail(12).to_string(
            index=False
        )
    )

    print(
        f"\n✓ Saved: {output_path}"
    )

    return monthly


# ============================================================
# 3. PRODUCT PERFORMANCE
# ============================================================

def product_performance(data):

    order_items = data["order_items"]

    products = data["products"][
        [
            "product_id",
            "product_name",
            "category",
            "subcategory",
            "brand"
        ]
    ]

    product_analysis = (
        order_items
        .groupby("product_id")
        .agg(
            units_sold=("quantity", "sum"),
            revenue=("item_revenue", "sum"),
            profit=("profit", "sum"),
            orders=("order_id", "nunique")
        )
        .reset_index()
    )

    product_analysis = product_analysis.merge(
        products,
        on="product_id",
        how="left"
    )

    product_analysis["profit_margin_percentage"] = (
        product_analysis["profit"]
        / product_analysis["revenue"]
        * 100
    )

    product_analysis = product_analysis.round(2)

    product_analysis = product_analysis.sort_values(
        "revenue",
        ascending=False
    )

    output_path = (
        OUTPUT_DIR /
        "product_performance.csv"
    )

    product_analysis.to_csv(
        output_path,
        index=False
    )

    print("\n" + "=" * 65)
    print("3. PRODUCT PERFORMANCE")
    print("=" * 65)

    print(
        product_analysis.head(10).to_string(
            index=False
        )
    )

    print(
        f"\n✓ Saved: {output_path}"
    )

    return product_analysis


# ============================================================
# 4. CUSTOMER PERFORMANCE
# ============================================================

def customer_performance(data):

    orders = data["orders"]

    customer_analysis = (
        orders
        .groupby("customer_id")
        .agg(
            total_orders=("order_id", "nunique"),
            total_spend=("final_amount", "sum"),
            average_order_value=("final_amount", "mean"),
            last_order_date=("order_date", "max")
        )
        .reset_index()
    )

    customer_analysis["customer_value_category"] = pd.cut(
        customer_analysis["total_spend"],
        bins=[
            -float("inf"),
            5000,
            20000,
            50000,
            float("inf")
        ],
        labels=[
            "Low Value",
            "Medium Value",
            "High Value",
            "Very High Value"
        ]
    )

    customer_analysis = customer_analysis.round(2)

    output_path = (
        OUTPUT_DIR /
        "customer_performance.csv"
    )

    customer_analysis.to_csv(
        output_path,
        index=False
    )

    print("\n" + "=" * 65)
    print("4. CUSTOMER PERFORMANCE")
    print("=" * 65)

    print(
        customer_analysis
        .sort_values(
            "total_spend",
            ascending=False
        )
        .head(10)
        .to_string(index=False)
    )

    print(
        f"\n✓ Saved: {output_path}"
    )

    return customer_analysis


# ============================================================
# 5. REGIONAL PERFORMANCE
# ============================================================

def regional_performance(data):

    orders = data["orders"]

    regional = (
        orders
        .groupby("delivery_state")
        .agg(
            orders=("order_id", "nunique"),
            customers=("customer_id", "nunique"),
            revenue=("final_amount", "sum")
        )
        .reset_index()
    )

    regional["average_order_value"] = (
        regional["revenue"]
        / regional["orders"]
    )

    regional = regional.round(2)

    regional = regional.sort_values(
        "revenue",
        ascending=False
    )

    output_path = (
        OUTPUT_DIR /
        "regional_performance.csv"
    )

    regional.to_csv(
        output_path,
        index=False
    )

    print("\n" + "=" * 65)
    print("5. REGIONAL PERFORMANCE")
    print("=" * 65)

    print(
        regional.head(10).to_string(
            index=False
        )
    )

    print(
        f"\n✓ Saved: {output_path}"
    )

    return regional


# ============================================================
# 6. RETURN ANALYSIS
# ============================================================

def return_analysis(data):

    returns = data["returns"]
    orders = data["orders"]

    total_orders = (
        orders["order_id"]
        .nunique()
    )

    returned_orders = (
        returns["order_id"]
        .nunique()
    )

    return_rate = (
        returned_orders
        / total_orders
        * 100
        if total_orders > 0
        else 0
    )

    summary = pd.DataFrame({
        "metric": [
            "Total Orders",
            "Returned Orders",
            "Return Rate (%)",
            "Total Refund Amount"
        ],

        "value": [
            total_orders,
            returned_orders,
            round(return_rate, 2),
            round(
                returns["refund_amount"].sum(),
                2
            )
        ]
    })

    output_path = (
        OUTPUT_DIR /
        "return_analysis.csv"
    )

    summary.to_csv(
        output_path,
        index=False
    )

    print("\n" + "=" * 65)
    print("6. RETURN ANALYSIS")
    print("=" * 65)

    print(
        summary.to_string(
            index=False
        )
    )

    print(
        f"\n✓ Saved: {output_path}"
    )

    return summary


# ============================================================
# 7. SHIPPING PERFORMANCE
# ============================================================

def shipping_performance(data):

    shipments = data["shipments"]

    shipping = (
        shipments
        .groupby("shipping_method")
        .agg(
            shipments=("shipment_id", "count"),
            average_delivery_days=(
                "delivery_days",
                "mean"
            ),
            delayed_shipments=(
                "delayed_flag",
                "sum"
            )
        )
        .reset_index()
    )

    shipping["delay_rate_percentage"] = (
        shipping["delayed_shipments"]
        / shipping["shipments"]
        * 100
    )

    shipping = shipping.round(2)

    output_path = (
        OUTPUT_DIR /
        "shipping_performance.csv"
    )

    shipping.to_csv(
        output_path,
        index=False
    )

    print("\n" + "=" * 65)
    print("7. SHIPPING PERFORMANCE")
    print("=" * 65)

    print(
        shipping.to_string(
            index=False
        )
    )

    print(
        f"\n✓ Saved: {output_path}"
    )

    return shipping


# ============================================================
# 8. MARKETING PERFORMANCE
# ============================================================

def marketing_performance(data):

    campaigns = data["marketing_campaigns"]

    marketing = (
        campaigns
        .groupby("channel")
        .agg(
            campaigns=("campaign_id", "count"),
            impressions=("impressions", "sum"),
            clicks=("clicks", "sum"),
            conversions=("conversions", "sum"),
            campaign_cost=("campaign_cost", "sum"),
            revenue_generated=(
                "revenue_generated",
                "sum"
            )
        )
        .reset_index()
    )

    marketing["click_through_rate_percentage"] = (
        marketing["clicks"]
        / marketing["impressions"]
        * 100
    )

    marketing["conversion_rate_percentage"] = (
        marketing["conversions"]
        / marketing["clicks"]
        * 100
    )

    marketing["roi_percentage"] = (
        (
            marketing["revenue_generated"]
            - marketing["campaign_cost"]
        )
        / marketing["campaign_cost"]
        * 100
    )

    marketing = marketing.replace(
        [float("inf"), -float("inf")],
        0
    )

    marketing = marketing.round(2)

    output_path = (
        OUTPUT_DIR /
        "marketing_performance.csv"
    )

    marketing.to_csv(
        output_path,
        index=False
    )

    print("\n" + "=" * 65)
    print("8. MARKETING PERFORMANCE")
    print("=" * 65)

    print(
        marketing.sort_values(
            "revenue_generated",
            ascending=False
        ).to_string(index=False)
    )

    print(
        f"\n✓ Saved: {output_path}"
    )

    return marketing


# ============================================================
# 9. PAYMENT ANALYSIS
# ============================================================

def payment_analysis(data):

    payments = data["payments"]

    payment = (
        payments
        .groupby("payment_method")
        .agg(
            transactions=("payment_id", "count"),
            amount_paid=("amount_paid", "sum"),
            refund_amount=("refund_amount", "sum"),
            transaction_fee=(
                "transaction_fee",
                "sum"
            )
        )
        .reset_index()
    )

    payment = payment.round(2)

    output_path = (
        OUTPUT_DIR /
        "payment_analysis.csv"
    )

    payment.to_csv(
        output_path,
        index=False
    )

    print("\n" + "=" * 65)
    print("9. PAYMENT ANALYSIS")
    print("=" * 65)

    print(
        payment.sort_values(
            "amount_paid",
            ascending=False
        ).to_string(index=False)
    )

    print(
        f"\n✓ Saved: {output_path}"
    )

    return payment


# ============================================================
# 10. CUSTOMER REVIEW & SENTIMENT ANALYSIS
# ============================================================

def review_sentiment_analysis(data):

    reviews = data["customer_reviews"]

    sentiment = (
        reviews
        .groupby("review_sentiment")
        .agg(
            reviews=("review_id", "count"),
            average_rating=("rating", "mean")
        )
        .reset_index()
    )

    sentiment = sentiment.round(2)

    output_path = (
        OUTPUT_DIR /
        "review_sentiment_analysis.csv"
    )

    sentiment.to_csv(
        output_path,
        index=False
    )

    print("\n" + "=" * 65)
    print("10. CUSTOMER REVIEW & SENTIMENT")
    print("=" * 65)

    print(
        sentiment.to_string(
            index=False
        )
    )

    print(
        f"\n✓ Saved: {output_path}"
    )

    return sentiment


# ============================================================
# MAIN PROGRAM
# ============================================================

def main():

    print("\n")
    print("=" * 65)
    print("INTELLIGENT BUSINESS ANALYTICS")
    print("PYTHON BUSINESS ANALYTICS ENGINE")
    print("=" * 65)

    try:

        # ----------------------------------------------------
        # LOAD DATA
        # ----------------------------------------------------

        data = load_data()

        # ----------------------------------------------------
        # PREPARE DATES
        # ----------------------------------------------------

        data = prepare_dates(data)

        print("\n✓ Data preparation completed")

        # ----------------------------------------------------
        # RUN ANALYTICS
        # ----------------------------------------------------

        executive_kpis(data)

        monthly_sales_analysis(data)

        product_performance(data)

        customer_performance(data)

        regional_performance(data)

        return_analysis(data)

        shipping_performance(data)

        marketing_performance(data)

        payment_analysis(data)

        review_sentiment_analysis(data)

        # ----------------------------------------------------
        # COMPLETE
        # ----------------------------------------------------

        print("\n" + "=" * 65)
        print("✓ PYTHON ANALYTICS COMPLETED SUCCESSFULLY")
        print("=" * 65)

        print(
            f"\nReports saved in:\n{OUTPUT_DIR}"
        )

    except Exception as error:

        print("\n" + "=" * 65)
        print("✗ PYTHON ANALYTICS FAILED")
        print("=" * 65)

        print(f"\nError: {error}")


# ============================================================
# RUN PROGRAM
# ============================================================

if __name__ == "__main__":
    main()