		-- 1.4 (iv) Practice a hardcore problem combining all the technical concepts

-- 		Exercise 1.4.1: (Joins - Hardcore Problem)
-- 	Problem: The company wants a detailed report to identify ”High-Impact Man-
-- agers” in departments located in the ’USA’. A ”High-Impact Manager” is defined
-- as a manager who:
-- a. Works in a department located in the ’USA’.
-- b. Was hired on or before ’2020-01-01’.
-- c. Manages at least 2 employees.
-- d. The average salary of their direct reports is greater than $65,000.
-- The report should list:
-- • Manager’s full name (manager name).
-- • Manager’s job title (manager job title).
-- • Manager’s department name (department name).
-- • The city of the department (department city).
-- • The number of direct reports (num direct reports).
-- • The average salary of their direct reports (avg reports salary), formatted
-- to 2 decimal places.
-- 	Additionally:
-- • Order the results by the manager’s last name.
-- • If a manager could be listed due to managing employees in multiple depart-
-- ments (not applicable with current schema but consider if structure allowed
-- it), they should be listed per department criteria.
-- • This problem primarily tests SELF JOINs (for manager-employee hierarchy),
-- standard JOINs (employees to departments, departments to locations), sub-
-- queries or CTEs for aggregation, and filtering with WHERE clause (Basic SQL,
-- Date Functions, Arithmetic). While CROSS JOIN and NATURAL JOIN are
-- not central to the optimal solution, briefly comment on whether a NATU-
-- RAL JOIN between employees and departments (if department id was the
-- only common column) or departments and projects (as department id is
-- common) would have been suitable and its risks.

WITH managed_employees AS (
    SELECT
        e1.employee_id AS managed_id,
        e2.employee_id,
        e2.department_id,
		d.location_id,
		e1.salary md_salary
    FROM advanced_joins_aggregators.employees e1
    JOIN advanced_joins_aggregators.employees e2
        ON e2.employee_id = e1.manager_id
    JOIN advanced_joins_aggregators.departments d 
        ON d.department_id = e1.department_id
)

SELECT
	COUNT(*) direct_reports,
	e.first_name || ' ' || e.last_name full_name,
	e.job_title, l.city, ROUND(AVG(me.md_salary), 2) avg_managed_salary
FROM managed_employees me
NATURAL JOIN advanced_joins_aggregators.employees e
NATURAL JOIN advanced_joins_aggregators.locations l
GROUP BY full_name, e.job_title, l.city
ORDER BY full_name;



