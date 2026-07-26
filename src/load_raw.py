import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

# Reads the .env file into environment variables so we can access your MySQL credentials
load_dotenv()

RAW_CSV_PATH = "data/raw/exim_fy25q4.csv"
TABLE_NAME = "bronze_exim_deals"

# Build the connection string from your .env values
user = os.getenv("MYSQL_USER")
password = os.getenv("MYSQL_PASSWORD")
host = os.getenv("MYSQL_HOST")
port = os.getenv("MYSQL_PORT")
database = os.getenv("MYSQL_DATABASE")

engine = create_engine(f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}")

print("Reading raw CSV...")
# dtype=str forces every column to load as plain text.
# This is the core bronze-layer rule: don't interpret or convert anything yet, just capture it as-is.
df = pd.read_csv(RAW_CSV_PATH, dtype=str)

# Clean up the column names to make them easier to work with in SQL
df.columns = [
    c.strip().replace(" ", "_").replace("/", "_").replace("(", "").replace(")", "")
    for c in df.columns
]

print(f"Loaded {len(df):,} rows, {len(df.columns)} columns from CSV")

print(f"Writing to MySQL table '{TABLE_NAME}' ...")
df.to_sql(TABLE_NAME, con=engine, if_exists="replace", index=False, chunksize=5000)

print("Done.")