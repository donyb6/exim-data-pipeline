import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

QUERY = """
SELECT
    f.deal_id,
    f.unique_id,
    f.fiscal_year,
    f.decision_date,
    f.effective_date,
    f.expiration_date,
    f.is_brokered,
    f.is_cancelled,
    f.approved_declined_amount,
    f.disbursed_shipped_amount,
    f.outstanding_exposure,
    f.small_business_amount,
    f.woman_owned_amount,
    f.minority_owned_amount,
    c.country_name,
    e.exporter_name,
    l.lender_name,
    p.program_name,
    p.policy_type
FROM fact_deals f
LEFT JOIN dim_country c ON f.country_id = c.country_id
LEFT JOIN dim_exporter e ON f.exporter_id = e.exporter_id
LEFT JOIN dim_lender l ON f.lender_id = l.lender_id
LEFT JOIN dim_program p ON f.program_id = p.program_id;
"""

OUTPUT_PATH = "data/exports/exim_full_deals.csv"


def run():
    user = os.getenv("MYSQL_USER")
    password = os.getenv("MYSQL_PASSWORD")
    host = os.getenv("MYSQL_HOST")
    port = os.getenv("MYSQL_PORT")
    database = os.getenv("MYSQL_DATABASE")

    engine = create_engine(f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}")

    print("Running full deal view query...")
    df = pd.read_sql(QUERY, con=engine)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    df.to_csv(OUTPUT_PATH, index=False)

    print(f"Exported {len(df):,} rows to {OUTPUT_PATH}")


if __name__ == "__main__":
    run()