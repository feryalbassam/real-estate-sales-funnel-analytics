IF OBJECT_ID('bronze.leads', 'U') IS NOT NULL
    DROP TABLE bronze.leads;
GO

CREATE TABLE bronze.leads (
    Lead_ID              NVARCHAR(20),
    Lead_Date            NVARCHAR(20),
    Marketing_Channel    NVARCHAR(50),
    Campaign_Name        NVARCHAR(100),
    Marketing_Cost_AED   NVARCHAR(20),
    Customer_ID          NVARCHAR(20),
    Property_ID          NVARCHAR(20),
    Agent_ID             NVARCHAR(20),
    Lead_Status          NVARCHAR(30),
    Qualification_Date   NVARCHAR(20),
    Site_Visit_Date      NVARCHAR(20),
    Negotiation_Date     NVARCHAR(20),
    Booking_Date         NVARCHAR(20),
    Lost_Reason          NVARCHAR(100),
);
GO 

IF OBJECT_ID('bronze.customers', 'U') IS NOT NULL
    DROP TABLE bronze.customers;
GO

CREATE TABLE bronze.customers (
    Customer_ID              NVARCHAR(20),
    Customer_Type            NVARCHAR(50),
    Nationality              NVARCHAR(50),
    Preferred_Location       NVARCHAR(100),
    Preferred_Property_Type  NVARCHAR(50),
    Budget_AED               NVARCHAR(20),
);
GO

IF OBJECT_ID('bronze.properties', 'U') IS NOT NULL
    DROP TABLE bronze.properties;
GO

CREATE TABLE bronze.properties (
    Property_ID          NVARCHAR(20),
    Project_Name         NVARCHAR(100),
    Developer_Name       NVARCHAR(100),
    Location             NVARCHAR(100),
    Property_Type        NVARCHAR(50),
    Bedrooms             NVARCHAR(10),
    Property_Price_AED   NVARCHAR(20),
    Payment_Plan         NVARCHAR(50)
);
GO

IF OBJECT_ID('bronze.agents', 'U') IS NOT NULL
    DROP TABLE bronze.agents;
GO

CREATE TABLE bronze.agents (
    Agent_ID             NVARCHAR(20),
    Agent_Name           NVARCHAR(100),
    Agent_Department     NVARCHAR(50)
);
GO

IF OBJECT_ID('bronze.sales', 'U') IS NOT NULL
    DROP TABLE bronze.sales;
GO

CREATE TABLE bronze.sales (
    Sale_ID              NVARCHAR(20),
    Lead_ID              NVARCHAR(20),
    Customer_ID          NVARCHAR(20),
    Property_ID          NVARCHAR(20),
    Agent_ID             NVARCHAR(20),
    Sale_Date            NVARCHAR(20),
    Sale_Value_AED       NVARCHAR(20),
    Commission_AED       NVARCHAR(20)
);
GO