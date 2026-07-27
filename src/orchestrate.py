import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("logs/pipeline.log"),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

logger.info("Orchestrator test run")


import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

user = os.getenv("MYSQL_USER")
password = os.getenv("MYSQL_PASSWORD")
host = os.getenv("MYSQL_HOST")
port = os.getenv("MYSQL_PORT")
database = os.getenv("MYSQL_DATABASE")

engine = create_engine(f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}")


def run_sql_file(filepath):
    logger.info(f"Running SQL file: {filepath}")
    with open(filepath, "r") as f:
        sql_script = f.read()

    # Split on semicolons to get individual statements.
    # Filter out empty strings from trailing semicolons/whitespace.
    statements = [s.strip() for s in sql_script.split(";") if s.strip()]

    with engine.connect() as conn:
        for statement in statements:
            conn.execute(text(statement))
        conn.commit()

    logger.info(f"Finished running: {filepath} ({len(statements)} statements)")
    
import requests
import yaml
from pathlib import Path
import pandas as pd


def extract():
    logger.info("Starting extract stage")
    with open("config/columns.yaml", "r") as f:
        config = yaml.safe_load(f)

    url = config["source_url"]
    save_path = Path(config["raw_file_path"])
    save_path.parent.mkdir(parents=True, exist_ok=True)

    response = requests.get(url)
    response.raise_for_status()

    with open(save_path, "wb") as f:
        f.write(response.content)

    logger.info(f"Extract complete: {len(response.content):,} bytes saved to {save_path}")


def load_bronze():
    logger.info("Starting bronze load stage")
    df = pd.read_csv("data/raw/exim_fy25q4.csv", dtype=str)
    df.columns = [
        c.strip().replace(" ", "_").replace("/", "_").replace("(", "").replace(")", "")
        for c in df.columns
    ]
    df.to_sql("bronze_exim_deals", con=engine, if_exists="replace", index=False, chunksize=5000)
    logger.info(f"Bronze load complete: {len(df):,} rows")


def main():
    try:
        extract()
        load_bronze()
        run_sql_file("src/silver_clean.sql")
        run_sql_file("src/gold_schema.sql")
        logger.info("Pipeline completed successfully")
    except Exception as e:
        logger.error(f"Pipeline failed: {e}")
        raise


if __name__ == "__main__":
    main()