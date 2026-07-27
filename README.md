# EXIM Data Pipeline

A bronze/silver/gold data pipeline built on the Export-Import Bank of the United States (EXIM) public transactions dataset. This was my first data engineering project, built to practise extract, load, transform, dimensional modelling, automated testing, and pipeline orchestration using Python and MySQL.

## Overview

The pipeline processes EXIM's authorised transaction records (FY2007 to FY2025 Q4, 52,122 rows) through three layers:

- **Bronze** – raw CSV loaded into MySQL untouched, all columns as text
- **Silver** – cleaned data: real dates, real decimal numbers, real NULLs instead of literal "N/A" strings, and standardised column names
- **Gold** – a star schema (`fact_deals` plus `dim_country`, `dim_exporter`, `dim_lender`, `dim_program`) for analysis-ready querying

The entire pipeline runs end to end with a single command via `orchestrate.py`, with logging at every stage.

## Tech stack

- Python (extraction, orchestration, testing)
- MySQL (storage and transformation)
- pandas, SQLAlchemy, requests, python-dotenv, pytest, logging

## Project structure

```
exim_pipeline/
├── config/
│   └── columns.yaml       # source URL and file paths
├── src/
│   ├── extract.py          # downloads the raw CSV from EXIM (standalone-runnable, also imported by orchestrate.py)
│   ├── load_raw.py         # loads raw CSV into MySQL (bronze) (standalone-runnable, also imported by orchestrate.py)
│   ├── silver_clean.sql    # cleans bronze into silver
│   ├── gold_schema.sql     # builds the star schema (gold)
│   ├── orchestrate.py      # runs the whole pipeline end to end with logging
│   └── analysis.sql        # analysis queries
├── tests/
│   └── test_data_quality.py  # pytest checks: no negative amounts, sane dates, no orphaned foreign keys, row count consistency
├── data/
│   └── raw/                 # downloaded CSV (not tracked in Git)
├── logs/
│   └── pipeline.log         # orchestrator run history (not tracked in Git)
├── requirements.txt
└── .env                      # MySQL credentials (not tracked in Git)
```

## Setup

1. Clone the repo and create a virtual environment:
```bash
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

2. Create a MySQL database:
```sql
CREATE DATABASE exim_pipeline;
```

3. Create a `.env` file in the project root:
```
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_password_here
MYSQL_DATABASE=exim_pipeline
```

## Running the pipeline

Run the whole thing (extract > bronze > silver > gold) with one command:

```bash
python src/orchestrate.py
```

Progress and errors are logged to both the terminal and `logs/pipeline.log`.

Each stage can also be run individually if needed:

```bash
python src/extract.py       # download raw CSV
python src/load_raw.py      # load into MySQL (bronze)
```

`silver_clean.sql` and `gold_schema.sql` run automatically as part of the orchestrator, or can be executed manually against the `exim_pipeline` database (e.g. via MySQL Workbench).

## Testing

Automated data quality checks live in `tests/test_data_quality.py`, covering:

- No negative transaction amounts
- Dates fall within a sane range
- No orphaned foreign keys between `fact_deals` and its dimension tables
- Row counts match across silver and gold layers

Run with:

```bash
pytest
```

## Data source

[EXIM Bank public dataset](https://img.exim.gov/s3fs-public/dataset/vbhv-d8am/Data.Gov+-+FY25+Q4.csv), covering authorised export financing transactions.