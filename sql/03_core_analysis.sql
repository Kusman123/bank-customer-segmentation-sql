-- ============================================================================
-- CORE BANKING ANALYTICAL QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Total Spend per Customer
-- Purpose: Calculate total debit volume for each customer across all their accounts.
-- ----------------------------------------------------------------------------

select
    a.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.city,
    SUM(t.amount) AS total_spend
from accounts a
join customers c ON c.customer_id = a.customer_id
join transactions t ON a.account_id = t.account_id
where t.transaction_type = 'Debit'
group by
    a.customer_id,
    customer_name,
    c.city
order by total_spend desc;


-- ----------------------------------------------------------------------------
-- 2. Salary Trend Analysis
-- Purpose: Monitor monthly salary credit patterns to detect payroll inflow stability.
-- ----------------------------------------------------------------------------


select
	date_format(transaction_date,"%Y-%m") as salary_month,
    count(transaction_id) as salary_transactions_count,
    sum(amount) as total_salary_credited,
    round(avg(amount),2) as avg_salary_amount
from transactions
where 
	transaction_type = "Credit"
	and transaction_category =  "Salary"
group by date_format(transaction_date,"%Y-%m") 
order by salary_month desc ;


-- ----------------------------------------------------------------------------
-- 3. Most Active Accounts by Transaction Count
-- Purpose: Identify high-frequency operating accounts for operational sizing.
-- ----------------------------------------------------------------------------


select
	t.account_id,
    concat(c.first_name, ' ', c.last_name) AS account_holder,
    a.account_type,
    count(t.transaction_id) as transaction_count
from transactions t 
join accounts a
on t.account_id = a.account_id
join customers c
on c.customer_id = a.customer_id
group by t.account_id,account_holder,a.account_type
order by transaction_count desc
limit 10;


-- ----------------------------------------------------------------------------
-- 4. Most Active Accounts by Transaction Volume
-- Purpose: Identify top accounts by gross monetary throughput.
-- ----------------------------------------------------------------------------


select
	a.account_id,
    concat(c.first_name," ",c.last_name) as account_holder,
    a.account_type,
    count(*) as transactions_count,
    sum(t.amount) as gross_transaction_volume,
    round(avg(t.amount),2) as avg_transaction_volume,
    
    count(case when t.transaction_type = "Credit" then 1 else null end) as credit_count,
    count(case when t.transaction_type = "Debit" then 1 else null end) as debit_count,
    
    sum(case when t.transaction_type = "Credit" then t.amount else 0 end) total_credit_volume,
    sum(case when t.transaction_type = "Debit" then t.amount else 0 end) total_debit_volume

from accounts a
join customers c
on a.customer_id = c.customer_id
join transactions t
on t.account_id = a.account_id
group by
	a.account_id,
    account_holder,
    a.account_type
order by gross_transaction_volume desc
limit 10;

-- ----------------------------------------------------------------------------
-- 5. Monthly Transaction Breakdown
-- Purpose: Track month-over-month volume, credits vs. debits, and count.
-- ----------------------------------------------------------------------------




with cte1 as (
select
	date_format(transaction_date,"%Y-%m") as trans_month,
	count(transaction_id) as total_transactions_count,
    sum(amount) as total_volume,
    
    count(case when transaction_type = "Credit" then transaction_id else null end) as cnt_of_credit_transactions,
    sum(case when transaction_type = "Credit" then amount else 0 end) as volume_of_credit_transactions,
    
	count(case when transaction_type = "Debit" then transaction_id else null end) as cnt_of_dedit_transaction,
	sum(case when transaction_type = "Debit" then amount else 0 end) as volume_of_debit_transactions
    
from transactions
group by date_format(transaction_date,"%Y-%m")

)
select
	trans_month,
    
    -- Monthly Breakdown
    total_transactions_count,
    total_volume,
    volume_of_credit_transactions,
    volume_of_debit_transactions,
    
    -- Cumulative / Running Totals
    
    sum(total_transactions_count) over(order by trans_month asc) as running_count_of_transaction,
    sum(total_volume) over(order by trans_month asc)  as running_sum_of_total_volume,
    sum(cnt_of_credit_transactions) over(order by trans_month asc) as running_count_of_credit_transaction,
    sum(volume_of_credit_transactions) over(order by trans_month asc) as running_sum_of_credit_transaction,
    sum(cnt_of_dedit_transaction) over(order by trans_month asc) as running_count_of_debit_transaction,
    sum(volume_of_debit_transactions) over(order by trans_month asc) as running_sum_of_debit_transaction
from cte1
order by trans_month asc;


-- ----------------------------------------------------------------------------
-- 6. Year-over-Year (YoY) Transaction Growth and Variance Analysis
-- Purpose: Macro-level annual analysis of banking growth.
-- ----------------------------------------------------------------------------


with cte1 as (
select
	year(transaction_date) as transaction_year,
    count(transaction_id) as total_transactions,
    sum(amount) as total_transaction_amount,
    lag(sum(amount)) over(order by year(transaction_date)) as prev_yr_transaction_amount
from transactions
group by year(transaction_date)
order by transaction_year
)
select
	transaction_year,
    total_transactions,
    total_transaction_amount,
    prev_yr_transaction_amount,
    
    -- Absolute Differences
    
    case when (total_transaction_amount-prev_yr_transaction_amount)>0 then (total_transaction_amount-prev_yr_transaction_amount) else null end as  "growth_amount",
    case when (total_transaction_amount-prev_yr_transaction_amount)<0 then abs(total_transaction_amount-prev_yr_transaction_amount) else null end as  "decline_amount",

	-- YoY Growth Percentage
	
    round(
        ((total_transaction_amount - prev_yr_transaction_amount) / prev_yr_transaction_amount) * 100, 
        2
    ) AS yoy_growth_pct
from cte1
;


-- ----------------------------------------------------------------------------
-- 7. Top 20 High-Value Customers (Credit Inflow)
-- Purpose: Rank top depositors/inflow generators for wealth management targeting.
-- ----------------------------------------------------------------------------


select
    c.customer_id,
    concat(c.first_name," ", c.last_name) as customer_name,
    c.city,
    sum(amount) as total_transaction_amount,
    dense_rank() over(order by sum(amount) desc) as rnk
from transactions t 
inner join accounts a
on a.account_id = t.account_id
inner join customers c 
on c.customer_id = a.customer_id
where t.transaction_type = "Credit"
group by c.customer_id,customer_name,c.city
order by total_transaction_amount desc
limit 20;

-- ----------------------------------------------------------------------------
-- 8. Dormant Accounts Detection
-- Purpose: Identify accounts with no recorded transactions in the last 12 months.
-- ----------------------------------------------------------------------------

select	* from transactions;
select * from accounts;

select
	a.account_id,
    concat(c.first_name," ", c.last_name) as customer_name,
    a.account_type,
    a.balance,
    max(t.transaction_date) as last_transaction_date,
    datediff(current_date(),max(t.transaction_date)) as days_inactive
from accounts a
join customers c
on c.customer_id = a.customer_id
left join transactions t
on a.account_id = t.account_id
group by a.account_id,customer_name,a.account_type,a.balance
having last_transaction_date is null or days_inactive > 365
order by days_inactive desc;


-- ----------------------------------------------------------------------------
-- 9. Single-Product Customers
-- Purpose: Identify customers holding only 1 account to run cross-selling campaigns.
-- ----------------------------------------------------------------------------

select
	c.customer_id,
    concat(c.first_name," ",c.last_name) as customer_name,
    c.city,
    count(a.account_id) as total_account,
    max(a.account_type) as current_account_type
from customers c
left join accounts a
on a.customer_id = c.customer_id
group by 
	c.customer_id,
    c.first_name,
    c.last_name,
    c.city
having total_account = 1;


-- ----------------------------------------------------------------------------
-- 10. Most Used Transaction Categories/Services
-- Purpose: Analyze consumer channels (POS, Utility, ATM, Salary, etc.).
-- ----------------------------------------------------------------------------

select
	transaction_category,
    transaction_type,
    count(transaction_id) as cnt,
    sum(amount) as total_volume,
    round(avg(amount),2) as avg_transaction_size
from transactions
group by 
	transaction_category,
    transaction_type
order by cnt desc;

-- ----------------------------------------------------------------------------
-- 11. City-Wise Banking Performance
-- Purpose: Benchmark regional activity, total volume, and customer base size.
-- ----------------------------------------------------------------------------
select
    c.city,
    c.region,
    count(distinct c.customer_id) as total_customers,
    count(t.transaction_id) as total_transactions,
    coalesce(sum(t.amount),0) as total_transaction_volume
from customers c
left join accounts a
on c.customer_id = a.customer_id
left join transactions t 
on a.account_id = t.account_id
group by
	c.city,
    c.region
order by total_transaction_volume desc;


-- ----------------------------------------------------------------------------
-- 12. Engagement by Region (Active vs. Dormant Accounts)
-- Purpose: Map account health status across geographic territories.
-- ----------------------------------------------------------------------------

select
    c.region,
    count(a.account_id) as total_accounts,
    
    count(case when a.account_status = "Active" then a.account_id else null end) as active_accounts,
    count(case when a.account_status = "Dormant" then a.account_id else null end) as dormant_account,
    
    -- Dormancy Rate
    coalesce(
		round(
			(sum(case when a.account_status = "Dormant"  then 1 else 0 end)/ nullif(count(a.account_id),0))*100,
        2)
        ,0) as dormancy_rate_percentage
    
from accounts a
left join customers c
on c.customer_id = a.customer_id
group by 
	c.region
order by total_accounts desc;


-- ----------------------------------------------------------------------------
-- 13. Highest Spender by City
-- Purpose: Uncovers the top spending customer in each city to help with targeted relationship management and regional performance boosts.
-- ----------------------------------------------------------------------------
with cte1 as (
select
	c.customer_id,
    concat(c.first_name," ",c.last_name) as customer_name,
    c.city,
    sum(t.amount) total_spend_amount,
    dense_rank() over(partition by city order by sum(t.amount) desc) as drnk
from customers c
join accounts a
on c.customer_id = a.customer_id
join transactions t
on a.account_id = t.account_id
where t.transaction_type = "Debit"
group by
	c.customer_id,
    customer_name,
    c.city
)
select
	city,
    customer_name,
    total_spend_amount
from cte1
where drnk=1
order by total_spend_amount desc;
