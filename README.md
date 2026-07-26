# EXIM Data Pipeline

A bronze/silver/gold data pipeline built on the Export-Import Bank of the United States (EXIM) public transactions dataset. This was my first data engineering project, built to practise extract, load, transform, and dimensional modelling using Python and MySQL.

## Overview

The pipeline processes EXIM's authorised transaction records (FY2007 to FY2025 Q4, 52,122 rows) through three layers:

- **Bronze** – raw CSV loaded into MySQL untouched, all columns as text
- **Silver** – cleaned data: real dates, real decimal numbers, real NULLs instead of literal "N/A" strings, and standardised column names
- **Gold** – a star schema (`fact_deals` plus `dim_country`, `dim_exporter`, `dim_lender`, `dim_program`) for analysis-ready querying

## Tech stack

- Python (extraction and orchestration)
- MySQL (storage and transformation)
- pandas, SQLAlchemy, requests, python-dotenv

## Project structure
exim_pipeline/
├── config/
│ └── columns.yaml # source URL and file paths
├── src/
│ ├── extract.py # downloads the raw CSV from EXIM
│ ├── load_raw.py # loads raw CSV into MySQL (bronze)
│ ├── silver_clean.sql # cleans bronze into silver
│ └── gold_schema.sql # builds the star schema (gold)
├── data/
│ └── raw/ # downloaded CSV (not tracked in Git)
├── requirements.txt
└── .env # MySQL credentials (not tracked in Git)

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
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_password_here
MYSQL_DATABASE=exim_pipeline

## Running the pipeline

```bash
python src/extract.py       # download raw CSV
python src/load_raw.py      # load into MySQL (bronze)
```

Then run `src/silver_clean.sql` and `src/gold_schema.sql` against the `exim_pipeline` database (e.g. via MySQL Workbench).

## Data source

[EXIM Bank public dataset](https://img.exim.gov/s3fs-public/dataset/vbhv-d8am/Data.Gov+-+FY25+Q4.csv), covering authorised export financing transactions.