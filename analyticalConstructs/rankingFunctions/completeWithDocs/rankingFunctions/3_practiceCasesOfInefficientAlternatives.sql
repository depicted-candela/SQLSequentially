-- 3. Practice Cases of Inefficient Alternatives

-- 		1. Find the employee(s) with the highest salary in each department
-- Problem: List the employee(s) with the highest salary in each department. If there are
-- ties, list all. Provide both an inefficient solution (e.g., using a subquery with MAX for each
-- department and joining back) and an efficient solution using ranking functions.

EXPLAIN ANALYZE							-- Verbose and not highly efficient, not only needs to aggregate by
SELECT e1.*, dept_max_salary				-- department and get the highest value. Also needs to compare with the
FROM ranking_functions.employees as e1	-- subquery all the departments relating the remaining departments
JOIN 									-- and then again the compare on each department every rows with the
	(										-- maximum salary aggregated previously
		SELECT department, MAX(salary) dept_max_salary 
		FROM ranking_functions.employees 
		GROUP BY department
	) AS e2
ON e1.department = e2.department
WHERE e1.salary = e2.dept_max_salary; 

EXPLAIN ANALYZE
SELECT * FROM (
	SELECT *, DENSE_RANK() OVER(PARTITION BY department ORDER BY salary) dept_sal
	FROM ranking_functions.employees		-- Create a rank partitioning (aggregations) by department and then order
) AS subquery								-- by salary. Using such ranking added to the other variables as a
WHERE subquery.dept_sal = 1;				-- subquery enables the direct usage of it in a parent query needing
											-- a single comparison one by one to select just department salaries = 1
											-- The partitioning and ordering tools are mathematically enhanced by
											-- postgresql

-- Inefficient: 0.278ms. Efficient: 0.215ms

-- An optimized version for massive data sets uses the following indexes for mathematical optimizations,
-- but since this dataset is small, is not easy to see the difference

-- DROP INDEX IF EXISTS ranking_functions.idx_employees_dept_salary;	-- Indexes for optimizations
-- DROP INDEX IF EXISTS ranking_functions.idx_employees_covering;
-- CREATE INDEX idx_employees_dept_salary 
-- ON ranking_functions.employees (department, salary DESC);
			
-- 		2. Assign sequential numbers to records
-- Problem: Provide a unique sequential number for each product sale, ordered by sale date
-- then by sale id. Provide both an inefficient solution (e.g., using a correlated subquery
-- to count preceding records) and an efficient solution using ranking functions.

SELECT
	*,
	(
		SELECT COUNT(*) + 1													-- X: Highly inefficient (needs too many
		FROM ranking_functions.product_sales AS ps2							-- comparisons), not easily readable (needs too
		WHERE																-- parenthesis controlling logics). The correlated
			(ps2.sale_date > ps1.sale_date) OR								-- subquery adds too much redundant data
			(ps2.sale_date = ps1.sale_date AND ps2.sale_id > ps2.sale_id)
	) manual_rank,
	ROW_NUMBER() OVER(ORDER BY ps1.sale_date DESC, ps1.sale_id DESC)		-- Ok: Highly efficient and simplified because is
FROM ranking_functions.product_sales AS ps1									-- based on orders made without redundant data
ORDER BY manual_rank;

-- 		3. Ranking based on an aggregate
-- Problem: Create a numerical Rank product categories by their total sales amount in descending order.
-- Provide both an inefficient solution (e.g., aggregating in a subquery/CTE, then using
-- another correlated subquery or complex logic for ranking) and an efficient solution using
-- ranking functions on the aggregated results.

WITH ordered_categories AS (				-- CTE: For reusability and avoidance of equal subqueries with a single creation
	SELECT category, SUM(sale_amount) total_sales
	FROM ranking_functions.product_sales
	GROUP BY category
)

SELECT									-- Note how despite the query was simplified using the CTE avoiding the multiple
	*,										-- creation of subqueries, it needs to make a lot of comparisons within
	(										-- the subquery in the select statement to assign ranks
		SELECT
			COUNT(*) + 1 manual_rank
		FROM ordered_categories AS oc1
		WHERE oc1.total_sales > oc2.total_sales
	)
FROM ordered_categories AS oc2
ORDER BY manual_rank;
											-- In this case is used just a subquery (and is not necessary a CTE) as the source
SELECT										-- for the ranking becuase provides the index to rank with ranking function
	category,								-- abstractions and all the optimizations that they're prone to have like indexed
	total_sales,							-- with trees and hash
	DENSE_RANK() OVER(ORDER BY total_sales DESC) auto_rank	-- functions ()
FROM (
	SELECT category, SUM(sale_amount) total_sales
	FROM ranking_functions.product_sales
	GROUP BY category
) AS ordered_categories
ORDER BY auto_rank ASC;
