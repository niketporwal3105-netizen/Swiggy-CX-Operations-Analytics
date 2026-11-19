-- =========================================================
-- PROJECT: SWIGGY CUSTOMER EXPERIENCE & OPERATIONS ANALYTICS
-- DATABASE: swiggy_analytics
-- =========================================================

-- TABLE OF CONTENTS:
-- SECTION 1: DATABASE & SCHEMA SETUP
-- SECTION 2: DATA VALIDATION & INTEGRITY CHECKS
-- SECTION 3: BUSINESS QUESTION 1 - DELIVERY SLA ANALYSIS
-- SECTION 4: BUSINESS QUESTION 2 - DEPARTMENT PERFORMANCE
-- SECTION 5: BUSINESS QUESTION 3 - REVENUE AT RISK
-- SECTION 6: BUSINESS QUESTION 4 - PRODUCT & TECH ANALYSIS
-- SECTION 7: BUSINESS QUESTION 5 - SEVERE DELIVERY FAILURES
-- SECTION 8: BUSINESS QUESTION 6 - DEPARTMENT-WISE RISK RANKING
-- SECTION 9: BUSINESS QUESTION 7 - CITY-WISE TOP ISSUE RANKING
-- SECTION 10: ANALYTICAL VIEW CREATION (POWER BI LAYER)




-- 1. Create a dedicated database
CREATE DATABASE IF NOT EXISTS swiggy_analytics;
USE swiggy_analytics;

-- 2. Drop existing tables if needed
DROP TABLE IF EXISTS fact_swiggy_reviews;
DROP TABLE IF EXISTS fact_order_operations;

-- 3. Create Fact Table 1: Order Operations
CREATE TABLE fact_order_operations (
    order_id VARCHAR(50) PRIMARY KEY,
    order_date DATE NOT NULL,
    customer_city VARCHAR(50) NOT NULL,
    order_amount_inr DECIMAL(10, 2) NOT NULL,
    promised_delivery_time_mins INT NOT NULL,
    actual_delivery_time_mins INT NOT NULL,
    refund_issued VARCHAR(10) NOT NULL
);

-- 4. Create Fact Table 2: Reviews & AI Classifications
CREATE TABLE fact_swiggy_reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    customer_rating INT NOT NULL,
    review_text TEXT,
    sentiment VARCHAR(20) NOT NULL,
    root_cause_category VARCHAR(100) NOT NULL,
    action_owner VARCHAR(50) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES fact_order_operations(order_id)
);

SELECT COUNT(*) AS total_orders FROM fact_order_operations;
SELECT COUNT(*) AS total_reviews FROM fact_swiggy_reviews;



USE swiggy_analytics;

/* ================================================================================
   BUSINESS QUESTION 1:
   Which metro cities are experiencing the worst delivery SLA breach rates, and 
   what is the average delay experienced by customers across each geography?
   ================================================================================ */
SELECT 
    customer_city,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN actual_delivery_time_mins > promised_delivery_time_mins THEN 1 ELSE 0 END) AS sla_breached_orders,
    ROUND(
        SUM(CASE WHEN actual_delivery_time_mins > promised_delivery_time_mins THEN 1.0 ELSE 0 END) * 100.0 / COUNT(order_id), 
        2
    ) AS sla_breach_rate_pct,
    ROUND(AVG(actual_delivery_time_mins - promised_delivery_time_mins), 1) AS avg_delay_mins
FROM fact_order_operations
GROUP BY customer_city
ORDER BY sla_breach_rate_pct DESC;


/* ================================================================================
   BUSINESS QUESTION 2:
   Which cross-functional department (Action Owner) generates the highest defect 
   volume, what is their defect density (negative feedback %), and how does it 
   impact the average CSAT rating?
   ================================================================================ */
SELECT 
    action_owner,
    COUNT(review_id) AS total_feedback_volume,
    SUM(CASE WHEN sentiment = 'Negative' THEN 1 ELSE 0 END) AS negative_defects,
    ROUND(
        SUM(CASE WHEN sentiment = 'Negative' THEN 1.0 ELSE 0 END) * 100.0 / COUNT(review_id), 
        2
    ) AS defect_density_pct,
    ROUND(AVG(customer_rating), 2) AS avg_csat_score
FROM fact_swiggy_reviews
GROUP BY action_owner
ORDER BY negative_defects DESC;


/* ================================================================================
   BUSINESS QUESTION 3:
   What is the total Gross Merchandise Value (GMV) at risk across root-cause 
   categories due to severe delivery delays (>15 mins late) or negative sentiment, 
   and how much direct cash was lost to customer refunds?
   ================================================================================ */
SELECT 
    r.root_cause_category,
    COUNT(DISTINCT o.order_id) AS impacted_orders,
    ROUND(SUM(o.order_amount_inr), 2) AS total_revenue_at_risk_inr,
    ROUND(
        SUM(CASE WHEN o.refund_issued = 'Yes' THEN o.order_amount_inr ELSE 0 END), 
        2
    ) AS direct_refund_loss_inr
FROM fact_order_operations o
JOIN fact_swiggy_reviews r ON o.order_id = r.order_id
WHERE (o.actual_delivery_time_mins - o.promised_delivery_time_mins) > 15
   OR r.sentiment = 'Negative'
GROUP BY r.root_cause_category
ORDER BY total_revenue_at_risk_inr DESC;


/* ================================================================================
   BUSINESS QUESTION 4:
   What is the business and user experience impact of App & Tech Glitches 
   (Product & Tech team) compared to other operational categories in terms of 
   refund volume and severe low-rating (1-star) frequency?
   ================================================================================ */
SELECT 
    r.root_cause_category,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN r.customer_rating = 1 THEN 1 ELSE 0 END) AS one_star_orders,
    ROUND(
        SUM(CASE WHEN r.customer_rating = 1 THEN 1.0 ELSE 0 END) * 100.0 / COUNT(o.order_id), 
        2
    ) AS one_star_rate_pct,
    SUM(CASE WHEN o.refund_issued = 'Yes' THEN 1 ELSE 0 END) AS refund_order_count,
    ROUND(SUM(CASE WHEN o.refund_issued = 'Yes' THEN o.order_amount_inr ELSE 0 END), 2) AS refund_value_inr
FROM fact_order_operations o
JOIN fact_swiggy_reviews r ON o.order_id = r.order_id
GROUP BY r.root_cause_category
ORDER BY one_star_orders DESC;


/* ================================================================================
   BUSINESS QUESTION 5:
   What is the distribution of orders experiencing critical operational failures 
   (delay > 20 mins) broken down by promised delivery SLA tiers (e.g., 25, 30, 45 mins)?
   ================================================================================ */
SELECT 
    promised_delivery_time_mins AS promised_sla_tier,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN (actual_delivery_time_mins - promised_delivery_time_mins) > 20 THEN 1 ELSE 0 END) AS severe_failure_orders,
    ROUND(
        SUM(CASE WHEN (actual_delivery_time_mins - promised_delivery_time_mins) > 20 THEN 1.0 ELSE 0 END) * 100.0 / COUNT(order_id), 
        2
    ) AS severe_failure_rate_pct,
    ROUND(AVG(actual_delivery_time_mins), 1) AS avg_actual_delivery_mins
FROM fact_order_operations
GROUP BY promised_delivery_time_mins
ORDER BY promised_sla_tier ASC;


USE swiggy_analytics;

/* ================================================================================
   BUSINESS QUESTION 6 
   Within each department (Action Owner), how do root-cause categories rank by 
   Revenue at Risk, and what percentage of the company's total Revenue at Risk 
   does each category represent?
   ================================================================================ */
WITH risk_summary AS (
    SELECT 
        r.action_owner,
        r.root_cause_category,
        COUNT(o.order_id) AS impacted_orders,
        ROUND(SUM(o.order_amount_inr), 2) AS revenue_at_risk_inr
    FROM fact_order_operations o
    JOIN fact_swiggy_reviews r ON o.order_id = r.order_id
    WHERE (o.actual_delivery_time_mins - o.promised_delivery_time_mins) > 15
       OR r.sentiment = 'Negative'
    GROUP BY r.action_owner, r.root_cause_category
)
SELECT 
    action_owner,
    root_cause_category,
    impacted_orders,
    revenue_at_risk_inr,
    DENSE_RANK() OVER (
        PARTITION BY action_owner 
        ORDER BY revenue_at_risk_inr DESC
    ) AS dept_risk_rank,
    ROUND(
        revenue_at_risk_inr * 100.0 / SUM(revenue_at_risk_inr) OVER (), 
        2
    ) AS pct_of_total_company_risk
FROM risk_summary
ORDER BY revenue_at_risk_inr DESC;


/* ================================================================================
   BUSINESS QUESTION 7
   Which is the #1 (top) root-cause issue generating the highest negative 
   reviews in each metro city?
   ================================================================================ */
WITH city_issues AS (
    SELECT 
        o.customer_city,
        r.root_cause_category,
        COUNT(r.review_id) AS negative_review_count
    FROM fact_order_operations o
    JOIN fact_swiggy_reviews r ON o.order_id = r.order_id
    WHERE r.sentiment = 'Negative'
    GROUP BY o.customer_city, r.root_cause_category
),
ranked_issues AS (
    SELECT 
        customer_city,
        root_cause_category,
        negative_review_count,
        RANK() OVER (
            PARTITION BY customer_city 
            ORDER BY negative_review_count DESC
        ) AS issue_rank
    FROM city_issues
)
SELECT 
    customer_city,
    root_cause_category AS top_issue,
    negative_review_count
FROM ranked_issues
WHERE issue_rank = 1
ORDER BY negative_review_count DESC;

/* ================================================================================
   BUSINESS VIEW (FOR POWER BI & DOWNSTREAM REPORTING):
   Create a single joined analytical view combining operational delivery variance, 
   SLA breach flags, and AI classification tags.
   ================================================================================ */
CREATE OR REPLACE VIEW vw_swiggy_operational_kpis AS
SELECT 
    o.order_id,
    o.order_date,
    o.customer_city,
    o.order_amount_inr,
    o.promised_delivery_time_mins,
    o.actual_delivery_time_mins,
    (o.actual_delivery_time_mins - o.promised_delivery_time_mins) AS delay_variance_mins,
    CASE 
        WHEN o.actual_delivery_time_mins > o.promised_delivery_time_mins THEN 1 
        ELSE 0 
    END AS is_sla_breached,
    o.refund_issued,
    r.review_id,
    r.customer_rating,
    r.review_text,
    r.sentiment,
    r.root_cause_category,
    r.action_owner
FROM fact_order_operations o
JOIN fact_swiggy_reviews r ON o.order_id = r.order_id;