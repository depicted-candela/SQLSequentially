		-- 4 Hardcore Problem Combining Concepts

-- 		Exercise iv.1: Top Employees by Salary per Department with Aggregates and Ranking
-- Problem: For each department, identify the top 2 employees by salary. For these em-
-- ployees, show their full name, department name, salary, their salary rank within the
-- department (dense rank), the total salary expenditure for their department, and their
-- salary as a percentage of their department’s total salary. Only include departments with
-- at least 3 employees. Order results by department name and then by rank.
SELECT
	(e.first_name || ' ' || e.last_name) fullname,
	d.department_name, e.salary, dsr.dept_salary_rank,
	dept_expenditure.dept_total_salary_expenditure,
	ROUND((e.salary / dept_expenditure.dept_total_salary_expenditure) * 100, 2) salary_percentage_dept
FROM
	aggregate_functions.employees AS e
JOIN (
	SELECT
		department_id, employee_id,
		DENSE_RANK() OVER(PARTITION BY department_id ORDER BY salary) dept_salary_rank
	FROM aggregate_functions.employees
) AS dsr ON e.department_id = dsr.department_id AND e.employee_id = dsr.employee_id AND dsr.dept_salary_rank IN (1, 2)
JOIN (
	SELECT
		department_id, SUM(salary) dept_total_salary_expenditure
	FROM aggregate_functions.employees
	GROUP BY(department_id)
) AS dept_expenditure ON dsr.department_id = dept_expenditure.department_id
JOIN aggregate_functions.departments d ON d.department_id = dept_expenditure.department_id
ORDER BY d.department_id, dept_salary_rank;

-- 		Exercise iv.2: Project Metrics, Budget Ranking, and Cumulative Budget
-- Problem: List all projects. For each project, show its name, budget, total hours spent
-- by all employees on that project, and the average hours spent per task on that project.
-- Additionally, rank projects by their budget (highest first). For projects that started in
-- 2023, also show the running total of budgets for projects started in 2023, ordered by their
-- start date.
SELECT p.project_name, p.budget, hours.total, hours.average, p.start_date,
	CASE
		WHEN EXTRACT(YEAR FROM start_date) = 2023 THEN SUM(budget) OVER(ORDER BY start_date ASC)
	END running_totals_2023
FROM aggregate_functions.projects p
JOIN (
	SELECT
	project_id, COALESCE(SUM(hours_spent), 0) total, ROUND(COALESCE(AVG(hours_spent), 0), 2) average
FROM aggregate_functions.employee_tasks GROUP BY project_id) AS hours
	ON p.project_id = hours.project_id
ORDER BY p.budget;

-- 		Exercise iv.3: Employees Above Department Average Salary with Ranking
-- Problem: For every employee, display their full name, department name, salary, the
-- average salary of their department, and their salary’s rank (using ROW NUMBER for unique
-- ranks) within their department. Then, filter this list to show only employees who earn
-- more than their department’s average salary and whose hire date is after ’2020-01-01’.
-- Order the final result by department name and then by salary in descending order.
SELECT * FROM (
	SELECT
		e.first_name || ' ' || e.last_name full_name,
		d.department_name,
		e.salary,
		e.hire_date,
		AVG(e.salary) OVER(PARTITION BY e.department_id) dept_salary_avg,
		ROW_NUMBER() OVER(PARTITION BY e.department_id ORDER BY salary DESC) dept_employee_salary_rank
	FROM aggregate_functions.employees e
	JOIN aggregate_functions.departments d
	ON e.department_id = d.department_id
) AS subquery WHERE subquery.salary > subquery.dept_salary_avg AND subquery.hire_date > '2020-01-01'
ORDER BY department_name, salary DESC;






