/*
	This script analyzes 10 questions from the sales database
*/

-- What is the overall sales revenue from the entire dataset?
SELECT SUM(sales) FROM order_items;

-- What percentage of total sales does each category (Furniture, Office Supplies, Tech) represent?
SELECT 
	p.category, 
	SUM(oi.sales) AS tot_cat_sales,
	SUM(oi.sales) / SUM(SUM(oi.sales)) OVER () AS percent
FROM order_items oi
JOIN products p ON p.product_key = oi.product_key
GROUP BY p.category;

-- Who are the top 10 customers by total sales, and what is their total contribution?
SELECT o.customer_id, c.customer_name, SUM(oi.sales) AS customer_sales
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY o.customer_id, c.customer_name
ORDER BY customer_sales DESC
LIMIT 10;

-- What are the top 5 best selling products?
SELECT p.product_key, p.product_id, p.product_name, 
	SUM(oi.sales) AS product_sales, 
	COUNT(oi.order_id) AS num_units_sold
FROM order_items oi
JOIN products p ON p.product_key = oi.product_key
GROUP BY p.product_key
ORDER BY product_sales DESC, num_units_sold DESC
LIMIT 5;

SELECT p.product_key, p.product_id, p.product_name, 
	SUM(oi.sales) AS product_sales, 
	COUNT(oi.order_id) AS num_units_sold
FROM order_items oi
JOIN products p ON p.product_key = oi.product_key
GROUP BY p.product_key
ORDER BY num_units_sold DESC, product_sales DESC
LIMIT 5;

-- What is the average shipping time by ship mode?
SELECT ship_mode, AVG(ship_date - order_date) AS avg_ship_time
FROM orders
GROUP BY ship_mode;

-- Which orders shipped later than average with respect to the ship mode?
WITH ship_calculations AS (
	SELECT order_id, ship_mode, 
		ship_date - order_date AS ship_time,
		AVG(ship_date - order_date) OVER (PARTITION BY ship_mode) AS avg_ship_time
	FROM orders
)
SELECT * FROM ship_calculations
WHERE ship_time > avg_ship_time;


-- How do sales fluctuate monthly accross different regions?
WITH monthly_summary AS (
	SELECT 
		region,
		EXTRACT(YEAR FROM order_date) AS sales_year,
		EXTRACT(MONTH FROM order_date) AS sales_month, 
		SUM(sales) AS tot_month_sales
	FROM order_items oi
	JOIN orders o ON o.order_id = oi.order_id
	GROUP BY region, sales_year, sales_month
	ORDER BY sales_year, sales_month, region
)
SELECT *, 
	tot_month_sales - LAG(tot_month_sales) OVER (
		PARTITION BY region 
		ORDER BY sales_year, sales_month
	) AS monthly_change_in_sales
FROM monthly_summary
GROUP BY region, sales_year, sales_month,tot_month_sales
ORDER BY sales_year, sales_month, region;

-- What percentage of your customer base has ordered more than once?
WITH customer_counts AS (
	SELECT DISTINCT
		SUM((COUNT(customer_id) > 1)::int) OVER () AS num_customers_returned,
		COUNT(customer_id) OVER () AS tot_num_customers
	FROM orders
	GROUP BY customer_id
)
SELECT *, (num_customers_returned::numeric / tot_num_customers) * 100 AS perecnt_returned
FROM customer_counts;

-- Which customers have shown a consistent increase in spending over time?
WITH customer_spending_history AS (
	SELECT 
		customer_id, order_date, SUM(sales) AS tot_order_sales
	FROM order_items oi
	JOIN orders o ON o.order_id = oi.order_id
	GROUP BY o.customer_id, o.order_date
),
spending_trends AS (
	SELECT 
		customer_id, 
		tot_order_sales - LAG(tot_order_sales) OVER (
			PARTITION BY customer_id ORDER BY order_date
		) AS change_from_last_sale
	FROM customer_spending_history
),
increase_check AS (
	SELECT customer_id, bool_and(change_from_last_sale > 0) AS has_increased_spending
	FROM spending_trends
	GROUP BY customer_id
)
SELECT ic.customer_id, c.customer_name FROM increase_check ic
JOIN customers c ON c.customer_id = ic.customer_id
WHERE has_increased_spending;

-- Within each category, what are the top 3 best-selling products by revenue?
WITH product_revenue AS (
	SELECT product_key, SUM(sales) AS product_sales
	FROM order_items oi
	GROUP BY product_key
),
ranked_products AS (
SELECT 
	pr.product_key, category, sub_category, product_name, product_sales,
	DENSE_RANK () OVER (
		PARTITION BY category, sub_category 
		ORDER BY product_sales DESC
	) AS product_rank
FROM product_revenue pr
JOIN products p ON p.product_key = pr.product_key
)
SELECT * FROM ranked_products
WHERE product_rank <= 3;