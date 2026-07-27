import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

RAW_CSV_PATH = "data/raw/exim_fy25q4.csv"
TABLE_NAME = "bronze_exim_deals"


def run():
    user = os.getenv("MYSQL_USER")
    password = os.getenv("MYSQL_PASSWORD")
    host = os.getenv("MYSQL_HOST")
    port = os.getenv("MYSQL_PORT")
    database = os.getenv("MYSQL_DATABASE")

    engine = create_engine(f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}")

    print("Reading raw CSV...")
    # forces everything to be read as string to avoid type issues
    df = pd.read_csv(RAW_CSV_PATH, dtype=str)
    # clean column names
    df.columns = [
        c.strip().replace(" ", "_").replace("/", "_").replace("(", "").replace(")", "")
        for c in df.columns
    ]

    print(f"Loaded {len(df):,} rows, {len(df.columns)} columns from CSV")

    print(f"Writing to MySQL table '{TABLE_NAME}' ...")
    df.to_sql(TABLE_NAME, con=engine, if_exists="replace", index=False, chunksize=5000)

    print("Done.")


if __name__ == "__main__":
    run()