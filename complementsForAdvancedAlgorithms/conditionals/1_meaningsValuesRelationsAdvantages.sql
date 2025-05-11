		-- 1 Practice Meanings, Values, Relations, Advantages, and Unique Uses
-- 		1.1 Subquery with IN
-- Problem: List the names and salaries of all employees who work in departments located
-- in ’New York’.
-- SELECT emp_name, salary 
-- FROM complementary.employees 
-- WHERE dept_id IN (SELECT dept_id FROM complementary.departments WHERE dept_name = 'New York');

-- 		1.2 Subquery with EXISTS
-- Problem: Find the names of departments that have at least one employee with a salary
-- greater than $85,000.
SELECT * FROM complementary.departments WHERE 