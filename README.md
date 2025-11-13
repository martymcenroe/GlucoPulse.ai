# GlucoPulse.ai

A personal health analytics project to analyze continuous glucose monitor (CGM) data using Snowflake, Snowflake Cortex AI, and Snowpark for Python.

## 1. Project Goal

As a person managing Type 2 Diabetes, I built this project to move beyond simple averages like HbA1c and analyze the real-world impact of **glycemic variability**.

The core hypothesis is that large, rapid glucose excursions are disproportionately damaging, and that a 3-month average (HbA1c) can be dangerously misleading. This project uses data analysis and machine learning to quantify, classify, and detect these high-variability events from over 96,000 personal CGM readings.

## 2. Technical Stack

* **Data Warehouse:** Snowflake
* **Data Pipeline:** Snowflake SQL (ELT Pattern)
* **Core Table:** `RAW_READINGS` (contains all Type 0, 1, and 6 records)
* **NLP/AI:** Snowflake Cortex AI (`COMPLETE` function)
* **ML Modeling:** Snowpark for Python (with `scikit-learn`)
* **Source Control:** Git / GitHub

## 3. Data Engineering Pipeline (ELT)

The source data from the LibreView export is not in a clean, queryable format. A multi-step ELT (Extract-Load-Transform) pipeline was built to clean and model the data for analysis.

### Source Data Profile

The raw `.csv` export contains several data quality issues:
* **Junk Header:** A non-data title row is present on row 1.
* **Misaligned Headers:** The true column headers are on row 2.
* **Conditional Data:** Glucose readings are stored in two different columns (`Historic Glucose mg/dL` vs. `Scan Glucose mg/dL`) based on a `Record Type` (0 or 1).
* **Sparse Data:** Non-reading events (`Record Type` 6), which contain all lifestyle notes, are mixed with valid glucose readings.
* **Fragmented Data:** Lifestyle notes are spread across 10+ separate columns.

### Loading Strategy (ELT)

A robust ELT pattern was used to ensure data integrity and auditability.
1.  **Extract/Load:** The raw CSV is first uploaded to a Snowflake Stage (`@RAW_FILE_STAGE`). It is then loaded *as-is* into a staging table (`LANDING_LIBRE_RAW`) where all 19 columns are defined as `VARCHAR`. This prevents type-mismatch errors and preserves the original source data for lineage.
2.  **Transform:** A `CREATE TABLE AS SELECT ...` (CTAS) statement transforms the raw data into a clean, analytics-ready table (`RAW_READINGS`).

### Transformation Logic (SQL)

The transformation query (`03_ELT.sql`) performs the following business logic:
* **Filtering:** Removes the junk header row (`WHERE "Record Type" != 'Record Type'`).
* **Preservation:** Keeps all critical record types (`Record Type` IN ('0', '1', '6')).
* **Pivoting (CASE):** A `CASE` statement unifies the two conditional glucose columns into a single `GLUCOSE_VALUE` column.
* **Merging (COALESCE):** A `COALESCE` function merges the 10+ disparate note columns into a single, clean `NOTES` field.
* **Type Casting:** All `VARCHAR` fields are safely cast to their proper data types (`TIMESTAMP_NTZ`, `NUMBER`).

## 4. AI & ML Pipeline (Next Steps)

With the clean `RAW_READINGS` table, the following analysis can be performed:

* **SQL Analysis:** Time-series analysis using window functions (`LAG`, `AVG() OVER...`) to find spikes, drops, and rolling averages.
* **NLP Feature Engineering (Cortex AI):** A `SNOWFLAKE.CORTEX.COMPLETE` function will be used to classify the `NOTES` field into clean categories: `EATING`, `EXERCISE`, `SLEEP`, `ALCOHOL`, or `OTHER`.
* **Anomaly Detection (Snowpark):** A Snowpark Python Stored Procedure will use `scikit-learn`'s `IsolationForest` to find "unknown unknowns"—statistically anomalous glucose events.

## 5. ⚠️ Privacy & Data Note

The raw CGM data (`.csv`) for this project is personal, private, and sensitive health information. **It is not, and will not be, included in this repository.**

The `.gitignore` file is configured to explicitly block this file from ever being committed. This repository contains only the SQL, Python, and configuration *code* used for the analysis.

## 6. License

This project is licensed under the MIT License. See the `LICENSE` file for details.