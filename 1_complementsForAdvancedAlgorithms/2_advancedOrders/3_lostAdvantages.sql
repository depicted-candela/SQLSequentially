		-- 3 Practice Cases of Lost Advantages
		
-- 		Exercise 3.1: Inefficient Simulation of NULLS FIRST
-- A developer needs to list employees, ensuring those with a ‘NULL‘ ‘bonus percentage‘
-- appear first, followed by others sorted by their ‘bonus percentage‘ in ascending order.
-- They implemented this using a ‘CASE‘ statement in the ‘ORDER BY‘ clause:
-- ORDER BY (CASE WHEN bonus percentage IS NULL THEN 0 ELSE 1 END) ASC, bonus percentage
-- ASC;
-- Provide the more direct ”Advanced ORDER BY” equivalent using ‘NULLS FIRST‘. Ex-
-- plain why the direct approach is generally preferred over the ‘CASE‘ statement method
-- for this specific task of handling NULLs in sorting.

SELECT first_name , last_name , department , bonus_percentage
FROM employees
ORDER BY bonus_percentage ASC NULLS FIRST ;

-- 		Exercise 3.2: Inefficient Custom Sort Order Implementation
-- A user wants to display employees with a specific ‘department‘ order: ’Sales’ first, then
-- ’Engineering’, then all other departments alphabetically. Within each of these depart-
-- ment groups, employees should be sorted by ‘salary‘ in descending order. An inefficient
-- approach might involve fetching data for each department group separately and then try-
-- ing to combine them (e.g., using ‘UNION ALL‘ with artificial sort keys). Demonstrate
-- how a single query using ‘CASE‘ within the ‘ORDER BY‘ clause for the custom depart-
-- ment sort, combined with multi-column sorting, is a vastly superior and more efficient
-- solution.

SELECT first_name , last_name , department , salary
FROM employees
ORDER BY
CASE department
WHEN 'Sales' THEN 1
WHEN 'Engineering' THEN 2
ELSE 3
END ASC,
department ASC,
salary DESC ;

