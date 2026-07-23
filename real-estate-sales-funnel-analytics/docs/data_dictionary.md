# Dubai Real Estate Sales Funnel — Data Dictionary & KPI Guide

File: `dubai_real_estate_sales_funnel.csv` — 5,000 rows, 31 columns
Grain: **one row = one lead**, tracked from marketing acquisition through to sale (or loss).

---

## 1. Data Dictionary

### Lead & Marketing Data
| Column | Type | Description |
|---|---|---|
| `Lead_ID` | Text (PK) | Unique identifier for the lead, format `LEAD-000001` |
| `Lead_Date` | Date | Date the lead entered the system |
| `Marketing_Channel` | Text | Source channel: Instagram, Google Ads, Bayut, Website, Referral, LinkedIn |
| `Campaign_Name` | Text | Specific campaign that generated the lead |
| `Marketing_Cost_AED` | Decimal | Estimated acquisition cost attributed to this lead (varies by channel) |
| `Customer_Type` | Text | `Investor` or `End User` |

### Customer Information
| Column | Type | Description |
|---|---|---|
| `Customer_ID` | Text (FK) | Unique customer identifier, format `CUST-000001` |
| `Nationality` | Text | Customer nationality (~3% missing — data-entry gaps) |
| `Preferred_Location` | Text | Area the customer expressed interest in (~4% missing) |
| `Preferred_Property_Type` | Text | Apartment, Villa, Townhouse, Penthouse, Studio |
| `Budget_AED` | Decimal | Customer's stated budget (~5% missing — undecided customers) |

### Property Information
| Column | Type | Description |
|---|---|---|
| `Property_ID` | Text (FK) | Unique property/unit identifier from a 600-unit inventory pool |
| `Project_Name` | Text | Development/project name |
| `Developer_Name` | Text | Developer (Emaar, DAMAC, Nakheel, Sobha, etc.) |
| `Location` | Text | Actual property location/community |
| `Property_Type` | Text | Apartment, Villa, Townhouse, Penthouse, Studio |
| `Bedrooms` | Integer | Number of bedrooms (0 = Studio) |
| `Property_Price_AED` | Integer | List price of the unit |
| `Payment_Plan` | Text | Payment structure offered (e.g. 60/40, Post Handover 60/40, 1% Monthly) |

### Sales Funnel Stages
| Column | Type | Description |
|---|---|---|
| `Lead_Status` | Text | Current funnel stage: `Lead`, `Contacted`, `Qualified`, `Site Visit`, `Negotiation`, `Booking`, `Sold`, `Lost` |
| `Qualification_Date` | Date | Date lead was qualified (null if not reached) |
| `Site_Visit_Date` | Date | Date of property site visit (null if not reached) |
| `Negotiation_Date` | Date | Date negotiation began (null if not reached) |
| `Booking_Date` | Date | Date booking form / reservation deposit was signed (null if not reached) |
| `Sale_Date` | Date | Date of final sale (SPA signed), only populated when `Lead_Status = Sold` |
| `Lost_Reason` | Text | Reason lead was lost (only populated when `Lead_Status = Lost`) |

> **Date logic:** `Lead_Date ≤ Qualification_Date ≤ Site_Visit_Date ≤ Negotiation_Date ≤ Booking_Date ≤ Sale_Date`. A null value in any of these date fields simply means the lead never reached that stage (it was lost earlier, or is still in progress).

### Sales Team
| Column | Type | Description |
|---|---|---|
| `Agent_ID` | Text (FK) | Assigned agent ID (~3% missing = unassigned leads) |
| `Agent_Name` | Text | Assigned agent's name |
| `Agent_Department` | Text | Off-Plan Sales, Secondary Market, Luxury & Branded Residences, Investor Relations |

### Final Sales Metrics
| Column | Type | Description |
|---|---|---|
| `Sale_Value_AED` | Decimal | Final negotiated sale price (only populated when Sold) |
| `Commission_AED` | Decimal | Agent commission, 2–5% of sale value (only populated when Sold) |

---

## 2. Suggested Star Schema (for Data Warehouse / Power BI)

**Fact table:** `Fact_Lead_Funnel`
- Keys: `Lead_ID`, `Customer_ID`, `Property_ID`, `Agent_ID`, `Date` keys (Lead/Qualification/SiteVisit/Negotiation/Booking/Sale)
- Measures: `Marketing_Cost_AED`, `Budget_AED`, `Property_Price_AED`, `Sale_Value_AED`, `Commission_AED`

**Dimension tables:**
- `Dim_Customer` (Customer_ID, Nationality, Customer_Type, Preferred_Location, Preferred_Property_Type)
- `Dim_Property` (Property_ID, Project_Name, Developer_Name, Location, Property_Type, Bedrooms, Payment_Plan)
- `Dim_Agent` (Agent_ID, Agent_Name, Agent_Department)
- `Dim_Marketing` (Marketing_Channel, Campaign_Name)
- `Dim_Date` (standard date dimension, one row per calendar day, linked to each of the 6 date columns via role-playing dimensions)
- `Dim_Funnel_Stage` (ordered list: Lead → Contacted → Qualified → Site Visit → Negotiation → Booking → Sold/Lost)

---

## 3. Suggested KPIs & Dashboard Ideas

### Funnel & Conversion KPIs
- **Overall conversion rate**: Sold ÷ Total Leads
- **Stage-to-stage conversion rate**: e.g. Qualified → Site Visit, Site Visit → Negotiation, Negotiation → Booking, Booking → Sold
- **Drop-off rate by stage** and **top Lost Reasons** (Pareto chart)
- **Average time-in-stage**: days spent at each funnel stage (Lead→Contacted, Contacted→Qualified, etc.)
- **Average sales cycle length**: Lead_Date → Sale_Date

### Marketing Performance KPIs
- **Cost per Lead (CPL)** by channel/campaign
- **Cost per Sale / Customer Acquisition Cost (CAC)** = total Marketing_Cost ÷ number of Sold leads, by channel
- **Lead-to-Sale conversion rate by Marketing_Channel** and by `Customer_Type` (Investor vs End User)
- **Marketing ROI** = (Sale_Value or Commission generated) ÷ Marketing_Cost, by channel/campaign
- **Lead volume trend over time** (monthly/weekly) by channel

### Sales & Revenue KPIs
- **Total Sales Value (AED)** and **Total Commission (AED)**, overall and by developer/project/location
- **Average Sale Value** and **Average Discount vs List Price** (Sale_Value_AED vs Property_Price_AED)
- **Revenue by Property_Type / Bedrooms / Location / Developer**
- **Top performing projects/developers** by sales volume and value

### Sales Team KPIs
- **Leads handled, Site Visits conducted, and Deals closed per Agent**
- **Agent conversion rate** (Sold ÷ Leads assigned)
- **Average deal size and commission per Agent / Department**
- **Department-level funnel performance comparison**

### Customer Insight KPIs
- **Sales/leads by Nationality** and by **Preferred vs Actual Location** (did they buy where they said they wanted to?)
- **Budget vs actual Sale_Value** — are customers over/under-buying their stated budget?
- **Investor vs End User** behavior: conversion rate, average ticket size, preferred property type

### Suggested Power BI Pages
1. **Executive Overview** — total leads, total sales value, overall conversion rate, revenue trend
2. **Funnel Analysis** — funnel chart (Lead → Sold), stage conversion rates, drop-off/lost reasons
3. **Marketing Performance** — CPL, CAC, ROI by channel/campaign
4. **Sales Team Performance** — agent/department leaderboard
5. **Property & Location Insights** — sales by developer, project, location, property type
