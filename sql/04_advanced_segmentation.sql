-- ================================================================================
-- FILE NAME : 04_advanced_segmentation.sql
-- PROJECT   : Core Banking & Transaction Analytics Platform
-- AUTHOR    : Usman khan
-- PHASE 4   : Advanced Customer Segmentation & Behavior Analytics
-- ================================================================================

/*
BUSINESS CONTEXT & STRATEGIC OBJECTIVE:
--------------------------------------------------------------------------------
To drive data-driven customer retention, personal banking relationship management, 
and cross-selling strategies, the executive leadership team requires a granular 
segmentation framework based on customer transaction behavior. 

This script implements an industry-standard RFM (Recency, Frequency, Monetary) 
analytical framework across the entire customer base:

1. RECENCY (R)   : Evaluates customer churn risk by calculating the exact 
                   number of days elapsed since their last debit transaction.
2. FREQUENCY (F) : Measures brand engagement and platform usage intensity 
                   via total debit transaction velocity.
3. MONETARY (M)  : Quantifies total capital inflow/outflow per customer to 
                   identify high-net-worth individual (HNWI) accounts.

TECHNICAL DESIGN & DATA GOVERNANCE HIGHLIGHTS:
--------------------------------------------------------------------------------
- Full Population Coverage : Utilizes explicit LEFT JOIN topologies with inline
                             transaction-type filtering to prevent excluding 
                             inactive or zero-debit customers (eliminating 
                             survivorship bias).
- Data Defensive Design    : Integrates COALESCE() and NULLIF() functions to safeguard
                             against NULL aggregations and potential division-by-zero 
                             errors during percentage or scoring transformations.
- Statistical Segmentation : Leverages NTILE(5) analytical window functions across
                             partitioned behavioral dimensions to assign dynamic, 
                             scalable scores (1 to 5 scale) for targeted marketing.
================================================================================
*/
-- ----------------------------------------------------------------------------
-- 1. Recency, Frequency, and Monetary (RFM) Metric Calculation
-- Purpose: The marketing and risk teams want to segment customers based on their transactional behavior using the industry-standard RFM Framework:
-- ----------------------------------------------------------------------------

select
	c.customer_id,
    concat(c.first_name, " ",c.last_name) as customer_name,
    c.city,
    
     -- Recency: Days since last debit transaction
    datediff(current_date(),max(transaction_date)) as recency_days,
    
    -- Frequency: Total count of debit transactions
    count(t.transaction_id) as frequency,
    
    -- Monetary: Total monetary spend
    coalesce(sum(t.amount),0) as total_amount_spent
  
from customers c 
left join accounts a
on a.customer_id = c.customer_id
left join transactions t 
on t.account_id = a.account_id
and t.transaction_type = "Debit"
group by
	c.customer_id,
    customer_name,
    c.city;
    
-- =============================================================================
-- Question 2: NTILE-Based Behavioral Quintile Scoring (1-5 Scale)
-- =============================================================================

    
    with cte1 as (
    select
        c.customer_id,
        concat(c.first_name, ' ', c.last_name) as customer_name,
        c.city,
        
        -- Recency: Default to 9999 days if no debit transactions exist
        coalesce(datediff(current_date(), max(t.transaction_date)), 9999) as recency_days,
        
        -- Frequency: Total count of debit transactions
        count(t.transaction_id) AS frequency,
        
        -- Monetary: Total monetary spend
        coalesce(sum(t.amount), 0) AS total_amount_spent
        
    from customers c 
    left join accounts a 
           on a.customer_id = c.customer_id
    left join transactions t 
           on t.account_id = a.account_id 
          and t.transaction_type = 'Debit'
    group by
        c.customer_id,
        customer_name,
        c.city
), cte2 as (
select
	customer_id,
	customer_name,
	city,
	recency_days,
	frequency,
	total_amount_spent,
	
	-- Lower recency days = higher score (5 = most recent, 1 = least recent/never)
	ntile(5) over (order by recency_days desc ,frequency asc) as r_score,

	-- Higher frequency = higher score
	ntile(5) over (order by frequency asc) as f_score,
        
	-- Higher monetary spend = higher score
	ntile(5) over (Order by total_amount_spent asc)as m_score
    
    from cte1
    )
    select
	customer_id,
    customer_name,
    city,
    recency_days,
    frequency,
    total_amount_spent,
    r_score,
    f_score,
    m_score,
        case
			when (r_score >=4 and f_score >=4 and m_score>=4) then "Champions"
            when (r_score <=2 and (f_score >=3 or m_score>=3)) then "At Risk Customers"
            when (r_score <=2 and f_score <=2 ) then "Hibernating/Dormant"
            else "Regular"
		end as segmentation_status
	from cte2
	order by r_score desc, m_score desc;
    
    

-- =============================================================================
-- QUESTION 3: Month-over-Month (MoM) Debit Transaction Growth
-- =============================================================================
-- BUSINESS CONTEXT:
-- Executive leadership needs visibility into monthly revenue and spending trends 
-- to monitor platform growth dynamics. Measuring raw volume alone obscures trend 
-- changes; calculating Month-over-Month (MoM) percentage change using window 
-- functions reveals growth acceleration, seasonality, or sudden user attrition.
--
-- steps performed:
-- 1. Aggregate total debit transaction amount by Year and Month.
-- 2. Use LAG() OVER () to retrieve the previous month's total spend.
-- 3. Calculate MoM % growth: ((current_month - prior_month) / prior_month) * 100.
-- 4. Apply NULLIF() to prevent division-by-zero runtime exceptions.
-- =============================================================================



with cte1 as (
select
	date_format(transaction_date,"%Y-%m") as txn_month,
    sum(amount) as current_month_volume,
    lag(sum(amount)) over(order by date_format(transaction_date,"%Y-%m") asc) as previous_month_volume
from transactions
where transaction_type = "Debit"
group by txn_month

)
select
	txn_month,
    current_month_volume,
    previous_month_volume,
    round(((current_month_volume-previous_month_volume)/nullif(previous_month_volume,0))*100,2) as mom_growth_percentage
from cte1
order by txn_month asc;


-- =============================================================================
-- QUESTION 5: Customer Churn Risk Scoring & Consecutive Inactivity Ranking
-- =============================================================================
-- BUSINESS CONTEXT:
-- Identifying dormant accounts after churn has occurred is reactive. To enable 
-- proactive retention, risk management requires a ranking model that scores 
-- accounts by risk level based on inactive duration and balance exposure.
--
-- Steps performed:
-- 1. Calculate days since last transaction for all active accounts.
-- 2. Classify accounts into Risk Tiers using CASE WHEN logic:
--    - 'High Risk'   : Days inactive > 180 AND Balance > 50000
--    - 'Medium Risk' : Days inactive > 90 AND Days inactive <= 180
--    - 'Low Risk'    : Days inactive <= 90
-- 3. Rank high-risk accounts using DENSE_RANK() ordered by balance DESC.
-- =============================================================================

-- Write a query to evaluate all accounts with status 'Active' and categorize their churn risk based on how long they have been inactive and how much money is sitting in the account.
-- Your final output should include:
-- account_id and customer_id.
-- balance: Current account balance
-- days_inactive: Number of days since the account's last transaction (CURRENT_DATE() vs MAX(transaction_date)).
-- risk_tier:
-- 'High Risk' if days_inactive > 180 AND balance > 50000
-- 'Medium Risk' if days_inactive > 90 AND days_inactive <= 180
-- 'Low Risk' for everything else.
-- risk_rank: Use DENSE_RANK() OVER (PARTITION BY risk_tier ORDER BY balance DESC) to rank accounts within each tier so high-balance accounts get prioritized.



with cte1 as (
select
	a.account_id,
    a.customer_id,
    a.balance as total_balance,
    coalesce(datediff(current_date(),max(t.transaction_date)),99999) as days_inactive
from accounts a
left join transactions t
on t.account_id = a.account_id
where a.account_status = "Active"
group by 
	a.account_id,
    a.customer_id,
    a.balance
), cte2 as (
select
	account_id,
    customer_id,
    total_balance,
    days_inactive,
	case
		when days_inactive > 180 and total_balance >50000 then "High Risk"
        when days_inactive > 90 and days_inactive <=180 then "Medium Risk"
        else "Low Risk"
    end as risk_tier
from cte1
)
select
	account_id,
    customer_id,
    total_balance,
    days_inactive,
    risk_tier,
    dense_rank() over(partition by risk_tier order by total_balance desc) as risk_rank
from cte2
order by risk_tier, risk_rank;;