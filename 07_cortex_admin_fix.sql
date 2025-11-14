/*
==================================================================================
PROJECT: GLUCOPULSE.AI
FILE: 07_cortex_admin_fix.sql
PURPOSE: Solves the "Brick Wall" 400 Error: 'model unavailable in your region'.

This file documents the troubleshooting process and the final, correct fix.
==================================================================================
*/

-- Step 1: Confirm our account's home region.
-- My Result: AZURE_SOUTHCENTRALUS
SELECT CURRENT_REGION();


-- -------------------------------------------------------------------------------
-- FAILED ATTEMPTS (Kept for historical record)
-- These parameters were guesses based on error messages and are invalid.
-- -------------------------------------------------------------------------------

/*
-- FAILED (Invalid Property)
USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT SET ENABLE_CORTEX_CROSS_REGION_CALLS = TRUE;

-- FAILED (Invalid Property)
USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT SET _ENABLE_CORTEX_CROSS_REGION_CALLS = TRUE;

-- FAILED (Incorrect RBAC approach)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER
  TO ROLE ACCOUNTADMIN;

-- FAILED (Wrong cloud provider)
USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AZURE_US';
*/


-- -------------------------------------------------------------------------------
-- THE DEFINITIVE, WORKING FIX
-- -------------------------------------------------------------------------------

/*
-- NARRATIVE: This is the engineered solution.
--
-- 1. THE "WHY": My account lives on Azure ('azure_southcentralus'), but the
--    GPU clusters that run the Cortex LLM models are a shared "utility"
--    or "power plant" that lives on AWS ('AWS_US').
--
-- 2. THE "BRICK WALL": By default, Snowflake's security model (correctly)
--    blocks an Azure-based account from sending data to an AWS hub.
--
-- 3. THE "FIX": This command is not "moving" my account. It is an explicit,
--    architect-level "allow list" rule. It tells my Azure account that
--    I am giving it permission to securely make this API call across clouds
--    to the 'AWS_US' hub for processing. This proves Snowflake's
--    cloud-agnostic architecture.
*/
USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';