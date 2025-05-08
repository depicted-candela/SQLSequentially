	-- 1 Practice Meanings, Values, Relations, and Advantages

	
-- 		Exercise i.1: Overall Company Metrics
-- Problem: Calculate the total number of employees, the total salary expenditure, the
-- average salary, the minimum salary, and the maximum salary across all employees. What
-- is the main advantage of using aggregate functions for this?

SELECT COUNT(DISTINCT employee_id), SUM(salary), AVG(salary), MIN(salary), MAX(salary)
FROM aggregate_functions.employees;


-- 		Exercise i.2: Department Employee Listing
-- Problem: For each department, list the department name, the number of employees in
-- that department, and a comma-separated list of all employee first names in that depart-
-- ment, ordered alphabetically by first name. How does STRING AGG help here?

SELECT d.*, departmental_summary.number_of_workers, departmental_summary.departmental_names
FROM aggregate_functions.departments AS d
JOIN (
	SELECT
		department_id,
		COUNT(DISTINCT employee_id) number_of_workers,
		STRING_AGG(first_name, ', ') AS departmental_names
	FROM aggregate_functions.employees
	GROUP BY department_id
) AS departmental_summary
ON d.department_id = departmental_summary.department_id;


-- 		Exercise i.3: Understanding Different COUNTs
-- Problem: Find the total number of employees, the number of employees with a bonus percentage
-- recorded, and the number of distinct performance rating values. Explain the difference
-- in meaning for each COUNT.

SELECT
	COUNT(employee_id) workers,
	COUNT(bonus_percentage) total_bonuses,
	COUNT(DISTINCT performance_rating) different_performance_ratings
FROM aggregate_functions.employees;


-- 		Exercise i.4: Median Salary and Mode Performance Rating
-- Problem: Calculate the median salary for employees in the ’Engineering’ department and
-- the most common (mode) performance rating for the entire company. What is the value
-- of PERCENTILE CONT and MODE?

SELECT
	MODE() WITHIN GROUP(ORDER BY performance_rating) performance_mode,			-- The most repeated performance_rating, 
	(																			-- because the workers are 25 and there
		SELECT																	-- exists 3 different performance ratings 
			PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY salary) AS median_salary -- is meaningful the most repeated one.
		FROM aggregate_functions.employees e									-- One special metric of percentiles is the
		JOIN aggregate_functions.departments d									-- median that lies in the 50% of the data
			ON e.department_id = d.department_id								-- distribution.
		WHERE d.department_name = 'Engineering'
	)
FROM aggregate_functions.employees;


-- Exercise i.5: Project Task Hours Distribution
-- Problem: For each project, display its name, total hours spent, and the variance and
-- standard deviation of hours spent on its tasks. How do VARIANCE and STDDEV help
-- understand data distribution?

SELECT p.project_name, et.*
FROM aggregate_functions.projects p
JOIN
	(SELECT
		project_id,
		SUM(hours_spent),
		VARIANCE(hours_spent),
		STDDEV(hours_spent)
	FROM aggregate_functions.employee_tasks
	GROUP BY project_id
) AS et ON p.project_id = et.project_id;


-- 		Exercise i.6: Departmental and Cumulative Salaries
-- Problem: Show the total salary for each department. Also, show the cumulative salary
-- within each department as employees are ordered by their hire date (earliest first). What
-- is the advantage of the window aggregate here?

SELECT
	department_id, hire_date, employee_id, salary,
	SUM(salary) OVER(PARTITION BY department_id) departmental_total_salary,
	SUM(salary) OVER(PARTITION BY department_id ORDER BY hire_date ASC, employee_id ASC) departmental_by_hire_date_cumulative_salaries
	-- The window function simplofies a lot because partition first by departments and then with important orders for this
	-- case like the hiring date that is the factor for the cumularive sum. Other not highly simple and efficient solution
	-- could be recursion CTE, too complex in comparison with this
FROM aggregate_functions.employees;





