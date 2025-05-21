		-- 2 Practice Disadvantages and Potential Pitfalls

-- 		Exercise ii.1: Loss of Detail with Average
-- Problem: Calculate the average salary for the ’Engineering’ department. What specific
-- salary information is lost when you only look at this average?
SELECT
	D.*,
	AVG_S.AVG
FROM
	AGGREGATE_FUNCTIONS.DEPARTMENTS AS D
	JOIN (
		SELECT
			DEPARTMENT_ID,
			AVG(SALARY)
		FROM
			AGGREGATE_FUNCTIONS.EMPLOYEES
		GROUP BY
			DEPARTMENT_ID
	) AS AVG_S ON D.DEPARTMENT_ID = AVG_S.DEPARTMENT_ID
WHERE
	D.DEPARTMENT_NAME = 'Engineering';

-- 		Exercise ii.2: Misleading Aggregate without GROUP BY
-- Problem: Consider the query SELECT department id, MAX(salary) FROM employees;.
-- Why might this query be misleading or incorrect if the user intends to find the maximum
-- salary for each department? What is the potential pitfall?

-- Despite is logical to think such query getting the max salary for each department it's ambiguous because
-- the query could be used also for printing the id and the maximum salary for all departments in all ids.
-- That's why the query returns an error, because it's ambiguous is necessary a clause for aggregation: GROUP BY

-- 		Exercise ii.3: NULL Handling in AVG()
-- Problem: Calculate the average bonus percentage for all employees. How does AVG()
-- handle NULL values in bonus percentage, and how could this be misleading if not un-
-- derstood?

SELECT AVG(salary) FROM aggregate_functions.employees; -- Treats NULL as nothing, then skips it, if the the logic
-- of the system stores NULL when is 0, then such skips are problematic because the average is sum()/n where n counts
-- even when the data is 0

-- 		Exercise ii.4: Aggregate in WHERE Clause
-- Problem: A manager wants to find departments where the average employee performance
-- rating is below 3.5. They try to write: SELECT department id, AVG(performance rating)
-- FROM employees WHERE AVG(performance rating) < 3.5 GROUP BY department id;.
-- Why will this query fail, and what is the disadvantage or common mistake illustrated
-- here regarding aggregate function placement?

-- In such cases must be used HAVING
SELECT department_id, AVG(performance_rating)
FROM aggregate_functions.employees
GROUP BY department_id
HAVING AVG(performance_rating) < 3.5;



