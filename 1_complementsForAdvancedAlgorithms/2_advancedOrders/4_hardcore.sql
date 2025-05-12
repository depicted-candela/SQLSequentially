		-- 4 Hardcore Problem Combining Concepts
		
-- 		Exercise 4.1: Comprehensive Employee Ranking and Reporting
-- List employees who were hired on or after January 1st, 2021, and work in departments
-- whose ‘location‘ (from the ‘departments‘ table) is either ’New York’ or ’San Francisco’.
-- For these selected employees, calculate their rank within their respective ‘department‘
-- based on their ‘salary‘ (highest salary first). If salaries are tied within a department, the
-- tie-breaking rules for ranking are as follows:
-- 1. Employees with a non-NULL ‘bonus percentage‘ should come before those with a
-- ‘NULL‘ ‘bonus percentage‘.
-- 2. If the ‘bonus percentage‘ status (NULL or not NULL) is also the same, or if both
-- have non-NULL bonuses, further sort by ‘bonus percentage‘ itself in descending
-- order (higher bonus is better).
-- 3. If ‘bonus percentage‘ values (or their NULL status where both are NULL) are also
-- tied, further sort by ‘hire date‘ in ascending order (earlier hire date first).
-- Display the employee’s full name (concatenated ‘first name‘ and ‘last name‘), their
-- ‘department‘ name, ‘salary‘, ‘hire date‘, ‘bonus percentage‘ (display ’0’ if NULL), and
-- their calculated rank.
-- A crucial condition: Only include employees from departments where the total ‘hours assigned‘
-- to projects for that entire department (sum of ‘hours assigned‘ from the ‘employee projects‘
-- table for all employees in that department) is greater than 200 hours. Employees who
-- themselves have no projects should still be included in the ranking if they meet other
-- criteria and their department meets this total hours threshold.
-- The final result set must be ordered by ‘department‘ name (A-Z) and then by the
-- calculated ‘department rank‘ (ascending).

SELECT e.first_name || ' ' || e.last_name full_name, e.department, e.salary, e.hire_date, 
	COALESCE(e.bonus_percentage, 0) END,
	RANK() OVER(ORDER BY COALESCE(e.bonus_percentage, 0)) bonus_rank
FROM advanced_orders.employees e
JOIN advanced_orders.departments p
	ON e.department = p.department_name AND p.department_name IN (
		SELECT e2.department
		FROM advanced_orders.employee_projects ep
		JOIN advanced_orders.employees e2
			ON ep.employee_id = e2.id
		JOIN advanced_orders.departments d2
			ON d2.department_name = e2.department
		GROUP BY e2.department HAVING SUM(ep.hours_assigned) > 200
	)
WHERE
	e.hire_date > TO_DATE('2021-01-01', 'YYYY-MM-DD')
	AND p.location IN ('San Francisco', 'New York')
ORDER BY e.bonus_percentage DESC NULLS LAST, hire_date, e.department, bonus_rank;

