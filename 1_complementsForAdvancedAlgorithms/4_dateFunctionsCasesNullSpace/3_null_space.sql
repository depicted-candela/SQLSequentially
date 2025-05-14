		-- 3 Null Space (Complementary SQL)
-- Concepts: NULLIF, NULL handling in aggregations, NULL handling in sorting.


-- 	(i) Meaning, values, relations, advantages of unique usage

-- 		Exercise 3.1: Safe Bonus Calculation Using NULLIF
-- Problem: Calculate a bonus as salary * 0.10 / performance rating. If performance rating
-- is 0 (hypothetically, though our check is 1-5 or NULL), this would cause a division by
-- zero. Use NULLIF to make performance rating NULL if it’s 0 (for our data, adapt this
-- to use a rating of 1 as the value to nullify for this example, as ’0’ is not a valid rating per
-- check constraint). Calculate salary * 0.10 / NULLIF(performance rating, 1).
SELECT
	emp_id,
	(salary * 0.1) / NULLIF(performance_rating, 1) bonus_salary
FROM advanced_dates_cases_and_null_space.employees;

-- 		Exercise 3.2: Average Billing Rate Excluding Internal/Non-Billable Roles
-- Problem: The employee projects table has a billing rate which can be NULL (e.g.,
-- for internal roles like ’HR Coordinator’). Calculate the average billing rate across all
-- project assignments. Show the query and discuss how AVG() handles the NULL billing
-- rates and why this is usually correct.
SELECT
	AVG(billing_rate) standard_avg,
	SUM(billing_rate) / COUNT(billing_rate) grained_avg,
	SUM(COALESCE(billing_rate, 0)) / COUNT(COALESCE(billing_rate, 0)) avg2, -- Granular solutions when null
	project_id, COUNT(emp_id) total_employees,								-- billing rates are 0 
	COUNT(billing_rate) billing_rates, COUNT(emp_id) = COUNT(billing_rate) billing_rates_as_employees
FROM advanced_dates_cases_and_null_space.employee_projects
GROUP BY project_id; -- As you can check, the billing rates are not always the same but AVG does not count
-- the number of null values in the ratio for the AVG. Despite this is not the case, could be that null values
-- should be trated as 0 values as shown in avg2

-- 		Exercise 3.3: Listing Projects by Actual End Date, Undefined Last
-- Problem: List all projects, showing their name and actual end date. Sort them by
-- actual end date ascending, but projects that are not yet completed (NULL actual end date)
-- should appear last.
SELECT * 
FROM advanced_dates_cases_and_null_space.projects
ORDER BY actual_end_date NULLS LAST;


-- (ii) Disadvantages of all its technical concepts

-- 		Exercise 3.4: NULLIF with Unintended Type Coercion or Comparison Issues
-- Problem: Suppose performance rating was a VARCHAR column and could contain
-- ’N/A’ or be NULL. A user tries NULLIF(performance rating, 0) (comparing string to
-- integer). Discuss potential issues like type coercion errors or unexpected behavior if the
-- database attempts implicit conversion. Provide a small hypothetical example if necessary
-- to illustrate.
-- Answer: sometimes people create bad designed databases where characters are used to store
-- numerical values, for example, to avoid the work to replace bad stored data in an excel filled
-- in a column with numerical values, 'N/A' and characters representing numbers the database maintainer
-- could create a column in a table with VARCHAR as the data type. If the data type does not coincide with
-- the given null value for the desired datatype all could not have any sense despite data type coercion
-- is possible.

-- 		Exercise 3.5: Aggregates over Mostly NULL Data Yielding Misleading Results
-- Problem: If a department has 10 employees, but only 1 has a performance rating (e.g.,
-- 5), and the rest are NULL. AVG(performance rating) would be 5. While mathemati-
-- cally correct by definition (ignores NULLs), this could be misleading if presented without
-- context of how many were rated. Write a query for a department (e.g., ’Human Re-
-- sources’) showing average rating, total employees, and rated employees, and discuss this
-- ”disadvantage” (it’s more a data interpretation issue).
SELECT
	AVG(billing_rate) standard_avg,
	SUM(COALESCE(billing_rate, 0)) / COUNT(COALESCE(billing_rate, 0)) real_avg,
	COUNT(billing_rate) billing_rates,
	COUNT(emp_id) = COUNT(billing_rate) billing_rates_as_employees
FROM advanced_dates_cases_and_null_space.employee_projects ep
NATURAL JOIN advanced_dates_cases_and_null_space.projects p
NATURAL JOIN advanced_dates_cases_and_null_space.departments d
WHERE d.dept_name = 'Human Resources';


-- 	(iii) Practice entirely cases where people in general does not use
-- these approaches losing their advantages, relations and values
-- because of the easier, basic, common or easily understandable
-- but highly inefficient solutions

-- 		Exercise 3.6: Using CASE WHEN expr = val THEN NULL ELSE expr END instead of
-- NULLIF(expr, val)
-- Problem: A user wants to convert reason text in leave requests to NULL if it’s an empty
-- string ’’. They write SELECT CASE WHEN reason = ’’ THEN NULL ELSE reason END
-- .... Show this verbose CASE method for the employee ’Kevin McCallister’ (who has an
-- empty reason) and then show how NULLIF is more concise for this.
SELECT CASE WHEN reason = '' THEN NULL ELSE reason END 
FROM advanced_dates_cases_and_null_space.leave_requests
NATURAL JOIN advanced_dates_cases_and_null_space.employees
WHERE emp_name = 'Kevin McCallister';

SELECT NULLIF(reason, '')
FROM advanced_dates_cases_and_null_space.leave_requests
NATURAL JOIN advanced_dates_cases_and_null_space.employees
WHERE emp_name = 'Kevin McCallister';
