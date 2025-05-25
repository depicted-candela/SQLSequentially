		-- 1 Practice Meanings, Values, Relations, and Advantages

-- 		Exercise 1.1: Ordering by Multiple Columns
-- List all employees, ordered primarily by their ‘department‘ alphabetically (A-Z), and
-- secondarily by their ‘salary‘ in descending order (highest salary first within each depart-
-- ment).
SELECT first_name , last_name , department , salary
FROM employees
ORDER BY department ASC , salary DESC ;

-- 		Exercise 1.2: Using NULLS FIRST
-- Display all employees, ordering them by their ‘bonus percentage‘. Employees who do not
-- have a ‘bonus percentage‘ specified (which are stored as ‘NULL‘ in the ‘bonus percentage‘
-- column) should appear at the top of the list. For employees with non-NULL bonus
-- percentages, they should be sorted in ascending order of their bonus.
SELECT first_name , last_name , department , bonus_percentage
FROM employees
ORDER BY bonus_percentage ASC NULLS FIRST ;

-- 		Exercise 1.3: Using NULLS LAST and Multiple Columns
-- List all employees from the ’Engineering’ department, ordered first by their ‘hire date‘
-- in ascending order (earliest first). If multiple employees share the same ‘hire date‘,
-- those with a ‘NULL‘ ‘bonus percentage‘ should be listed after those with a non-NULL
-- ‘bonus percentage‘. Among those with non-NULL bonus percentages on the same ‘hire date‘,
-- sort by ‘bonus percentage‘ in descending order (highest bonus first).
SELECT first_name , last_name , hire_date , bonus_percentage
FROM employees
WHERE department = 'Engineering'
ORDER BY hire_date ASC , bonus_percentage DESC NULLS LAST ;