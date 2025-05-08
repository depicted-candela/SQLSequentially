-- 4. Practice Hardcore Combined Problem

-- 		Comprehensive Employee Analysis

-- Problem: For each department:
-- 	1. Identify the employee(s) with the highest salary in that department.
-- 	2. For these top-paid employees, determine their salary rank across the entire company
-- (use RANK() for ties).
-- 	3. Show the average salary of their department.
-- 	4. Calculate the difference between their salary and their department’s average salary.
-- 	5. Identify the employee id and full name (first name || ' ' ’ || last name) of
-- the employee who was hired immediately after them within the same department,
-- along with that next hire’s date. If they are the last one hired in their department
-- (among the top-paid, or overall if simpler for this part), this should be NULL for the
-- next hire’s details. (Clarification: 'last one hired in their department' should be
-- interpreted as the one with latest hire date in the entire department for identifying
-- the 'next hire').

WITH departmental_hiring_sequence AS (
	SELECT 
		employee_id,
		department,
		(first_name || ' ' || last_name) full_name,
		RANK() OVER(PARTITION BY department ORDER BY hire_date DESC) hiring_rank
	FROM ranking_functions.employees
)

-- 1 & 2 & 3
SELECT
	e1.employee_id id_top_emp,
	(e1.first_name || ' ' || e1.last_name) top_full_name,
	e1.department top_department,
	e1.salary top_department, 
	(e1.salary - avg_salaries.average_salary) AS highest_differential_salaries,
	next_hiring_sequence.full_name next_hired
FROM (
	SELECT
		*,
		RANK() OVER(PARTITION BY department ORDER BY salary DESC) d_rank,
		RANK() OVER(ORDER BY salary DESC) c_rank
	FROM ranking_functions.employees
) AS e1
JOIN (
	SELECT department, AVG(salary) average_salary
	FROM ranking_functions.employees GROUP BY department
) AS avg_salaries
	ON e1.department = avg_salaries.department
JOIN departmental_hiring_sequence AS current_hiring_sequence
	ON current_hiring_sequence.employee_id = e1.employee_id
LEFT JOIN departmental_hiring_sequence AS next_hiring_sequence
	ON current_hiring_sequence.department = next_hiring_sequence.department
	AND current_hiring_sequence.hiring_rank = next_hiring_sequence.hiring_rank - 1
WHERE e1.d_rank = 1;


