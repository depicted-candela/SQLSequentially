		-- 3 Inefficient vs. Efficient Aggregate Usage

-- 		Exercise iii.1: Counting Tasks Inefficiently
-- Problem: A junior analyst needs to find the total number of tasks for ’Project Alpha’.
-- They write a script that fetches all task IDs for ’Project Alpha’ into an application and
-- then counts them using application code. Provide the efficient SQL aggregate function
-- solution.

SELECT COUNT(et.task_id) alpha_task_number
FROM aggregate_functions.employee_tasks et
JOIN aggregate_functions.projects p
ON et.project_id = p.project_id
WHERE project_name = 'Project Alpha';

-- 		Exercise iii.2: Calculating Average Salary Inefficiently
-- Problem: To find the average salary of employees hired in 2020, a developer first queries
-- for all salaries of employees hired in 2020, then sums them up and divides by the count
-- in their programming language. How can this be done efficiently in a single SQL query
-- using aggregate functions?

SELECT AVG(salary) FROM aggregate_functions.employees WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- 		Exercise iii.3: Finding Max Salary Per Department Inefficiently
-- Problem: A data scientist wants to get a list of departments and, for each, the maximum
-- salary. They write separate queries for each department: SELECT MAX(salary) FROM
-- employees WHERE department id = 1;, then SELECT MAX(salary) FROM employees WHERE
-- department id = 2;, etc. for all departments. Provide a single, efficient SQL query.

SELECT department_id, MAX(salary) FROM aggregate_functions.employees GROUP BY department_id;

-- 		Exercise iii.4: Filtering by Total Hours Inefficiently
-- Problem: An HR assistant needs to find all employees who have logged more than 150
-- total hours on tasks. They fetch all tasks for every employee, sum the hours in a spread-
-- sheet, and then filter. How can this be done with an efficient SQL query using aggregates
-- and HAVING?

SELECT first_name || ' ' || last_name employees_morethan_150_hours, hours_spent
FROM (
	SELECT employee_id, SUM(hours_spent) hours_spent
	FROM aggregate_functions.employee_tasks
	GROUP BY employee_id HAVING SUM(hours_spent) > 150
) more_than_150
JOIN aggregate_functions.employees e
ON e.employee_id = more_than_150.employee_id;















