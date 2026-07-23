/* ============================================================
   03_ANALYSIS_QUERIES.sql
   Real Estate Sales Funnel — SQL Analysis Portfolio
   Beginner -> Intermediate -> Advanced queries answering real
   business questions, plus the official KPI calculation queries.
   All queries run against the Silver layer (RealEstateDW.silver).
   ============================================================ */

USE RealEstateDW;
GO


/* ============================================================
   SECTION 1: BENEFICIARY / SETUP -- COMBINED SALES VIEW
   silver.sales alone only contains 457 deduplicated rows (one
   sale per property). Revenue/deal-count analysis needs the
   FULL picture (813 rows), so we combine it with the flagged
   duplicates table here. Use silver.sales ALONE only when the
   question is specifically about unique properties sold.
   ============================================================ */

IF OBJECT_ID('silver.All_Sales_View', 'V') IS NOT NULL
    DROP VIEW silver.All_Sales_View;
GO
CREATE VIEW silver.All_Sales_View AS
    SELECT Sale_ID, Lead_ID, Customer_ID, Property_ID, Agent_ID,
           Sale_Date, Sale_Value_AED, Commission_AED
    FROM silver.sales
    UNION ALL
    SELECT Sale_ID, Lead_ID, Customer_ID, Property_ID, Agent_ID,
           Sale_Date, Sale_Value_AED, Commission_AED
    FROM silver.sales_flagged_duplicates;
GO


/* ============================================================
   SECTION 2: BEGINNER -- single-table filters & aggregates
   ============================================================ */

-- Q1: How many leads came from each marketing channel?
SELECT
    Marketing_Channel,
    COUNT(*) AS Total_Leads
FROM silver.leads
GROUP BY Marketing_Channel
ORDER BY Total_Leads DESC;
GO

-- Q2: Total, average, and max property price by property type
SELECT
    Property_Type,
    COUNT(*) AS Total_Properties,
    AVG(Property_Price_AED) AS Average_Property_Price,
    MAX(Property_Price_AED) AS Maximum_Property_Price
FROM silver.properties
GROUP BY Property_Type
ORDER BY Average_Property_Price DESC;
GO

-- Q3: How many leads are currently sitting in each funnel stage?
SELECT
    Lead_Status,
    COUNT(*) AS Lead_Count
FROM silver.leads
GROUP BY Lead_Status
ORDER BY Lead_Count DESC;
GO


/* ============================================================
   SECTION 3: INTERMEDIATE -- joins, CASE WHEN, subqueries
   ============================================================ */

-- Q4: Conversion rate by Marketing_Channel AND Customer_Type
-- (do Investors and End Users respond differently per channel?)
SELECT
    l.Marketing_Channel,
    c.Customer_Type,
    COUNT(*) AS Total_Leads,
    SUM(CASE WHEN l.Lead_Status = 'Sold' THEN 1 ELSE 0 END) AS Sold_Leads,
    (SUM(CASE WHEN l.Lead_Status = 'Sold' THEN 1 ELSE 0 END) * 100.0)
        / NULLIF(COUNT(*), 0) AS Conversion_Rate_Percent
FROM silver.leads AS l
INNER JOIN silver.customers AS c
    ON l.Customer_ID = c.Customer_ID
GROUP BY l.Marketing_Channel, c.Customer_Type
ORDER BY l.Marketing_Channel, c.Customer_Type;
GO

-- Q5: Average sale value by Location (using the full combined Sales view)
SELECT
    p.Location,
    COUNT(*) AS Units_Sold,
    AVG(s.Sale_Value_AED) AS Average_Sale_Value
FROM silver.All_Sales_View AS s
INNER JOIN silver.properties AS p
    ON s.Property_ID = p.Property_ID
GROUP BY p.Location
ORDER BY Average_Sale_Value DESC;
GO

-- Q5b: Same question, controlled for Property_Type (avoids the
-- property-mix confound -- e.g. a location with more Penthouses
-- will look artificially "premium" unless you filter to one type)
SELECT
    p.Location,
    COUNT(*) AS Apartment_Units_Sold,
    AVG(s.Sale_Value_AED) AS Average_Apartment_Sale_Value
FROM silver.All_Sales_View AS s
INNER JOIN silver.properties AS p
    ON s.Property_ID = p.Property_ID
WHERE p.Property_Type = 'Apartment'
GROUP BY p.Location
ORDER BY Average_Apartment_Sale_Value DESC;
GO


/* ============================================================
   SECTION 4: ADVANCED -- CTEs & window functions
   ============================================================ */

-- Q6: Deduplicate Sales -- keep only the earliest sale per property
-- (the actual Phase 4 data-cleaning logic, using ROW_NUMBER)
WITH Ranked_Sales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Property_ID
            ORDER BY Sale_Date ASC
        ) AS rn
    FROM bronze.sales
)
SELECT *
FROM Ranked_Sales
WHERE rn = 1;
GO

-- Q6b: The "other side" -- rows flagged for investigation
WITH Ranked_Sales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Property_ID
            ORDER BY Sale_Date ASC
        ) AS rn
    FROM bronze.sales
)
SELECT *
FROM Ranked_Sales
WHERE rn > 1;
GO

-- Q7: Top-performing agent in EACH department (RANK within groups)
WITH Agent_Sales AS (
    SELECT
        a.Agent_ID,
        a.Agent_Name,
        a.Agent_Department,
        SUM(CASE WHEN l.Lead_Status = 'Sold' THEN 1 ELSE 0 END) AS Sold_Count
    FROM silver.leads l
    INNER JOIN silver.agents a
        ON l.Agent_ID = a.Agent_ID
    GROUP BY a.Agent_ID, a.Agent_Name, a.Agent_Department
),
Ranked_Agents AS (
    SELECT
        Agent_ID, Agent_Name, Agent_Department, Sold_Count,
        RANK() OVER (
            PARTITION BY Agent_Department
            ORDER BY Sold_Count DESC
        ) AS Agent_Rank
    FROM Agent_Sales
)
SELECT Agent_ID, Agent_Name, Agent_Department, Sold_Count
FROM Ranked_Agents
WHERE Agent_Rank = 1;
GO

-- Q8: Multi-stage business rule validation in one query (CTE + CASE WHEN)
-- Checks the funnel date-order rule across 3 different Lead_Status values
WITH Data_Quality_Check AS (
    SELECT
        Lead_ID, Lead_Status, Qualification_Date, Site_Visit_Date,
        Negotiation_Date, Booking_Date,
        CASE
            WHEN Lead_Status = 'Lead'
                 AND (Qualification_Date IS NOT NULL OR Site_Visit_Date IS NOT NULL
                      OR Negotiation_Date IS NOT NULL OR Booking_Date IS NOT NULL)
            THEN 'Lead should not have any later stage dates'
            WHEN Lead_Status = 'Contacted'
                 AND (Qualification_Date IS NOT NULL OR Site_Visit_Date IS NOT NULL
                      OR Negotiation_Date IS NOT NULL OR Booking_Date IS NOT NULL)
            THEN 'Contacted lead should not have qualification or later dates'
            WHEN Lead_Status = 'Qualified'
                 AND (Qualification_Date IS NULL OR Site_Visit_Date IS NOT NULL
                      OR Negotiation_Date IS NOT NULL OR Booking_Date IS NOT NULL)
            THEN 'Qualified lead has missing Qualification_Date or unexpected later dates'
        END AS Violation_Reason
    FROM silver.leads
)
SELECT *
FROM Data_Quality_Check
WHERE Violation_Reason IS NOT NULL;
GO


/* ============================================================
   SECTION 5: OFFICIAL KPI QUERIES
   ============================================================ */

-- Funnel stage reach counts (basis for the funnel chart)
SELECT
    COUNT(*) AS Total_Leads,
    SUM(CASE WHEN Qualification_Date IS NOT NULL THEN 1 ELSE 0 END) AS Reached_Qualified,
    SUM(CASE WHEN Site_Visit_Date IS NOT NULL THEN 1 ELSE 0 END) AS Reached_Site_Visit,
    SUM(CASE WHEN Negotiation_Date IS NOT NULL THEN 1 ELSE 0 END) AS Reached_Negotiation,
    SUM(CASE WHEN Booking_Date IS NOT NULL THEN 1 ELSE 0 END) AS Reached_Booking,
    SUM(CASE WHEN Lead_Status = 'Sold' THEN 1 ELSE 0 END) AS Reached_Sold
FROM silver.leads;
GO

-- Conversion Rate & Win Rate (two different denominators, two different questions)
SELECT
    COUNT(*) AS Total_Leads,
    SUM(CASE WHEN Negotiation_Date IS NOT NULL THEN 1 ELSE 0 END) AS Opportunities,
    SUM(CASE WHEN Lead_Status = 'Sold' THEN 1 ELSE 0 END) AS Sold,
    (SUM(CASE WHEN Lead_Status = 'Sold' THEN 1 ELSE 0 END) * 100.0)
        / NULLIF(COUNT(*), 0) AS Conversion_Rate_Percent,
    (SUM(CASE WHEN Lead_Status = 'Sold' THEN 1 ELSE 0 END) * 100.0)
        / NULLIF(SUM(CASE WHEN Negotiation_Date IS NOT NULL THEN 1 ELSE 0 END), 0) AS Win_Rate_Percent
FROM silver.leads;
GO

-- Pipeline Value: uses Property_Price_AED (list price), NOT Sale_Value_AED
-- -- the latter is only populated for already-closed deals.
SELECT
    SUM(p.Property_Price_AED) AS Pipeline_Value_AED,
    COUNT(*) AS Pipeline_Lead_Count
FROM silver.leads AS l
INNER JOIN silver.properties AS p
    ON l.Property_ID = p.Property_ID
WHERE l.Lead_Status IN ('Qualified', 'Site Visit', 'Negotiation', 'Booking');
GO

-- Sales Cycle: average days from Lead_Date to Sale_Date, Sold leads only
SELECT
    AVG(DATEDIFF(day, l.Lead_Date, s.Sale_Date)) AS Avg_Sales_Cycle_Days
FROM silver.leads AS l
INNER JOIN silver.All_Sales_View AS s
    ON l.Lead_ID = s.Lead_ID
WHERE l.Lead_Status = 'Sold';
GO

-- CAC vs CPL by channel (CAC should scale consistently with CPL if
-- conversion rates are similar across channels -- confirms CPL,
-- not differential conversion, drives acquisition cost)
SELECT
    Marketing_Channel,
    COUNT(*) AS Total_Leads,
    SUM(Marketing_Cost_AED) AS Total_Marketing_Cost,
    SUM(CASE WHEN Lead_Status = 'Sold' THEN 1 ELSE 0 END) AS Sold_Leads,
    SUM(Marketing_Cost_AED) / NULLIF(COUNT(*), 0) AS CPL,
    SUM(Marketing_Cost_AED) / NULLIF(SUM(CASE WHEN Lead_Status = 'Sold' THEN 1 ELSE 0 END), 0) AS CAC
FROM silver.leads
GROUP BY Marketing_Channel
ORDER BY CAC DESC;
GO

-- Overall Marketing ROI: total revenue over total cost as ONE ratio
-- -- never average the per-channel ROI ratios together, since
-- channels have very different spend levels (an "average of averages"
-- trap that misleadingly weights small channels equally to large ones).
SELECT
    (SELECT SUM(Sale_Value_AED) FROM silver.All_Sales_View) AS Total_Revenue,
    (SELECT SUM(Marketing_Cost_AED) FROM silver.leads) AS Total_Marketing_Cost,
    (SELECT SUM(Sale_Value_AED) FROM silver.All_Sales_View) * 1.0
        / (SELECT SUM(Marketing_Cost_AED) FROM silver.leads) AS Marketing_ROI;
GO

-- Monthly Revenue & Month-over-Month Growth (LAG window function)
WITH Monthly_Revenue AS (
    SELECT
        FORMAT(Sale_Date, 'yyyy-MM') AS Sale_Month,
        COUNT(*) AS Deals_Closed,
        SUM(Sale_Value_AED) AS Total_Revenue
    FROM silver.All_Sales_View
    GROUP BY FORMAT(Sale_Date, 'yyyy-MM')
),
Revenue_With_Lag AS (
    SELECT
        Sale_Month, Deals_Closed, Total_Revenue,
        LAG(Total_Revenue) OVER (ORDER BY Sale_Month) AS Prior_Month_Revenue
    FROM Monthly_Revenue
)
SELECT
    Sale_Month, Deals_Closed, Total_Revenue, Prior_Month_Revenue,
    (Total_Revenue - Prior_Month_Revenue) * 100.0
        / NULLIF(Prior_Month_Revenue, 0) AS Monthly_Growth_Percent
FROM Revenue_With_Lag
ORDER BY Sale_Month;
GO
