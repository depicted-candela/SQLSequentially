		-- 2.4 (iv) Practice a hardcore problem combining all the technical concepts
		
-- 		Exercise 2.4.1: (Aggregators - Hardcore Problem)
-- Problem: Generate a sales performance report for product categories. The report
-- should include, for each product category:
	-- a. category name: The name of the product category. from products <- category
	-- b. total revenue: Total revenue generated for the category. Revenue for a sale.
	-- item is (quantity sold * unit price at sale * (1 - discount percentage)). 
	-- Format to 2 decimal places.
	-- c. unique customers count: The number of unique customers who purchased
	-- products in this category. (Uses COUNT(DISTINCT)).
	-- d. high perf employee sales count: The number of sales transactions in this
	-- category handled by ’High-Performance’ employees (defined as employees with
	-- performance rating = 5). (Uses FILTER).
	-- e. high value cc sales usa count: The number of sales transactions in this
	-- category that had a total value (quantity sold * unit price at sale) over
	-- $200, were made in the ’North America’ region, AND were paid by ’Credit
	-- Card’. (Uses FILTER).
	-- f. category revenue rank: The rank of the category based on total revenue
	-- in descending order. Use DENSE RANK().
	-- Filtering Criteria for Output:
	-- 		• Only include categories where high perf employee sales count is at least 1.
	-- 		• AND the unique customers count is greater than 2.
	-- Output Order:
	-- 		• Order the final result by category revenue rank (ascending), then by category name.
SELECT *, RANK() OVER(ORDER BY total_revenue DESC) revenue_rank FROM (
	SELECT
		category_id, category_name,
		COUNT(DISTINCT s.customer_id_text) unique_customers,
		COUNT(*) FILTER(WHERE e.performance_rating = 5) high_performance_sales,
		COUNT(*) FILTER(
			WHERE s.quantity_sold * unit_price_at_sale > 200 AND 
			s.region = 'North America' AND 
			s.payment_method = 'Credit Card'
		) high_value_cc_sales_usa,
		ROUND(SUM(quantity_sold * unit_price_at_sale * (1 - discount_percentage)), 2) AS total_revenue
	FROM advanced_joins_aggregators.categories c
	NATURAL JOIN advanced_joins_aggregators.products p
	NATURAL JOIN advanced_joins_aggregators.sales_data s
	NATURAL JOIN advanced_joins_aggregators.employees e
	GROUP BY category_id
) AS sq WHERE high_performance_sales > 0 AND unique_customers > 2
ORDER BY revenue_rank ASC;