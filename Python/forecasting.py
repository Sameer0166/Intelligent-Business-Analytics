import os
import pandas as pd
import numpy as np
from dotenv import load_dotenv
from pathlib import Path

from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

from sklearn.linear_model import Ridge
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from sklearn.metrics import (
    mean_absolute_error,
    mean_squared_error
)
load_dotenv(
    Path(__file__).resolve().parent.parent / ".env"
)
# ============================================================
# CONFIGURATION
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

PROCESSED_DIR = (
    PROJECT_ROOT /
    "Data" /
    "Processed"
)

OUTPUT_DIR = (
    PROJECT_ROOT /
    "Documentation" /
    "reports"
)

OUTPUT_DIR.mkdir(
    parents=True,
    exist_ok=True
)

ORDERS_FILE = (
    PROCESSED_DIR /
    "orders_cleaned.csv"
)

# ============================================================
# POSTGRESQL CONNECTION
# ============================================================
def get_postgres_engine():

    load_dotenv()

    db_password = os.getenv("DB_PASSWORD")
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv(
        "DB_NAME",
        "intelligent_business_analytics"
    )
    db_user = os.getenv(
        "DB_USER",
        "postgres"
    )

    if not db_password:
        raise ValueError(
            "DB_PASSWORD environment variable is not set."
        )

    connection_url = URL.create(
        drivername="postgresql+psycopg2",
        username=db_user,
        password=db_password,
        host=db_host,
        port=db_port,
        database=db_name
    )

    return create_engine(connection_url)
# ============================================================
# SAVE FORECAST TO POSTGRESQL
# ============================================================

def save_forecast_to_postgres(
    forecast,
    model_name="Ridge Regression",
    model_mape=16.91
):
    engine = get_postgres_engine()

    forecast_row = forecast.iloc[0]

    forecast_date = forecast_row["forecast_date"]
    predicted_revenue = float(
        forecast_row["predicted_revenue"]
    )

    with engine.begin() as connection:

        # Remove any previous forecast for the same date.
        connection.execute(
            text("""
                DELETE FROM ecommerce.sales_forecasts
                WHERE forecast_date = :forecast_date
            """),
            {
                "forecast_date": forecast_date
            }
        )

        # Insert the latest forecast.
        connection.execute(
            text("""
                INSERT INTO ecommerce.sales_forecasts (
                    forecast_date,
                    predicted_revenue,
                    model_name,
                    model_mape
                )
                VALUES (
                    :forecast_date,
                    :predicted_revenue,
                    :model_name,
                    :model_mape
                )
            """),
            {
                "forecast_date": forecast_date,
                "predicted_revenue": predicted_revenue,
                "model_name": model_name,
                "model_mape": model_mape
            }
        )

    print(
        "\n✓ Forecast successfully saved to PostgreSQL:"
    )

    print(
        "  Table: ecommerce.sales_forecasts"
    )

    print(
        f"  Forecast date: {forecast_date}"
    )

    print(
        f"  Predicted revenue: ₹{predicted_revenue:,.2f}"
    )

# ============================================================
# LOAD ORDER DATA
# ============================================================

def load_orders():

    print("\n" + "=" * 65)
    print("LOADING CLEANED ORDER DATA")
    print("=" * 65)

    orders = pd.read_csv(
        ORDERS_FILE
    )

    orders["order_date"] = pd.to_datetime(
        orders["order_date"],
        errors="coerce"
    )

    orders["final_amount"] = pd.to_numeric(
        orders["final_amount"],
        errors="coerce"
    )

    orders = orders.dropna(
        subset=[
            "order_date",
            "final_amount"
        ]
    )

    print(
        f"✓ Orders loaded: {len(orders):,}"
    )

    print(
        f"✓ Date range: "
        f"{orders['order_date'].min().date()} "
        f"to "
        f"{orders['order_date'].max().date()}"
    )

    return orders


# ============================================================
# CREATE DAILY REVENUE DATA
# ============================================================

def create_daily_revenue(orders):

    print("\n" + "=" * 65)
    print("CREATING DAILY REVENUE SERIES")
    print("=" * 65)

    daily_revenue = (
        orders
        .groupby("order_date")
        .agg(
            revenue=("final_amount", "sum"),
            orders=("order_id", "nunique")
        )
        .reset_index()
    )

    # Create continuous daily date range
    full_dates = pd.DataFrame({
        "order_date": pd.date_range(
            start=daily_revenue["order_date"].min(),
            end=daily_revenue["order_date"].max(),
            freq="D"
        )
    })

    daily_revenue = full_dates.merge(
        daily_revenue,
        on="order_date",
        how="left"
    )

    # No order on a date = zero revenue
    daily_revenue["revenue"] = (
        daily_revenue["revenue"]
        .fillna(0)
    )

    daily_revenue["orders"] = (
        daily_revenue["orders"]
        .fillna(0)
    )

    print(
        f"✓ Daily observations: "
        f"{len(daily_revenue):,}"
    )

    print(
        f"✓ Total revenue: "
        f"{daily_revenue['revenue'].sum():,.2f}"
    )

    return daily_revenue

# ============================================================
# FEATURE ENGINEERING
# ============================================================

def create_features(dataframe):

    df = dataframe.copy()

    # Convert date column to datetime
    df["order_date"] = pd.to_datetime(
        df["order_date"],
        errors="coerce"
    )

    # Time index
    df["time_index"] = (
        df["order_date"] - df["order_date"].min()
    ).dt.days

    # Lag features
    df["lag_1"] = (
        df["revenue"].shift(1)
    )

    df["lag_7"] = (
        df["revenue"].shift(7)
    )

    df["lag_14"] = (
        df["revenue"].shift(14)
    )

    df["lag_30"] = (
        df["revenue"].shift(30)
    )

    # Rolling features
    # Shift by 1 day to avoid using the current day's
    # revenue when predicting that same day.
    df["rolling_7"] = (
        df["revenue"]
        .shift(1)
        .rolling(7)
        .mean()
    )

    df["rolling_30"] = (
        df["revenue"]
        .shift(1)
        .rolling(30)
        .mean()
    )

    # Calendar features
    df["day_of_week"] = (
        df["order_date"].dt.dayofweek
    )

    df["month"] = (
        df["order_date"].dt.month
    )

    return df
# ============================================================
# PREPARE TRAINING DATA
# ============================================================

def prepare_training_data(dataframe):

    feature_columns = [
        "time_index",
        "lag_1",
        "lag_7",
        "lag_14",
        "lag_30",
        "rolling_7",
        "rolling_30",
        "day_of_week",
        "month"
    ]

    model_data = dataframe.dropna(
        subset=feature_columns + ["revenue"]
    ).copy()

    X = model_data[
        feature_columns
    ]

    y = model_data[
        "revenue"
    ]

    print("\n" + "=" * 65)
    print("PREPARING RIDGE REGRESSION DATA")
    print("=" * 65)

    print(
        f"✓ Training observations available: "
        f"{len(model_data):,}"
    )

    print(
        f"✓ Features used: {len(feature_columns)}"
    )

    print("\nFeatures:")

    for feature in feature_columns:
        print(f"  - {feature}")

    return model_data, X, y, feature_columns

# ============================================================
# TRAIN / TEST SPLIT
# ============================================================

def split_time_series(
    model_data,
    X,
    y
):

    # Last 30 days are reserved
    # for testing.

    test_days = 30

    split_index = (
        len(model_data)
        - test_days
    )

    X_train = X.iloc[
        :split_index
    ]

    X_test = X.iloc[
        split_index:
    ]

    y_train = y.iloc[
        :split_index
    ]

    y_test = y.iloc[
        split_index:
    ]

    test_dates = model_data[
        "order_date"
    ].iloc[
        split_index:
    ]

    print("\n" + "=" * 65)
    print("TIME-BASED TRAIN / TEST SPLIT")
    print("=" * 65)

    print(
        f"Training observations: "
        f"{len(X_train):,}"
    )

    print(
        f"Testing observations : "
        f"{len(X_test):,}"
    )

    print(
        f"Test period: "
        f"{test_dates.min().date()} "
        f"to "
        f"{test_dates.max().date()}"
    )

    return (
        X_train,
        X_test,
        y_train,
        y_test,
        test_dates
    )


# ============================================================
# TRAIN RIDGE REGRESSION MODEL
# ============================================================

def train_model(
    X_train,
    y_train
):

    print("\n" + "=" * 65)
    print("TRAINING RIDGE REGRESSION MODEL")
    print("=" * 65)

    model = Pipeline([
        (
            "scaler",
            StandardScaler()
        ),
        (
            "ridge",
            Ridge(alpha=10.0)
        )
    ])

    model.fit(
        X_train,
        y_train
    )

    print("✓ Ridge Regression model trained")
    print("✓ StandardScaler applied")
    print("✓ Ridge alpha: 10.0")

    return model


# ============================================================
# MODEL EVALUATION
# ============================================================

def evaluate_model(
    model,
    X_test,
    y_test
):

    predictions = model.predict(
        X_test
    )

    mae = mean_absolute_error(
        y_test,
        predictions
    )

    rmse = np.sqrt(
        mean_squared_error(
            y_test,
            predictions
        )
    )

    # Avoid division by zero
    non_zero_mask = (
        y_test != 0
    )

    if non_zero_mask.sum() > 0:

        mape = np.mean(
            np.abs(
                (
                    y_test[
                        non_zero_mask
                    ]
                    -
                    predictions[
                        non_zero_mask
                    ]
                )
                /
                y_test[
                    non_zero_mask
                ]
            )
        ) * 100

    else:

        mape = np.nan

    metrics = pd.DataFrame({
        "metric": [
            "MAE",
            "RMSE",
            "MAPE"
        ],

        "value": [
            round(mae, 2),
            round(rmse, 2),
            round(mape, 2)
        ]
    })

    print("\n" + "=" * 65)
    print("MODEL EVALUATION")
    print("=" * 65)

    print(
        metrics.to_string(
            index=False
        )
    )

    return predictions, metrics


# ============================================================
# SAVE TEST PREDICTIONS
# ============================================================

def save_test_predictions(
    test_dates,
    y_test,
    predictions
):

    results = pd.DataFrame({
        "date": test_dates.values,
        "actual_revenue": y_test.values,
        "predicted_revenue": predictions
    })

    results["prediction_error"] = (
        results["actual_revenue"]
        -
        results["predicted_revenue"]
    )

    results["actual_revenue"] = results["actual_revenue"].round(2)
    results["predicted_revenue"] = results["predicted_revenue"].round(2)
    results["prediction_error"] = results["prediction_error"].round(2)
    output_path = (
        OUTPUT_DIR /
        "forecast_test_predictions.csv"
    )

    results.to_csv(
        output_path,
        index=False
    )

    print(
        f"\n✓ Test predictions saved:"
        f"\n{output_path}"
    )

    return results

# ============================================================
# RIDGE COEFFICIENT ANALYSIS
# ============================================================

def save_feature_importance(
    model,
    feature_columns
):

    # Extract Ridge coefficients from the pipeline
    ridge_model = model.named_steps["ridge"]

    coefficients = ridge_model.coef_

    importance = pd.DataFrame({
        "feature": feature_columns,
        "coefficient": coefficients
    })

    # Absolute coefficient magnitude
    importance["absolute_coefficient"] = (
        importance["coefficient"].abs()
    )

    importance = importance.sort_values(
        "absolute_coefficient",
        ascending=False
    )

    importance["coefficient"] = (
        importance["coefficient"]
        .round(2)
    )

    importance["absolute_coefficient"] = (
        importance["absolute_coefficient"]
        .round(2)
    )

    output_path = (
        OUTPUT_DIR /
        "forecast_ridge_coefficients.csv"
    )

    importance.to_csv(
        output_path,
        index=False
    )

    print(
        f"✓ Ridge coefficients saved:"
        f"\n{output_path}"
    )

    print("\nTop forecasting features by coefficient magnitude:")

    print(
        importance.head(10)
        .to_string(index=False)
    )

    return importance

# ============================================================
# NEXT-DAY REVENUE FORECAST
# ============================================================

def forecast_future(
    model,
    dataframe,
    feature_columns
):

    print("\n" + "=" * 65)
    print("GENERATING NEXT-DAY REVENUE FORECAST")
    print("=" * 65)

    history = dataframe[
        [
            "order_date",
            "revenue"
        ]
    ].copy()

    history = history.sort_values(
        "order_date"
    ).reset_index(drop=True)

    last_date = history["order_date"].max()

    next_date = (
        last_date +
        pd.Timedelta(days=1)
    )

    revenue_history = (
        history["revenue"]
        .tolist()
    )

    next_time_index = (
        dataframe["time_index"].max() + 1
    )

    # Create features for the next day
    row = {

        "time_index":
            next_time_index,

        "lag_1":
            revenue_history[-1],

        "lag_7":
            revenue_history[-7],

        "lag_14":
            revenue_history[-14],

        "lag_30":
            revenue_history[-30],

        "rolling_7":
            np.mean(
                revenue_history[-7:]
            ),

        "rolling_30":
            np.mean(
                revenue_history[-30:]
            ),

        "day_of_week":
            next_date.dayofweek,

        "month":
            next_date.month
    }

    feature_row = pd.DataFrame(
        [row]
    )[
        feature_columns
    ]

    prediction = model.predict(
        feature_row
    )[0]

    # Revenue cannot be negative
    prediction = max(
        0,
        prediction
    )

    forecast = pd.DataFrame({

        "forecast_date": [
            next_date
        ],

        "predicted_revenue": [
            round(prediction, 2)
        ]
    })

    output_path = (
        OUTPUT_DIR /
        "sales_forecast_next_day.csv"
    )

    forecast.to_csv(
        output_path,
        index=False
    )

    print(
        f"✓ Next-day forecast saved:"
        f"\n{output_path}"
    )

    print("\nForecast result:")

    print(
        forecast.to_string(
            index=False
        )
    )

    return forecast

# ============================================================
# MAIN PROGRAM
# ============================================================

def main():

    print("\n")
    print("=" * 65)
    print("INTELLIGENT BUSINESS ANALYTICS")
    print("MACHINE LEARNING SALES FORECASTING")
    print("=" * 65)

    try:

        # ----------------------------------------------------
        # LOAD DATA
        # ----------------------------------------------------

        orders = load_orders()

        # ----------------------------------------------------
        # DAILY REVENUE
        # ----------------------------------------------------

        daily_revenue = (
            create_daily_revenue(
                orders
            )
        )

        # ----------------------------------------------------
        # FEATURE ENGINEERING
        # ----------------------------------------------------

        featured_data = (
            create_features(
                daily_revenue
            )
        )

        # ----------------------------------------------------
        # PREPARE MODEL DATA
        # ----------------------------------------------------

        (
            model_data,
            X,
            y,
            feature_columns
        ) = prepare_training_data(
            featured_data
        )

        # ----------------------------------------------------
        # TIME-BASED SPLIT
        # ----------------------------------------------------

        (
            X_train,
            X_test,
            y_train,
            y_test,
            test_dates
        ) = split_time_series(
            model_data,
            X,
            y
        )

        # ----------------------------------------------------
        # TRAIN MODEL
        # ----------------------------------------------------

        model = train_model(
            X_train,
            y_train
        )

        # ----------------------------------------------------
        # EVALUATE MODEL
        # ----------------------------------------------------

        (
            predictions,
            metrics
        ) = evaluate_model(
            model,
            X_test,
            y_test
        )

        # ----------------------------------------------------
        # SAVE METRICS
        # ----------------------------------------------------

        metrics_path = (
            OUTPUT_DIR /
            "forecast_model_metrics.csv"
        )

        metrics.to_csv(
            metrics_path,
            index=False
        )

        print(
            f"\n✓ Model metrics saved:"
            f"\n{metrics_path}"
        )

        # ----------------------------------------------------
        # SAVE TEST PREDICTIONS
        # ----------------------------------------------------

        save_test_predictions(
            test_dates,
            y_test,
            predictions
        )

        # ----------------------------------------------------
        # FEATURE IMPORTANCE
        # ----------------------------------------------------

        save_feature_importance(
            model,
            feature_columns
        )

        # ----------------------------------------------------
        # NEXT-DAY FORECAST
        # ----------------------------------------------------
        forecast = forecast_future(
            model,
            featured_data,
            feature_columns
        )

        save_forecast_to_postgres(
            forecast
        )
        # ----------------------------------------------------
        # COMPLETE
        # ----------------------------------------------------

        print("\n" + "=" * 65)
        print(
            "✓ SALES FORECASTING COMPLETED SUCCESSFULLY"
        )
        print("=" * 65)

        print(
            f"\nForecast reports saved in:"
            f"\n{OUTPUT_DIR}"
        )

    except Exception as error:

        print("\n" + "=" * 65)
        print("✗ SALES FORECASTING FAILED")
        print("=" * 65)

        print(
            f"\nError: {error}"
        )


# ============================================================
# RUN PROGRAM
# ============================================================

if __name__ == "__main__":
    main()