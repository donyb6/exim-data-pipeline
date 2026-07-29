SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS fact_deals;
DROP TABLE IF EXISTS dim_country;
DROP TABLE IF EXISTS dim_exporter;
DROP TABLE IF EXISTS dim_lender;
DROP TABLE IF EXISTS dim_program;

SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE dim_country (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) UNIQUE
);
INSERT INTO dim_country (country_name)
SELECT DISTINCT country
FROM silver_exim_deals
WHERE country IS NOT NULL;

CREATE TABLE dim_exporter(
    exporter_id INT AUTO_INCREMENT PRIMARY KEY,
    exporter_name VARCHAR(255) UNIQUE
);
INSERT INTO dim_exporter (exporter_name)
SELECT DISTINCT primary_exporter
FROM silver_exim_deals
WHERE primary_exporter IS NOT NULL;

CREATE TABLE dim_lender (
    lender_id INT AUTO_INCREMENT PRIMARY KEY,
    lender_name VARCHAR(255),
    normalised_name VARCHAR(255) UNIQUE
);

INSERT INTO dim_lender (lender_name, normalised_name)
SELECT 
    MIN(display_name) AS lender_name,
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(match_key, ' NA$', ' N.A.'),
            ' INC$', ' INC.'
        ),
        ' LLC$', ' LLC.'
    ) AS normalised_name
FROM (
    SELECT 
        primary_lender AS display_name,
        REGEXP_REPLACE(
            UPPER(TRIM(REPLACE(REPLACE(REPLACE(primary_lender, '.', ''), ',', ''), '  ', ' '))),
            ' NATIONAL ASSOCIATION$', ' NA'
        ) AS match_key
    FROM silver_exim_deals
    WHERE primary_lender IS NOT NULL
) t
GROUP BY match_key;

CREATE TABLE dim_program (
    program_id INT AUTO_INCREMENT PRIMARY KEY,
    program_name VARCHAR(100),
    policy_type VARCHAR(100),
    UNIQUE (program_name, policy_type)
);
INSERT INTO dim_program (program_name, policy_type)
SELECT DISTINCT program, policy_type
FROM silver_exim_deals
WHERE program IS NOT NULL;

SELECT * FROM dim_program;

CREATE TABLE fact_deals (
    deal_id INT AUTO_INCREMENT PRIMARY KEY,
    unique_id VARCHAR(50),
    fiscal_year INT,
    country_id INT,
    exporter_id INT,
    lender_id INT,
    program_id INT,
    decision_date DATE,
    effective_date DATE,
    expiration_date DATE,
    is_brokered TINYINT,
    is_cancelled TINYINT,
    approved_declined_amount DECIMAL(18,2),
    disbursed_shipped_amount DECIMAL(18,2),
    outstanding_exposure DECIMAL(18,2),
    small_business_amount DECIMAL(18,2),
    woman_owned_amount DECIMAL(18,2),
    minority_owned_amount DECIMAL(18,2),
    FOREIGN KEY (country_id) REFERENCES dim_country(country_id),
    FOREIGN KEY (exporter_id) REFERENCES dim_exporter(exporter_id),
    FOREIGN KEY (lender_id) REFERENCES dim_lender(lender_id),
    FOREIGN KEY (program_id) REFERENCES dim_program(program_id)
);

SELECT s.unique_id, c.country_id
FROM silver_exim_deals AS s
LEFT JOIN dim_country AS c ON s.country = c.country_name
LIMIT 10;

SELECT
    s.unique_id,
    c.country_id,
    e.exporter_id,
    l.lender_id
FROM silver_exim_deals AS s
LEFT JOIN dim_country AS c ON s.country = c.country_name
LEFT JOIN dim_exporter AS e ON s.primary_exporter = e.exporter_name
LEFT JOIN dim_lender AS l ON s.primary_lender = l.lender_name
LIMIT 10;

SELECT s.unique_id, c.country_id, e.exporter_id, l.lender_id, p.program_id
FROM silver_exim_deals AS s
LEFT JOIN dim_country AS c 
    ON s.country = c.country_name
LEFT JOIN dim_exporter AS e 
    ON s.primary_exporter = e.exporter_name
LEFT JOIN dim_lender AS l 
    ON s.primary_lender = l.lender_name
LEFT JOIN dim_program AS p 
    ON s.program = p.program_name AND s.policy_type <=> p.policy_type
LIMIT 10;

INSERT INTO fact_deals
    (unique_id, fiscal_year, country_id, exporter_id, lender_id, program_id,
     decision_date, effective_date, expiration_date,
     is_brokered, is_cancelled,
     approved_declined_amount, disbursed_shipped_amount, outstanding_exposure,
     small_business_amount, woman_owned_amount, minority_owned_amount)
SELECT
    s.unique_id, s.fiscal_year, c.country_id, e.exporter_id, l.lender_id, p.program_id,
    s.decision_date, s.effective_date, s.expiration_date,
    s.is_brokered, s.is_cancelled,
    s.approved_declined_amount, s.disbursed_shipped_amount, s.outstanding_exposure,
    s.small_business_amount, s.woman_owned_amount, s.minority_owned_amount
FROM silver_exim_deals AS s
LEFT JOIN dim_country AS c ON s.country = c.country_name
LEFT JOIN dim_exporter AS e ON s.primary_exporter = e.exporter_name
LEFT JOIN dim_lender l 
    ON REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    UPPER(TRIM(REPLACE(REPLACE(REPLACE(s.primary_lender, '.', ''), ',', ''), '  ', ' '))),
                    ' NATIONAL ASSOCIATION$', ' NA'
                ),
                ' NA$', ' N.A.'
            ),
            ' INC$', ' INC.'
        ),
        ' LLC$', ' LLC.'
    ) = l.normalised_name
LEFT JOIN dim_program AS p ON s.program = p.program_name AND s.policy_type <=> p.policy_type;
SELECT * FROM fact_deals LIMIT 10;