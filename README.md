# 🏦 Core Banking & Transaction Analytics Platform

A end-to-end SQL data analytics project simulating a commercial retail bank's transactional core. This repository demonstrates practical data engineering and analytical workflows—from database architecture and data quality checks to customer behavioral segmentation and C-suite operational summaries.

---

## 📌 Project Overview

Financial institutions generate vast amounts of transactional data daily. Without structured analytics, identifying key growth drivers, managing liquidity risk, or spotting churn signals can be difficult.

This project tackles those challenges by evaluating customer account lifecycles, deposit distributions, regional performance, and spending patterns across thousands of core transactions.

### Key Objectives:

- **Liquidity & Portfolio Risk:** Measure total bank deposit concentrations across product lines (Savings, Checking, Money Market, Fixed Deposit).
- **Customer Value & Retention:** Identify High-Net-Worth Individuals (HNWIs) and flag dormant or high-churn-risk accounts.
- **Regional Market Share:** Evaluate regional account performance and average customer balances across major metropolitan areas.
- **Operational Performance:** Track monthly transacting footprints, average transaction sizes, and Month-over-Month (MoM) volume trends.

---

## 🛠️ Tools & Tech Stack

- **Database Engine:** MySQL
- **SQL Techniques Applied:**
  - Common Table Expressions (CTEs) & Subqueries for modular query logic
  - Window Functions (`LAG()`, `SUM() OVER()`, `NTILE()`, `ROW_NUMBER()`) for running totals and MoM calculations
  - Multi-table relational joins (`INNER`, `LEFT`) optimized to prevent fan-out multiplication
  - Conditional Aggregation (`CASE WHEN`, `COALESCE()`, `NULLIF()`) for resilient calculations

---

## 📂 Repository Structure

The project is structured into **5 modular SQL scripts**, built progressively from foundation to executive reporting:

| File Name                           | Phase                              | Key Analytical Focus                                                                                        |
| :---------------------------------- | :--------------------------------- | :---------------------------------------------------------------------------------------------------------- |
| `sql/01_schema_setup.sql`           | **Phase 1: Architecture**          | Database creation, primary/foreign key relationships, table constraints, and data loading.                  |
| `sql/02_data_cleaning.sql`          | **Phase 2: Quality Control**       | Identifying missing values, handling null balances, deduplicating records, and data profiling.              |
| `sql/03_intermediate_analytics.sql` | **Phase 3: Core Analytics**        | Active vs. inactive accounts, regional customer counts, average account balances, and product distribution. |
| `sql/04_advanced_segmentation.sql`  | **Phase 4: Customer Intelligence** | RFM customer scoring, churn risk models, single vs. multi-product engagement, and spending velocity.        |
| `sql/05_executive_kpis.sql`         | **Phase 5: Executive Reporting**   | C-suite summary matrices, liquidity concentration ratios, HNWI share, and MoM operational run-rates.        |

---

## 📊 Key SQL Queries & Purposes

Below is the complete inventory of analytical queries developed across all 5 phases of the platform:

### 🧹 Phase 1 & 2: Database Setup, Schema Constraints & Data Quality

| No. | Query Title                         | Purpose                                                                                                                               |
| :-: | :---------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------ |
|  1  | **Relational Schema Definition**    | Creates `customers`, `accounts`, and `transactions` tables with primary keys, foreign keys, and check constraints.                    |
|  2  | **Data Type Validation & Audit**    | Verifies database structures, column data types, constraints, and index mappings.                                                     |
|  3  | **Null Value Identification**       | Identifies missing or null values across key fields (e.g., account balances, transaction amounts) to establish baseline data quality. |
|  4  | **Orphaned Record Detection**       | Audits transactional logs for accounts or customers that do not exist in parent tables (`LEFT JOIN` checks).                          |
|  5  | **Duplicate Transaction Profiling** | Detects duplicate transaction entries using window functions (`ROW_NUMBER()`) based on timestamp, account, and amount.                |

---

### 📈 Phase 3: Core & Regional Banking Analytics

| No. | Query Title                                                       | Purpose                                                                                                                       |
| :-: | :---------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------- |
|  1  | **Total Spend per Customer**                                      | Calculate total debit volume for each customer across all their accounts.                                                     |
|  2  | **Salary Trend Analysis**                                         | Monitor monthly salary credit patterns to detect payroll inflow stability..                                                   |
|  3  | **Most Active Accounts by Transaction Count**                     | Identify high-frequency operating accounts for operational sizing.                                                            |
|  4  | **Most Active Accounts by Transaction Volume**                    | Identify top accounts by gross monetary throughput.                                                                           |
|  5  | **Monthly Transaction Breakdown**                                 | Track month-over-month volume, credits vs. debits, and count.                                                                 |
|  6  | **Year-over-Year (YoY) Transaction Growth and Variance Analysis** | Macro-level annual analysis of banking growth.                                                                                |
|  7  | **Top 20 High-Value Customers (Credit Inflow)**                   | Rank top depositors/inflow generators for wealth management targeting.                                                        |
|  8  | **Dormant Accounts Detection**                                    | Identify accounts with no recorded transactions in the last 12 months.                                                        |
|  9  | **Single-Product Customers**                                      | Identify customers holding only 1 account to run cross-selling campaigns.                                                     |
| 10  | **Most Used Transaction Categories/Services**                     | Analyze consumer channels (POS, Utility, ATM, Salary, etc.)                                                                   |
| 11  | **City-Wise Banking Performance**                                 | Benchmark regional activity, total volume, and customer base size.                                                            |
| 12  | **Engagement by Region (Active vs. Dormant Accounts)**            | Map account health status across geographic territories.                                                                      |
| 13  | **Highest Spender by City**                                       | Uncovers the top spending customer in each city to help with targeted relationship management and regional performance boosts |

---

### 🎯 Phase 4: Advanced Customer Intelligence & Segmentation

| No. | Query Title                                                   | Purpose                                                                                                            |
| :-: | :------------------------------------------------------------ | :----------------------------------------------------------------------------------------------------------------- |
|  1  | **Recency, Frequency, and Monetary (RFM) Metric Calculation** | to segment customers based on their transactional behavior using the industry-standard RFM Framework               |
|  2  | **RFM Customer Scoring Matrix**                               | Segments customers into 5 distinct tiers based on transaction Recency, Frequency, and Monetary value (`NTILE(5)`). |
|  3  | **Month-over-Month (MoM) Debit Transaction Growth**           | Finding monthly revenue and spending trends to monitor platform growth dynamics                                    |
| 12  | **RFM Customer Scoring Matrix**                               | Segments customers into 5 distinct tiers based on transaction Recency, Frequency, and Monetary value (`NTILE(5)`). |
| 13  | **90-Day Account Dormancy & Churn Risk**                      | Flags active accounts with zero transactions in the last 90 days to identify retention risks.                      |

---

### 🏛️ Phase 5: C-Suite Executive Dashboards & Portfolio KPIs

| No. | Query Title                                | Purpose                                                                                                                                                 |
| :-: | :----------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 17  | **Macro Bank-Level Executive Summary**     | Consolidates total active customers, active accounts, overall deposit liabilities, and total debit transaction volume into a single C-suite KPI matrix. |
| 18  | **Regional Liquidity & Market Share**      | Computes total regional deposits, average deposit per customer, and each city's percentage contribution (`SUM() OVER()`) to total bank deposits.        |
| 19  | **Product Portfolio Concentration**        | Evaluates balance concentration ratios across account types to assess liquidity stability during economic downturns.                                    |
| 20  | **High-Net-Worth Individual (HNWI) Share** | Identifies customers holding active balances $> ₹100,000$ and calculates their percentage share of total bank deposits.                                 |
| 21  | **Monthly Operational Run-Rate Dashboard** | Tracks active transacting user footprint, total debit spend, average transaction size, and MoM spend growth velocity over time.                         |

---

## 💡 Key Business Insights Discovered

1. **Liquidity Concentration:**
   - High-Net-Worth Individuals (customers with total active balances exceeding ₹100,000) represent a small fraction of the total user base but control over **98% of total bank deposits**. This indicates strong deposit stability, but highlights a key retention priority for wealth management teams.

2. **Regional Performance Gaps:**
   - Regional grouping revealed specific cities with high customer volume but below-average deposit balances. These markets present prime targets for cross-selling term deposits and payroll accounts.

3. **Multi-Account Stickiness:**
   - Customers holding more than one active account type exhibit significantly higher transaction frequency and lower 90-day dormancy rates compared to single-product holders.

4. **Monthly Run-Rate Trends:**
   - Monthly debit spend and transacting footprint showed steady quarter-over-quarter growth, with average transaction size remaining stable even as overall user transaction counts increased.

---

## 🚀 How to Run This Project

1. **Clone the repository:**
   ````bash
   git clone [https://github.com/Kusman123/bank-customer-segmentation-sql
   .git](https://github.com/Kusman123/bank-customer-segmentation-sql
   .git)
   cd bank-customer-segmentation-sql
    ```
   ````

### 2. Database Setup

1. Open your preferred SQL client (MySQL Workbench, pgAdmin, or VS Code SQL extension).
2. Run the scripts sequentially from the `sql/` directory:
   - Execute `01_schema_setup.sql` to build the schema.
   - Execute `02_data_cleaning.sql` to profile and clean the dataset.
   - Run phases `03`, `04`, and `05` to generate analytical outputs and executive reports.

---

## 👨‍💻 About the Author

I am a Data Analyst passionate about translating complex transactional datasets into clear, actionable business insights. My focus is on building clean, robust analytical models in SQL to support strategic decision-making in financial services, e-commerce, and operations.

- **LinkedIn:** [https://www.linkedin.com/in/usmankhanbly]
- **GitHub:** [https://github.com/Kusman123]
- **Email:** [usmanahmadkhan93@gmail.com]
