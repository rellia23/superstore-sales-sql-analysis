-- Week 2 Day 1: window functions on the Superstore dataset
-- Run after setup.sql (uses superstore_raw, customers and products)
-- Format: question, query, finding

-- Q1. Which order lines are the largest? (ROW_NUMBER)
SELECT order_id, ROUND(sales, 2) AS sales,
       ROW_NUMBER() OVER (ORDER BY sales DESC) AS rn
FROM superstore_raw
ORDER BY rn
LIMIT 10;
-- Finding: The largest order line is $22,638.48 (CA-2015-145317). The ranking matches the Week 1 top 10.

-- Q2. What are the 3 largest lines in each region? (ROW_NUMBER + PARTITION BY)
WITH ranked AS (
    SELECT region, order_id, ROUND(sales, 2) AS sales,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY sales DESC) AS rn
    FROM superstore_raw
)
SELECT *
FROM ranked
WHERE rn <= 3
ORDER BY region, rn;
-- Finding: The largest line in the dataset ($22,638.48) is in the South, the
-- lowest-selling region, where it is about 5.8% of regional sales (2% or less
-- in West and East). South's total depends more on single large purchases.

-- Q3. How do the three ranking functions treat ties?
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS orders
    FROM superstore_raw
    GROUP BY customer_id
)
SELECT customer_id, orders,
       ROW_NUMBER() OVER (ORDER BY orders DESC) AS row_num,
       RANK()       OVER (ORDER BY orders DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY orders DESC) AS dense_rnk
FROM customer_orders
ORDER BY orders DESC, customer_id
LIMIT 20;
-- Finding: Order counts have many ties (4 customers at 13 orders, 18 at 12).
-- "Top 3" returns 3 customers with ROW_NUMBER, 5 with RANK, and 23 with
-- DENSE_RANK, so the function has to match the question. ROW_NUMBER also
-- needs a tiebreaker, or the result can change between runs.

-- Q4. What are the top 3 sub-categories in each region?
WITH sub_totals AS (
    SELECT region, sub_category, SUM(sales) AS total_sales
    FROM superstore_raw
    GROUP BY region, sub_category
),
ranked AS (
    SELECT region, sub_category, ROUND(total_sales, 2) AS total_sales,
           RANK() OVER (PARTITION BY region ORDER BY total_sales DESC) AS rnk
    FROM sub_totals
)
SELECT *
FROM ranked
WHERE rnk <= 3
ORDER BY region, rnk;
-- Finding: Phones and Chairs are in the top 3 in every region, which is why
-- they lead overall. West is almost a tie (Chairs leads Phones by 2.2%);
-- Central has the clearest winner (Chairs, 12.7% ahead). South is the only
-- region where Machines ranks in the top 3.

-- Q5. Who are the top 3 customers by sales in each segment? (RANK + PARTITION BY)
WITH customer_sales AS (
    SELECT c.customer_name, c.segment, SUM(r.sales) AS total_sales
    FROM superstore_raw AS r
    INNER JOIN customers AS c
      ON r.customer_id = c.customer_id
    GROUP BY c.customer_name, c.segment
),
ranked AS (
    SELECT customer_name, segment, ROUND(total_sales, 2) AS total_sales,
           RANK() OVER (PARTITION BY segment ORDER BY total_sales DESC) AS rnk
    FROM customer_sales
)
SELECT *
FROM ranked
WHERE rnk <= 3
ORDER BY segment, rnk;
-- Finding: Consumer holds most of the largest customers (3 of the 9 shown, and
-- 7 of the overall top 10 by elimination), while Sean Miller leads Home Office
-- and Tamara Chand leads Corporate. The one $22,638 line is in Home Office,
-- which explains why its average is high but its median is the lowest.

-- Q6. When did each customer place their first order? (ROW_NUMBER, PARTITION BY)
WITH first_orders AS (
    SELECT customer_id, order_id, order_date_clean,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY order_date_clean, order_id
           ) AS rn
    FROM superstore_raw
)
SELECT EXTRACT(YEAR FROM order_date_clean) AS first_order_year,
       COUNT(*) AS customers
FROM first_orders
WHERE rn = 1
GROUP BY first_order_year
ORDER BY first_order_year;
-- Finding: 589 of 793 customers (74%) placed their first order in 2015; new
-- customers then fall each year (141, 52, 11). Sales still grew in 2017-2018,
-- and 679 of the 690 customers active in 2018 had ordered before, so growth
-- came from existing customers buying more. Note: the data starts in 2015, so
-- "first order in 2015" may include customers who started earlier.

-- Week 2 Day 2: LAG/LEAD functions on the Superstore dataset
-- LAG(col, n) looks n rows back; LEAD looks n rows ahead.
-- Without PARTITION BY, the window function works on the rows that reach the SELECT clause. With it, the window is limited to each partition.
-- On the first row, LAG returns NULL because there is no previous row.
-- Q1: year-over-year sales (one finding: yearly growth %)
WITH yearly AS (
  SELECT EXTRACT(YEAR FROM order_date_clean) AS yr,
         SUM(sales) AS sales
  FROM superstore_raw
  GROUP BY EXTRACT(YEAR FROM order_date_clean)
),
with_prev AS (
  SELECT yr, sales,
         LAG(sales) OVER (ORDER BY yr) AS prev_sales
  FROM yearly
)
SELECT yr, sales, prev_sales,
       ROUND( ( (sales - prev_sales) / prev_sales * 100 )::numeric, 1 ) AS growth_pct
FROM with_prev
ORDER BY yr;
-- Finding: The 2015 returns NULL for previous sales, as expected. 
-- YoY growth. Checked: 2016 -4.3%, 2017 +30.6%, 2018 +20.3%.

-- Q2: LAG over the same month last year (ties to my seasonality finding)
WITH monthly AS (
  SELECT EXTRACT(YEAR FROM order_date_clean) AS yr,
         EXTRACT(MONTH FROM order_date_clean) AS mth,
         SUM(sales) AS sales
  FROM superstore_raw
  GROUP BY EXTRACT(YEAR FROM order_date_clean), EXTRACT(MONTH FROM order_date_clean)
)
SELECT yr, mth, sales,
       LAG(sales) OVER (PARTITION BY mth ORDER BY yr) AS same_month_last_year
FROM monthly
ORDER BY yr, mth;
-- Finding: The NULL count is 12, all in 2015. Because there is no data before 2015.
-- LAG returns the previous year for each month, so the first year of data has no previous year to compare to. This allows us to see how sales for each month compare to the same month in the previous year, highlighting seasonal trends and growth patterns.
-- Like for September 2016 shows $63,133.61 in sales, and September 2015 shows $81,623.53, so there was a 22.7% decrease in sales for that month.
-- Each partition holds one month across the years, ordered by year. So the previous row is the same month in the previous year, and the default offset of 1 is enough.
WITH monthly AS (
  SELECT EXTRACT(YEAR FROM order_date_clean) AS yr,
         EXTRACT(MONTH FROM order_date_clean) AS mth,
         SUM(sales) AS sales
  FROM superstore_raw
  GROUP BY EXTRACT(YEAR FROM order_date_clean), EXTRACT(MONTH FROM order_date_clean)
),
with_prev AS (
  SELECT yr, mth, sales,
         LAG(sales) OVER (PARTITION BY mth ORDER BY yr) AS same_month_last_year
  FROM monthly
)
SELECT yr, mth, sales, same_month_last_year,
       ROUND( (sales - same_month_last_year)::numeric, 0 ) AS diff_usd,
       ROUND( ( (sales - same_month_last_year)/same_month_last_year * 100 )::numeric, 1 ) AS yoy_pct
FROM with_prev
ORDER BY yr, mth;
-- Finding: The highest percentage growth on February 92.3%, October 92.1%, May 89.1%. 
-- And the months that added the most dollars on 2017 was October +28,571, May +26,697, December +21,196.
-- February’s high yoy_pct comes from a low base, and Feb is the lowest month of the year in 2015,2016 and 2018; in 2017 it is January. The dollar gain (+11,027) is moderate next to Oct (+28,571) or May (+26,697).

-- Q3: Days until a customer's next order (LEAD + PARTITION BY)
WITH orders AS (
  SELECT DISTINCT customer_id, order_id, order_date_clean
  FROM superstore_raw
),
with_next AS (
  SELECT customer_id, order_id, order_date_clean,
         LEAD(order_date_clean) OVER (PARTITION BY customer_id ORDER BY order_date_clean, order_id) AS next_order_date
  FROM orders
)
SELECT customer_id, order_id, order_date_clean, next_order_date,
       next_order_date - order_date_clean AS days_to_next
FROM with_next
ORDER BY customer_id, order_date_clean, order_id;
WITH orders AS (
  SELECT DISTINCT customer_id, order_id, order_date_clean
  FROM superstore_raw
),
with_next AS (
  SELECT customer_id, order_id, order_date_clean,
         LEAD(order_date_clean) OVER (PARTITION BY customer_id ORDER BY order_date_clean, order_id) AS next_order_date
  FROM orders
)
SELECT COUNT(*) AS total_rows,
       COUNT(next_order_date) AS rows_with_next
FROM with_next;
-- Finding: 4,922 orders; 793 have no next order (each customer's last order,
-- one NULL per customer); 4,922 - 793 = 4,129 orders with a gap.
WITH orders AS ( 
  SELECT DISTINCT customer_id, order_id, order_date_clean
  FROM superstore_raw
),
with_next AS (
  SELECT customer_id, order_id, order_date_clean,
         LEAD(order_date_clean) OVER (PARTITION BY customer_id ORDER BY order_date_clean, order_id) AS next_order_date
  FROM orders
),
gaps AS (
  SELECT customer_id, next_order_date - order_date_clean AS days_to_next
  FROM with_next
)
SELECT COUNT(days_to_next) AS n_gaps,
       ROUND(AVG(days_to_next), 1) AS mean_days,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_to_next) AS median_days
FROM gaps;
-- Finding: across 4,129 gaps between consecutive orders, the median gap is 129 days
-- and the mean is 190.8 days. Half of all gaps are 129 days or shorter; a smaller number
-- of very long gaps pulls the mean upward.
-- Checks: 4,922 orders, 793 NULLs (one per customer), 4,129 gaps = 4,922 - 793.
-- Hand-check: AA-10315, 2015-03-31 to 2015-09-15 = 153 + 15 = 168 days, matches days_to_next.
-- Customers with many orders contribute many gaps, so frequent buyers weigh more in these numbers than occasional ones.
-- A gap only exists between two orders. A customer who bought once and never returned has no gap at all, so the data says nothing about how long people stay away.

-- Week 2 Day 3: SUM (...) OVER (ORDER BY ...), ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- Q1: Running total monthly sales 
WITH monthly AS (
  SELECT EXTRACT(YEAR FROM order_date_clean) AS yr,
         EXTRACT(MONTH FROM order_date_clean) AS mth,
         SUM(sales) AS sales
  FROM superstore_raw
  GROUP BY EXTRACT(YEAR FROM order_date_clean), EXTRACT(MONTH FROM order_date_clean)
)
SELECT yr, mth, sales,
       SUM(sales) OVER (ORDER BY yr, mth
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM monthly
ORDER BY yr, mth;
-- Finding:  running total of monthly sales. Checks: 48 rows; Dec 2015 = 479,856.21 (2015 total);
-- last row = 2,261,536.78 (matches Week 1). Finding: first passed $1,000,000 in Mar 2017
-- The running total is the cumulative sum of sales up to and including the current month, allowing us to see how sales have accumulated over time.

-- Q2: Running total that restarts each year (PARTITION BY)
WITH monthly AS (
  SELECT EXTRACT(YEAR FROM order_date_clean) AS yr,
         EXTRACT(MONTH FROM order_date_clean) AS mth,
         SUM(sales) AS sales
  FROM superstore_raw
  GROUP BY EXTRACT(YEAR FROM order_date_clean), EXTRACT(MONTH FROM order_date_clean)
) 
SELECT yr, mth, sales,
       SUM(sales) OVER (PARTITION BY yr ORDER BY mth
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM monthly
ORDER BY yr, mth;
-- Wed Q2: running total restarting each year (PARTITION BY yr).
-- Checks: 48 rows; Dec = each year's total (479,856.21 / 459,436.01 / 600,192.55 / 722,052.02);
-- Jan = Jan's own sales; the four Decembers sum to 2,261,536.78.

-- Q3: 3-month moving average 
WITH monthly AS (
  SELECT EXTRACT(YEAR FROM order_date_clean) AS yr,
         EXTRACT(MONTH FROM order_date_clean) AS mth,
         SUM(sales) AS sales
  FROM superstore_raw
  GROUP BY EXTRACT(YEAR FROM order_date_clean), EXTRACT(MONTH FROM order_date_clean)
)
SELECT yr, mth, sales,
       ROUND(AVG(sales) OVER (ORDER BY yr, mth
                              ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)::numeric, 0) AS ma_3
FROM monthly
ORDER BY yr, mth;
-- Checks: 48 rows; row 3 = 24,644 (hand: 73,931.4 / 3); rows 1-2 average 1 and 2 months.
-- Finding: Sep to Oct 2015 sales fell 61.5% (81,624 to 31,453) but ma_3 fell only 1.6%
-- (47,508 to 46,731). Smoothing shows the peak season but hides which month peaked;
-- the smoothed peak is Nov 2015 (63,662).

-- Q4: What are the Customer quartiles by sales? (NTILE)
WITH cust AS (
  SELECT customer_id, SUM(sales) AS total_sales
  FROM superstore_raw
  GROUP BY customer_id
),
ranked AS (
  SELECT customer_id, total_sales,
         NTILE(4) OVER (ORDER BY total_sales DESC, customer_id) AS quartile
  FROM cust
)
SELECT quartile,
       COUNT(*) AS n_customers,
       ROUND(SUM(total_sales)::numeric, 2) AS quartile_sales,
	                 ROUND( (SUM(total_sales) / COUNT(*))::numeric, 2 ) AS avg_per_customer,
            ROUND( (100 * SUM(total_sales) / SUM(SUM(total_sales)) OVER ())::numeric, 1 ) AS pct_of_sales
FROM ranked
GROUP BY quartile
ORDER BY quartile; 
-- Finding: The top quartile (199 customers) holds 55.5% of sales, then 25.0%, 14.2% and 5.3%;
-- the top half holds 80.5%. Average per customer is about $6,303 in the top quartile and $608
-- in the bottom, roughly 10 times. Sizes are 199/198/198/198 (NTILE gives the extra row to
-- the first group). Check: quartile sales add up to 2,261,536.78.
-- Note: the 44.5% from Week 1 is the top 5% of order lines, a different unit, so the two
-- numbers are not directly comparable.

-- Week 2 Day 5
SELECT region, ROUND(SUM(sales)::numeric, 2) AS sales,
       COUNT(DISTINCT customer_id) AS customers
FROM superstore_raw
GROUP BY region
ORDER BY sales DESC;
-- Finding: West is highest (710,219.68), then East, Central and South (389,151.46).
-- West and East together hold about 61% of sales, and South about 17%.
-- South is lowest in sales and has the fewest customers (509 vs 626-681)