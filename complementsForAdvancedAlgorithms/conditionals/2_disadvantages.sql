		-- 2 Practice Disadvantages of All Its Technical Concepts
		
-- 		2.1 NOT IN with Subquery Returning NULL
-- Problem: Attempt to list employees who are NOT leads on any project using the
-- condition emp id NOT IN (SELECT lead emp id FROM projects). Observe the (poten-
-- tially unexpected) result given that projects.lead emp id can be NULL (e.g., ’NoLead
-- Project’). Explain why this happens.
-- SELECT * 
-- FROM complementary.employees 
-- WHERE emp_id NOT IN (
-- 	SELECT lead_emp_id FROM complementary.projects
-- ); 	-- Prone to errors because a single falsy value in the list of the subquery creates entirely a chained effect of FALSE
--		-- because of a not NULL value can not exists in the kernel
-- SELECT * 
-- FROM complementary.employees 
-- WHERE emp_id NOT IN (
-- 	SELECT lead_emp_id FROM complementary.projects WHERE lead_emp_id IS NOT NULL
-- ); -- Simpler alternative

-- SELECT * 
-- FROM complementary.employees e1 
-- WHERE NOT EXISTS (
-- 	SELECT lead_emp_id FROM complementary.projects p WHERE e1.emp_id = p.lead_emp_id
-- ); -- Other alternative

-- 		2.2 != ANY Misinterpretation
-- Problem: Find employees whose salary is not equal to any salary found in the ’Intern
-- Pool’ department. The ’Intern Pool’ department currently has one employee (’Intern
-- Zero’) with a salary of $20,000. Consider what happens if the ’Intern Pool’ department
-- had multiple distinct salaries (e.g., $20,000, $22,000). Explain the logical evaluation of
-- salary != ANY (subquery salaries) in such a scenario.
-- SELECT e1.*
-- FROM complementary.employees e1									-- The problem with this is that a salary different to any
-- WHERE e1.salary != ALL (										-- in the same set is the same set to be compared, thus ALL
-- 	SELECT e2.salary											-- statement must be used to get the difference between both
-- 	FROM complementary.employees e2								-- sets
-- 	JOIN complementary.departments d
-- 	ON d.dept_name = 'Intern Pool' AND e1.dept_id = d.dept_id
-- )

-- 		2.3 Performance of IS DISTINCT FROM vs. Standard Operators
-- (Conceptual)
-- Problem: Consider finding employees where performance rating is 3.
-- • Compare conceptually querying this using performance rating = 3 versus performance rating
-- IS NOT DISTINCT FROM 3.
-- • When might the IS NOT DISTINCT FROM approach be slightly less optimal if performance rating
-- is indexed and guaranteed NOT NULL? Discuss potential minor overheads or familiarity issues.
-- for developers

-- Since IS DISTINCT FROM is a construct to make multiple comparisons useful when data is nasty with NULL values, make all
-- the operations of their constructs means lots of operations for a column that does need them, then is preferred the usage
-- of <> or != when data is completely because they're single operations

-- 		2.4 Readability of EXISTS vs. IN for Simple Cases
-- Problem: Retrieve employees who are in departments listed in a small, explicit list of
-- department IDs (e.g., department IDs 1 and 2).
-- • Write a query fragment using IN with a literal list.
-- • Write a query fragment using EXISTS with a subquery that provides these values.
-- • Compare the readability and conciseness of these two approaches for this specific
-- simple case.

-- SELECT * FROM complementary.employees WHERE dept_id IN (SELECT dept_id FROM complementary.departments d WHERE d.dept_id IS NOT NULL); -- clearly cleaner
-- SELECT * FROM complementary.employees e WHERE EXISTS (SELECT d.dept_id FROM complementary.departments d WHERE d.dept_id IS NOT NULL AND d.dept_id = d.dept_id);



