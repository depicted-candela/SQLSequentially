		-- 3. Advanced Joins And Aggregators: Aggregators

-- 	2.1(i) Practice meanings, values, relations, advantages of all its technical concepts
		
-- 		Exercise 2.1.1: (COUNT(DISTINCT column) - Meaning & Advantage)
-- Problem: The sales department wants to know how many unique customers have
-- made purchases from the sales data table.
SELECT COUNT(DISTINCT customer_id_text) distinct_customers FROM advanced_joins_aggregators.sales_data;

-- 		Exercise 2.1.2: (FILTER clause - Meaning & Advantage)
-- Problem: Calculate the total number of sales transactions and, in the same query,
-- the number of sales transactions specifically made in the ’Europe’ region. Use the
-- FILTER clause for the conditional count.
SELECT COUNT(*) total, COUNT(*) FILTER (WHERE region = 'Europe') european 
FROM advanced_joins_aggregators.sales_data;