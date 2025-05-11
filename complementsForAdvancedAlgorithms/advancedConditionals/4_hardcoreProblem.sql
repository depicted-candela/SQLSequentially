-- 		4 Hardcore Problem Combining Previous Concepts
-- Problem Statement:
-- Identify ”Key Departments” based on the following criteria:
-- 1. The department name must contain either ’Tech’ or ’HR’ (case-sensitive as per
-- standard SQL LIKE).
-- 2. The department’s monthly budget IS NULL, OR its monthly budget = 50000.00.
-- 3. The department must have at least one ”veteran” employee associated with it. This
-- is determined by checking if there EXISTS such an employee in the department. A
-- ”veteran” employee is defined as someone:
-- • Hired more than 8 years ago from CURRENT DATE.
-- • Whose performance rating IS DISTINCT FROM 1 (i.e., their rating is not 1,
-- or their rating is NULL).
-- For these ”Key Departments”, calculate the total hours assigned to all their em-
-- ployees for projects that started on or after ’2023-01-01’. If a department has no such
-- employees or projects meeting this date criterion, their total hours should be displayed
-- as 0.
-- Display the dept name and the calculated total project hours. Order the results
-- in descending order of total project hours, then by dept name alphabetically. Limit
-- the result to the top 3 departments.

-- UPDATE complementary.departments SET monthly_budget = 50000.00 WHERE dept_name = 'Technology';

SELECT sq1.dept_name dept_name, SUM(ep.hours_assigned) total_project_hours
FROM complementary.employee_projects ep
JOIN complementary.projects p ON p.proj_id = ep.proj_id
JOIN complementary.employees e ON ep.emp_id = e.emp_id
JOIN (
	SELECT dept_id, dept_name
	FROM complementary.departments d
	WHERE
		( dept_name LIKE '%Tech%' OR dept_name LIKE '%HR%' )
		AND ( monthly_budget IS NOT DISTINCT FROM 50000 )
		AND EXISTS (
			SELECT * FROM complementary.employees e 
			WHERE
				e.dept_id IS NOT DISTINCT FROM d.dept_id
				AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) > 8
				AND e.performance_rating IS DISTINCT FROM 1
		)
) AS sq1 ON e.dept_id = sq1.dept_id
WHERE p.start_date >= TO_DATE('2023-01-01', 'YYYY-MM-DD')
GROUP BY sq1.dept_name ORDER BY total_project_hours;