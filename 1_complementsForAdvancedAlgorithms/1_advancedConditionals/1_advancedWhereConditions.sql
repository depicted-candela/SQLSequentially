		-- 1 Practice Meanings, Values, Relations, Advantages, and Unique Uses
-- 		1.1 Subquery with IN
-- Problem: List the names and salaries of all employees who work in departments located
-- in ’New York’.
SELECT emp_name, salary 
FROM complementary.employees 
WHERE dept_id IN (SELECT dept_id FROM complementary.departments WHERE dept_name = 'New York');

-- 		1.2 Subquery with EXISTS
-- Problem: Find the names of departments that have at least one employee with a salary
-- greater than $85,000.
SELECT * 
FROM complementary.departments d 
WHERE EXISTS (SELECT 1 FROM complementary.employees e WHERE salary > 85000 AND d.dept_id = d.dept_id);

-- 		1.3 Subquery with ANY
-- Problem: List employees whose salary is greater than any salary in the ’Support’ de-
-- partment. (This means their salary is greater than the minimum salary in the ’Support’
-- department).
SELECT *
FROM complementary.employees e1
WHERE salary > ANY (SELECT salary
FROM complementary.employees e2
JOIN complementary.departments d
	ON d.dept_name = 'Support' AND e2.dept_id = d.dept_id);

-- 		1.4 Subquery with ALL
-- Problem: Find employees in the ’Sales’ department whose salary is less than all salaries
-- in the ’Technology’ department.
SELECT * 
FROM complementary.employees e1 
JOIN complementary.departments d1 ON d1.dept_name = 'Sales' AND e1.dept_id = d1.dept_id
WHERE salary < ALL (
	SELECT salary
	FROM complementary.employees e2 
	JOIN complementary.departments d2 ON d2.dept_name = 'Technology' AND e2.dept_id = d2.dept_id
);

-- 		1.5 IS DISTINCT FROM
-- Problem: List employees whose performance rating is different from 3. This list
-- should include employees who have a NULL performance rating (as NULL is distinct
-- from 3).
SELECT * FROM complementary.employees WHERE performance_rating IS DISTINCT FROM 3;

-- 		1.6 IS NOT DISTINCT FROM
-- Problem: Find pairs of employees (display their names) who have the exact same
-- manager id, including cases where both employees have no manager (i.e., their manager id
-- is NULL). Avoid listing an employee paired with themselves.
SELECT e1.emp_name emp1, e2.emp_name emp2, e2.manager_id
FROM complementary.employees e1
JOIN complementary.employees e2
ON e1.emp_id < e2.emp_id
WHERE e2.manager_id IS NOT DISTINCT FROM e1.manager_id;
