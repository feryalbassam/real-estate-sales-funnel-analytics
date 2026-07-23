# KPI Definitions — Real Estate Sales Funnel Project

Each KPI below includes its formula, the data source, and the business reasoning behind key design decisions.

---

## Funnel & Conversion KPIs

**Leads** — `COUNT(*)` of all rows in the Leads table. The total universe of potential customers who entered the funnel.

**Qualified Leads** — Count where `Qualification_Date IS NOT NULL`. Uses the date column (not `Lead_Status`) because a lead's final status (e.g., "Lost") doesn't reveal whether it passed through earlier stages first.

**Opportunities** — Count where `Negotiation_Date IS NOT NULL`. Defined as reaching Negotiation, the point at which a deal becomes a genuine, serious possibility (not just interest).

**Conversion Rate** = `Sold ÷ Total Leads × 100`
Answers: "Of everyone who ever became a lead, what fraction did we eventually sell to?" — a broad, top-of-funnel-inclusive measure.

**Win Rate** = `Sold ÷ Opportunities × 100`
Answers a narrower question: "Once a deal reached serious negotiation, how often did we actually close it?" **Distinct from Conversion Rate on purpose** — a low Conversion Rate combined with a high Win Rate (our actual finding: 16.26% vs. 68.67%) indicates the sales team closes well; the problem is upstream lead engagement, not sales execution.

---

## Marketing Cost KPIs

**Cost Per Lead (CPL)** = `Total Marketing Cost ÷ Total Leads`
Cost to generate one unit of interest, regardless of whether it converts.

**Customer Acquisition Cost (CAC)** = `Total Marketing Cost ÷ Sold Leads`
Cost to acquire one actual paying customer, all-in. **Not the same as CPL** — CAC divides the same spend by a much smaller number (only the winners), so CAC will always be a multiple of CPL, scaled by the inverse of the conversion rate.

**Return on Ad Spend / Marketing ROI** = `Total Revenue ÷ Total Marketing Cost`
**Critical design decision:** when calculating this at a company-wide level from multiple channels, always compute it as one ratio of totals — `SUM(all revenue) ÷ SUM(all cost)` — never as an average of each channel's individual ROI. Averaging per-channel ratios together weights a small-spend channel equally with a large-spend one, producing a misleading blended figure.

---

## Revenue & Deal KPIs

**Average Deal Size** = `AVERAGE(Sale_Value_AED)` for Sold leads.

**Sales Cycle** = `AVG(DATEDIFF(day, Lead_Date, Sale_Date))` for Sold leads only.
Tells the business how long, on average, it takes to close a deal from first contact — useful for cash flow planning and realistic quota-setting.

**Pipeline Value** = `SUM(Property_Price_AED)` for leads currently in `Qualified`, `Site Visit`, `Negotiation`, or `Booking`.
**Critical design decision:** uses `Property_Price_AED` (the list price), NOT `Sale_Value_AED` — the latter is only populated once a deal is already Sold, so it would return zero/null for exactly the in-progress deals this KPI is meant to estimate. Should always be reported alongside the number of leads it's based on (a small, moving set — ours was 67 leads at time of calculation), since it's a volatile snapshot, not a stable historical total like Revenue.

**Revenue** = `SUM(Sale_Value_AED)` where `Lead_Status = 'Sold'`. Confirmed, realized money — as opposed to Pipeline Value (potential) or Booked Revenue (reserved but not yet finalized).

---

## Growth & Forecasting KPIs

**Monthly Growth** = `(This_Month_Revenue − Last_Month_Revenue) ÷ Last_Month_Revenue × 100`
**Caution:** highly sensitive to a low starting base — early, low-volume months can produce dramatic-looking but meaningless percentage swings (we observed +460%/-49% in a business's first few months of activity). Best practice: exclude early ramp-up periods, or use a rolling average, when reporting this to stakeholders.

**Sales Forecast** (simple method) = `Average monthly revenue over the most recent stable period × (1 + average recent growth rate)`.
A defensible, simple projection — not a sophisticated model. Should always carry an explicit caveat about its assumptions (recent growth continues, no major market changes) and be reviewed alongside Pipeline Value and known upcoming inventory/launches.

---

## A Note on Data Source Selection

Several KPIs above depend on choosing between two possible Sales tables:
- **`silver.sales`** (457 rows) — one sale per property (earliest sale kept), for questions about **unique properties sold**.
- **`silver.sales` UNION `silver.sales_flagged_duplicates`** (813 rows, the "full" combined view) — for **all revenue and deal-count questions**, since the deduplicated-only table understates real recorded revenue by roughly half.

Every revenue/deal-count KPI above uses the full 813-row combined view unless explicitly noted otherwise.
