SELECT 
    c.country_name,
    COUNT(*) AS deal_count,
    SUM(f.approved_declined_amount) AS total_approved
FROM fact_deals f
LEFT JOIN dim_country c ON f.country_id = c.country_id
GROUP BY c.country_name
ORDER BY total_approved DESC
LIMIT 10;