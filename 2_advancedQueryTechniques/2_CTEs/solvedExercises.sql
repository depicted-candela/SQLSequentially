		-- Common Table Expressions - CTEs

-- 	1 Category (i): Practice Meanings, Values, Relations, and Advantages

-- These exercises focus on understanding the fundamental meanings, values, and relational
-- aspects of Common Table Expressions (CTEs). They demonstrate unique uses and ad-
-- vantages, building upon concepts from Basic and Intermediate SQL.

-- 		1. Exercise 1: Basic CTE for Readability
-- Problem: List all employees in the ’Technology’ department who earn more than
-- $90,000. Show how a CTE can simplify selecting the department first.
-- WITH technologicalEmployees AS (
-- 	SELECT e.* FROM advanced_query_techniques.employeesi e
-- 	NATURAL JOIN advanced_query_techniques.departmentsi di
-- 	WHERE di.departmentName = 'Technology'
-- )
-- SELECT * FROM technologicalEmployees WHERE salary > 90000;

-- 		2. Exercise 2: CTE Referenced Multiple Times
-- Problem: Find all employees whose salary is above the average salary of their
-- respective department. Also, show the department’s average salary. This requires
-- calculating departmental average salary and then using it for comparison.
-- WITH departmentalAverageSalary AS (
-- 	SELECT e.departmentId, AVG(e.salary) departmentalAvgSalary FROM advanced_query_techniques.employees e
-- 	NATURAL JOIN advanced_query_techniques.departmentsi di
-- 	GROUP BY e.departmentId
-- )
-- SELECT e.* FROM advanced_query_techniques.employeesi e
-- NATURAL JOIN departmentalAverageSalary d
-- WHERE e.salary > d.departmentalAvgSalary;

-- 		3. Exercise 3: Nested CTEs
-- Problem: List employees from ’New York’ or ’London’ who were hired after 2019.
-- First, create a CTE for relevant departments. Then, a CTE for employees in those
-- departments hired after 2019.
-- WITH NYLEmployees AS (
-- 	SELECT e.* FROM advanced_query_techniques.employeesi e
-- 	NATURAL JOIN advanced_query_techniques.departmentsi di
-- 	WHERE di.locationcity IN ('New York', 'London')
-- ), NYLEmployeesHiredAfter2019 AS (
-- 	SELECT * FROM NYLEmployees n WHERE EXTRACT(YEAR FROM n.hireDate) > 2019
-- )
-- SELECT * FROM NYLEmployeesHiredAfter2019;

-- 		4. Exercise 4: Recursive CTE for Hierarchical Data
-- Problem: Display the organizational hierarchy for ’Charlie Brown’ (employeeId
-- 103), showing his reporting line up to the top manager. List employee ID, name,
-- manager ID, and level in hierarchy.
-- WITH RECURSIVE SingularReportingLine AS (
-- 	SELECT employeeName, employeeId, managerId, 0 AS level 
-- 	FROM advanced_query_techniques.employeesi
-- 	WHERE employeeName = 'Charlie Brown'
-- 	UNION ALL
-- 	SELECT ei.employeeName, ei.employeeId, ei.managerId, srl.level + 1
-- 	FROM advanced_query_techniques.employeesi ei
-- 	JOIN singularreportingline srl ON ei.employeeid = srl.managerId 
-- )
-- SELECT * FROM SingularReportingLine;


-- 	2 Category (ii): Practice Disadvantages

-- These exercises explore potential disadvantages or limitations associated with CTEs, such
-- as performance considerations and scope.

-- 		1. Exercise 1: Potential Performance Issue (Optimization Fence / Materi-
-- alization)
-- Problem: Calculate the total revenue (price * quantity * (1-discount)) for each
-- product using tables from dataset part II (‘ProductsII‘, ‘SalesTransactionsII‘, ‘Pro-
-- ductCategoriesII‘). Then, retrieve this information ONLY for products in the ’Elec-
-- tronics’ category. A CTE might calculate revenue for ALL products first, then filter.
-- (This exercise highlights a *potential* disadvantage; actual performance depends
-- on the DBMS optimizer).
-- WITH productTotalRevenue AS (
-- 	SELECT st.productId, AVG(p.basePrice * st.quantitySold * (1 - st.discount)) totalRevenue, p.categoryId
-- 	FROM advanced_query_techniques.ProductsII p
-- 	NATURAL JOIN advanced_query_techniques.SalesTransactionsII st		-- This is the more obvious solution
-- 	GROUP BY st.productId, p.categoryId									-- for the given sequential explanation
-- ), electronicProductsTotalRevenue AS (									-- of the problemn, but such sequence
-- 	SELECT p.*, pc.categoryName											-- is not necessarily the best because the
-- 	FROM productTotalRevenue p											-- bigger aggregation (and thus simplifier)
-- 	NATURAL JOIN advanced_query_techniques.ProductCategoriesII pc		-- is the categoryName. Note that all totalRevenues
-- 	WHERE pc.categoryName = 'Electronics'								-- were computed before to be filtered, thus a lot
-- )																	-- of calculations were made with any reason
-- SELECT * FROM electronicProductsTotalRevenue;
-- WITH electronicProducts AS (											-- This order makes the query faster
-- 	SELECT p.*
-- 	FROM advanced_query_techniques.ProductsII p
-- 	NATURAL JOIN advanced_query_techniques.ProductCategoriesII pc
-- 	WHERE pc.categoryName = 'Electronics'
-- ), electronicProductsTotalRevenue AS (
-- 	SELECT st.productId, AVG(p.basePrice * st.quantitySold * (1 - st.discount)) totalRevenue, p.categoryId
-- 	FROM electronicProducts p
-- 	NATURAL JOIN advanced_query_techniques.SalesTransactionsII st
-- 	GROUP BY st.productId, p.categoryId
-- )
-- SELECT productId, totalRevenue FROM electronicProductsTotalRevenue;

-- 		2. Exercise 2: No Indexing on CTE Results
-- Problem: Using tables from dataset part II, identify products that had sales in the
-- month immediately preceding the current month (e.g., if today is Feb 15, 2024,
-- identify sales in Jan 2024). Simulate multiple conceptual uses of this intermediate
-- result: first list the product names, then provide a count of these distinct products.
-- The disadvantage illustrated is that if the CTE result was large and queried multiple
-- times, it’s re-evaluated or its unindexed materialized result is scanned.
-- WITH interval AS (
-- 	SELECT productId
-- 	FROM advanced_query_techniques.SalesTransactionsII
-- 	WHERE DATE_TRUNC('month', saleDate) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
-- )
-- SELECT p.productName										-- In this scenario is used the same
-- FROM advanced_query_techniques.ProductsII p				-- CTE twice but not meaningfully
-- WHERE p.productId IN (SELECT productID FROM interval)	-- mapping and reducing separately
-- 	UNION ALL												-- data in a scenario of too much 
-- SELECT CONCAT('Totals: ', COUNT(DISTINCT i.productId))	-- information in the tables for products
-- FROM interval i;											-- and sales the query could be too
															-- expensive because CTEs are not indexed 
-- despite with 
-- WITH interval AS (
-- 	SELECT DISTINCT productId
-- 	FROM advanced_query_techniques.SalesTransactionsII
-- 	...
-- )
-- could be reduced the number of necessary
-- steps

-- 		3. Exercise 3: CTE Scope Limitation
-- Problem: You need to calculate total sales revenue for the ’Books’ category (using
-- dataset part II tables) and use this total in two *separate subsequent independent
-- queries* (e.g., one to show the total, another to show 10% of this total). Show
-- conceptually or by attempting that a CTE defined in one query is not available in
-- the next, illustrating its scope. Then, demonstrate how you would achieve this by
-- re-declaring the CTE if needed.
-- WITH BooksTotalRevenue AS (
-- 	SELECT SUM(p.basePrice * s.quantitySold * (1 - s.discount)) total
-- 	FROM advanced_query_techniques.ProductCategoriesII c
-- 	NATURAL JOIN advanced_query_techniques.ProductsII p
-- 	NATURAL JOIN advanced_query_techniques.SalesTransactionsII s
-- 	WHERE c.categoryName = 'Books'
-- )

-- SELECT total discount FROM BooksTotalRevenue;				-- These two queries performed
-- SELECT total * 0.1 discount FROM BooksTotalRevenue;			-- not simultaneously in the same 
															-- query will fail because in the
															-- second invoking the CTE wont
															-- exists
-- SELECT total, total * 0.1 discount FROM BooksTotalRevenue;	-- This query is the solution because
															-- uses the same query in the 


-- 	3 Category (iii): Practice Cases Avoiding Inefficient Basic Solutions

-- These exercises demonstrate scenarios where CTEs offer significant advantages in read-
-- ability, maintainability, and sometimes performance over more basic or convoluted ap-
-- proaches that don’t leverage CTEs effectively. Use tables from dataset part III (‘Cus-
-- tomersIII‘, ‘ProductsMasterIII‘, ‘OrdersIII‘, ‘OrderItemsIII‘).

-- 		1. Exercise 1: Replacing Repeated Subqueries
-- Problem: Find customers who placed orders in both 2022 and 2023. List their names
-- and city. Illustrate how CTEs can avoid repeating subquery logic that might scan
-- ‘OrdersIII‘ multiple times.
-- WITH OrdersIn2022 AS (
-- 	SELECT * 
-- 	FROM advanced_query_techniques.OrdersIII
-- 	WHERE DATE_PART('year', orderDate) = 2022
-- ), OrdersIn2023 AS (
-- 	SELECT * 
-- 	FROM advanced_query_techniques.OrdersIII
-- 	WHERE DATE_PART('year', orderDate) = 2023
-- )
-- SELECT * FROM advanced_query_techniques.CustomersIII c							-- Without the CTEs must be necessary
-- WHERE EXISTS(SELECT 1 FROM OrdersIn2022 o WHERE c.customerId = o.customerId)	-- two subqueries within this creating
-- AND EXISTS(SELECT 1 FROM OrdersIn2023 o WHERE c.customerId = o.customerId)	-- a highly unreadable query

-- 		2. Exercise 2: Simplifying Complex Joins and Filters
-- Problem: List products (name and category) that were part of orders shipped to
-- ’North America’ and had a total order value (sum of quantity * pricePerUnit for
-- all items in that order) greater than $600. Show how CTEs can break down this
-- logic compared to a single, very long query.
-- WITH USAOrders AS (															-- Note how this CTE is useful to break from
-- 	SELECT *																	-- the beginning the number of necessary mappings
-- 	FROM advanced_query_techniques.OrdersIII									-- in joins by filtering first by shipment region.
-- 	WHERE shipmentRegion = 'North America'										-- Such breaking not only makes more readable the query
-- ), TotalOrderValue AS (														-- but more performant
-- SELECT 
-- 	u.shipmentRegion, 
-- 	p.productName, |
-- 	(o.quantity * o.pricePerUnit) totalOrderValue
-- FROM USAOrders u
-- NATURAL JOIN advanced_query_techniques.OrderItemsIII o
-- NATURAL JOIN advanced_query_techniques.ProductsMasterIII p
-- )
-- SELECT * FROM TotalOrderValue;

-- 		3. Exercise 3: Avoiding Temporary Tables for Single-Query Scope
-- Problem: Calculate the average total order value for each ‘shipmentRegion‘. Then,
-- list regions whose average order value is greater than the overall average order
-- value across all regions. Demonstrate how CTEs provide a cleaner, single-statement
-- solution compared to potentially using temporary tables.
-- WITH RegionizedValue AS (
-- 	SELECT o.shipmentRegion region, AVG(oi.pricePerUnit * oi.quantity) reg_value
-- 	FROM advanced_query_techniques.OrderItemsIII oi
-- 	NATURAL JOIN advanced_query_techniques.OrdersIII o
-- 	GROUP BY o.shipmentRegion
-- )
-- SELECT * 
-- FROM RegionizedValue 
-- WHERE reg_value > (SELECT AVG(reg_value) FROM RegionizedValue);
	
-- 		4. Exercise 4: Step-by-Step Multi-Level Aggregations (Revised)
-- Problem: For each product category, find the month (e.g., ’2023-04’) with the
-- highest total sales quantity for that category. Display category, the best month,
-- and total quantity for that month. Solve this using CTEs for structured aggregation,
-- without using window functions.
-- WITH categoricalMaximumTotalSales AS (
-- 	SELECT p.category, o.orderDate, MAX(oi.quantity) maxQuantity
-- 	FROM advanced_query_techniques.productsMasterIII p
-- 	NATURAL JOIN advanced_query_techniques.ordersIII o
-- 	NATURAL JOIN advanced_query_techniques.orderItemsIII oi
-- 	GROUP BY p.category, o.orderDate
-- )
-- SELECT DISTINCT c1.category, l.*
-- FROM categoricalMaximumTotalSales c1,
-- LATERAL(
-- 	SELECT c2.*
-- 	FROM categoricalMaximumTotalSales c2
-- 	WHERE c1.category = c2.category
-- 	ORDER BY c2.maxQuantity DESC LIMIT 1
-- ) l;


-- 	4 Category (iv): Hardcore Combined Problem

-- This problem requires combining various SQL concepts learned prior to and including
-- Common Table Expressions, focusing on their application in a complex scenario. Use
-- tables from dataset part IV (‘DepartmentsIV‘, ‘EmployeesIV‘, ‘ProjectsIV‘, ‘TasksIV‘,
-- ‘TimeLogsIV‘). Window functions (like ‘RANK()‘, ‘ROW NUMBER() OVER()‘) should
-- NOT be used as they are covered later in the course sequence.

-- 		1. Hardcore Problem
-- Problem: Identify the top 2 departments by the total salary of their ’Senior’ em-
-- ployees. A ’Senior’ employee is defined as someone with a salary > $70,000 AND
-- hired on or after ’2020-01-01’ AND has logged time (in ‘TimeLogsIV‘) on at least
-- one task belonging to a ’Critical’ project. A ’Critical’ project is any project from
-- ‘ProjectsIV‘ with a budget > $150,000.
-- For these top 2 departments, display:
-- a. Department Name.
-- b. Total salary of these qualified ’Senior’ employees in that department.
-- c. The count of such ’Senior’ employees in the department.
-- d. Using a LATERAL join, for each of these top 2 departments, find the em-
-- ployee (can be any employee in that department, not necessarily senior) who
-- has logged time against the highest number of distinct projects (based on
-- ‘TimeLogsIV‘ and ‘TasksIV‘). If there’s a tie in distinct project count, pick
-- the one with the lower ‘employeeId‘. Show this employee’s name and their
-- distinct project count.
-- Additionally, for the single department (from the top 2 identified above) that has
-- the absolute highest total senior salary:

-- WITH -- for the first part
WITH RECURSIVE -- for the second part
taskedTimeLogs AS (
	SELECT tl.logId, t.taskId, t.assignedToEmployeeId employeeId, t.projectId
	FROM advanced_query_techniques.timeLogsIV tl
	NATURAL JOIN advanced_query_techniques.tasksIV t
), 
projectsByEmployeeWithDepartments AS (
	SELECT m.*, e.departmentId, e.employeeName FROM (
		SELECT employeeId, COUNT(DISTINCT projectId) projects, ARRAY_AGG(DISTINCT projectId) projectsId
		FROM taskedTimeLogs
		GROUP BY employeeId
	) m NATURAL JOIN advanced_query_techniques.employeesIV e
), 
taskedTimeLogsOfCriticalProjects AS (
	SELECT t.taskId, t.employeeId, p.projectId
	FROM taskedTimeLogs t
	JOIN advanced_query_techniques.projectsIV p 
		ON p.budget > 150000 AND t.projectId = p.projectId
), 
departmentalTaskedLogsOfCriticalProjects AS (
	SELECT pbewd.departmentId, ttlocp.projectId, ARRAY_AGG(ttlocp.employeeId) employeesId
	FROM projectsByEmployeeWithDepartments pbewd 
	JOIN (
		SELECT employeeId, projectId, COUNT(DISTINCT taskid) tasksId
		FROM taskedTimeLogsOfCriticalProjects
		GROUP BY employeeId, projectId
	) ttlocp ON ttlocp.employeeId = pbewd.employeeId AND ttlocp.projectId = ANY(pbewd.projectsId)
	GROUP BY pbewd.departmentId, ttlocp.projectId
),
topEmployeesByDepartments AS (
	SELECT dtlocp.departmentId, l1.employeeId, l1.salary, l1.employeeName, l2.employees, l2.totalSalary
	FROM departmentalTaskedLogsOfCriticalProjects dtlocp, LATERAL (
		SELECT ieIV.employeeId, ieIV.salary, ieIV.employeeName
		FROM advanced_query_techniques.employeesIV ieIV 
		WHERE ieIV.employeeId = ANY(dtlocp.employeesId) 
		AND dtlocp.departmentId = ieIV.departmentid
		AND ieIV.salary > 70000 AND ieIV.hireDate >= TO_DATE('2020-01-01', 'YYYY-MM-DD')
		ORDER BY ieIV.salary DESC FETCH NEXT 1 ROWS ONLY 
	) AS l1, LATERAL (
		SELECT COUNT(ieIV.employeeId) employees, SUM(ieIV.salary) totalSalary
		FROM advanced_query_techniques.employeesIV ieIV 
		WHERE ieIV.employeeId = ANY(dtlocp.employeesId) 
		AND dtlocp.departmentId = ieIV.departmentid
		AND ieIV.salary > 70000 AND ieIV.hireDate >= TO_DATE('2020-01-01', 'YYYY-MM-DD')
	) AS l2 ORDER BY l1.salary DESC FETCH NEXT 2 ROWS ONLY
), filteredDepartmentalProjectedTopEmployees AS (
	SELECT m.departmentId, m.departmentName, m.employees, m.totalSalary, l1.employeeId, l1.employeeName, l1.projects FROM (	-- First part 
		SELECT 
			m.*, 
			(
				SELECT s1.departmentName FROM advanced_query_techniques.departmentsIV s1 WHERE s1.departmentId = m.departmentId
			)
		FROM topEmployeesByDepartments m
	) m, LATERAL(
		SELECT * 
		FROM projectsByEmployeeWithDepartments pbewd
		WHERE pbewd.departmentId = m.departmentId
		ORDER BY pbewd.projects DESC, employeeId ASC FETCH NEXT 1 ROWS ONLY
	) l1
	ORDER BY m.totalSalary DESC
)

-- SELECT * FROM filteredDepartmentalProjectedTopEmployees;

-- e. Display the organizational hierarchy for its department head (employee speci-
-- fied in ‘DepartmentsIV.headEmployeeId‘), showing the reporting line upwards
-- to the CEO (employee with ‘managerId IS NULL‘). List employee ID, name,
-- manager ID, and level in hierarchy (0 for the department head, increasing for
-- their managers).

, projectManagerHierarchy AS ( 		-- Second part for the hierarchy 
	SELECT eIV.employeeId, eIV.departmentId, eIV.employeeName, eIV.managerId, 0 AS level
	FROM advanced_query_techniques.employeesIV eIV 
	JOIN advanced_query_techniques.departmentsIV dIV ON dIV.headEmployeeId = eIV.employeeId
	AND EXISTS(
		SELECT * FROM (
			SELECT * 
			FROM filteredDepartmentalProjectedTopEmployees
			ORDER BY salary
			LIMIT 1
		) as sq WHERE sq.departmentId = div.departmentId
	)
		UNION ALL
	SELECT eIV.employeeId, eIV.departmentId, eIV.employeeName, eIV.managerId, pmh.level + 1
	FROM projectManagerHierarchy pmh
	JOIN advanced_query_techniques.employeesIV eIV
	ON pmh.managerId = eIV.employeeId 
)

SELECT * FROM projectManagerHierarchy;

-- Constraints:
-- • Departments must have at least 2 qualified ’Senior’ employees to be considered
-- for the top 2.
-- • Use ‘FETCH FIRST ... ROWS ONLY‘ to get the top 2 departments based on
-- total senior salary (descending).
-- • The final list of top 2 departments should be ordered by their total senior
-- salary in descending order.
-- • The hierarchy should be for the head of the #1 department from this list.
-- • All parts of the problem should be solved within a single SQL statement where
-- possible (the hierarchy query might be separate if needed for clarity, but aim to
-- use CTEs effectively if combining). Ideally, two main ‘SELECT‘ statements:
-- one for the top 2 departments’ details, and one for the hierarchy of the #1
-- department’s head.