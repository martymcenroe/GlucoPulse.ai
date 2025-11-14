USE DATABASE CGM_HEALTH;
USE SCHEMA ANALYTICS;

-- Create a Python Stored Procedure
CREATE OR REPLACE PROCEDURE sp_detect_glucose_anomalies(OUTPUT_TABLE_NAME STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.9
-- Specify the packages you need. Snowflake will install them.
PACKAGES = ('snowflake-snowpark-python', 'scikit-learn', 'pandas')
HANDLER = 'run'
AS
$$
import pandas as pd
from sklearn.ensemble import IsolationForest
from snowflake.snowpark.functions import col, lag, hour, dayofweek
from snowflake.snowpark.window import Window

def run(session, output_table_name):
    # 1. Load data and perform feature engineering in Snowpark
    # We must use the FULLY QUALIFIED name
    base_df = session.table("CGM_HEALTH.ANALYTICS.RAW_READINGS").filter(col("GLUCOSE_VALUE").is_not_null())
    
    window_spec = Window.order_by("TIMESTAMP")
    
    # Engineer features
    features_snowpark_df = base_df.select(
        col("TIMESTAMP"),
        col("GLUCOSE_VALUE"),
        # Feature 1: Rate of Change
        (col("GLUCOSE_VALUE") - lag(col("GLUCOSE_VALUE")).over(window_spec)).alias("GLUCOSE_DELTA"),
        # Feature 2: Time-based features
        hour(col("TIMESTAMP")).alias("HOUR_OF_DAY")
    ).na.drop() # Drop the first row with a null delta

    # 2. Convert to Pandas for scikit-learn
    features_pandas_df = features_snowpark_df.select(
        "GLUCOSE_VALUE", "GLUCOSE_DELTA", "HOUR_OF_DAY"
    ).to_pandas()
    
    if features_pandas_df.empty:
        return "No data to process."

    # 3. Train Isolation Forest model
    model = IsolationForest(n_estimators=100, contamination=0.01, random_state=42)
    model.fit(features_pandas_df)
    
    # 4. Predict anomalies
    # --------
    # THE FIX: Store the original features the model was fit on.
    # --------
    original_features = features_pandas_df.columns.to_list()
    
    # Now, use that list for decision_function and predict.
    features_pandas_df['ANOMALY_SCORE'] = model.decision_function(features_pandas_df[original_features])
    features_pandas_df['IS_ANOMALY'] = model.predict(features_pandas_df[original_features]) # -1 for anomaly, 1 for inlier

    # 5. Join results back to original Snowpark DataFrame
    # Need to get the timestamps back
    results_pandas_df = features_snowpark_df.to_pandas()
    results_pandas_df['ANOMALY_SCORE'] = features_pandas_df['ANOMALY_SCORE']
    results_pandas_df['IS_ANOMALY'] = features_pandas_df['IS_ANOMALY']

    # 6. Write results to a new Snowflake table
    results_snowpark_df = session.write_pandas(results_pandas_df, output_table_name, auto_create_table=True, overwrite=True)
    
    return f"Successfully created {output_table_name} with {results_snowpark_df.count()} rows."
$$;

-- Now, execute the stored procedure
CALL sp_detect_glucose_anomalies('GLUCOSE_ANOMALIES');

-- Query your new results table!
SELECT
    TIMESTAMP,
    GLUCOSE_VALUE,
    GLUCOSE_DELTA,
    ANOMALY_SCORE
FROM
    GLUCOSE_ANOMALIES
WHERE
    IS_ANOMALY = -1 -- Filter for anomalies
ORDER BY
    ANOMALY_SCORE ASC; -- Lowest scores are "most anomalous"