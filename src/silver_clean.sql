DROP TABLE IF EXISTS silver_exim_deals;

CREATE TABLE silver_exim_deals AS
SELECT * FROM bronze_exim_deals;

SELECT CAST(Fiscal_Year AS UNSIGNED) AS fiscal_year, Unique_Identifier AS unique_id, 
        Deal_Number AS deal_number,Decision AS decision
FROM silver_exim_deals;

-- properly format date columns
SELECT STR_TO_DATE(NULLIF(Decision_Date, 'N/A'), '%m/%d/%Y') AS decision_date,
    STR_TO_DATE(NULLIF(Effective_Date, 'N/A'), '%m/%d/%Y') AS effective_date,
    STR_TO_DATE(NULLIF(Expiration_Date, 'N/A'), '%m/%d/%Y') AS expiration_date
FROM silver_exim_deals;

UPDATE silver_exim_deals
SET
    Fiscal_Year = CAST(Fiscal_Year AS UNSIGNED),
    Decision_Date = STR_TO_DATE(NULLIF(Decision_Date, 'N/A'), '%m/%d/%Y'),
    Effective_Date = STR_TO_DATE(NULLIF(Effective_Date, 'N/A'), '%m/%d/%Y'),
    Expiration_Date = STR_TO_DATE(NULLIF(Expiration_Date, 'N/A'), '%m/%d/%Y');

ALTER TABLE silver_exim_deals
RENAME COLUMN Fiscal_Year TO fiscal_year,
RENAME COLUMN Unique_Identifier TO unique_id,
RENAME COLUMN Deal_Number TO deal_number,
RENAME COLUMN Decision TO decision,
RENAME COLUMN Decision_Date TO decision_date,
RENAME COLUMN Effective_Date TO effective_date,
RENAME COLUMN Expiration_Date TO expiration_date;

ALTER TABLE silver_exim_deals
    MODIFY COLUMN fiscal_year INT UNSIGNED;
    

-- Convert Yes/No text into a real 0/1 flag
SELECT CASE WHEN Brokered = 'Yes' THEN 1 ELSE 0 END AS is_brokered,
CASE WHEN Deal_Cancelled = 'Yes' THEN 1 ELSE 0 END AS is_cancelled
FROM silver_exim_deals;

ALTER TABLE silver_exim_deals
RENAME COLUMN Brokered TO is_brokered,
RENAME COLUMN Deal_Cancelled TO is_cancelled;

UPDATE silver_exim_deals
SET
    is_brokered = CASE
        WHEN is_brokered = 'Yes' THEN 1
        ELSE 0
    END,
    is_cancelled = CASE
        WHEN is_cancelled = 'Yes' THEN 1
        ELSE 0
    END;

ALTER TABLE silver_exim_deals
MODIFY COLUMN is_brokered TINYINT(1),
MODIFY COLUMN is_cancelled TINYINT(1);

-- replace 'N/A' with NULL for string columns
SELECT
    NULLIF(Country, 'N/A') AS country,
    NULLIF(Program, 'N/A') AS program,
    NULLIF(Policy_Type, 'N/A') AS policy_type,
    NULLIF(Decision_Authority, 'N/A') AS decision_authority,
    NULLIF(Primary_Export_Product_NAICS_SIC_code, 'N/A') AS naics_sic_code,
    NULLIF(Product_Description, 'N/A') AS product_description,
    NULLIF(Term, 'N/A')                                        AS term,
    TRIM(NULLIF(Primary_Applicant, 'N/A')) AS primary_applicant,
    TRIM(NULLIF(Primary_Lender, 'N/A')) AS primary_lender,
    TRIM(NULLIF(Primary_Exporter, 'N/A')) AS primary_exporter,
    NULLIF(Primary_Exporter_City, 'N/A')  AS exporter_city,
    NULLIF(Primary_Exporter_State_Code, 'N/A')  AS exporter_state_code,
    NULLIF(Primary_Exporter_State_Name, 'N/A') AS exporter_state_name,
    TRIM(NULLIF(Primary_Borrower, 'N/A')) AS primary_borrower,
    NULLIF(Primary_Source_of_Repayment_PSOR, 'N/A') AS primary_source_repayment
FROM silver_exim_deals;

UPDATE silver_exim_deals
SET
    Country = NULLIF(Country, 'N/A'),
    Program = NULLIF(Program, 'N/A'),
    Policy_Type = NULLIF(Policy_Type, 'N/A'),
    Decision_Authority = NULLIF(Decision_Authority, 'N/A'),
    Primary_Export_Product_NAICS_SIC_code = NULLIF(Primary_Export_Product_NAICS_SIC_code, 'N/A'),
    Product_Description = NULLIF(Product_Description, 'N/A'),
    Term = NULLIF(Term, 'N/A'),
    Primary_Applicant = TRIM(NULLIF(Primary_Applicant, 'N/A')),
    Primary_Lender = TRIM(NULLIF(Primary_Lender, 'N/A')),
    Primary_Exporter = TRIM(NULLIF(Primary_Exporter, 'N/A')),
    Primary_Exporter_City = NULLIF(Primary_Exporter_City, 'N/A'),
    Primary_Exporter_State_Code = NULLIF(Primary_Exporter_State_Code, 'N/A'),
    Primary_Exporter_State_Name = NULLIF(Primary_Exporter_State_Name, 'N/A'),
    Primary_Borrower = TRIM(NULLIF(Primary_Borrower, 'N/A')),
    Primary_Source_of_Repayment_PSOR = NULLIF(Primary_Source_of_Repayment_PSOR, 'N/A');

ALTER TABLE silver_exim_deals
RENAME COLUMN Country TO country,
RENAME COLUMN Program TO program,
RENAME COLUMN Policy_Type TO policy_type,
RENAME COLUMN Decision_Authority TO decision_authority,
RENAME COLUMN Primary_Export_Product_NAICS_SIC_code TO naics_sic_code,
RENAME COLUMN Product_Description TO product_description,
RENAME COLUMN Term TO term,
RENAME COLUMN Primary_Applicant TO primary_applicant,
RENAME COLUMN Primary_Lender TO primary_lender,
RENAME COLUMN Primary_Exporter TO primary_exporter,
RENAME COLUMN Primary_Exporter_City TO exporter_city,
RENAME COLUMN Primary_Exporter_State_Code TO exporter_state_code,
RENAME COLUMN Primary_Exporter_State_Name TO exporter_state_name,
RENAME COLUMN Primary_Borrower TO primary_borrower,
RENAME COLUMN Primary_Source_of_Repayment_PSOR TO primary_source_repayment;


    -- cast numeric columns to DECIMAL(18,2) and replace 'N/A' with NULL
SELECT
    CAST(NULLIF(Approved_Declined_Amount, 'N/A') AS DECIMAL(18,2)) AS approved_declined_amount,
    CAST(NULLIF(Disbursed_Shipped_Amount, 'N/A') AS DECIMAL(18,2)) AS disbursed_shipped_amount,
    CAST(NULLIF(Undisbursed_Exposure_Amount, 'N/A') AS DECIMAL(18,2)) AS undisbursed_exposure,
    CAST(NULLIF(Outstanding_Exposure_Amount, 'N/A') AS DECIMAL(18,2)) AS outstanding_exposure,
    CAST(NULLIF(Small_Business_Authorized_Amount, 'N/A') AS DECIMAL(18,2)) AS small_business_amount,
    CAST(NULLIF(Woman_Owned_Authorized_Amount, 'N/A') AS DECIMAL(18,2)) AS woman_owned_amount,
    CAST(NULLIF(Minority_Owned_Authorized_Amount, 'N/A') AS DECIMAL(18,2)) AS minority_owned_amount
FROM silver_exim_deals;

UPDATE silver_exim_deals
SET
    Approved_Declined_Amount = CAST(NULLIF(Approved_Declined_Amount, 'N/A') AS DECIMAL(18,2)),
    Disbursed_Shipped_Amount = CAST(NULLIF(Disbursed_Shipped_Amount, 'N/A') AS DECIMAL(18,2)),
    Undisbursed_Exposure_Amount = CAST(NULLIF(Undisbursed_Exposure_Amount, 'N/A') AS DECIMAL(18,2)),
    Outstanding_Exposure_Amount = CAST(NULLIF(Outstanding_Exposure_Amount, 'N/A') AS DECIMAL(18,2)),
    Small_Business_Authorized_Amount = CAST(NULLIF(Small_Business_Authorized_Amount, 'N/A') AS DECIMAL(18,2)),
    Woman_Owned_Authorized_Amount = CAST(NULLIF(Woman_Owned_Authorized_Amount, 'N/A') AS DECIMAL(18,2)),
    Minority_Owned_Authorized_Amount = CAST(NULLIF(Minority_Owned_Authorized_Amount, 'N/A') AS DECIMAL(18,2));

ALTER TABLE silver_exim_deals
RENAME COLUMN Approved_Declined_Amount TO approved_declined_amount,
RENAME COLUMN Disbursed_Shipped_Amount TO disbursed_shipped_amount,
RENAME COLUMN Undisbursed_Exposure_Amount TO undisbursed_exposure,
RENAME COLUMN Outstanding_Exposure_Amount TO outstanding_exposure,
RENAME COLUMN Small_Business_Authorized_Amount TO small_business_amount,
RENAME COLUMN Woman_Owned_Authorized_Amount TO woman_owned_amount,
RENAME COLUMN Minority_Owned_Authorized_Amount TO minority_owned_amount,
RENAME COLUMN Loan_Interest_Rate TO loan_interest_rate,
RENAME COLUMN Multiyear_Working_Capital_Extension TO multiyear_working_capital_extension,
RENAME COLUMN Working_Capital_Delegated_Authority TO working_capital_delegated_authority;

ALTER TABLE silver_exim_deals
    MODIFY COLUMN approved_declined_amount DECIMAL(18,2),
    MODIFY COLUMN disbursed_shipped_amount DECIMAL(18,2),
    MODIFY COLUMN undisbursed_exposure DECIMAL(18,2),
    MODIFY COLUMN outstanding_exposure DECIMAL(18,2),
    MODIFY COLUMN small_business_amount DECIMAL(18,2),
    MODIFY COLUMN woman_owned_amount DECIMAL(18,2),
    MODIFY COLUMN minority_owned_amount DECIMAL(18,2);

-- check for duplicates based on all columns
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY working_capital_delegated_authority, woman_owned_amount, unique_id, undisbursed_exposure, term, small_business_amount, program, 
        product_description, primary_source_repayment, primary_lender, primary_exporter, primary_borrower, primary_applicant, policy_type, outstanding_exposure, naics_sic_code, 
        multiyear_working_capital_extension, minority_owned_amount, loan_interest_rate, is_cancelled, is_brokered, fiscal_year, exporter_state_name, exporter_state_code, exporter_city, 
        expiration_date, effective_date, disbursed_shipped_amount, decision_date, decision_authority, decision, deal_number, country, approved_declined_amount
        ORDER BY fiscal_year) AS row_num
    FROM silver_exim_deals
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;