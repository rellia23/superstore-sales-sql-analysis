Window functions

What it does: A window function calculates something across a group of related rows, but keeps every row and adds the result as a new column. GROUP BY collapses many rows into one per group, and a window function does not.

Syntax:

sql
function() OVER (PARTITION BY column ORDER BY column DESC)
PARTITION BY splits the rows into groups, like GROUP BY without collapsing. It is optional: leave it out and the whole table is one group.
ORDER BY inside OVER sets the order used for ranking. It is separate from the ORDER BY at the end of the query, which only sorts the output.

Superstore example 1: top 3 lines in each region

sql
WITH ranked AS (
    SELECT region, order_id, ROUND(sales, 2) AS sales,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY sales DESC) AS rn
    FROM superstore_raw
)
SELECT *
FROM ranked
WHERE rn <= 3
ORDER BY region, rn;
-- 12 rows: 3 per region. Largest line: $22,638.48 (South).

Superstore example 2: top 3 sub-categories in each region

sql
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

This replaces Friday's chained CTE with a join back to MAX. It is shorter, and it shows the runners-up too.

ROW_NUMBER vs RANK vs DENSE_RANK (customers ranked by order count):

Customers	Orders	ROW_NUMBER	RANK	DENSE_RANK
1 customer	17	1	1	1
4 customers (tied)	13	2, 3, 4, 5	2, 2, 2, 2	2, 2, 2, 2
18 customers (tied)	12	6, 7, 8...	6, 6, 6...	3, 3, 3...
ROW_NUMBER is always unique, even for ties.
RANK gives ties the same number and skips the numbers after them (2, 2, 2, 2, then 6).
DENSE_RANK gives ties the same number and does not skip (2, 2, 2, 2, then 3).

"Top 3" gives three different answers:

Filter	Customers kept	Why
ROW_NUMBER() <= 3	3	exactly 3 rows
RANK() <= 3	5	ranks 1 and 2 only (1 + 4 customers), because rank 2 is followed by 6
DENSE_RANK() <= 3	23	the three highest order counts: 1 + 4 + 18 customers

Which one to use:

Exactly N rows, one per rank (add a tiebreaker): ROW_NUMBER
Ties share a place and the numbers skip after them: RANK
The top N distinct values, keeping all ties: DENSE_RANK

Watch out:

OVER (...) is required. ROW_NUMBER() alone gives an error.
You can't filter on a window function in the same query level. WHERE rn <= 3 only works outside the CTE, where rn already exists.
ROW_NUMBER on tied values is arbitrary. Add a tiebreaker column inside OVER so the result is the same on every run: ORDER BY orders DESC, customer_id. In my output without a tiebreaker, the row numbers within the 13-order group jumped around (4, 2, 3, 5).
Check the counts. 12 rows for "top 3 in 4 regions", 793 rows for "one row per customer".

Week 2 Day 2: LAG/LEAD functions on the Superstore dataset
LAG(col, n) looks n rows back; LEAD looks n rows ahead.
Without PARTITION BY, the window function works on the rows taht reach the SELECT clause. With it, the window is limited to each partition.
On the first row, LAG returns NULL because there is no previous row.

Week 2 Day 3
A running total is SUM(...) OVER (ORDER BY ...). The frame ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW means "from the first row to the current row".
A 3-month moving average uses ROWS BETWEEN 2 PRECEDING AND CURRENT ROW. Why is it 2, not 3? Because ROWS BETWEEN 2 PRECEDING AND CURRENT ROW means the 2 rows before the current row, plus the current row itself, which makes 3 rows in total.
NTILE(4) splits the rows into 4 groups of equal size, not equal sales.

Week 2 Day 4
Power BI
Power Query is for shaping data before it loads. DAX is for calculations after it loads.
Why set the locale to US? What went wrong in Excel in Week 1?
So that the Power BI can read it as decimal and not just integers. Excel read it not as decimal.
Import mode vs DirectQuery: which one are you using, and why?
I am using Import mode
Findings at Power BI
- the date swap: types looked right, but the values were wrong, and day/month data needs a day/month locale
- how you caught it: order vs ship dates, then min 0 and max 7 on ship_days
- the corrected finding: Sep, Nov and Dec are the top three months every year, the top month varies, and sales fell in 2016 before growing in 2017 and 2018

Week 2 Day 5
-- a distinct count in a Total row is recalculated, not summed, so the regions overlap but the total doesn’t double-count.