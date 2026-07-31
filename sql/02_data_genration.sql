USE bank_analytics;

-- Disable Foreign Key checks for clean re-runs
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE transactions;
TRUNCATE TABLE accounts;
TRUNCATE TABLE customers;
SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================
-- 1. GENERATE CUSTOMERS (200 Records)
-- ==========================================
INSERT INTO customers (first_name, last_name, email, city, region, created_at)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 200
),
-- Fixed City-Region Lookup Pool
city_pool AS (
    SELECT 1 AS id, 'Bareilly' AS city, 'North' AS region UNION ALL
    SELECT 2, 'Delhi', 'North' UNION ALL
    SELECT 3, 'Lucknow', 'North' UNION ALL
    SELECT 4, 'Chandigarh', 'North' UNION ALL
    SELECT 5, 'Jaipur', 'North' UNION ALL
    SELECT 6, 'Mumbai', 'West' UNION ALL
    SELECT 7, 'Ahmedabad', 'West' UNION ALL
    SELECT 8, 'Pune', 'West' UNION ALL
    SELECT 9, 'Surat', 'West' UNION ALL
    SELECT 10, 'Bengaluru', 'South' UNION ALL
    SELECT 11, 'Hyderabad', 'South' UNION ALL
    SELECT 12, 'Chennai', 'South' UNION ALL
    SELECT 13, 'Kolkata', 'East'
),
generated_raw AS (
    SELECT 
        s.n,
        -- Pick random First Name
        ELT(FLOOR(1 + RAND() * 20), 
            'Aarav', 'Priya', 'Rohan', 'Ananya', 'Vikram', 'Neha', 'Kabir', 'Isha', 
            'Aditya', 'Riya', 'Siddharth', 'Pooja', 'Karan', 'Sneha', 'Rahul', 'Divya', 
            'Amit', 'Tanvi', 'Varun', 'Kavya') AS f_name,
            
        -- Pick random Last Name
        ELT(FLOOR(1 + RAND() * 20), 
            'Sharma', 'Verma', 'Mehta', 'Singh', 'Patel', 'Gupta', 'Joshi', 'Rao', 
            'Nair', 'Kumar', 'Reddy', 'Chopra', 'Malhotra', 'Bhasin', 'Deshmukh', 'Kulkarni', 
            'Bhat', 'Saxena', 'Iyer', 'Agarwal') AS l_name,
            
        -- Pick a single integer ID for city lookup
        FLOOR(1 + RAND() * 13) AS random_city_id,
        
        -- Random signup date within the last 3 years (1095 days)
        DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 1095) DAY) AS signup_dt
    FROM seq s
)
SELECT 
    g.f_name,
    g.l_name,
    LOWER(CONCAT(g.f_name, '.', g.l_name, g.n, '@example.com')) AS email,
    cp.city,
    cp.region,
    g.signup_dt AS created_at
FROM generated_raw g
JOIN city_pool cp ON g.random_city_id = cp.id;


-- ==========================================
-- 2. GENERATE ACCOUNTS (1 to 2 per Customer)
-- ==========================================
INSERT INTO accounts (customer_id, account_type, account_status, balance, created_at)
WITH RECURSIVE multiplier AS (
    SELECT 1 AS m_id 
    UNION ALL 
    SELECT m_id + 1 FROM multiplier WHERE m_id < 2
),
account_pool AS (
    SELECT 
        c.customer_id,
        ELT(FLOOR(1 + RAND() * 3), 'Savings', 'Checking', 'Fixed Deposit') AS acc_type,
        CASE WHEN RAND() < 0.15 THEN 'Dormant' ELSE 'Active' END AS acc_status,
        ROUND(1000 + (RAND() * 499000), 2) AS initial_balance,
        DATE_ADD(c.created_at, INTERVAL FLOOR(RAND() * 30) DAY) AS acc_created_at
    FROM customers c
    CROSS JOIN multiplier m
    -- ~75% chance of a second account per customer
    WHERE m.m_id = 1 OR (m.m_id = 2 AND RAND() < 0.75)
)
SELECT customer_id, acc_type, acc_status, initial_balance, acc_created_at 
FROM account_pool
LIMIT 300;


-- ==========================================
-- 3. GENERATE TRANSACTIONS (1,000 Records)
-- ==========================================
INSERT INTO transactions (account_id, transaction_type, transaction_category, amount, transaction_date)
WITH RECURSIVE tx_seq AS (
    SELECT 1 AS t_id 
    UNION ALL 
    SELECT t_id + 1 FROM tx_seq WHERE t_id < 1000
),
raw_transactions AS (
    SELECT 
        t_id,
        -- Random valid account link
        (SELECT account_id FROM accounts ORDER BY RAND() LIMIT 1) AS acc_id,
        -- 50/50 split between Credit and Debit
        CASE WHEN RAND() < 0.5 THEN 'Credit' ELSE 'Debit' END AS tx_type,
        -- Random date over past 2 years (730 days)
        DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 730) DAY) AS tx_date,
        -- Random amount between 500 and 250,000
        ROUND(500 + (RAND() * 249500), 2) AS tx_amount
    FROM tx_seq
)
SELECT 
    acc_id,
    tx_type,
    CASE 
        WHEN tx_type = 'Credit' THEN 
            ELT(FLOOR(1 + RAND() * 5), 'Salary', 'Deposit', 'Business Inflow', 'Refund', 'Transfer')
        ELSE 
            ELT(FLOOR(1 + RAND() * 5), 'POS', 'Utility', 'Airtime', 'Transfer', 'ATM Withdrawal')
    END AS transaction_category,
    tx_amount,
    tx_date
FROM raw_transactions;


-- ==========================================
-- 4. DATA INTEGRITY DIAGNOSTICS
-- ==========================================

-- Verify City-Region consistency
SELECT city, region, COUNT(*) AS customer_count 
FROM customers 
GROUP BY city, region 
ORDER BY region, city;

-- Confirm overall row counts
SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions;