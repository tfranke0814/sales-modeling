/*
	Normalizes raw_sales_data into a Star Schema. 
	Handles duplicate Product IDs using a surrogate Serial Key.
*/

-- Customers Table
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers AS
SELECT DISTINCT customer_id, customer_name, segment
FROM raw_sales_data;

ALTER TABLE customers ADD PRIMARY KEY (customer_id);
SELECT * FROM customers LIMIT 5;


-- Orders Table
DROP TABLE IF EXISTS orders CASCADE;

CREATE TABLE orders AS
SELECT DISTINCT order_id, order_date, ship_date, ship_mode, customer_id,
	country, city, state, postal_code, region
FROM raw_sales_data;

ALTER TABLE orders ADD PRIMARY KEY (order_id);
SELECT * FROM orders LIMIT 5;


-- Products Table

-- There are distinct products with the same product id
-- so a unique key is created

-- SELECT product_id, COUNT(DISTINCT product_name)
-- FROM raw_sales_data
-- GROUP BY product_id
-- HAVING COUNT(DISTINCT product_name) > 1;

DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products AS
SELECT DISTINCT product_id, product_name, category, sub_category
FROM raw_sales_data;

ALTER TABLE products ADD COLUMN product_key SERIAL;
ALTER TABLE products ADD PRIMARY KEY (product_key);
SELECT * FROM products LIMIT 5;

-- Order Sales Table

-- Duplicate product_id, but product_key distinct
-- relative to product_name

-- SELECT *
-- FROM raw_sales_data AS R
-- JOIN products AS P ON R.product_id = P.product_id
-- 					AND R.product_name = P.product_name
-- WHERE r.product_id LIKE 'TEC-AC-10002550';

DROP TABLE IF EXISTS order_items CASCADE;

CREATE TABLE order_items AS
SELECT R.row_id, R.order_id, P.product_key, R.sales
FROM raw_sales_data AS R
JOIN products AS P ON R.product_id = P.product_id
				  AND R.product_name = P.product_name
ORDER BY row_id ASC;

ALTER TABLE order_items ADD PRIMARY KEY (row_id);
SELECT * FROM order_items;


-- Final Output | Adding Table References
ALTER TABLE order_items ADD CONSTRAINT fk_items_product 
FOREIGN KEY (product_key) REFERENCES products (product_key);

ALTER TABLE order_items ADD CONSTRAINT fk_items_order 
FOREIGN KEY (order_id) REFERENCES orders (order_id);

ALTER TABLE orders ADD CONSTRAINT fk_orders_customer 
FOREIGN KEY (customer_id) REFERENCES customers (customer_id);

SELECT 
	SUM(r.sales) AS raw_sales_sum, 
	SUM(o.sales) AS order_items_sales_sum,
	SUM(r.sales) = SUM(o.sales) AS are_equal
FROM raw_sales_data AS r
JOIN order_items AS o on o.row_id = r.row_id;