CREATE OR ALTER PROCEDURE silver.load_silver as
BEGIN
    DECLARE @Start_time DATETIME , @End_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME;
    BEGIN TRY
	PRINT '=============================';
	PRINT 'LOADING SILVER LAYER';
	PRINT '=============================';
SET @Start_time = GETDATE();
	print '>> Truncating Table: silver.leads';
	TRUNCATE TABLE silver.leads;
	print '>>Inserting Data info:silver.leads';
	INSERT INTO silver.leads(
	Lead_ID,
    Lead_Date,
    Marketing_Channel,
    Campaign_Name,
    Marketing_Cost_AED,
    Customer_ID,
    Property_ID,
    Agent_ID,
    Lead_Status,
    Qualification_Date,
    Site_Visit_Date,	
    Negotiation_Date,
    Booking_Date,
    Lost_Reason,
	Qualification_Sequence_Check,
	Booking_Sequence_Check
)
SELECT
    Lead_ID,
    Lead_Date,
    Marketing_Channel,
    Campaign_Name,
    Marketing_Cost_AED,
    Customer_ID,
    Property_ID,
    Agent_ID,

    CASE
        WHEN UPPER(TRIM(Lead_Status)) = 'LEAD'        THEN 'Lead'
        WHEN UPPER(TRIM(Lead_Status)) = 'CONTACTED'   THEN 'Contacted'
        WHEN UPPER(TRIM(Lead_Status)) = 'QUALIFIED'   THEN 'Qualified'
        WHEN UPPER(TRIM(Lead_Status)) = 'SITE VISIT'  THEN 'Site Visit'
        WHEN UPPER(TRIM(Lead_Status)) = 'NEGOTIATION' THEN 'Negotiation'
        WHEN UPPER(TRIM(Lead_Status)) = 'BOOKING'     THEN 'Booking'
        WHEN UPPER(TRIM(Lead_Status)) = 'SOLD'        THEN 'Sold'
        WHEN UPPER(TRIM(Lead_Status)) = 'LOST'        THEN 'Lost'
        ELSE 'Unknown'
    END AS Lead_Status,
    Qualification_Date,
    Site_Visit_Date,
    Negotiation_Date,
    Booking_Date,
    Lost_Reason,
    
	CASE
        WHEN Qualification_Date IS NULL THEN 'Not Yet Reached'
        WHEN Lead_Date IS NULL THEN 'Invalid'
        WHEN Qualification_Date >= Lead_Date THEN 'Valid'
        ELSE 'Invalid'
    END AS Qualification_Sequence_Check,

    CASE
        WHEN Booking_Date IS NULL THEN 'Not Yet Reached'
        WHEN Negotiation_Date IS NULL THEN 'Invalid'
        WHEN Booking_Date >= Negotiation_Date THEN 'Valid'
        ELSE 'Invalid'
    END AS Booking_Sequence_Check
FROM bronze.leads

SET @End_time = GETDATE();
PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
PRINT '---------------------';

SET @Start_time = GETDATE();
	print '>> Truncating Table: silver.customers';
	TRUNCATE TABLE silver.customers;
	print '>>Inserting Data info:silver.customers';
	INSERT INTO silver.customers(
	Customer_ID,
	Customer_Type,
    Nationality,
    Preferred_Location,
    Preferred_Property_Type,
	Budget_AED
	)
SELECT
    Customer_ID,
	CASE
        WHEN UPPER(TRIM(Customer_Type)) = 'INVESTOR'  THEN 'Investor'
        WHEN UPPER(TRIM(Customer_Type)) = 'END USER'  THEN 'End User'
        ELSE 'Unknown'
    END AS Customer_Type,
    Nationality,
    Preferred_Location,
    Preferred_Property_Type,
    Budget_AED
FROM bronze.customers

SET @End_time = GETDATE();
PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
PRINT '---------------------';

SET @Start_time = GETDATE();
	print '>> Truncating Table: silver.properties';
	TRUNCATE TABLE silver.properties;
	print '>>Inserting Data info:silver.properties';
	INSERT INTO silver.properties(
	Property_ID,
    Project_Name,
    Developer_Name,
    Location,
	Property_Type,
	Bedrooms,
    Property_Price_AED,
    Payment_Plan
	)
	SELECT
    Property_ID,
    Project_Name,
    Developer_Name,
    Location,

    CASE
        WHEN UPPER(TRIM(Property_Type)) IN ('APARTMENT','VILLA','TOWNHOUSE','PENTHOUSE','STUDIO')
            THEN Property_Type
        ELSE 'Unknown'
    END AS Property_Type,
    Bedrooms,
    Property_Price_AED,
    Payment_Plan
FROM bronze.properties;

SET @End_time = GETDATE();
PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
PRINT '---------------------';

SET @Start_time = GETDATE();
	print '>> Truncating Table: silver.agents';
	TRUNCATE TABLE silver.agents;
	print '>>Inserting Data info:silver.agents';
	INSERT INTO silver.agents(
	Agent_ID,
    Agent_Name,
	Agent_Department 
   )
	SELECT
    Agent_ID,
    Agent_Name,

    CASE
        WHEN UPPER(TRIM(Agent_Department)) IN
            ('OFF-PLAN SALES','SECONDARY MARKET','LUXURY & BRANDED RESIDENCES','INVESTOR RELATIONS')
            THEN Agent_Department
        ELSE 'Unknown'
    END AS Agent_Department

FROM bronze.agents;

SET @End_time = GETDATE();
PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
PRINT '---------------------';

SET @Start_time = GETDATE();
	print '>> Truncating Table: silver.sales';
	TRUNCATE TABLE silver.sales;
	print '>>Inserting Data info:silver.sales';
	INSERT INTO silver.sales(
	Sale_ID, 
	Lead_ID,
	Customer_ID,
	Property_ID,
	Agent_ID,
	Sale_Date,
    Sale_Value_AED,
    Commission_AED
   )
    SELECT
    Sale_ID,
    Lead_ID,
    Customer_ID,
    Property_ID,
    Agent_ID,
    Sale_Date,
    Sale_Value_AED,
    Commission_AED
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Property_ID
            ORDER BY Sale_Date ASC
        ) AS rn
    FROM bronze.sales
    WHERE Property_ID IS NOT NULL
) t
WHERE rn = 1;

SET @End_time = GETDATE();
PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
PRINT '---------------------';

SET @Start_time = GETDATE();
	print '>> Truncating Table: silver.sales_flagged_duplicates';
	TRUNCATE TABLE silver.sales_flagged_duplicates;
	print '>>Inserting Data info:silver.sales_flagged_duplicates';
	INSERT INTO silver.sales_flagged_duplicates(
	Sale_ID,
    Lead_ID	,	
    Customer_ID,
    Property_ID,
    Agent_ID,
    Sale_Date,
    Sale_Value_AED,
    Commission_AED,
    rn
   )
	SELECT
    Sale_ID,
    Lead_ID,
    Customer_ID,
    Property_ID,
    Agent_ID,
    Sale_Date,
    Sale_Value_AED,
    Commission_AED,
	rn
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Property_ID
            ORDER BY Sale_Date ASC
        ) AS rn
    FROM bronze.sales
    WHERE Property_ID IS NOT NULL
) t
WHERE rn > 1;

SET @End_time = GETDATE();
PRINT'#LOAD DURATION:'+ CAST(DATEDIFF(second, @Start_time, @End_time) AS NVARCHAR)+'seconds';
PRINT '---------------------';

SET @batch_end_time = GETDATE();
		PRINT '===================================';
		PRINT 'LOADING SILVER LAYER IS COMPLETED'; 
		PRINT 'TOTAL LOAD DURATION:'+CAST(DATEDIFF(SECOND ,@batch_start_time , @batch_end_time )AS NVARCHAR)+'SECONDS';
	END TRY
	BEGIN CATCH
	    PRINT '============================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'ERROR MESSAGE'+ ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE'+ CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE'+ CAST (ERROR_STATE() AS NVARCHAR);
	    PRINT '============================================';
	END CATCH
END

/* ------------------------------------------------------------
   6. RECONCILIATION CHECK — run this after every rebuild
   Expected: Leads 5000 | Customers 5000 | Properties 600
             Agents 45 | Sales 457 | Sales_Flagged 356
   ------------------------------------------------------------ */
SELECT
    (SELECT COUNT(*) FROM silver.leads)                    AS Leads,
    (SELECT COUNT(*) FROM silver.customers)                AS Customers,
    (SELECT COUNT(*) FROM silver.properties)                AS Properties,
    (SELECT COUNT(*) FROM silver.agents)                    AS Agents,
    (SELECT COUNT(*) FROM silver.sales)                     AS Sales,
    (SELECT COUNT(*) FROM silver.sales_flagged_duplicates)  AS Sales_Flagged;

