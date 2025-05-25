	-- 4. Date Functions, Cases, NULL Space 
		-- 2 Cases (Complementary SQL)


-- Concepts: Searched CASE expressions, CASE in ORDER BY, CASE in GROUP BY.

-- 	(i) Meaning, values, relations, advantages of unique usage

-- 		Exercise 2.1: Project Status Categorization
-- Problem: Categorize projects into: ’Upcoming’ (starts after ’2024-01-15’), ’Ongoing’
-- (started on or before ’2024-01-15’ and actual end date is NULL or after ’2024-01-15’),
-- ’Completed Early/On-Time’ (actual end date <= planned end date), ’Completed Late’
-- (actual end date > planned end date). Use a searched CASE expression. Display
-- project name and its status.
SELECT
 	STRING_AGG(project_name, ', '),
 	CASE
 		WHEN start_date > DATE '2024-01-15' THEN 'Upcoming'
 		WHEN start_date <= DATE '2024-01-15' THEN 'Ongoing'
 		WHEN actual_end_date <= planned_end_date THEN 'Completed Early/On-Time'
 		WHEN actual_end_date > planned_end_date THEN 'Completed Late'
 	END status
FROM advanced_dates_cases_and_null_space.projects
GROUP BY
 	CASE
 		WHEN start_date > DATE '2024-01-15' THEN 'Upcoming'
 		WHEN start_date <= DATE '2024-01-15' THEN 'Ongoing'
 		WHEN actual_end_date <= planned_end_date THEN 'Completed Early/On-Time'
 		WHEN actual_end_date > planned_end_date THEN 'Completed Late'
	END;
	
-- 		Exercise 2.2: Sorting Employees by Custom Priority
-- Problem: List all employees. Sort them by: first, managers (those who are manager id
-- for someone or have no manager id themselves), then non-managers. Within managers,
-- sort by salary descending. Within non-managers, sort by hire date ascending. Use CASE
-- in ORDER BY.
SELECT
     *,
 	CASE 
         WHEN EXISTS(
 			SELECT * FROM advanced_dates_cases_and_null_space.projects p WHERE p.lead_emp_id = e.emp_id
 		) OR e.manager_id IS NOT NULL THEN 'Manager'
         ELSE 'Not Manager'
     END status
 FROM advanced_dates_cases_and_null_space.employees e
 ORDER BY 
     CASE 
         WHEN EXISTS(
 			SELECT * FROM advanced_dates_cases_and_null_space.projects p WHERE p.lead_emp_id = e.emp_id
 		) OR e.manager_id IS NOT NULL THEN 0
         ELSE 1
     END ASC,
 	CASE 
         WHEN EXISTS(
 			SELECT * FROM advanced_dates_cases_and_null_space.projects p WHERE p.lead_emp_id = e.emp_id
 		) OR e.manager_id IS NOT NULL THEN salary
         ELSE NULL									-- skips orders when the cased when does not match
     END DESC,										-- the subquery of managers
 	CASE 
         WHEN e.manager_id <> ALL(
 			SELECT p.lead_emp_id FROM advanced_dates_cases_and_null_space.projects p
 		) OR e.manager_id IS NULL THEN hire_date
         ELSE NULL									-- skips orders when the cased when does not match
     END ASC;										-- the subquery for not managers

-- 		Exercise 2.3: Grouping Projects by Budget Ranges
-- Problem: Group projects by budget: ’Low’ (<= 50000), ’Medium’ (50001 - 150000),
-- ’High’ (> 150000), ’Undefined’ (budget IS NULL). Count projects and sum their budgets
-- in each category. Use CASE in GROUP BY.
 SELECT
 	STRING_AGG(project_name, ', '),
 	SUM(budget) total_budget,
 	CASE
 		WHEN budget <= 50000 THEN 'Low'
 		WHEN budget BETWEEN 50000 AND 150000 THEN 'High'
 		WHEN budget > 150000 THEN 'High'
 		WHEN budget IS NULL THEN 'Undefined' 
 	END AS financial_project
 FROM advanced_dates_cases_and_null_space.projects
 GROUP BY
 	financial_project;


-- 	(ii) Disadvantages of all its technical concepts

-- 		Exercise 2.4: Overly Nested CASE Expressions for Readability
-- Problem: Create a complex employee ”profile string” using a CASE expression. If salary ¿
-- 100k, profile starts ”High Earner”. If also in Eng dept (ID 2), append ”, Key Engineer”.
-- If also rating 5, append ”, Top Performer”. Otherwise, profile is ”Standard”. Construct
-- this query and discuss the readability impact of such deeply nested or numerous WHEN
-- conditions.
 SELECT
 	emp_id, emp_name,
 	CASE													-- Too complex to be easily readed
 		WHEN salary > 100000 THEN 'High Earner' ||			-- because the nested logic grows exponentially
-- 			CASE 											-- in the number of necessary commands
-- 				WHEN dept_id = 2 THEN ', Key Engineer' ||
-- 					CASE
-- 						WHEN performance_rating = 5 THEN ', Top Performer'
-- 						ELSE ''
-- 					END
-- 				WHEN dept_id <> 2 THEN ', Non Key Engineer'  -- Meaningful logic for better decisions
-- 			END
-- 		ELSE 'Standard'
-- 	END AS title
-- FROM advanced_dates_cases_and_null_space.employees;

-- 		Exercise 2.5: CASE in GROUP BY Causing Performance Issues with Non-
-- SARGable Conditions
-- Problem: Group employees by a category derived from their email address: ’Internal’
-- (ends with ’@example.com’), ’External’ (otherwise). Write the query using CASE in
-- GROUP BY. If the CASE expression uses a function like SUBSTRING or LIKE ’%pattern’
-- on the email column, and that column is not indexed appropriately for such operations,
-- discuss potential performance disadvantages.
-- SELECT
-- 	STRING_AGG(email, ', '),
-- 	CASE
-- 		WHEN email LIKE '%example.com' THEN 'Internal'
-- 		ELSE 'External'
-- 	END AS email_type
-- FROM advanced_dates_cases_and_null_space.employees
-- GROUP BY
-- 	email_type;

-- 	(iii) Practice entirely cases where people in general does not use
-- these approaches losing their advantages, relations and values
-- because of the easier, basic, common or easily understandable
-- but highly inefficient solutions

-- 		Exercise 2.6: Multiple UNION ALL Queries vs. CASE in GROUP BY for
-- Segmented Counts
-- Problem: Count employees in ’Engineering’ (dept id=2) and ’Sales’ (dept id=3) sepa-
-- rately, and all other employees as ’Other’. A common but verbose way is to use UNION
-- ALL with three separate SELECT COUNT(*) queries. Show this inefficient method, then
-- solve efficiently using CASE in GROUP BY.
