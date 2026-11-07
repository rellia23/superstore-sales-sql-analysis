-- 1. Which categories and sub-categories bring in the most sales?

-- 1a. By category
SELECT category,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM superstore_raw), 1) AS pct_of_sales
FROM superstore_raw
GROUP BY category
ORDER BY total_sales DESC;
-- Finding: Technology leads with 36.6% of sales, then Furniture (32.2%)
-- and Office Supplies (31.2%). The three are fairly close.

-- 1b. By sub-category
SELECT sub_category, ROUND(SUM(sales), 2) AS total_sales
FROM superstore_raw
GROUP BY sub_category
ORDER BY total_sales DESC;
-- Finding: Phones ($327,782), Chairs ($322,823) and Storage ($219,343) lead,
-- one from each category. Fasteners is the lowest ($3,002).

-- 2. Which months and years had the highest and lowest sales, and do the same months sell well every year?

-- 2a. Five best months

SELECT DATE_TRUNC('month', order_date_clean)::date AS month,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore_raw
GROUP BY 1
ORDER BY total_sales DESC
LIMIT 5;
-- Finding: November 2017 is the best month ($117,938). 
-- Three of the five best months are in 2018, and none are in 2016, the weakest year. The worst year.

-- 2b. Five worst months

SELECT EXTRACT(MONTH FROM order_date_clean) AS month_number,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore_raw
GROUP BY 1
ORDER BY month_number;
-- Finding : five weakest months through all four years are; February, January, April, July, and June. 
-- The 12 months also add up to $2,261,536.78, so nothing is missing. --
-- By value, the order from lowest is February ($59,371), January ($94,292), April ($136,283), July ($145,536), and June ($145,838).

-- 2c. Total sales by calendar month (all four years combined)
SELECT DATE_TRUNC('month', order_date_clean)::date AS month,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore_raw
GROUP BY 1
ORDER BY total_sales ASC
LIMIT 5;
-- Finding: April 2016 is the worst month ($2,456). 
-- Three of the five worst months are in 2016, and none are in 2018.

-- 2d. Monthly sales by year
SELECT EXTRACT(MONTH FROM order_date_clean) AS month_number,
       ROUND(SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date_clean) = 2015), 0) AS y2015,
       ROUND(SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date_clean) = 2016), 0) AS y2016,
       ROUND(SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date_clean) = 2017), 0) AS y2017,
       ROUND(SUM(sales) FILTER (WHERE EXTRACT(YEAR FROM order_date_clean) = 2018), 0) AS y2018
FROM superstore_raw
GROUP BY month_number
ORDER BY month_number;
-- Finding: September, November and December are the top three months in all
-- four years, so the seasonality is consistent, not a one-year effect.
-- Their share of annual sales fell from about 47% (2015) to about 40% (2018)
-- as other months grew. January and February are the weakest in 2015-2017;
-- January 2018 more than doubled ($43K vs $19K the year before).

-- 2e. Total sales by year
SELECT EXTRACT(YEAR FROM order_date_clean) AS order_year,
       ROUND(SUM(sales), 2) AS total_sales
FROM superstore_raw
GROUP BY order_year
ORDER BY order_year;
-- Finding: Sales dipped about 4% in 2016, then grew about 31% in 2017 and
-- 20% in 2018, reaching $722K. Overall growth 2015 to 2018 is about 50%.

-- 3. Which regions perform best, and which are weakest?
-- 3a. Sales by region
SELECT region, 
    ROUND(SUM(sales),2) AS total_sales,
    ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM superstore_raw), 1) AS pct_of_sales
FROM superstore_raw
GROUP BY region
ORDER BY total_sales DESC;
-- Finding : West(31.4%), East(29.6%), Central(21.8%), and South(17.2%).

-- 3b. Why : orders, customers and order size by region
SELECT region,
       COUNT(DISTINCT order_id) AS orders,
       COUNT(DISTINCT customer_id) AS customers,
       ROUND(1.0 * COUNT(DISTINCT order_id) / COUNT(DISTINCT customer_id), 2) AS orders_per_customer,
       ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS sales_per_order,
       ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS sales_per_customer
FROM superstore_raw
GROUP BY region
ORDER BY orders DESC;
-- Note: customers are counted per region, so the column does not add up to 793.
-- Finding: South has the lowest sales because it has the fewest customers (509)
-- and they order least often (1.6 orders each vs 2.3 in West). Order size is
-- not the issue: South's $480 per order is the second highest.
-- South has the lowest sales because it has fewer custmers and those customers order less often. Order size is not the issue.

-- 4. Who are the top 10 customers, and is their spending driven by one big purchase or by repeat buying?
SELECT c.customer_name,
       COUNT(DISTINCT r.order_id) AS orders,
       ROUND(SUM(r.sales), 2) AS total_sales,
       ROUND(MAX(r.sales), 2) AS largest_line,
       ROUND(100.0 * MAX(r.sales) / SUM(r.sales), 0) AS largest_line_pct
FROM superstore_raw AS r
INNER JOIN customers AS c
  ON r.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_sales DESC
LIMIT 10;
-- Finding: Spending in the top 10 is driven mostly by single large purchases.
-- Each customer's largest line is 58% to 93% of their total. Without it,
-- four of the ten (Sean Miller, Tamara Chand, Raymond Buch, Hunter Lopez)
-- would fall below the average customer ($2,852); all four have 6 or fewer
-- orders. Four others (Adrian Barton, Ken Lonsdale, Sanjit Chand, Sanjit Engle)
-- have 9 to 12 orders, so their totals combine repeat buying with big lines.

-- 5. How many customers buy only once compared with repeatedly, and how much more do repeat customers spend?
-- 5a. Count of one-time vs repeat customers, and their total and average sales
WITH customer_summary AS (
    SELECT customer_id,
           COUNT(DISTINCT order_id) AS orders,
           SUM(sales) AS total_sales
    FROM superstore_raw
    GROUP BY customer_id
)
SELECT CASE WHEN orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
       COUNT(*) AS customers,
       ROUND(SUM(total_sales), 2) AS group_sales,
       ROUND(AVG(total_sales), 2) AS avg_per_customer
FROM customer_summary
GROUP BY customer_type
ORDER BY MIN(orders);
-- Finding: One-time: 13 (1.6%); Repeat: 780 (98.4%), a very loyal base. 
-- With total sales OF $5,181.75 for One-time vs $2,256,355.03 for Repeat, the average One-time customer spends $398.60 and Repeat customers spend $2,892.76, about 7.2 times more.
-- (about 6.3 orders vs 1); order size differs by only about 15%.
-- Note: the one-time group is small, and the data spans four years.

-- 5b. Customer groups by number of orders
WITH customer_summary AS (
    SELECT customer_id,
           COUNT(DISTINCT order_id) AS orders,
           SUM(sales) AS total_sales
    FROM superstore_raw
    GROUP BY customer_id
)
SELECT CASE
         WHEN orders = 1 THEN '1 order'
         WHEN orders BETWEEN 2 AND 6 THEN '2 to 6 orders'
         ELSE '7 or more orders'
       END AS customer_group,
       COUNT(*) AS customers,
       ROUND(SUM(total_sales), 2) AS group_sales,
       ROUND(AVG(total_sales), 2) AS avg_per_customer
FROM customer_summary
GROUP BY customer_group
ORDER BY MIN(orders);
-- Finding: Customers with 7+ orders are 42% of customers but 57% of sales.
-- They spend about 77% more per customer than the 2-to-6 group, mainly
-- because they order more often, not because each order is larger.
-- Note: the data spans four years, so more orders partly reflects more time.

-- Groups split at the median (6 orders); 14+ merged because only 1 customer.
-- 6. Which customers placed no orders in 2018?
SELECT c.customer_id, c.customer_name
FROM customers AS c
LEFT JOIN (
    SELECT DISTINCT customer_id
    FROM superstore_raw
    WHERE EXTRACT(YEAR FROM order_date_clean) = 2018
) AS o
  ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

SELECT COUNT(*) 
FROM customers AS c
LEFT JOIN (
    SELECT DISTINCT customer_id
    FROM superstore_raw
    WHERE EXTRACT(YEAR FROM order_date_clean) = 2018
) AS o
  ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;
-- Finding: 103 of 793 customers (13%) placed no orders in 2018, while 690 (87%) did.
WITH last_orders AS (
    SELECT customer_id, MAX(order_date_clean) AS last_order
    FROM superstore_raw
    GROUP BY customer_id
)
SELECT EXTRACT(YEAR FROM last_order) AS last_order_year,
       COUNT(*) AS customers
FROM last_orders
GROUP BY last_order_year
ORDER BY last_order_year;
-- Finding: 2018 is the most common last order year (690 customers), followed by 2017 (83), 2016 (17), and 2015 (3). The 103 customers who placed no orders in 2018 are mostly from 2017 and earlier.

-- 7. Which sub-category sells the most in each region?
-- Step 1 (region_sub): total sales for every region and sub-category pair.
WITH region_sub AS (
    SELECT r.region, p.sub_category, SUM(r.sales) AS total_sales
    FROM superstore_raw AS r
    INNER JOIN products AS p
      ON r.product_id = p.product_id
     AND r.product_name = p.product_name
    GROUP BY r.region, p.sub_category
),
-- Step 2 (region_max): the biggest total in each region (the number only).
region_max AS (
    SELECT region, MAX(total_sales) AS max_sales
    FROM region_sub
    GROUP BY region
)
-- Final query: join back to step 1 to recover the sub-category name.
SELECT rs.region, rs.sub_category, ROUND(rs.total_sales, 2), AS total_sales
FROM region_sub AS rs
INNER JOIN region_max AS rm
  ON rs.region = rm.region
 AND rs.total_sales = rm.max_sales;
-- INNER JOIN keeps only rows that match on both sides, so here it keeps just the sub-category whose total equals the region’s maximum. (It filters out the other sub-categories in that region.)
-- Finding: Phones lead East and South; Chairs lead Central and West. Phones and
-- Chairs are within 1.5% of each other overall, so no single sub-category
-- clearly dominates. The top two cells (West Chairs $100,023 and East Phones
-- $99,885) are only $139 apart.

-- 8. How much of total sales comes from low-, medium-, and high-value order lines?
-- Tiers: Low < median ($54.49), High = top 5% of lines (>= P95, $959.98)
SELECT CASE
         WHEN sales >= 959.98 THEN 'High'
         WHEN sales >= 54.49  THEN 'Medium'
         ELSE 'Low'
       END AS sales_tier,
       COUNT(*) AS line_count,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM superstore_raw), 1) AS pct_of_sales
FROM superstore_raw
GROUP BY sales_tier
ORDER BY total_sales DESC;
-- Finding: Half of all lines (Low, under $54.49) bring in only 4.5% of sales,
-- while the top 5% of lines (High, $959.98 and above) bring in 44.5%.
-- Revenue depends heavily on a small number of large purchases.