		-- 1.2 Exercises for Indexing Strategies

-- 		1.2.1 Exercise IS-1 (Meaning, Values, Advantages of B-tree Indexes)
-- Problem: The HR department frequently searches for employees by their exact jobTitle.
-- Currently, this search is slow.
-- 1. Write a query to find all employees with jobTitle = ’Data Analyst’.
-- 2. Use EXPLAIN ANALYZE to observe its performance and note the scan type on Employees.
-- 3. Create an appropriate B-tree index on the jobTitle column.
-- 4. Re-run EXPLAIN ANALYZE on the same query. Describe the change in the execution
-- plan (e.g., scan type) and explain why the B-tree index provides an advantage here.
	EXPLAIN ANALYZE													-- without optimizations
	SELECT * 
	FROM query_optimizations_and_performance.employees 
	WHERE jobtitle = 'Data Analyst';
	-- QUERY PLAN
	-- "Seq Scan on employees  (cost=0.00..862.00 rows=5000 width=92) (actual time=0.034..14.065 rows=5000 loops=1)"
	-- "  Filter: ((jobtitle)::text = 'Data Analyst'::text)"
	-- "  Rows Removed by Filter: 25000"
	-- "Planning Time: 0.223 ms"
	-- "Execution Time: 14.739 ms"
	CREATE INDEX idxEmployeeLastJobTitle 							-- optimized
	ON query_optimizations_and_performance.employees (jobtitle);
	EXPLAIN ANALYZE
	SELECT * 
	FROM query_optimizations_and_performance.employees 
	WHERE jobtitle = 'Data Analyst';
	-- 	QUERY PLAN
	-- "Bitmap Heap Scan on employees  (cost=59.04..608.54 rows=5000 width=92) (actual time=0.434..1.967 rows=5000 loops=1)"
	-- "  Recheck Cond: ((jobtitle)::text = 'Data Analyst'::text)"
	-- "  Heap Blocks: exact=487"
	-- "  ->  Bitmap Index Scan on idxemployeelastjobtitle  (cost=0.00..57.79 rows=5000 width=0) (actual time=0.328..0.328 rows=5000 loops=1)"
	-- "        Index Cond: ((jobtitle)::text = 'Data Analyst'::text)"
	-- "Planning Time: 0.189 ms"
	-- "Execution Time: 2.318 ms"
	
	-- CREATE INDEX idxEmployeeLastJobTitleDataAnalyst  				-- optimized specifically for 'Data Analyst' as jobtitle
	-- ON query_optimizations_and_performance.employees (jobtitle) 
	-- WHERE jobtitle = 'Data Analyst';
	EXPLAIN ANALYZE
	SELECT * 
	FROM query_optimizations_and_performance.employees 
	WHERE jobtitle = 'Data Analyst';
	-- 	QUERY PLAN 
	-- "Bitmap Heap Scan on employees  (cost=54.53..604.03 rows=5000 width=92) (actual time=0.379..1.505 rows=5000 loops=1)"
	-- "  Recheck Cond: ((jobtitle)::text = 'Data Analyst'::text)"
	-- "  Heap Blocks: exact=487"
	-- "  ->  Bitmap Index Scan on idxemployeelastjobtitledataanalyst  (cost=0.00..53.28 rows=5000 width=0) (actual time=0.277..0.278 rows=5000 loops=1)"
	-- "Planning Time: 0.116 ms"
	-- "Execution Time: 1.717 ms"

-- 		1.2.2 Exercise IS-2 (Disadvantages of Indexes / When B-tree Indexes are Not Optimal)
-- Problem:
-- 1. Write Overhead: You are adding 5,000 new employee records. If the Employees
-- table has 10 indexes versus just 2 indexes, describe qualitatively how the INSERT
-- performance would differ and why. What is the disadvantage being illustrated?
	-- Answer: indexes must be calculated always when new elements are agggregated in a 
	-- single buch, if 5000 new employees are aggregated and 10 indexes exists in the table
	-- then 10 indexes must be computed not only for the new 5000 employees but also for
	-- the existing rows after the updating, thus is always preferrable to be careful with
	-- the indexes to avoid overheading re calculating unnecessary (dependent) indexes in
	-- the same table where the independent scenario is with only 2 indexes. Imagine a database
	-- where new rows are added every second
-- 2. Very Low Selectivity / Small Table: The Departments table is small (10
-- rows). You want to find departments in ’Building A, Floor 1’. Create an index
-- on location. Query for it and use EXPLAIN ANALYZE. Does the optimizer use the
-- index? Why might it choose a Seq Scan even if an index exists on a very small
-- table or for a very common value?
	EXPLAIN ANALYZE SELECT * 
	FROM query_optimizations_and_performance.departments
	WHERE location = 'Building A, Floor 1';
	-- "Seq Scan on departments  (cost=0.00..12.12 rows=1 width=440) (actual time=0.017..0.022 rows=1 loops=1)"
	-- "  Filter: ((location)::text = 'Building A, Floor 1'::text)"
	-- "  Rows Removed by Filter: 9"
	-- "Planning Time: 0.095 ms"
	-- "Execution Time: 0.043 ms"
	CREATE INDEX idxDepartmentsLocation ON query_optimizations_and_performance.departments(location);
	EXPLAIN ANALYZE SELECT * 
	FROM query_optimizations_and_performance.departments
	WHERE location = 'Building A, Floor 1';
	-- "Seq Scan on departments  (cost=0.00..1.12 rows=1 width=440) (actual time=0.068..0.078 rows=1 loops=1)"
	-- "  Filter: ((location)::text = 'Building A, Floor 1'::text)"
	-- "  Rows Removed by Filter: 9"
	-- "Planning Time: 0.588 ms"
	-- "Execution Time: 0.121 ms"
	-- Answer: because an index is an abstraction that aggregates the complexity of being called, such
	-- calling must be avoided if it does not provide the speed necessary for a big table, imagine
	-- yourself paying for an helicopter to go to the park of yout neighborhood
-- 3. Leading Wildcard LIKE: You need to find employees whose email address *con-
-- tains* ’user123’. An index exists on email (due to UNIQUE constraint). Write
-- the query using LIKE ’%user123%’. Use EXPLAIN ANALYZE. Does it use the B-tree
-- index on email effectively for this pattern? Why or why not?
	EXPLAIN ANALYZE
	SELECT * FROM query_optimizations_and_performance.employees 
	WHERE email LIKE '%user123%'
	-- It does not use the B-tree index because the most appropriate index to do so
	-- is the GIN or GiST indices
		
		-- 1.2.3 Exercise IS-3 (Inefficient Alternatives / GIN & GiST Indexes for Full-
-- Text Search)
-- Problem: The company wants to search projectDescription for projects mentioning
-- ”innovation” and ”strategy”. A naive SQL approach might use multiple LIKE clauses.
-- 1. Write a query using projectDescription LIKE ’%innovation%’ AND projectDescription
-- LIKE ’%strategy%’. Run EXPLAIN ANALYZE. Note its inefficiency.
-- 2. Create a GIN index on projectDescription using to tsvector.
-- 3. Rewrite the query to use the GIN index with full-text search operators (e.g., @@
-- and to tsquery) to find projects containing both ”innovation” AND ”strategy”.
-- 4. Run EXPLAIN ANALYZE on the FTS query. Compare plan and performance. Briefly
-- explain GIN’s advantage for this type of search over B-trees and multiple LIKEs.
	EXPLAIN ANALYZE
	SELECT * FROM query_optimizations_and_performance.projects
	WHERE projectDescription LIKE '%innovation%' AND projectDescription LIKE '%strategy%';
	-- "Seq Scan on projects  (cost=0.00..1894.75 rows=513 width=1433) (actual time=1.200..85.178 rows=500 loops=1)"
	-- "  Filter: ((projectdescription ~~ '%innovation%'::text) AND (projectdescription ~~ '%strategy%'::text))"
	-- "  Rows Removed by Filter: 9550"
	-- "Planning Time: 0.372 ms"
	-- "Execution Time: 85.270 ms"
	DROP INDEX IF EXISTS query_optimizations_and_performance.projects.idxProjectDescriptions;
	CREATE INDEX idxDescriptionsOnProjects ON query_optimizations_and_performance.projects
	USING GIN(to_tsvector('english', projectDescription));
	EXPLAIN ANALYZE
	SELECT * FROM query_optimizations_and_performance.projects
	WHERE to_tsvector('english', projectDescription) @@ to_tsquery('english', 'innovation & strategy');
	-- "Bitmap Heap Scan on projects  (cost=31.79..2191.88 rows=1521 width=1433) (actual time=2.591..6.133 rows=1500 loops=1)"
	-- "  Recheck Cond: (to_tsvector('english'::regconfig, projectdescription) @@ '''innov'' & ''strategi'''::tsquery)"
	-- "  Heap Blocks: exact=903"
	-- "  ->  Bitmap Index Scan on idxdescriptionsonprojects  (cost=0.00..31.41 rows=1521 width=0) (actual time=2.038..2.039 rows=1500 loops=1)"
	-- "        Index Cond: (to_tsvector('english'::regconfig, projectdescription) @@ '''innov'' & ''strategi'''::tsquery)"
	-- "Planning Time: 0.507 ms"
	-- "Execution Time: 6.556 ms"
		-- Note the Bitmap Heap Scan rather than Seq Scan with a notable difference of speed

-- 		1.2.4 Exercise IS-4 (Hardcore Problem - Comprehensive Indexing Strategy
-- for Complex Reporting Query)
-- Problem: Generate a report of all ’Active’ employees in the ’Engineering’ or ’Prod-
-- uct Management’ departments, hired between Jan 1, 2015, and Dec 31, 2020, with a
-- performanceScore of 3.5 or higher. For these employees, list their full name, job title,
-- department name, hire date, and the number of projects they are currently assigned to.
-- Order the result by department name, then by number of projects (descending), then by
-- hire date (most recent first).
-- 1. Write the SQL query to generate this report. Use a CTE for clarity if it helps.
-- 2. Analyze the query and list all columns from Employees, Departments, and EmployeeProjects
-- that are involved in WHERE clauses, JOIN conditions, or ORDER BY clauses. These
-- are candidates for indexing.
-- 3. Propose a set of single-column B-tree indexes that would optimize this query. Ex-
-- plain your choices for each index. (Assume standard PK/FK indexes exist for join
-- keys like employeeId, departmentId).
-- 4. Create these indexes. Then run EXPLAIN ANALYZE on your query. Conceptually,
-- describe how the plan might look with these indexes (e.g., types of scans, joins, and
-- how filters are applied).
	EXPLAIN ANALYZE
	SELECT 
		d.departmentName, e.hireDate, 
		(e.firstName || ' ' || e.lastName) fullName, 
		(
			SELECT COUNT(DISTINCT ep.projectId) -- here a b-tree index for ep.projectId 
			FROM query_optimizations_and_performance.employeeProjects ep 
			WHERE ep.employeeId = e.employeeId -- here a b-tree index for ep.employeeId
		) projects
	FROM query_optimizations_and_performance.employees e
	JOIN query_optimizations_and_performance.departments d 
		ON d.departmentName 
		IN ('Engineering', 'Product Management') -- here could be used b-tree (partial and/or complete) index for both strings in d.departmentName
		AND e.departmentId = d.departmentId -- here a b-tree index for e.departmentName
	WHERE e.status = 'Active' -- here a b-tree index (partial and/or complete) for e.status
		AND hireDate 
			BETWEEN TO_DATE('Jan 1, 2015', 'Mon DD, YYYY') 	-- Here a b-tree for dates (partial or complete) or maybe with GIN because the well ordered nature of dates
			AND TO_DATE('Dec 31, 2020', 'Mon DD, YYYY')
		AND performanceScore >= 3.5							-- Here a b-tree for performance scores (partial and/or complete)
	ORDER BY departmentName, projects DESC, hireDate DESC;	-- Here a b-tree for the tree columns to order
	
	-- Joins are efficient.
	-- The subquery is efficient.
	-- Selected columns are easily accessible, ideally from an index (covering index).
	
	-- Given the schema and the query:
	-- Automatic Indexes (from PK/UNIQUE constraints in your schema):
	-- 	departments_pkey ON Departments(departmentId)
	-- 	departments_departmentname_key ON Departments(departmentName) (Crucial for d.departmentName IN ...)
	-- 	projects_pkey ON Projects(projectId)
	-- 	projects_projectname_key ON Projects(projectName)
	-- 	employees_pkey ON Employees(employeeId)
	-- 	employees_email_key ON Employees(email)
	-- 	employeeprojects_pkey ON EmployeeProjects(employeeProjectId)
	-- 	employeeprojects_employeeid_projectid_key ON EmployeeProjects(employeeId, projectId) (Crucial for the subquery)
	-- Indexes from the provided setup script:
	-- 	idxEmployeesLastName ON Employees(lastName) (Not directly used by this query's filters/joins)
	-- 	idxEmployeesDepartmentId ON Employees(departmentId) (Helpful for the join)
	-- 	idxEmployeesHireDate ON Employees(hireDate) (Helpful for the hireDate BETWEEN filter)
	-- The Core Challenge for This Query Lies in the Employees Table Filters:
	-- 	The query filters Employees by:
	-- 		e.status = 'Active'
	-- 		e.hireDate BETWEEN ...
	-- 		e.performanceScore >= 3.5
	-- 		And it needs e.departmentId for the join, e.employeeId for the subquery, and e.firstName, e.lastName for the fullName.
	-- Most Performant and Simplest Effective Set of Additional Indexes:
	-- 	To make the query most performant, especially considering e.status = 'Active' is likely a very common and selective filter 
	-- 	(your data generation has ~90% Active), a partial composite covering index on the Employees table is the most impactful single 
	-- 	addition.
	-- Primary Recommended Index (New):
	-- 	This index is designed to cover almost all interactions with the Employees table for rows where status = 'Active'.
	
	CREATE INDEX idx_employees_active_main_query_covering
	ON query_optimizations_and_performance.employees (hireDate, performanceScore, departmentId, employeeId, firstName, lastName)
	WHERE status = 'Active';
	
	-- WHERE status = 'Active': Makes the index smaller and highly targeted.
	-- 	hireDate: First key part for the BETWEEN filter.
	-- 	performanceScore: Second key part for the >= filter.
	-- 	departmentId: Included to help the join (can be fetched from the index).
	-- 	employeeId: Included to provide the ID for the correlated subquery (can be fetched from the index).
	-- 	firstName, lastName: Included to make this a covering index for the fullName calculation, potentially avoiding a lookup to the main table (heap fetch) for these columns.
	
	-- Summary of ALL Key Indexes for Optimal Performance of THIS Query:
	-- 	This list includes automatically generated indexes crucial for the query and the new highly effective one.
	-- 	SQL to Create/Ensure Key Indexes:
		-- On Departments table (these are typically created automatically by PK/UNIQUE constraints)
		CREATE UNIQUE INDEX IF NOT EXISTS departments_pkey ON query_optimizations_and_performance.Departments(departmentId); -- Assuming PK
		CREATE UNIQUE INDEX IF NOT EXISTS departments_departmentname_key ON query_optimizations_and_performance.Departments(departmentName); -- Assuming UNIQUE
		-- On EmployeeProjects table (these are typically created automatically by PK/UNIQUE constraints)
		CREATE UNIQUE INDEX IF NOT EXISTS employeeprojects_pkey ON query_optimizations_and_performance.EmployeeProjects(employeeProjectId); -- Assuming PK
		CREATE UNIQUE INDEX IF NOT EXISTS employeeprojects_employeeid_projectid_key ON query_optimizations_and_performance.EmployeeProjects(employeeId, projectId); -- Assuming UNIQUE
		-- On Employees table
		CREATE UNIQUE INDEX IF NOT EXISTS employees_pkey ON query_optimizations_and_performance.Employees(employeeId); -- Assuming PK
	
	-- The most impactful NEW index for THIS specific query:
	-- CREATE INDEX IF NOT EXISTS idx_employees_active_main_query_covering
	-- ON query_optimizations_and_performance.employees (hireDate, performanceScore, departmentId, employeeId, firstName, lastName)
	-- WHERE status = 'Active';
	
	-- Note: The setup script already adds idxEmployeesDepartmentId and idxEmployeesHireDate.
	-- If idx_employees_active_main_query_covering is created and used,
	-- idxEmployeesDepartmentId and idxEmployeesHireDate might become redundant FOR THIS SPECIFIC QUERY
	-- when status = 'Active', but they could still be useful for other queries or when status is different.
	-- For the "simplest way to make THIS query most performant", the composite index above is the key.
	
	-- Why this set is "simplest effective":
	-- 	It relies heavily on the naturally efficient PK/UNIQUE indexes.
	-- 	It adds one highly targeted and powerful composite index (idx_employees_active_main_query_covering) 
	-- 	that addresses the most complex part of the query's filtering and data retrieval needs on the largest table involved in filtering.
	-- 	The existing employeeprojects_employeeid_projectid_key is perfectly suited for the subquery.
	-- 	The existing departments_departmentname_key is perfectly suited for the IN clause on departments.
	-- 	This approach minimizes the number of new indexes while maximizing the performance gain for the specified query. The pre-existing 
	-- 	idxEmployeesDepartmentId and idxEmployeesHireDate can still serve other queries or this query if the status condition changes.
	
	-- Previous Concepts Used: SELECT, FROM, JOIN (INNER, LEFT), WHERE (AND, OR,
	-- BETWEEN, >=), GROUP BY, COUNT, ORDER BY (multiple columns, DESC), CTEs, Date
	-- Functions.
	
	-- 		1.2.5 Exercise IS-5 (BRIN Indexes for Time-Series Data)
	-- Problem: The Projects table has grown significantly, and many queries filter projects
	-- by startDate to focus on recent projects (e.g., started after 2023). Due to the table’s
	-- size and the sequential nature of startDate, a BRIN index could be more efficient than
	-- a B-tree.
	-- 1. Write a query to find all projects with startDate > ’2023-01-01’.
	-- 2. Run EXPLAIN ANALYZE to observe the current performance and scan type.
	-- 3. Create a BRIN index on startDate in the Projects table.
	-- 4. Re-run EXPLAIN ANALYZE on the query. Compare the execution plan and perfor-
	-- mance. Explain why a BRIN index is advantageous for this scenario, considering
	-- the sequential nature of startDate.
		EXPLAIN ANALYZE SELECT * 
		FROM query_optimizations_and_performance.projects 
		WHERE startDate > TO_DATE('2023-01-01', 'YYYY-MM-DD');
		-- "Seq Scan on projects  (cost=0.00..1894.75 rows=10049 width=1433) (actual time=0.030..16.947 rows=10050 loops=1)"
		-- "  Filter: (startdate > to_date('2023-01-01'::text, 'YYYY-MM-DD'::text))"
		-- "Planning Time: 0.266 ms"
		-- "Execution Time: 17.911 ms"
		CREATE INDEX idxProjectsStartDatePartialBRIN		-- Partial BRIN index over startDate
		ON query_optimizations_and_performance.projects
		USING BRIN(startDate) WHERE startDate > DATE '2023-01-01';
		EXPLAIN ANALYZE SELECT * 
		FROM query_optimizations_and_performance.projects 
		WHERE startDate > DATE '2023-01-01';
		-- "Seq Scan on projects  (cost=0.00..1869.62 rows=10049 width=1433) (actual time=0.013..4.582 rows=10050 loops=1)"
		-- "  Filter: (startdate > '2023-01-01'::date)"
		-- "Planning Time: 0.141 ms"
		-- "Execution Time: 5.330 ms"
		CREATE INDEX idxProjectsStartDateBRIN			-- Complete BRIN index over startDate
		ON query_optimizations_and_performance.projects
		USING BRIN(startDate);
		EXPLAIN ANALYZE SELECT * 
		FROM query_optimizations_and_performance.projects 
		WHERE startDate > DATE '2023-01-01';
		-- "Seq Scan on projects  (cost=0.00..1869.62 rows=10049 width=1433) (actual time=0.010..3.616 rows=10050 loops=1)"
		-- "  Filter: (startdate > '2023-01-01'::date)"
		-- "Planning Time: 0.094 ms"
		-- "Execution Time: 4.183 ms"

-- 		1.2.6 Exercise IS-6 (Hash Indexes and Advanced Options for Equality Lookups)
-- Problem: The company frequently searches for employees by their exact email address
-- for login verification. The email column already has a B-tree index (due to the UNIQUE
-- constraint), but you want to test a Hash index for faster equality lookups and explore
-- non-disruptive index creation.
-- 1. Write a query to find an employee by email = ’user100@example.com’.
-- 2. Run EXPLAIN ANALYZE to confirm the B-tree index is used.
-- 3. Drop the existing UNIQUE constraint on email (to allow a new index), then create
-- a Hash index on email using the CONCURRENTLY option to avoid locking the table.
-- Restore the UNIQUE constraint afterward.
-- 4. Re-run EXPLAIN ANALYZE. Does the planner use the Hash index? Explain why a
-- Hash index might be more efficient for exact equality lookups compared to a B-tree,
-- and why CONCURRENTLY is useful in a production environment.
	EXPLAIN ANALYZE SELECT * FROM query_optimizations_and_performance.employees WHERE email = 'user100@example.com';
	-- "Index Scan using employees_email_key on employees  (cost=0.41..8.43 rows=1 width=92) (actual time=0.052..0.055 rows=1 loops=1)"
	-- "  Index Cond: ((email)::text = 'user100@example.com'::text)"
	-- "Planning Time: 0.202 ms"
	-- "Execution Time: 0.092 ms"
	ALTER TABLE IF EXISTS query_optimizations_and_performance.employees DROP CONSTRAINT IF EXISTS employees_email_key;
	CREATE INDEX CONCURRENTLY idx_employee_email ON query_optimizations_and_performance.employees(email);
	EXPLAIN ANALYZE SELECT * FROM query_optimizations_and_performance.employees WHERE email = 'user100@example.com';
	-- "Index Scan using idx_employee_email on employees  (cost=0.29..8.30 rows=1 width=92) (actual time=0.033..0.035 rows=1 loops=1)"
	-- "  Index Cond: ((email)::text = 'user100@example.com'::text)"
	-- "Planning Time: 0.150 ms"
	-- "Execution Time: 0.063 ms"

-- 1.2.7 Exercise IS-7 (Full-Text Search with Stored tsvector and Covering Indexes)
-- Problem: The project management team needs to frequently search projectDescription
-- for keywords like ”agile” and ”release” and retrieve the projectName and startDate
-- without accessing the table. You decide to use a stored tsvector column and a covering
-- index to optimize performance.
-- 1. Alter the Projects table to add a generated tsvector column for projectDescription.
-- 2. Create a GIN index on the tsvector column
-- 3. Write a query to search for projects containing both ”agile” and ”release” in
-- projectDescription, selecting only projectName and startDate.
-- 4. Run EXPLAIN ANALYZE to confirm an Index Only Scan is used. Explain how the
-- stored tsvector and covering index improve performance compared to a regular
-- GIN index on to tsvector(’english’, projectDescription).
-- ALTER TABLE query_optimizations_and_performance.projects
-- ADD COLUMN described_ts TSVECTOR 
-- GENERATED ALWAYS AS (to_tsvector('english', projectDescription)) STORED;
-- CREATE INDEX idx_describedproject_on_agility_and_release 
-- ON query_optimizations_and_performance.projects
-- USING GIN(described_ts);
SELECT * FROM query_optimizations_and_performance.projects
WHERE to_tsvector('english', projectDescription) @@ to_tsquery('english', 'agile & release');
