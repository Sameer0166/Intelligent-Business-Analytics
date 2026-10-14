import os
from pathlib import Path
from datetime import datetime, timezone

import requests
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from flask_cors import CORS
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


# ============================================================
# CONFIGURATION
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

load_dotenv(PROJECT_ROOT / ".env")

N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL")
N8N_API_KEY = os.getenv("N8N_API_KEY")

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv(
    "DB_NAME",
    "intelligent_business_analytics"
)
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD")


# ============================================================
# APPLICATION
# ============================================================

app = Flask(__name__)

CORS(
    app,
    resources={
        r"/api/*": {
            "origins": [
                "http://localhost:5173",
                "http://localhost:5174",
            ]
        }
    }
)


# ============================================================
# DATABASE
# ============================================================

def get_database_engine():
    """
    Create a PostgreSQL SQLAlchemy engine using
    environment-based credentials.
    """

    if not DB_PASSWORD:
        raise RuntimeError(
            "DB_PASSWORD is not configured."
        )

    connection_url = URL.create(
        drivername="postgresql+psycopg2",
        username=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME
    )

    return create_engine(
        connection_url,
        pool_pre_ping=True,
        pool_recycle=3600
    )


# ============================================================
# DATABASE HELPERS
# ============================================================

def fetch_one(query, parameters=None):
    """
    Execute a SQL query and return one row as a dictionary.
    """

    engine = get_database_engine()

    with engine.connect() as connection:

        result = connection.execute(
            text(query),
            parameters or {}
        )

        row = result.mappings().first()

        if row is None:
            return {}

        return dict(row)


def fetch_all(query, parameters=None):
    """
    Execute a SQL query and return rows as dictionaries.
    """

    engine = get_database_engine()

    with engine.connect() as connection:

        result = connection.execute(
            text(query),
            parameters or {}
        )

        return [
            dict(row)
            for row in result.mappings().all()
        ]


# ============================================================
# SERIALIZATION
# ============================================================

def serialize_value(value):
    """
    Convert PostgreSQL/Python values into JSON-safe values.
    """

    if isinstance(value, datetime):
        return value.isoformat()

    return value


def serialize_record(record):
    """
    Serialize an individual database record.
    """

    return {
        key: serialize_value(value)
        for key, value in record.items()
    }


def serialize_records(records):
    """
    Serialize a list of database records.
    """

    return [
        serialize_record(record)
        for record in records
    ]


# ============================================================
# ERROR RESPONSE
# ============================================================

def error_response(
    message,
    status_code=500,
    details=None
):
    """
    Standardized API error response.
    """

    response = {
        "status": "error",
        "message": message,
        "timestamp": datetime.now(
            timezone.utc
        ).isoformat()
    }

    if details:
        response["details"] = details

    return jsonify(response), status_code


# ============================================================
# HEALTH
# ============================================================

@app.get("/api/health")
def health_check():
    """
    Platform health endpoint.
    """

    database_status = "unknown"
    n8n_status = "configured"

    # --------------------------------------------------------
    # PostgreSQL health
    # --------------------------------------------------------

    try:

        result = fetch_one(
            "SELECT 1 AS database_connection;"
        )

        if result.get("database_connection") == 1:
            database_status = "healthy"
        else:
            database_status = "unhealthy"

    except Exception:
        database_status = "unavailable"

    # --------------------------------------------------------
    # n8n configuration health
    # --------------------------------------------------------

    if not N8N_WEBHOOK_URL or not N8N_API_KEY:
        n8n_status = "not_configured"

    overall_status = (
        "healthy"
        if database_status == "healthy"
        and n8n_status == "configured"
        else "degraded"
    )

    return jsonify({
        "status": overall_status,

        "platform": {
            "name": (
                "Intelligent Automated "
                "Business Analytics Platform"
            ),
            "version": "v1.0",
            "service": "Flask API"
        },

        "services": {
            "api": "healthy",
            "postgresql": database_status,
            "n8n": n8n_status
        },

        "timestamp": datetime.now(
            timezone.utc
        ).isoformat()
    })


# ============================================================
# EXECUTIVE DASHBOARD
# ============================================================

@app.get("/api/dashboard")
def dashboard():
    """
    Unified executive dashboard endpoint.

    Pulls live metrics from PostgreSQL.
    """

    try:

        kpis = fetch_one(
            """
            WITH order_metrics AS (
                SELECT
                    COUNT(DISTINCT order_id)
                        AS total_orders,

                    COUNT(DISTINCT customer_id)
                        AS total_customers,

                    SUM(final_amount)
                        AS total_revenue
                FROM ecommerce.orders
                WHERE order_date IS NOT NULL
            ),

            profit_metrics AS (
                SELECT
                    COALESCE(
                        SUM(profit),
                        0
                    ) AS total_profit
                FROM ecommerce.order_items
            ),

            return_metrics AS (
                SELECT
                    COUNT(DISTINCT return_id)
                        AS total_returns
                FROM ecommerce.returns
            ),

            shipping_metrics AS (
                SELECT
                    ROUND(
                        AVG(delivery_days),
                        2
                    ) AS average_delivery_days,

                    ROUND(
                        COUNT(*) FILTER (
                            WHERE delayed_flag = 1
                        )::NUMERIC
                        /
                        NULLIF(
                            COUNT(*),
                            0
                        ),
                        4
                    ) AS delayed_shipment_rate
                FROM ecommerce.shipments
            )

            SELECT

                o.total_orders,

                o.total_customers,

                ROUND(
                    o.total_revenue,
                    2
                ) AS total_revenue,

                ROUND(
                    p.total_profit,
                    2
                ) AS total_profit,

                ROUND(
                    o.total_revenue
                    /
                    NULLIF(
                        o.total_orders,
                        0
                    ),
                    2
                ) AS average_order_value,

                r.total_returns,

                ROUND(
                    r.total_returns::NUMERIC
                    /
                    NULLIF(
                        o.total_orders,
                        0
                    ),
                    4
                ) AS return_rate,

                s.average_delivery_days,

                s.delayed_shipment_rate

            FROM order_metrics o

            CROSS JOIN profit_metrics p

            CROSS JOIN return_metrics r

            CROSS JOIN shipping_metrics s;
            """
        )

        latest_forecast = fetch_one(
            """
            SELECT
                forecast_date,
                predicted_revenue,
                model_name,
                model_mape,
                generated_at
            FROM ecommerce.sales_forecasts
            ORDER BY generated_at DESC
            LIMIT 1;
            """
        )

        latest_run = fetch_one(
            """
            SELECT
                run_id,
                execution_time,
                data_quality_status,
                business_status,
                execution_status,
                quality_issue_count
            FROM ecommerce.analytics_run_history
            ORDER BY run_id DESC
            LIMIT 1;
            """
        )

        return jsonify({

            "status": "success",

            "platform": {
                "name": (
                    "Intelligent Automated "
                    "Business Analytics Platform"
                ),
                "version": "v1.0"
            },

            "business_performance": serialize_record(
                kpis
            ),

            "forecast": serialize_record(
                latest_forecast
            ),

            "automation": serialize_record(
                latest_run
            ),

            "timestamp": datetime.now(
                timezone.utc
            ).isoformat()

        })

    except Exception as error:

        return error_response(
            "Unable to load executive dashboard.",
            500,
            str(error)
        )


# ============================================================
# KPI ENDPOINT
# ============================================================

@app.get("/api/kpis")
def get_kpis():
    """
    Return current business KPIs.
    """

    try:

        result = fetch_one(
            """
            SELECT
                COUNT(
                    DISTINCT order_id
                ) AS total_orders,

                COUNT(
                    DISTINCT customer_id
                ) AS total_customers,

                ROUND(
                    SUM(final_amount),
                    2
                ) AS total_revenue

            FROM ecommerce.orders;
            """
        )

        return jsonify({
            "status": "success",
            "data": serialize_record(result)
        })

    except Exception as error:

        return error_response(
            "Unable to retrieve KPIs.",
            500,
            str(error)
        )


# ============================================================
# OPERATIONS
# ============================================================

@app.get("/api/operations")
def operations():
    """
    Operational performance endpoint.
    """

    try:

        performance = fetch_one(
            """
            SELECT

                ROUND(
                    AVG(delivery_days),
                    2
                ) AS average_delivery_days,

                ROUND(
                    COUNT(*) FILTER (
                        WHERE delayed_flag = 1
                    )::NUMERIC
                    /
                    NULLIF(
                        COUNT(*),
                        0
                    ),
                    4
                ) AS delayed_shipment_rate

            FROM ecommerce.shipments;
            """
        )

        returns = fetch_all(
            """
            SELECT
                return_reason,
                COUNT(*) AS return_count
            FROM ecommerce.returns
            GROUP BY return_reason
            ORDER BY return_count DESC;
            """
        )

        return jsonify({

            "status": "success",

            "performance": serialize_record(
                performance
            ),

            "returns": serialize_records(
                returns
            )

        })

    except Exception as error:

        return error_response(
            "Unable to retrieve operational analytics.",
            500,
            str(error)
        )


# ============================================================
# FORECAST
# ============================================================

@app.get("/api/forecast")
def forecast():
    """
    Return the latest ML revenue forecast.
    """

    try:

        result = fetch_one(
            """
            SELECT
                forecast_id,
                forecast_date,
                predicted_revenue,
                model_name,
                model_mape,
                generated_at

            FROM ecommerce.sales_forecasts

            ORDER BY generated_at DESC

            LIMIT 1;
            """
        )

        return jsonify({

            "status": "success",

            "forecast": serialize_record(
                result
            )

        })

    except Exception as error:

        return error_response(
            "Unable to retrieve forecast.",
            500,
            str(error)
        )


# ============================================================
# DATA QUALITY
# ============================================================

@app.get("/api/data-quality")
def data_quality():
    """
    Return latest data-quality status.
    """

    try:

        result = fetch_one(
            """
            SELECT
                run_id,
                execution_time,
                quality_issue_count,
                data_quality_status,
                execution_status

            FROM ecommerce.analytics_run_history

            ORDER BY run_id DESC

            LIMIT 1;
            """
        )

        return jsonify({

            "status": "success",

            "data_quality": serialize_record(
                result
            )

        })

    except Exception as error:

        return error_response(
            "Unable to retrieve data quality status.",
            500,
            str(error)
        )


# ============================================================
# AUTOMATION STATUS
# ============================================================

@app.get("/api/automation/status")
def automation_status():
    """
    Return latest automation execution status.
    """

    try:

        result = fetch_one(
            """
            SELECT
                run_id,
                execution_time,
                total_orders,
                total_customers,
                total_revenue,
                total_profit,
                average_order_value,
                return_rate,
                average_delivery_days,
                delayed_shipment_rate,
                quality_issue_count,
                data_quality_status,
                business_status,
                execution_status

            FROM ecommerce.analytics_run_history

            ORDER BY run_id DESC

            LIMIT 1;
            """
        )

        return jsonify({

            "status": "success",

            "automation": serialize_record(
                result
            )

        })

    except Exception as error:

        return error_response(
            "Unable to retrieve automation status.",
            500,
            str(error)
        )


# ============================================================
# ANALYTICS HISTORY
# ============================================================

@app.get("/api/analytics/history")
def analytics_history():
    """
    Return recent analytics executions.
    """

    try:

        limit = request.args.get(
            "limit",
            default=10,
            type=int
        )

        limit = max(
            1,
            min(limit, 100)
        )

        result = fetch_all(
            f"""
            SELECT
                run_id,
                execution_time,
                total_orders,
                total_customers,
                total_revenue,
                total_profit,
                average_order_value,
                return_rate,
                average_delivery_days,
                delayed_shipment_rate,
                quality_issue_count,
                data_quality_status,
                business_status,
                execution_status

            FROM ecommerce.analytics_run_history

            ORDER BY run_id DESC

            LIMIT {limit};
            """
        )

        return jsonify({

            "status": "success",

            "count": len(result),

            "history": serialize_records(
                result
            )

        })

    except Exception as error:

        return error_response(
            "Unable to retrieve analytics history.",
            500,
            str(error)
        )


# ============================================================
# BUSINESS INSIGHTS
# ============================================================

@app.get("/api/insights")
def insights():
    """
    Generate current decision-support insights
    directly from the latest analytics run.
    """

    try:

        result = fetch_one(
            """
            SELECT
                business_status,
                delayed_shipment_rate,
                return_rate,
                total_revenue,
                total_profit,
                quality_issue_count,
                data_quality_status

            FROM ecommerce.analytics_run_history

            ORDER BY run_id DESC

            LIMIT 1;
            """
        )

        delayed_rate = float(
            result.get(
                "delayed_shipment_rate"
            ) or 0
        )

        return_rate = float(
            result.get(
                "return_rate"
            ) or 0
        )

        quality_issues = int(
            result.get(
                "quality_issue_count"
            ) or 0
        )

        if quality_issues > 0:

            insight_status = "CRITICAL"

            primary_insight = (
                f"{quality_issues} data quality "
                "issue(s) require attention."
            )

            recommended_action = (
                "Resolve data-quality issues "
                "before downstream decision-making."
            )

        elif delayed_rate >= 0.30:

            insight_status = "ATTENTION REQUIRED"

            primary_insight = (
                "Delayed shipments are above "
                "the configured operational threshold."
            )

            recommended_action = (
                "Investigate warehouse, carrier, "
                "and shipping-method performance."
            )

        elif return_rate >= 0.15:

            insight_status = "ATTENTION REQUIRED"

            primary_insight = (
                "Return rate is above the "
                "configured management threshold."
            )

            recommended_action = (
                "Analyze return reasons and "
                "high-return product categories."
            )

        else:

            insight_status = "HEALTHY"

            primary_insight = (
                "Business performance is within "
                "configured monitoring thresholds."
            )

            recommended_action = (
                "Continue monitoring business "
                "and operational KPIs."
            )

        return jsonify({

            "status": "success",

            "decision_support": {

                "status": insight_status,

                "primary_insight":
                    primary_insight,

                "recommended_action":
                    recommended_action

            },

            "source": {
                "system": "PostgreSQL",
                "analytics_engine": "n8n"
            }

        })

    except Exception as error:

        return error_response(
            "Unable to generate business insights.",
            500,
            str(error)
        )


# ============================================================
# RUN ANALYSIS
# ============================================================

@app.post("/api/automation/run")
def run_analysis():
    """
    Trigger the complete n8n analytics workflow.

    The n8n API key never reaches the React client.
    """

    if not N8N_WEBHOOK_URL:

        return error_response(
            "n8n webhook URL is not configured.",
            500
        )

    if not N8N_API_KEY:

        return error_response(
            "n8n API authentication is not configured.",
            500
        )

    payload = request.get_json(
        silent=True
    ) or {}

    request_payload = {

        "source": "web-app",

        "requested_at":
            datetime.now(
                timezone.utc
            ).isoformat(),

        "request": payload

    }

    try:

        response = requests.post(

            N8N_WEBHOOK_URL,

            headers={
                "X-API-Key": N8N_API_KEY,
                "Content-Type":
                    "application/json"
            },

            json=request_payload,

            timeout=180

        )

        response.raise_for_status()

        try:

            n8n_result = response.json()

        except ValueError:

            n8n_result = {
                "status": "success",
                "message": response.text
            }

        # ----------------------------------------------------
        # Retrieve the newly generated analytics state
        # ----------------------------------------------------

        dashboard_data = fetch_one(
            """
            SELECT
                run_id,
                execution_time,
                total_orders,
                total_customers,
                total_revenue,
                total_profit,
                average_order_value,
                return_rate,
                average_delivery_days,
                delayed_shipment_rate,
                quality_issue_count,
                data_quality_status,
                business_status,
                execution_status

            FROM ecommerce.analytics_run_history

            ORDER BY run_id DESC

            LIMIT 1;
            """
        )

        forecast_data = fetch_one(
            """
            SELECT
                forecast_date,
                predicted_revenue,
                model_name,
                model_mape,
                generated_at

            FROM ecommerce.sales_forecasts

            ORDER BY generated_at DESC

            LIMIT 1;
            """
        )

        return jsonify({

            "status": "success",

            "message":
                "Analytics workflow completed successfully.",

            "execution": {

                "source": "web-app",

                "engine": "n8n",

                "status": "completed",

                "timestamp":
                    datetime.now(
                        timezone.utc
                    ).isoformat()

            },

            "business_performance":
                serialize_record(
                    dashboard_data
                ),

            "forecast":
                serialize_record(
                    forecast_data
                ),

            "n8n_response":
                n8n_result

        })

    except requests.exceptions.Timeout:

        return error_response(

            "Analytics workflow timed out.",

            504,

            "n8n did not respond within 180 seconds."

        )

    except requests.exceptions.RequestException as error:

        print("N8N REQUEST ERROR:", repr(error))

        return error_response(
            "Unable to execute the analytics workflow.",
            502,
            str(error)
        )

    except Exception as error:

        return error_response(

            "Analytics workflow completed, but "
            "the latest results could not be retrieved.",

            500,

            str(error)

        )


# ============================================================
# APPLICATION ENTRY POINT
# ============================================================

if __name__ == "__main__":

    print(
        "\n"
        "==============================================\n"
        " Intelligent Automated Business Analytics\n"
        " Flask Application Server\n"
        "==============================================\n"
    )

    print(
        "API: http://127.0.0.1:5000"
    )

    print(
        "Health: "
        "http://127.0.0.1:5000/api/health"
    )

    print(
        "Dashboard: "
        "http://127.0.0.1:5000/api/dashboard"
    )

    print(
        "Automation: "
        "POST /api/automation/run"
    )

    print(
        "==============================================\n"
    )

    app.run(
        host="127.0.0.1",
        port=5000,
        debug=True
    )