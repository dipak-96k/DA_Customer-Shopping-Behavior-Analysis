-- ============================================================
-- Bank 360 — SQL Analysis Queries
-- Database: banking (PostgreSQL)
-- ============================================================

-- ============================================================
-- Query 1: Churn Rate by Geography + Age Group
-- ============================================================
SELECT
    geography,
    CASE
        WHEN age < 30 THEN '18-29'
        WHEN age < 45 THEN '30-44'
        WHEN age < 60 THEN '45-59'
        ELSE '60+'
    END AS age_group,
    COUNT(*) AS total_customers,
    SUM(exited) AS churned_customers,
    ROUND(100.0 * SUM(exited) / COUNT(*), 2) AS churn_rate_pct
FROM churn
GROUP BY geography, age_group
ORDER BY churn_rate_pct DESC;

-- Key insight: Germany 45-59 age group shows ~66% churn rate


-- ============================================================
-- Query 2: Fraud Pattern by Hour of Day
-- ============================================================
SELECT
    FLOOR(time_sec / 3600)::int % 24 AS hour_of_day,
    COUNT(*) AS total_transactions,
    SUM(class) AS fraud_count,
    ROUND(100.0 * SUM(class) / COUNT(*), 4) AS fraud_rate_pct,
    ROUND(AVG(amount)::numeric, 2) AS avg_amount
FROM creditcard
GROUP BY hour_of_day
ORDER BY fraud_rate_pct DESC
LIMIT 10;

-- Key insight: Hour 2 (2 AM) has the highest fraud rate at 1.71%


-- ============================================================
-- Query 3: Grade-wise Interest Rate Ranking (Window Function)
-- ============================================================
SELECT
    grade,
    loan_status,
    loan_amnt,
    int_rate,
    RANK() OVER (PARTITION BY grade ORDER BY int_rate DESC) AS rate_rank_in_grade,
    AVG(loan_amnt) OVER (PARTITION BY grade) AS avg_loan_amnt_by_grade,
    COUNT(*) OVER (PARTITION BY grade) AS total_loans_in_grade
FROM accepted_2007_to_2018q4
WHERE grade IS NOT NULL
ORDER BY grade, rate_rank_in_grade
LIMIT 20;

-- Demonstrates PARTITION BY: ranks each loan by interest rate within its own grade,
-- while also showing grade-level averages alongside individual rows (unlike GROUP BY,
-- which would collapse the individual rows)


-- ============================================================
-- Query 4: Default Rate by Loan Grade
-- ============================================================
SELECT
    grade,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_rate_pct,
    ROUND(AVG(int_rate)::numeric, 2) AS avg_interest_rate
FROM accepted_2007_to_2018q4
GROUP BY grade
ORDER BY grade;

-- Key insight: Grade A = 5.16% default, Grade G = 50.39% default
-- Validates risk-based pricing model


-- ============================================================
-- Query 5: Grade + Term Risk Segmentation (CTE)
-- ============================================================
WITH risk_summary AS (
    SELECT
        grade,
        term,
        COUNT(*) AS total_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS defaults,
        ROUND(AVG(annual_inc)::numeric, 0) AS avg_income,
        ROUND(AVG(loan_amnt)::numeric, 0) AS avg_loan_amount
    FROM accepted_2007_to_2018q4
    GROUP BY grade, term
)
SELECT
    grade,
    term,
    total_loans,
    defaults,
    ROUND(100.0 * defaults / total_loans, 2) AS default_rate_pct,
    avg_income,
    avg_loan_amount
FROM risk_summary
ORDER BY grade, term;


-- ============================================================
-- Query 6: High-Value Churned Customers (Window Function)
-- ============================================================
SELECT
    customerid,
    surname,
    geography,
    balance,
    numofproducts,
    isactivemember,
    RANK() OVER (ORDER BY balance DESC) AS wealth_rank
FROM churn
WHERE exited = 1
    AND balance > 100000
ORDER BY balance DESC
LIMIT 20;
