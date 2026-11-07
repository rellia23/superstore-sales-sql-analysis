-- setup.sql: builds all tables from the raw Superstore CSV
-- Source: Kaggle "Superstore Sales Dataset" (add link). Raw CSV not included.

-- 1. Raw table (import train.csv in pgAdmin: Header on, Delimiter ",", Quote and Escape both ")
CREATE TABLE IF NOT EXISTS superstore_raw ( 
    row_id        INT,
    order_id      VARCHAR(20),
    order_date    TEXT,
    ship_date     TEXT,
    ship_mode     VARCHAR(30),
    customer_id   VARCHAR(20),
    customer_name VARCHAR(100),
    segment       VARCHAR(30),
    country       VARCHAR(50),
    city          VARCHAR(100),
    state         VARCHAR(100),
    postal_code   VARCHAR(10),
    region        VARCHAR(20),
    product_id    VARCHAR(30),
    category      VARCHAR(50),
    sub_category  VARCHAR(50),
    product_name  TEXT,
    sales         NUMERIC(12,4)
    
 );

-- 2. Clean date columns (source dates are DD/MM/YYYY text)
ALTER TABLE superstore_raw ADD COLUMN IF NOT EXISTS order_date_clean DATE;
ALTER TABLE superstore_raw ADD COLUMN IF NOT EXISTS ship_date_clean DATE;
UPDATE superstore_raw
SET order_date_clean = TO_DATE(order_date, 'DD/MM/YYYY'),
    ship_date_clean  = TO_DATE(ship_date,  'DD/MM/YYYY');

-- 3. customers (customer_id is a clean key: one name and one segment per ID)
DROP TABLE IF EXISTS customers;
CREATE TABLE customers AS 
SELECT DISTINCT customer_id, customer_name, segment
FROM superstore_raw;
ALTER TABLE customers ADD PRIMARY KEY (customer_id);

-- 4. products (product_id is reused for different products, so the key is ID + name)
DROP TABLE IF EXISTS products;
CREATE TABLE products AS 
SELECT DISTINCT product_id, product_name, category, sub_category
FROM superstore_raw;;
ALTER TABLE products ADD PRIMARY KEY (product_id, product_name);

-- Expected counts: superstore_raw 9,800 | customers 793 | products 1,893

-- Verify row counts (expected: 9800 / 793 / 1893)
SELECT 'superstore_raw' AS table_name, COUNT(*) AS row_count FROM superstore_raw
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products;