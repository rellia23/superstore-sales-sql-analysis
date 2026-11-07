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

- 11 rows have no postal code, all in Burlington, Vermont. They’re kept because postal code isn’t used in any analysis.
- Product IDs are reused for different products (1,861 IDs but 1,893 ID and name pairs), so the products table uses both columns as its key. Joining on the ID alone inflates 9,800 rows to 10,131.
- The CSV was imported with LATIN1 encoding, which garbled a few accented names (for example “Neil Französisch”). UTF8 is the better setting.
- Each sales value is for one product line, not a whole order, so “largest order” really means “largest line”.
- Excel misread the decimal point in the CSV because of regional settings, inflating totals about 490 times. It was caught by checking against SQL and fixed with a Power Query import.

## Key findings

1. Sales depend on a few large purchases: the top 5% of lines bring in 44.5% of revenue, and the median line is only $54.49.
2. South has the lowest sales because it has the fewest customers (509) and they order least often (1.6 orders each vs 2.3 in West). Order size is not the issue, South's $480 per order is the second highest.
3. Top customers by sales are mostly one-big-purchase buyers. Each of the top customer's largest line is 58% to 93% of their total. Without it, four of the ten would fall below the average customer ($2,852); all four have 6 or fewer orders. Four others have 9 to 12 orders, so their totals combine repeat buying with big lines.
4. Repeat customers (98% of customers) With total sales of $2,256,355.03 for Repeat customers and $5,181.75 for One-time customers, the average One-time customer spends $398.60 and Repeat customers spend $2,892.76 spend about 7 times more, mostly through order frequency.

## How to run

1. Download the CSV from Kaggle.
2. Create a PostgreSQL database.
3. Run section 1 of `setup.sql` to create the raw table.
4. Import the CSV into `superstore_raw`. Settings I used: Header on, delimiter comma, Quote and Escape both set to `"`, encoding LATIN1 (this garbled a few accented names; UTF8 is the better setting).
5. Run the whole of `setup.sql`. It should end with row counts of 9,800, 793, and 1,893.
6. Run the queries file section by section.