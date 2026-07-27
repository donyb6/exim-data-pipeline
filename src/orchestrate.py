import logging
import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

import extract
import load_raw

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("logs/pipeline.log"),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

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

    # Split on semicolons to get individual statements
    # Filter out empty strings from trailing semicolons/whitespace
    statements = [s.strip() for s in sql_script.split(";") if s.strip()]

    with engine.connect() as conn:
        for statement in statements:
            conn.execute(text(statement))
        conn.commit()

    logger.info(f"Finished running: {filepath} ({len(statements)} statements)")


def main():
    try:
        extract.run()
        load_raw.run()
        run_sql_file("src/silver_clean.sql")
        run_sql_file("src/gold_schema.sql")
        logger.info("Pipeline completed successfully")
    except Exception as e:
        logger.error(f"Pipeline failed: {e}")
        raise


if __name__ == "__main__":
    main()