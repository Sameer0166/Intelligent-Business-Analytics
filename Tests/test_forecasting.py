import sys
from pathlib import Path
import numpy as np
import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parent.parent
PYTHON_DIR = PROJECT_ROOT / "python"

sys.path.insert(0, str(PYTHON_DIR))

from forecasting import create_features

def test_create_features():
    """Verify forecasting feature engineering."""

    dates = pd.date_range(
        start="2025-01-01",
        periods=40,
        freq="D"
    )

    df = pd.DataFrame({
        "order_date": dates,
        "revenue": np.arange(40, dtype=float)
    })

    result = create_features(df)

    expected_features = [
        "lag_1",
        "lag_7",
        "lag_14",
        "lag_30",
        "rolling_7",
        "rolling_30",
        "day_of_week",
        "month"
    ]

    for feature in expected_features:
        assert feature in result.columns

    assert "time_index" in result.columns
    assert len(result) == 40

def test_feature_values_are_numeric():
    """Verify forecasting features contain numeric values."""

    dates = pd.date_range(
        start="2025-01-01",
        periods=40,
        freq="D"
    )

    df = pd.DataFrame({
        "order_date": dates,
        "revenue": np.arange(40, dtype=float)
    })

    result = create_features(df)

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

    assert all(
        pd.api.types.is_numeric_dtype(result[column])
        for column in feature_columns
    )