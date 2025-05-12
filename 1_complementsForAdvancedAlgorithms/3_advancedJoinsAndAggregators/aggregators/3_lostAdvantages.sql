		-- 2.3 (iii) Practice entirely cases where people in general does not use these approaches losing their advantages, relations
-- and values because of the easier, basic, common or easily understandable but highly inefficient solutions

-- 		Exercise 2.3.1: (COUNT(DISTINCT column) - Inefficient Alternative)
-- Problem: A data analyst needs to find the number of unique products sold. Instead
-- of using COUNT(DISTINCT product id), they first select all distinct product IDs
-- into a subquery and then count the rows from that subquery. Show this less direct
-- (and potentially less optimized by some older DBs) approach.

SELECT COUNT (*) AS unique_products_sold
FROM (												-- Too much verbosity with increased communication cost from the subquery
	SELECT DISTINCT product_id						-- up to the query
	FROM advanced_joins_aggregators.sales_data
) AS distinct_products;

SELECT COUNT(DISTINCT product_id) AS unique_products_sold FROM advanced_joins_aggregators.sales_data; -- Verbosity reduced
													-- with less communication cost

-- 		Exercise 2.3.2: (FILTER clause - Inefficient Alternative: Multiple Queries or Complex CASE)
-- Problem: An analyst needs to count sales: total sales, sales in ’North Amer-
-- ica’, and sales paid by ’PayPal’. Instead of using FILTER, they write three sep-
-- arate queries or use multiple SUM(CASE WHEN ... THEN 1 ELSE 0 END) expres-
-- sions which can be less readable for simple counts. Show the multiple query ap-
-- proach (conceptually) and the SUM(CASE...) approach, then the FILTER clause
-- solution.

SELECT
    COUNT(*) AS total_sales,
    COUNT(CASE WHEN region = 'North America' THEN 1 END) AS na_sales_count,
    COUNT(CASE WHEN payment_method = 'PayPal' THEN 1 END) AS paypal_sales_count
FROM advanced_joins_aggregators.sales_data;

SELECT			-- CONCISE, CLEAR, READABLE
    COUNT(*) AS total_sales,
    COUNT(*) FILTER(WHERE region = 'North America') AS na_sales_count,
    COUNT(*) FILTER(WHERE payment_method = 'PayPal') AS paypal_sales_count
FROM advanced_joins_aggregators.sales_data;
