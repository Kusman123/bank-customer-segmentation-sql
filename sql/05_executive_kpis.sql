/*
================================================================================
FILE NAME : 05_executive_kpis.sql
PROJECT   : Core Banking & Transaction Analytics Platform
AUTHOR    : Usman Khan
PHASE 5   : Executive Dashboards &  KPI Summaries
================================================================================

BUSINESS CONTEXT & STRATEGIC OBJECTIVE:
--------------------------------------------------------------------------------
Executive leadership requires high-level KPI aggregations and multi-dimensional
summaries to make data-driven decisions on capital allocation, regional expansion,
and risk exposure. 

This phase aggregates granular transactional data into executive-ready reporting 
views suitable for direct consumption by BI dashboards (Tableau / Power BI) 
and C-suite summaries.

KEY METRICS GENERATED:
--------------------------------------------------------------------------------
1. Macro Bank-Level KPIs (Total Active Deposits, Total Transaction Volume, Active User Count)
2. Regional Performance & Balance Metrics
3. Account Type Distribution & Liquidity Concentration
================================================================================
*/

-- ==========================================================================================================================================================

-- QUESTION 1: Write a query to calculate the overall macro-level key performance indicators (KPIs) across the entire bank in a single summary row.

-- =======================================================================================================================================================



with customer_kpis as (
    select count(distinct customer_id) as total_customers 
    from customers
),
account_kpis as (
    select 
        count(account_id) as total_active_accounts,
        coalesce(sum(balance), 0) as total_bank_deposits
    from accounts
    where account_status = 'Active'
),
transaction_kpis as (
    select 
        count(transaction_id) as total_debit_transactions,
        coalesce(SUM(amount), 0) as total_debit_volume
    from transactions
    where transaction_type = 'Debit'
)
select
    c.total_customers,
    a.total_active_accounts,
    a.total_bank_deposits,
    t.total_debit_transactions,
    t.total_debit_volume
from customer_kpis c
cross join account_kpis a
cross join transaction_kpis t;

-- =============================================================================
-- QUESTION 2: Regional Performance & Balance Distribution Matrix
-- =============================================================================
-- BUSINESS CONTEXT:
-- Regional directors need a geographic breakdown of bank performance to identify 
-- high-performing markets vs underperforming territories. Comparing total customers, 
-- active accounts, total deposits, and average balance per city informs target 
-- resource allocation and local marketing strategies.
--
-- Steps Performed:
-- 1. Group data by customer city (`c.city`).
-- 2. Count total unique customers per city.
-- 3. Count total active accounts per city.
-- 4. Calculate total deposits held in each city.
-- 5. Compute average customer deposit volume (`total_deposits / NULLIF(total_customers, 0)`).
-- 6. Order results by total deposits descending.
-- =============================================================================


with regional_summary as(
select
    c.city,
    count(distinct c.customer_id) as total_customers,
    count(a.account_id) as total_active_accounts,
    coalesce(sum(a.balance),0) as total_regional_deposits,
    round(avg(coalesce(a.balance,0)), 2) as avg_customer_balance
from customers c
left join accounts a
on a.customer_id = c.customer_id
and a.account_status = 'Active'
group by c.city
)
select
    city,
    total_customers,
    total_active_accounts,
    total_regional_deposits,
    round(total_regional_deposits / nullif(total_customers, 0), 2) as avg_deposit_per_customer,
    round((total_regional_deposits / nullif(sum(total_regional_deposits) over(), 0)) * 100, 2) as pct_of_total_bank_deposits
from regional_summary
order by total_regional_deposits desc;



-- =============================================================================
-- QUESTION 3: Product Portfolio Liquidity & Balance Concentration
-- =============================================================================
-- BUSINESS CONTEXT:
-- Product managers need to analyze liquidity concentration across different account 
-- types (Savings, Checking, Fixed Deposit, Money Market) to assess capital stability. 
-- High concentration in volatile product types presents liquidity risk during 
-- economic downturns.
--
-- Steps Performed:
-- 1. Aggregate total account count and total balance by account_type.
-- 2. Calculate average balance per account type.
-- 3. Calculate balance share percentage across the bank's total deposit portfolio.
-- 4. Filter for 'Active' accounts only and order by total balance descending.
-- =============================================================================



with account_types as (
select
	account_type,
    count(account_id) as total_active_accounts,
    sum(balance) as total_portfolio_balance
from accounts
where account_status = "Active"
group by account_type
)
select
	account_type,
    total_active_accounts,
    total_portfolio_balance,
    round(total_portfolio_balance/nullif(total_active_accounts,0),2) as avg_account_balance,
    round(total_portfolio_balance*100/(select sum(balance) from accounts where account_status="Active"),2) as pct_of_total_liquidity
from account_types
order by total_portfolio_balance desc;


-- =============================================================================
-- QUESTION 4: High-Value Customer (HNWI) Liquidity Concentration
-- =============================================================================
-- BUSINESS CONTEXT:
-- Private banking and wealth management teams require identification of high-net-worth 
-- individual (HNWI) accounts—defined as customers holding cumulative active balances 
-- exceeding ₹100,000. Understanding balance concentration among top-tier clients is 
-- critical for liquidity management and VIP retention programs.
--
-- TECHNICAL REQUIREMENTS:
-- 1. Aggregate cumulative active account balance per customer.
-- 2. Filter for customers with cumulative balance > 100,000.
-- 3. Calculate total HNWI customer count and total HNWI balance.
-- 4. Compute HNWI deposit share as a percentage of overall total bank deposits.
-- =============================================================================