import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

user = os.getenv("MYSQL_USER")
password = os.getenv("MYSQL_PASSWORD")
host = os.getenv("MYSQL_HOST")
port = os.getenv("MYSQL_PORT")
database = os.getenv("MYSQL_DATABASE")

engine = create_engine(f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}")


def test_no_negative_amounts():
    df = pd.read_sql("SELECT approved_declined_amount FROM fact_deals", con=engine)
    assert (df["approved_declined_amount"] >= 0).all()
    
def test_dates_within_sane_range():
    df = pd.read_sql("SELECT decision_date FROM fact_deals WHERE decision_date IS NOT NULL", con=engine)
    dates = pd.to_datetime(df["decision_date"])
    assert (dates >= pd.Timestamp("2000-01-01")).all()
    assert (dates <= pd.Timestamp("2026-12-31")).all()


def test_no_orphaned_country_foreign_keys():
    df = pd.read_sql(
        """
        SELECT f.deal_id
        FROM fact_deals AS f
        LEFT JOIN dim_country AS c ON f.country_id = c.country_id
        WHERE f.country_id IS NOT NULL AND c.country_id IS NULL
        """,
        con=engine
    )
    assert len(df) == 0


def test_deal_count_matches_silver():
    fact_count = pd.read_sql("SELECT COUNT(*) AS n FROM fact_deals", con=engine)["n"][0]
    silver_count = pd.read_sql("SELECT COUNT(*) AS n FROM silver_exim_deals", con=engine)["n"][0]
    assert fact_count == silver_count