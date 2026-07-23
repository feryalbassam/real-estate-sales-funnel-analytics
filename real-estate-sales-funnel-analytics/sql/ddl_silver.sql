IF OBJECT_ID('silver.leads', 'U') IS NOT NULL
    DROP TABLE silver.leads;
GO

CREATE TABLE silver.leads (
    Lead_ID						 NVARCHAR(50),
    Lead_Date					 DATE,
    Marketing_Channel			 NVARCHAR(50),
    Campaign_Name				 NVARCHAR(100),
    Marketing_Cost_AED			 DECIMAL(10,2),
    Customer_ID					 NVARCHAR(50),
    Property_ID					 NVARCHAR(50),
    Agent_ID					 NVARCHAR(50),
    Lead_Status					 NVARCHAR(50),
    Qualification_Date			 DATE,
    Site_Visit_Date				 DATE,
    Negotiation_Date			 DATE,
    Booking_Date				 DATE,
    Lost_Reason					 NVARCHAR(100),
	Qualification_Sequence_Check NVARCHAR(100),
	Booking_Sequence_Check       NVARCHAR(100)
	
);
GO

IF OBJECT_ID('silver.customers', 'U') IS NOT NULL
    DROP TABLE silver.customers;
GO

CREATE TABLE silver.customers (
    Customer_ID              NVARCHAR(50),
    Customer_Type            NVARCHAR(50),
    Nationality              NVARCHAR(50),
    Preferred_Location       NVARCHAR(100),
    Preferred_Property_Type  NVARCHAR(50),
    Budget_AED               DECIMAL(10,2),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.properties', 'U') IS NOT NULL
    DROP TABLE silver.properties;
GO

CREATE TABLE silver.properties (
    Property_ID          NVARCHAR(50),
    Project_Name         NVARCHAR(100),
    Developer_Name       NVARCHAR(100),
    Location             NVARCHAR(100),
    Property_Type        NVARCHAR(50),
    Bedrooms             INT,
    Property_Price_AED   DECIMAL(12,2),
    Payment_Plan         NVARCHAR(50),
	dwh_create_date	     DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.agents', 'U') IS NOT NULL
    DROP TABLE silver.agents;
GO

CREATE TABLE silver.agents (
    Agent_ID             NVARCHAR(50),
    Agent_Name           NVARCHAR(100),
    Agent_Department     NVARCHAR(50),
	dwh_create_date		 DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('silver.sales', 'U') IS NOT NULL
    DROP TABLE silver.sales;
GO

CREATE TABLE silver.sales (
    Sale_ID              NVARCHAR(20),
    Lead_ID              NVARCHAR(20),
    Customer_ID          NVARCHAR(20),
    Property_ID          NVARCHAR(20),
    Agent_ID             NVARCHAR(20),
    Sale_Date            DATE,
    Sale_Value_AED       DECIMAL(12,2),
    Commission_AED       DECIMAL(12,2),
	dwh_create_date		 DATETIME2 DEFAULT GETDATE()

);
GO
IF OBJECT_ID('silver.sales_flagged_duplicates', 'U') IS NOT NULL
DROP TABLE IF EXISTS silver.sales_flagged_duplicates;
GO

CREATE TABLE silver.sales_flagged_duplicates (
    Sale_ID			NVARCHAR(50),
    Lead_ID			NVARCHAR(50),
    Customer_ID		NVARCHAR(50),
    Property_ID		NVARCHAR(50),
    Agent_ID		NVARCHAR(50),
    Sale_Date		DATE,
    Sale_Value_AED  DECIMAL(12,2),
    Commission_AED  DECIMAL(12,2),
    rn				INT,
	dwh_create_date	DATETIME2 DEFAULT GETDATE()
);
GO