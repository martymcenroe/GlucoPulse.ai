USE DATABASE CGM_HEALTH;
USE SCHEMA ANALYTICS;

-- Create a new table to hold the classified notes
CREATE OR REPLACE TABLE CLASSIFIED_NOTES AS
SELECT
    TIMESTAMP,
    NOTES,
    --
    -- THE FIX: Swapped 'snowflake-arctic' for 'llama3-8b', 
    -- which is available in all regions.
    --
    SNOWFLAKE.CORTEX.COMPLETE(
        'llama3-8b',
        CONCAT(
            'Classify the following lifestyle note into one category: EATING, EXERCISE, SLEEP, MEDICATION, ALCOHOL, STRESS, or OTHER. Respond with only the category name.\n',
            'Note: "', NOTES, '"\n',
            'Category:'
        )
    ) AS LIFESTYLE_CATEGORY
FROM
    CGM_HEALTH.ANALYTICS.RAW_READINGS
WHERE
    NOTES IS NOT NULL AND NOTES != ''; -- Only run on rows that have notes

-- Check your results
SELECT LIFESTYLE_CATEGORY, COUNT(*)
FROM CLASSIFIED_NOTES
GROUP BY LIFESTYLE_CATEGORY
ORDER BY COUNT(*) DESC;

SELECT * FROM CLASSIFIED_NOTES LIMIT 50;