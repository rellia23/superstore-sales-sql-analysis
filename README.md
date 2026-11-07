# Superstore Sales Analysis (SQL)

SQL analysis of four years of retail sales, built in PostgreSQL and cross-checked in Excel.

## Business questions

1. Which categories and sub-categories bring in the most sales?
2. Which months and years had the highest and lowest sales, and do the same months sell well every year?
3. Which regions perform best, and which are weakest?
4. Who are the top 10 customers, and is their spending driven by one big purchase or by repeat buying?
5. How many customers buy only once compared with repeatedly, and how much more do repeat customers spend?
6. Which customers placed no orders in 2018?
7. Which sub-category sells the most in each region?
8. How much of total sales comes from low-, medium-, and high-value order lines?

## Dataset

- "Superstore Sales Dataset" by Rohit Sahoo: https://www.kaggle.com/datasets/rohitsahoo/sales-forecasting
- 9,800 order lines from a global retailer, 4 years of complete data (2015 to 2018), 18 columns.
- One row is one product line within an order (about 4,922 orders and 793 customers), so counting rows, orders, and customers gives different answers.
- The raw CSV isn't in this repo because of the dataset's license. Download it from Kaggle.
- Tools used: PostgreSQL and pgAdmin, with Excel to cross-check the totals.

## Data quality notes

## Key findings

## How to run

1. Download the CSV from Kaggle.
2. Create a PostgreSQL database.
3. Run section 1 of `setup.sql` to create the raw table.
4. Import the CSV into `superstore_raw`. Settings I used: Header on, delimiter comma, Quote and Escape both set to `"`, encoding LATIN1 (this garbled a few accented names; UTF8 is the better setting).
5. Run the whole of `setup.sql`. It should end with row counts of 9,800, 793, and 1,893.
6. Run the queries file section by section.