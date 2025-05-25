-- 3.2 Exercises for Optimizing Window Functions and Aggregates

-- 		3.2.1 Exercise OWA-1 (Meaning, Values, Advantages of Window Functions
-- - Contextual Aggregation)
-- Problem: For each sale transaction, you want to display its totalAmount alongside the
-- average totalAmount of all transactions made by that same customerId.
-- 1. Write a query using a window function AVG(...) OVER (PARTITION BY ...) to
-- achieve this efficiently. Select a few columns for readability and LIMIT the result.
-- 2. Explain the ”value” or ”advantage” of using a window function here compared to,
-- for example, a LEFT JOIN to a subquery that calculates average sales per customer.
EXPLAIN (ANALYZE)			-- Inefficient
WITH UseredAVGTotalAmount AS (
	SELECT customerId, AVG(totalAmount) avgTotalAmount 
	FROM query_optimizations_and_performance.salesTransactions 
	GROUP BY customerId
)
SELECT transactionId, customerId, totalAmount, transactionDate, l.avgTotalAmount
FROM query_optimizations_and_performance.salesTransactions o
LEFT JOIN UseredAVGTotalAmount l USING(customerId)
ORDER BY customerId;

SELECT 						-- Rich, highly less verbose but a little bit slower
	transactionId, customerId, 
	totalAmount, transactionDate,
	AVG(totalAmount) OVER(PARTITION BY customerId) avgTotalAmount
FROM query_optimizations_and_performance.salesTransactions;
-- The second query gives the data already ordered by user, something that the other query 
-- needs to do after the query and also gives the opportunity to make running averages
-- by ordered dates. Its 1sec slower but improvable with indexes

-- 		3.2.2 Exercise OWA-2 (Disadvantages/Overhead of Window Functions - Cost
-- of Sorting & Large Partitions)
-- Problem: You want to calculate, for every sales transaction, its rank based on totalAmount
-- across *all* transactions in the entire SalesTransactions table (1.5M rows).
-- 1. Write this query using RANK() OVER (ORDER BY totalAmount DESC).
-- 2. Run EXPLAIN ANALYZE. Focus on the ”WindowAgg” node and any preceding ”Sort”
-- node. What is the primary disadvantage highlighted by the cost/time of these
-- operations for such a large, unpartitioned window?
-- 3. If you added PARTITION BY productId to the OVER() clause, how would that con-
-- ceptually change the workload and potentially reduce the ”disadvantage” observed
-- in step 2 (even if total work is similar, how is it broken down)?
EXPLAIN ANALYZE
SELECT transactionId, RANK() OVER(ORDER BY totalAmount DESC) 
FROM query_optimizations_and_performance.salesTransactions;
-- High actual time created by too many rows: 1.5M
SELECT productId, RANK() OVER(PARTITION BY productId ORDER BY totalAmount DESC) 
FROM query_optimizations_and_performance.salesTransactions;
-- With this the query can be improved through composed indexes for productId and totalAmount
-- simultaneously where parallelism is useful because there exists multiple parallel workers
-- ordering each well indexed partition

-- 		3.2.3 Exercise OWA-3 (Inefficient Alternatives vs. Optimized Approach -
-- Using Window Functions for Running Totals)
-- Problem: For each customer, you want to see their monthly sales in 2022 and a running
-- total of their sales month by month throughout 2022.
-- 	1. Inefficient Sketch: Briefly describe how you might achieve the running total
-- *inefficiently* using a correlated subquery for each customer-month, summing up
-- sales from the start of the year up to that month. Why is this approach bad?
-- 	2. Optimized Query: Write an efficient query. First, use a CTE to aggregate sales
-- per customer per month in 2022. Then, in an outer query, use SUM(...) OVER
-- (PARTITION BY ... ORDER BY ...) to calculate the running total.
-- 	3. What indexes on SalesTransactions and Customers would be most beneficial for
-- the aggregation part (the CTE)?
-- Answers: 1. the query that does not use window functions necessarily needs to have
-- too many correlated queries with applied filters for each user using laterals
-- aggregating monthly data, this is highly verbose and time consuming because such
-- solution does not use the internal efficiency of postgresql, instead uses not
-- optimized constructs for repetitive tasks that can be outperform with mathematical
-- properties
-- 	2. 
WITH SalesOf2022 AS (
	SELECT customerId, EXTRACT(MONTH FROM transactionDate) transactionalMonth, SUM(totalAmount) monthlyAmount
	FROM query_optimizations_and_performance.salesTransactions
	WHERE EXTRACT(YEAR FROM transactionDate) = 2020
	GROUP BY customerId, EXTRACT(MONTH FROM transactionDate)
)
SELECT 
	customerName, transactionalMonth, monthlyAmount,
	SUM(monthlyAmount) OVER(PARTITION BY customerId ORDER BY transactionalMonth)
FROM SalesOf2022 NATURAL JOIN query_optimizations_and_performance.customers;
-- 	3. Indexes to be made on SalesTransactions are partially composed with the functional 
-- EXTRACT(MONTH FROM transactionDate) and customerId with totalAmount as the covering
-- value attached to the composed index where EXTRACT(YEAR FROM transactionDate) = 2020
-- is the partial order

-- 		3.2.4 Exercise OWA-4 (Hardcore Problem - Complex Analytics with Optimized Window 
-- Functions and Aggregates)
-- Problem: Management wants a detailed sales report for the year 2022. For each Product
-- Category and Region:
-- 1. Calculate the total sales amount for that category in that region for 2022.
-- 2. Calculate the rank of this category-region combination based on its total sales,
-- compared to all other category-region combinations in 2022.
-- 3. For each category-region, also show its percentage contribution to the total sales of
-- its Region in 2022.
-- 4. For each category-region, show its percentage contribution to the total sales of its
-- Product Category across all regions in 2022.
-- Filter the final result to show only combinations where the category-region total sales
-- amount is greater than $10,000. Order by the overall rank.
-- Previous Concepts Used: CTEs, Joins (multiple), Aggregate Functions (SUM),
-- Window Functions (RANK, SUM OVER for percentages), Date Functions (filtering by
-- year), GROUP BY (multiple columns), Arithmetic for percentages, Filtering (HAVING
-- or WHERE on CTE).

WITH SalesOf2022 AS (
	SELECT category, regionId, SUM(totalAmount) totalAmount
	FROM query_optimizations_and_performance.salesTransactions
	JOIN query_optimizations_and_performance.products USING(productId)
	JOIN query_optimizations_and_performance.customers USING(customerId)
	JOIN query_optimizations_and_performance.regions USING(regionId)
	WHERE EXTRACT(YEAR FROM transactionDate) = 2022
	GROUP BY category, regionId
), RegionalizedSalesOf2022 AS (
	SELECT regionId, SUM(totalAmount) totalAmount
	FROM SalesOf2022
	GROUP BY regionId
), CategorizedSalesOf2022 AS (
	SELECT category, SUM(totalAmount) totalAmount
	FROM SalesOf2022
	GROUP BY category
)

SELECT *, 
	RANK() OVER(PARTITION BY s.category, s.regionId ORDER BY s.totalAmount) regionalizedCategoricalSales,
	(s.totalAmount / r.totalAmount) * 100 regionalizedContribution,
	(s.totalAmount / c.totalAmount) * 100 categoricalContribution
FROM SalesOf2022 s
JOIN RegionalizedSalesOf2022 r USING (regionId)
JOIN CategorizedSalesOf2022 c USING (category)
WHERE s.totalAmount > 1000
ORDER BY regionalizedCategoricalSales;