-- Week 2: window functions on the Superstore dataset
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