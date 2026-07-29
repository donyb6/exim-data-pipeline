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

## Key Findings

**The 2015 EXIM board quorum crisis is directly visible in the data.** Total approved financing peaked at $35.8B in FY2012, then collapsed to just $3.3B by FY2018 — a drop that lines up with the well-documented period when EXIM's board lost quorum and could not approve deals above $10 million for an extended stretch.

**This collapse distorts equity-lending percentages in a way worth flagging.** Small-business, woman-owned, and minority-owned shares of total approved financing all spike sharply during 2016-2018 (small-business share rising from ~17-19% in 2012-2013 to over 60% by 2017-2018), even though the absolute dollar amounts for these categories actually *declined* over the same period. The shared spike across all three unrelated categories, moving in lockstep, points to a denominator effect (total financing shrinking) rather than three independent policy successes.

**Deal size and dollar volume are extremely concentrated.** Boeing alone accounts for $77.7B across 618 deals — more than any other exporter, and roughly 60% larger than the second-place entry ("Multiple - Exporters," a blanket category). A handful of large aircraft/energy/infrastructure exporters (Boeing, Bechtel, Anadarko Petroleum, GE) account for a disproportionate share of total dollars, while hundreds of smaller, frequent exporters (Air Tractor, Concannon Corporation, Eagle Paper International) account for most of the deal *count* but a small fraction of total dollars.

**Program type correlates strongly with both deal size and cancellation risk.** Loan and Guarantee deals average $115.6M and $40.5M respectively, with cancellation rates around 9-10%. Working Capital and Insurance deals average under $5M, with cancellation rates under 1.5%. Larger, longer-term financial commitments appear meaningfully more likely to fall through than small, routine transactions.

**Brokered deals are far more common but far smaller.** 39,993 deals (roughly 77% of all deals) were brokered, averaging $1.76M each. The remaining direct deals average $15.9M — nearly 9x larger — suggesting brokers primarily facilitate high-volume, small-dollar transactions (Working Capital, Insurance) rather than the large one-off Guarantee/Loan deals, which are typically negotiated directly.

**Lender names required real deduplication work.** Automated normalization (stripping punctuation, standardising casing, folding "National Association" to "N.A.") merged dozens of duplicate lender entries that would otherwise have understated real lending totals — for example, JPMorgan Chase Bank's true combined total ($32.5B across 738 deals) was originally split across multiple spelling variants before this fix.

## Known Limitations

- **Lender name deduplication is approximate.** The gold layer normalises lender names (stripping punctuation, standardising casing, folding "National Association" to "N.A.") to merge common spelling variants of the same institution — e.g. "JPMorgan Chase Bank, N.A." and "JPMORGAN CHASE BANK NA" now correctly resolve to one entity. However, some edge cases aren't caught by this rule, such as space-separated abbreviations (e.g. "N A" instead of "NA"), which can still appear as separate entries. Full entity resolution across 18+ years of manually-entered institution names is an open-ended problem; this pipeline handles the common cases rather than attempting exhaustive matching.
- **Full refresh, not incremental.** Every pipeline run drops and rebuilds all tables from the latest source file, rather than only loading new or changed records. This is a deliberate choice given the dataset's size (~50k rows, loads in under a minute) and the fact that EXIM republishes the full historical file each quarter rather than an appendable delta.
- **Exporter and country names are not deduplicated.** Unlike lenders, `dim_exporter` and `dim_country` use exact text matching with no normaliz=sation, so minor spelling variants of the same exporter (if any exist) would appear as separate entities.

## Data source

[EXIM Bank public dataset](https://img.exim.gov/s3fs-public/dataset/vbhv-d8am/Data.Gov+-+FY25+Q4.csv), covering authorised export financing transactions.