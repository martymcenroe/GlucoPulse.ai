/*
==================================================================================
PROJECT: GLUCOPULSE.AI - AI-DRIVEN CGM HEALTH ANALYTICS
AUTHOR: Martin McEnroe
DEMO SCRIPT: This script tells the end-to-end story of the project.
==================================================================================
*/

-- -------------------------------------------------------------------------------
-- STEP 1: THE "BEFORE" - RAW, MESSY DATA
-- This is the 19-column VARCHAR-only data from the LibreView export.
-- It's unusable for analysis.
-- -------------------------------------------------------------------------------
SELECT * FROM LANDING_LIBRE_RAW LIMIT 10;


-- -------------------------------------------------------------------------------
-- STEP 2: THE "AFTER" - THE CLEAN, TRANSFORMED TABLE
-- This is the output of our ELT pipeline (03_ELT.sql).
-- It's clean, typed, and ready for AI. Note the unified GLUCOSE_VALUE and NOTES.
-- -------------------------------------------------------------------------------
SELECT * FROM RAW_READINGS LIMIT 10;


-- -------------------------------------------------------------------------------
-- STEP 3: INSIGHT (CORTEX AI) - CLASSIFYING HUMAN NOTES
-- We use Cortex AI (04_cortex_classification.sql) to turn messy,
-- human-entered notes into clean, categorical data.
-- -------------------------------------------------------------------------------
SELECT * FROM CLASSIFIED_NOTES LIMIT 10;

-- Show the "before and after" of the NLP
SELECT
    r.NOTES,
    c.LIFESTYLE_CATEGORY
FROM RAW_READINGS r
JOIN CLASSIFIED_NOTES c ON r.TIMESTAMP = c.TIMESTAMP
WHERE r.NOTES IS NOT NULL
LIMIT 20;


-- -------------------------------------------------------------------------------
-- STEP 4: INSIGHT (MY HYPOTHESIS) - THE GLYCATION INDEX
-- This tests my hypothesis that damage is non-linear.
-- A spike to 180 is 64x more damaging than 150 (not 26% more).
-- -------------------------------------------------------------------------------
SELECT 
    TIMESTAMP, 
    GLUCOSE_VALUE, 
    GLYCATION_INDEX 
FROM 
    GLUCOSE_FEATURES
WHERE 
    GLYCATION_INDEX > 0
ORDER BY 
    GLYCATION_INDEX DESC
LIMIT 20;


-- -------------------------------------------------------------------------------
-- STEP 5: INSIGHT (SNOWPARK ML) - FINDING "UNKNOWN UNKNOWNS"
-- This is the output of our scikit-learn IsolationForest model
-- (05_snowpark_anomaly_detection.sql). It finds the most
-- statistically unusual events based on value, rate-of-change, and time-of-day.
-- -------------------------------------------------------------------------------
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
    ANOMALY_SCORE ASC -- Lowest scores are "most anomalous"
LIMIT 20;