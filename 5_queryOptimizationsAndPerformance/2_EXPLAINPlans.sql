-- 2 EXPLAIN Plans

-- 2.1 Dataset for EXPLAIN Plans

-- The exercises in this section use the same dataset as defined in Section 1.1 (Dataset for Indexing Strategies, see Listing 1 on page 3).

-- 	2.2 Exercises for EXPLAIN Plans

-- 		2.2.1 Exercise EP-1 (Meaning, Values of EXPLAIN - Basic Scan & Join Types)
-- Problem: You want to list employees from the ’Sales’ department and their jobTitle.
-- 1. Write a query joining Employees and Departments to achieve this.
-- 2. Use EXPLAIN (not ANALYZE yet). Identify:
--    - The scan type on Employees (e.g., Seq Scan, Index Scan).
--    - The scan type on Departments.
--    - The join type (e.g., Nested Loop, Hash Join, Merge Join).
-- 3. What do ”cost”, ”rows”, and ”width” represent in the EXPLAIN output for a node?
-- EXPLAIN SELECT e.firstName, e.lastName, e.jobTitle, d.departmentName
-- FROM query_optimizations_and_performance.Employees e
-- JOIN query_optimizations_and_performance.Departments d ON e.departmentId = d.departmentId
-- WHERE d.departmentName = 'Sales';
-- Scan type on employees: bit map heap
		  -- on idxemployeesdepartmentid: bitmap index scan
		  -- on departments: Seq Scan thus Improvable
-- Join type: Nested Loop thus improvable
-- Cost: divided as x..y are x: startup_cost and y:total_cost
-- Rows: the number of outputs as rows
-- Width: the size of every returned row measured in bytes

-- 		2.2.2 Exercise EP-2 (Disadvantages/Misinterpretations of EXPLAIN - Stale Statistics & Actual Time)
-- Problem: EXPLAIN provides estimates. EXPLAIN ANALYZE provides actuals.
-- 1. Consider a query: 
-- EXPLAIN ANALYZE SELECT * FROM query_optimizations_and_performance.Employees WHERE salary > 150000;
-- 2. Run EXPLAIN on this query. Note the estimated rows.
-- -- 3. Now, run the following INSERT statement:
-- INSERT INTO query_optimizations_and_performance.Employees (firstName, lastName, email, departmentId,
-- salary, hireDate, jobTitle, performanceScore, status)
-- VALUES ('High', 'Earner', 'high.earner@example.com',
-- (SELECT departmentId FROM query_optimizations_and_performance.Departments WHERE departmentName = 'Finance' LIMIT 1),
-- 200000.00, CURRENT_DATE, 'CFO', 5.0, 'Active');
--    Do NOT run ANALYZE Employees; yet.
-- 4. Re-run EXPLAIN on the same query from step 1. Does the estimated rows change significantly? Why or why not? This 
-- illustrates a disadvantage of relying solely on EXPLAIN with potentially stale statistics.
-- 5. Run EXPLAIN ANALYZE on the query from step 1. Compare actual time for nodes vs. estimated cost. 
-- Compare actual rows vs. estimated rows. What’s the key value ANALYZE adds?
-- First
-- "Seq Scan on employees  (cost=0.00..862.00 rows=3 width=92)"
-- "  Filter: (salary > '150000'::numeric)"
-- Second
-- "Seq Scan on employees  (cost=0.00..862.00 rows=3 width=92)"
-- "  Filter: (salary > '150000'::numeric)"
-- There is not real difference
-- First
-- "Seq Scan on employees  (cost=0.00..862.00 rows=3 width=92) (actual time=1.760..12.763 rows=2 loops=1)"
-- "  Filter: (salary > '150000'::numeric)"
-- "  Rows Removed by Filter: 30000"
-- "Planning Time: 0.208 ms"
-- "Execution Time: 12.790 ms"
-- Second
-- "Seq Scan on employees  (cost=0.00..862.00 rows=3 width=92) (actual time=0.910..9.448 rows=3 loops=1)"
-- "  Filter: (salary > '150000'::numeric)"
-- "  Rows Removed by Filter: 30000"
-- "Planning Time: 0.134 ms"
-- "Execution Time: 9.468 ms"
-- There exists an augment in the number of rows and evident different in planning and execution times

-- 		2.2.3 Exercise EP-3 (Inefficient Alternatives & EXPLAIN for Correlated Subqueries vs. JOINs)
-- Problem: You need to list each employee and the name of their project if they are working on ’Project Alpha 1’. 
-- A common inefficient way is a correlated subquery in the SELECT list.
-- 1. Write this query using such a correlated subquery to fetch projectName. Filter for employees on ’Project Alpha 1’.
-- 2. Run EXPLAIN ANALYZE. Observe the plan, especially how often the subquery might be executed (implied by loops and costs).
-- 3. Rewrite using a LEFT JOIN to EmployeeProjects and Projects.
-- 4. Run EXPLAIN ANALYZE on the JOIN version. Compare plan (e.g., join types, scan costs) and total actual execution time. 
-- Why is the JOIN generally better?
	 EXPLAIN ANALYZE
	 SELECT
	     e.employeeId,
	     e.firstName,
	     e.lastName,
	     (SELECT p.projectName
	      FROM query_optimizations_and_performance.Projects p
	      JOIN query_optimizations_and_performance.EmployeeProjects epFind ON p.projectId = epFind.projectId
	      WHERE epFind.employeeId = e.employeeId AND p.projectName = 'Project Alpha 1'
	      LIMIT 1) AS projectAlphaName
	 FROM
	     query_optimizations_and_performance.Employees e
	 WHERE EXISTS (
	     SELECT 1
	     FROM query_optimizations_and_performance.EmployeeProjects epChk
	     JOIN query_optimizations_and_performance.Projects pChk ON epChk.projectId = pChk.projectId
	     WHERE epChk.employeeId = e.employeeId AND pChk.projectName = 'Project Alpha 1'
	 );
	-- "Nested Loop  (cost=1718.98..1836.37 rows=9 width=348) (actual time=24.115..24.119 rows=0 loops=1)"
	-- "  ->  HashAggregate  (cost=1718.69..1718.78 rows=9 width=4) (actual time=24.114..24.117 rows=0 loops=1)"
	-- "        Group Key: epchk.employeeid"
	-- "        Batches: 1  Memory Usage: 24kB"
	-- "        ->  Hash Join  (cost=8.31..1718.67 rows=9 width=4) (actual time=24.112..24.114 rows=0 loops=1)"
	-- "              Hash Cond: (epchk.projectid = pchk.projectid)"
	-- "              ->  Seq Scan on employeeprojects epchk  (cost=0.00..1474.00 rows=90000 width=8) (actual time=0.006..9.612 rows=90000 loops=1)"
	-- "              ->  Hash  (cost=8.30..8.30 rows=1 width=4) (actual time=0.044..0.045 rows=1 loops=1)"
	-- "                    Buckets: 1024  Batches: 1  Memory Usage: 9kB"
	-- "                    ->  Index Scan using projects_projectname_key on projects pchk  (cost=0.29..8.30 rows=1 width=4) (actual time=0.039..0.041 rows=1 loops=1)"
	-- "                          Index Cond: ((projectname)::text = 'Project Alpha 1'::text)"
	-- "  ->  Index Scan using employees_pkey on employees e  (cost=0.29..0.38 rows=1 width=30) (never executed)"
	-- "        Index Cond: (employeeid = epchk.employeeid)"
	-- "  SubPlan 1"
	-- "    ->  Limit  (cost=0.58..12.69 rows=1 width=18) (never executed)"
	-- "          ->  Nested Loop  (cost=0.58..12.69 rows=1 width=18) (never executed)"
	-- "                Join Filter: (p.projectid = epfind.projectid)"
	-- "                ->  Index Scan using projects_projectname_key on projects p  (cost=0.29..8.30 rows=1 width=22) (never executed)"
	-- "                      Index Cond: ((projectname)::text = 'Project Alpha 1'::text)"
	-- "                ->  Index Only Scan using employeeprojects_employeeid_projectid_key on employeeprojects epfind  (cost=0.29..4.35 rows=3 width=4) (never executed)"
	-- "                      Index Cond: (employeeid = e.employeeid)"
	-- "                      Heap Fetches: 0"
	-- "Planning Time: 2.267 ms"
	-- "Execution Time: 24.176 ms"

	 EXPLAIN ANALYZE
	 SELECT
	     e.employeeId,
	     e.firstName,
	     e.lastName,
	     p.projectName
	 FROM query_optimizations_and_performance.Employees e
	 JOIN query_optimizations_and_performance.EmployeeProjects ep ON e.employeeId = ep.employeeId
	 JOIN query_optimizations_and_performance.Projects p ON ep.projectId = p.projectId
	 WHERE p.projectName = 'Project Alpha 1';
	-- "Nested Loop  (cost=8.60..1721.64 rows=9 width=48) (actual time=16.457..16.460 rows=0 loops=1)"
	-- "  ->  Hash Join  (cost=8.31..1718.67 rows=9 width=22) (actual time=16.456..16.458 rows=0 loops=1)"
	-- "        Hash Cond: (ep.projectid = p.projectid)"
	-- "        ->  Seq Scan on employeeprojects ep  (cost=0.00..1474.00 rows=90000 width=8) (actual time=0.008..6.376 rows=90000 loops=1)"
	-- "        ->  Hash  (cost=8.30..8.30 rows=1 width=22) (actual time=0.025..0.026 rows=1 loops=1)"
	-- "              Buckets: 1024  Batches: 1  Memory Usage: 9kB"
	-- "              ->  Index Scan using projects_projectname_key on projects p  (cost=0.29..8.30 rows=1 width=22) (actual time=0.020..0.021 rows=1 loops=1)"
	-- "                    Index Cond: ((projectname)::text = 'Project Alpha 1'::text)"
	-- "  ->  Index Scan using employees_pkey on employees e  (cost=0.29..0.33 rows=1 width=30) (never executed)"
	-- "        Index Cond: (employeeid = ep.employeeid)"
	-- "Planning Time: 0.625 ms"
	-- "Execution Time: 16.498 ms"
	-- Note how the not query without the correlated query is simpler in strategy and faster by properties despite both can be
	-- enhanced changing the Nested Loop with a better strategy for joins


-- 		2.2.4 Exercise EP-4 (Hardcore Problem - Analyzing and Suggesting Improvements for Complex Query Plan)
-- Problem: A query is written to find departments where the average salary of ’Software Engineer’ employees hired after Jan 1, 
-- 2018, exceeds $75,000. The query also lists the count of such engineers in those departments.
	 EXPLAIN (ANALYZE, BUFFERS) SELECT
	  d.departmentName,
	  COUNT(e.employeeId) as numEngineers,
	  AVG(e.salary) as avgSalary
	 FROM query_optimizations_and_performance.Departments d
	 JOIN query_optimizations_and_performance.Employees e ON d.departmentId = e.departmentId
	 WHERE e.jobTitle = 'Software Engineer' AND e.hireDate > '2018-01-01'
	 GROUP BY d.departmentId, d.departmentName
	 HAVING AVG(e.salary) > 75000
	 ORDER BY avgSalary DESC;
	 SELECT schemaname, relname AS tablename, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
	 FROM pg_stat_user_indexes
	 WHERE schemaname = 'query_optimizations_and_performance'
	 ORDER BY idx_scan ASC;

-- 1. Run EXPLAIN (ANALYZE, BUFFERS) on this query.
-- 2. Identify the most time-consuming operations (nodes with high actual total time).
-- 3. Check for discrepancies between estimated rows (rows) and actual rows in key filter or join nodes. What might this indicate?
-- 4. Look at Buffers: shared hit=... read=.... What does a high read count suggest for a particular table scan?
-- 5. Based on the plan, suggest two distinct potential improvements. These could be adding a specific type of index 
-- (single/composite), rewriting part of the query, or an environment tweak (like work_mem if a sort/hash is spilling to disk). 
-- Explain why your suggestions might help.

-- After a cleaning of all particular indexes made previously for this database for specific problems (where wsuch cleaining was
-- statistically-based using the query presented in the title Advanced Indexing Features: Supercharging Your Shortcuts of the lecture) 
-- the following analysis was performed.

 EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT -- 5 - 18ms 
  d.departmentName,
  COUNT(e.employeeId) as numEngineers,
  AVG(e.salary) as avgSalary
 FROM query_optimizations_and_performance.Departments d
 JOIN query_optimizations_and_performance.Employees e 
 	ON d.departmentId = e.departmentId
 WHERE e.jobTitle = 'Software Engineer' AND e.hireDate > '2018-01-01'
 GROUP BY d.departmentId, d.departmentName
 HAVING AVG(e.salary) > 75000
 ORDER BY avgSalary DESC;

-- 2. 	-->  Bitmap Heap Scan on employees e  (cost=200.59..910.96 rows=2481 width=14) (actual time=1.622..7.304 rows=2441 loops=1)
		-- Bitmap Heap Scan	1	5.711 ms	45.23% requires almost all the compute power of the query
		-- for WHERE e.jobTitle = 'Software Engineer' AND e.hireDate > '2018-01-01'
		-- with a shared Buffer hit of 487 meaning 3.8 MB, to high for the query itself
		-- gets a high cost because needs to filter lots of rows having the highest percentage of buffer of type shared cache activity
		-- Thus, the most appropriate solution is 
-- 3. 	-- Not really big differencess between estimated rows and actual rows in most process steps, thus statistics are not highly stale 
-- 4. 	-- High numbers here must be used to prioritize queries that simplifies subsequent processes or to use most appropriate 
		-- indexes if aggregations or relations are made
		--> Bitmap Heap Scan on employees e  (cost=200.59..910.96 rows=2481 width=14) (actual time=1.622..7.304 rows=2441 loops=1)
-- 5. Query improvements

-- First improvement
-- CREATE INDEX idx_employees_hiredate_title 			-- Because the order for composed index is: equalities, ranges and then grouping
 ON query_optimizations_and_performance.Employees 	-- and orderings:
 	(jobTitle, hireDate, departmentId)				-- equalities -> e.jobTitle = 'Software Engineer'
 INCLUDE(salary); 	-- to have salary				-- ranges -> e.hireDate > DATE '2018-01-01' 
					-- directly related				-- orderings or groupings -> GROUP BY e.departmentId
 EXPLAIN (ANALYZE, BUFFERS)
 WITH NewEngineers AS (
 	SELECT e.departmentId, AVG(e.salary) avgSalary, COUNT(e.employeeId) numEngineers
 	FROM query_optimizations_and_performance.Employees e
	WHERE e.jobTitle = 'Software Engineer' AND e.hireDate > DATE '2018-01-01' 
	GROUP BY e.departmentId
)
SELECT d.departmentId, d.departmentName, e.numEngineers	-- Improves first improvement a little bit but makes a too high
FROM query_optimizations_and_performance.Departments d	-- specialized index
NATURAL JOIN NewEngineers e
WHERE avgSalary > 75000;

-- Second improvement: reduces the percentage
CREATE INDEX idx_employees_departmental_partial
ON query_optimizations_and_performance.Employees
	(departmentId)
INCLUDE(salary) 	-- to have salary related
WHERE jobTitle = 'Software Engineer'
AND hireDate > '2018-01-01';
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
WITH NewEngineers AS (
	SELECT e.departmentId, AVG(e.salary) avgSalary, COUNT(e.employeeId) numEngineers
	FROM query_optimizations_and_performance.Employees e
	WHERE e.jobTitle = 'Software Engineer' AND e.hireDate > DATE '2018-01-01' 
	GROUP BY e.departmentId
)
SELECT d.departmentId, d.departmentName, e.numEngineers
FROM query_optimizations_and_performance.Departments d
NATURAL JOIN NewEngineers e
WHERE avgSalary > 75000;

-- Previous Concepts Used: SELECT, FROM, JOIN, WHERE (AND, >), GROUP BY, HAVING, AVG, COUNT, ORDER BY DESC, Date comparisons.