-- query to retrieve all deals information
SELECT
	f.deal_id,
    f.unique_id,
    f.decision_date,
    f.effective_date,
    f.expiration_date,
    f.is_brokered,
    f.is_cancelled,
    f.approved_declined_amount,
    f.disbursed_shipped_amount,
    f.outstanding_exposure,
    c.country_name,
    e.exporter_name,
    l.lender_name,
    p.program_name,
    p.policy_type
FROM fact_deals AS f
LEFT JOIN dim_country AS c 
    ON f.country_id = c.country_id
LEFT JOIN dim_exporter AS e 
    ON f.exporter_id = e.exporter_id
LEFT JOIN dim_lender AS l 
    ON f.lender_id = l.lender_id
LEFT JOIN dim_program AS p 
    ON f.program_id = p.program_id;


-- real foreign country exposure
SELECT 
    c.country_name,
    COUNT(*) AS deal_count,
    SUM(f.approved_declined_amount) AS total_approved
FROM fact_deals AS f
LEFT JOIN dim_country AS c 
    ON f.country_id = c.country_id
WHERE c.country_name NOT IN ('Multiple - Countries', 'United States')
GROUP BY c.country_name
ORDER BY total_approved DESC;

-- top exporters by dollar amount
SELECT e.exporter_name, COUNT(*) AS deal_count, SUM(f.approved_declined_amount) AS total_approved
FROM fact_deals AS f
LEFT JOIN dim_exporter AS e 
    ON f.exporter_id = e.exporter_id
GROUP BY e.exporter_name
ORDER BY total_approved DESC
LIMIT 10;

-- top exporters by deal count
SELECT e.exporter_name, COUNT(*) AS deal_count, SUM(f.approved_declined_amount) AS total_approved
FROM dim_exporter AS e
LEFT JOIN fact_deals AS f 
    ON e.exporter_id = f.exporter_id
GROUP BY e.exporter_name
ORDER BY deal_count DESC
LIMIT 10;

-- top lenders by dollar amount
SELECT l.lender_name, COUNT(*) AS deal_count, SUM(f.approved_declined_amount) AS total_approved
FROM dim_lender AS l
LEFT JOIN fact_deals AS f
    ON l.lender_id = f.lender_id
GROUP BY l.lender_name
ORDER BY total_approved DESC
LIMIT 10;
-- from this query, there are duplicated lender names. they have to be merged into a single generalised name. this correction will be made in the gold_schema

-- average deal size and cancellation rate
SELECT 
    p.program_name,
    COUNT(*) AS deal_count,
    AVG(f.approved_declined_amount) AS avg_deal_size,
    SUM(f.is_cancelled) / COUNT(*) * 100 AS cancellation_rate_pct
FROM fact_deals AS f
LEFT JOIN dim_program AS p 
    ON f.program_id = p.program_id
WHERE p.program_name IS NOT NULL
GROUP BY p.program_name
ORDER BY avg_deal_size DESC;

-- approved amount by fiscal year
SELECT 
    fiscal_year,
    COUNT(*) AS deal_count,
    SUM(approved_declined_amount) AS total_approved
FROM fact_deals
GROUP BY fiscal_year
ORDER BY fiscal_year;

-- average deal size by fiscal year
SELECT 
    fiscal_year,
    COUNT(*) AS deal_count,
    AVG(approved_declined_amount) AS avg_deal_size
FROM fact_deals
GROUP BY fiscal_year
ORDER BY fiscal_year;

-- average comparision between brokered and non-brokered deals
SELECT 
    is_brokered,
    COUNT(*) AS deal_count,
    AVG(approved_declined_amount) AS avg_deal_size
FROM fact_deals
GROUP BY is_brokered;

-- year over year growth
SELECT 
    fiscal_year,
    SUM(approved_declined_amount) AS total_approved,
    LAG(SUM(approved_declined_amount)) OVER (ORDER BY fiscal_year) AS prev_year_total,
    ROUND(
        (SUM(approved_declined_amount) - LAG(SUM(approved_declined_amount)) OVER (ORDER BY fiscal_year)) 
        / LAG(SUM(approved_declined_amount)) OVER (ORDER BY fiscal_year) * 100, 
        1
    ) AS yoy_growth_pct
FROM fact_deals
GROUP BY fiscal_year
ORDER BY fiscal_year;

-- outstanding exposure concentration by country
SELECT 
    c.country_name,
    SUM(f.outstanding_exposure) AS total_outstanding_exposure,
    COUNT(*) AS deal_count
FROM fact_deals AS f
LEFT JOIN dim_country c ON f.country_id = c.country_id
GROUP BY c.country_name
ORDER BY total_outstanding_exposure DESC
LIMIT 10;

-- small business / woman-owned / minority-owned share over time
SELECT 
    fiscal_year,
    SUM(small_business_amount) AS total_small_business,
    SUM(woman_owned_amount) AS total_woman_owned,           
    SUM(minority_owned_amount) AS total_minority_owned,
    SUM(approved_declined_amount) AS total_approved,
    ROUND(SUM(small_business_amount) / SUM(approved_declined_amount) * 100, 1) AS small_business_share_pct,
    ROUND(SUM(woman_owned_amount) / SUM
(approved_declined_amount) * 100, 1) AS woman_owned_share_pct,
    ROUND(SUM(minority_owned_amount) / SUM(approved_declined_amount) * 100, 1) AS minority_owned_share_pct
FROM fact_deals
GROUP BY fiscal_year
ORDER BY fiscal_year;