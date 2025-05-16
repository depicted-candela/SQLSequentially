		-- 2 Category: LATERAL Joins


-- 	2.1 (i) Practice meanings, values, relations, unique usage, and advantages

-- 		2.1.1 Exercise 1: Meaning and unique usage of LATERAL - Top N per group
-- Problem: For each department, list the top 2 employees with the highest salary. Use
-- LIMIT 2 within the LATERAL subquery. If there are ties in salary that would extend
-- beyond the top 2 individuals, your query should strictly return only 2 employees per
-- department based on the salary ordering (and any secondary ordering specified). Display
-- ‘departmentName‘, ‘employeeId‘, ‘firstName‘, ‘lastName‘, and ‘salary‘.
SELECT d.departmentId, sq.employeeId, sq.firstName, sq.lastName, sq.salary
FROM complementary_other_query_clauses_lateral_joins.departments AS d, 
LATERAL (
	SELECT employeeId, firstName, lastName, salary
	FROM complementary_other_query_clauses_lateral_joins.employees e
	WHERE e.departmentId = d.departmentId
	ORDER BY salary DESC LIMIT 2
) AS sq;

-- 		2.1.2 Exercise 2: LATERAL with a function-like subquery producing multiple related rows
-- Problem: For each product sale in the ’Electronics’ category made in ’2023-03-01’ or
-- later, calculate its total revenue (‘quantitySold * unitPrice‘). Then, list up to 2 other
-- sales for the same product that occurred earlier than the current sale, ordered by the
-- earlier sale date descending (most recent of the earlier sales first). Display the ‘saleId‘,
-- ‘productName‘, and calculated total revenue of the current ’Electronics’ sale, and the
-- ‘saleId‘, ‘saleDate‘, and ‘quantitySold‘ of the (up to) two prior sales for that product.
SELECT 
	sq.currentSaleId, 
	sq.currentProductName, 
	sq.currentTotalRevenue, 
	sq.previousSaleId, 
	sq.previousSaleDate, 
	sq.previousQuantitySold
FROM (
	SELECT * FROM (
		SELECT saleId currentSaleId, saleDate, productName currentProductName, (quantitySold * unitPrice) currentTotalRevenue
		FROM complementary_other_query_clauses_lateral_joins.productSales
		WHERE category = 'Electronics' AND saleDate >= DATE '2023-03-01'
	) m, LATERAL (
		SELECT saleId previousSaleId, saleDate previousSaleDate, quantitySold previousQuantitySold
		FROM complementary_other_query_clauses_lateral_joins.productSales
		WHERE category = 'Electronics' AND productName = m.currentProductName AND saleDate < m.saleDate
		ORDER BY saleDate LIMIT 2
	) o
) as sq;


-- 	2.2 (ii) Practice disadvantages of all its technical concepts

-- 		2.2.1 Exercise 3: Disadvantage of LATERAL - Potential Performance Impact
-- Problem: For every employee, list their ‘employeeId‘, ‘firstName‘, ‘lastName‘, and then
-- use a LATERAL subquery to find up to 3 other employees in the same department who
-- were hired before them and have a higher salary. Display the ‘firstName‘, ‘lastName‘,
-- ‘hireDate‘, and ‘salary‘ of these senior, higher-paid colleagues. Discuss the potential
-- performance disadvantage of this LATERAL join, especially if the ‘Employees‘ table is very
-- large and not optimally indexed for the subquery’s conditions.
SELECT e.*, o.*
FROM complementary_other_query_clauses_lateral_joins.employees e,
LATERAL (
	SELECT firstName seniorFirstName, lastName seniorLastName, hireDate seniorHireDate, salary seniorSalary
	FROM complementary_other_query_clauses_lateral_joins.employees i
	WHERE i.hireDate < e.hireDate AND i.salary > e.salary	-- This is an example of how a badly designed database
	ORDER BY i.salary DESC LIMIT 3							-- could create bad scenarios of analytics for the TopN
) o;														-- related entities from a subquery.
						-- See 2.1.2 Exercise 2 where a categorical and thus prone to be well indexed is used to filter
-- each entry first with such indexed variable, because names are repeated they're prone to be indexed but worst because
-- their values have higher cardinality, thus the subquery in the lateral join made first with the best variable to be indexed
-- (category) and then with the another one (product name) enables fast queries. Also note that first was applied a filter
-- for just electronics. In this case, both compared variables are not indexed and neither the date nor the salary are good 
-- for indexes because they're continuous and not categorical: time and salary, adding that none filter was made after to the
-- lateral query we have a highly not efficient technique for giant tables

-- 		2.2.2 Exercise 4: Disadvantage - Readability/Complexity for simple cases
-- Problem: Retrieve all employees and their corresponding department names.
-- a) Solve this using a simple INNER JOIN.
-- b) Solve this using a LATERAL join where the subquery fetches the department name
-- for the current employee’s ‘departmentId‘.
-- c) Explain why using LATERAL here is an overkill and a disadvantage in terms of
-- readability and simplicity for this specific task.
SELECT e.*, d.departmentName
FROM complementary_other_query_clauses_lateral_joins.employees e
NATURAL JOIN complementary_other_query_clauses_lateral_joins.departments d;
SELECT e.*, sq.departmentName
FROM complementary_other_query_clauses_lateral_joins.employees e, 
LATERAL (
	SELECT departmentName
	FROM complementary_other_query_clauses_lateral_joins.departments d
	WHERE e.departmentId = d.departmentId
) sq;
-- Despite speed is almost the same with both approaches because departmentId is prone to be 
-- indexed (low cardinality in employees and small in departmens) the second approach is highly
-- more verbose and does not give additional and valuable information fot the query

-- 	2.3 (iii) Practice cases where people use inefficient basic solutions instead

-- 		2.3.1 Exercise 5: Inefficient Top-1 per group without LATERAL
-- Problem: For each distinct ‘region‘ in ‘ProductSales‘, find the single product sale that
-- had the highest total revenue (defined as ‘quantitySold * unitPrice‘). Display the ‘region‘,
-- ‘productName‘, ‘saleDate‘, and this highest total revenue. If multiple sales in a region
-- share the same highest revenue, pick the one with the latest ‘saleDate‘. If there’s still a
-- tie, pick any.
-- a) Describe or attempt to implement a common (potentially inefficient or more com-
-- plex) SQL-based approach to solve this without using LATERAL or window func-
-- tions. Consider methods involving multiple queries with application-level joining of
-- results, or complex correlated subqueries in the SELECT or WHERE clauses.
-- b) Show how to solve this efficiently and clearly using a LATERAL join.
-- c) Discuss why LATERAL (or window functions, though not the focus here) is superior
-- to more basic, fragmented approaches for this ”top-1-per-group” problem.
SELECT
    DISTINCT PS.region,
    (
		SELECT PS_inner.productName 
		FROM complementary_other_query_clauses_lateral_joins.ProductSales PS_inner
		WHERE PS_inner.region = PS.region
		ORDER BY (PS_inner.quantitySold * PS_inner.unitPrice) DESC, PS_inner.saleDate
		DESC LIMIT 1																-- This solution needs double comparison 
	) AS topProductName,															-- to extract filtering from ps.region both:
    (																				-- topProduct and topRevenue, creating two
		SELECT (PS_inner.quantitySold * PS_inner.unitPrice) 						-- subqueries in SELECT
		FROM complementary_other_query_clauses_lateral_joins.ProductSales PS_inner
		WHERE PS_inner.region = PS.region
		ORDER BY (PS_inner.quantitySold * PS_inner.unitPrice) DESC, PS_inner.saleDate
		DESC LIMIT 1
	) AS topRevenue
FROM complementary_other_query_clauses_lateral_joins.ProductSales PS;

SELECT r.region, o.*													-- This aggregates data in directly in from avoiding the double
FROM (																	-- comparison of subqueries in select. Now two subqueries are
	SELECT DISTCINT region												-- joined and data calculated in the second subquery LATERAL
	FROM complementary_other_query_clauses_lateral_joins.productsales	-- at the same time and just selected one time
	GROUP BY region
) r, LATERAL (
	SELECT productName, saleDate, (i.quantitySold * i.unitPrice) totalRevenue
	FROM complementary_other_query_clauses_lateral_joins.productsales i
	WHERE i.region = r.region
	ORDER BY (i.quantitySold * i.unitPrice) DESC, saleDate DESC
	LIMIT 1
) o;


-- 	2.4(iv) Practice a hardcore problem combining previous concepts

-- 		2.4.1 Exercise 6: Hardcore LATERAL with complex correlation, aggregation, and filtering
-- Problem: For each employee who is a manager (i.e., ‘employeeId‘ appears as ‘managerId‘
-- for at least one other employee):
-- 1. Identify the top 2 most recent project assignments from the ‘EmployeeProjects‘
-- table for each employee they directly manage.
-- 2. For these selected project assignments (up to 2 per managed employee), calculate
-- a ”complexityScore” which is ‘hoursWorked * (YEAR(assignmentDate) - 2020)‘.
-- Only consider projects with ‘hoursWorked > 50‘. If ‘YEAR(assignmentDate) - 2020‘
-- is less than 1, use 1 for that part of the calculation to avoid zero or negative scores.
-- 3. Then, for each manager, calculate the sum of these ”complexityScores” from all
-- considered projects of their direct reports.
-- 4. Display the manager’s ‘employeeId‘, ‘firstName‘, ‘lastName‘, and this total ”sum-
-- ComplexityScore”.
-- 5. Only include managers whose total ”sumComplexityScore” is greater than 100.
-- 6. Order the final result by the ”sumComplexityScore” in descending order.
SELECT s1.*, SUM(l1.complexityScore) sumComplexityScore
FROM (
	SELECT DISTINCT e1.employeeId, e1.firstName, e1.lastName
	FROM complementary_other_query_clauses_lateral_joins.employees e1
	WHERE EXISTS(
		SELECT * 
		FROM complementary_other_query_clauses_lateral_joins.employees e2
		WHERE e1.employeeId = e2.managerId
)) s1, LATERAL(
	SELECT projectName, hoursWorked * GREATEST(EXTRACT(YEAR FROM assignmentDate) - 2020, 1) complexityScore
	FROM complementary_other_query_clauses_lateral_joins.employeeProjects ep
	WHERE 
		s1.employeeId = ep.employeeId 
		AND hoursWorked * GREATEST(EXTRACT(YEAR FROM assignmentDate) - 2020, 1) > 50
	ORDER BY ep.assignmentDate DESC LIMIT 2
) l1
GROUP BY s1.employeeId, s1.firstName, s1.lastName
HAVING SUM(l1.complexityScore) > 100
ORDER BY sumComplexityScore DESC;


