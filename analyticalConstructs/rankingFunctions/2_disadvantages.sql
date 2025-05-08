-- 2. Practice Disadvantages of Technical Concepts

-- 		1. Misinterpretation of RANK() vs DENSE_RANK() for Nth distinct value
-- Problem: A manager wants to identify all employees who are in the top 2 distinct
-- salary tiers within the company. Demonstrate this by comparing results from RANK()
-- and DENSE_RANK(). Specifically, if the requirement is ”employees in the 4th highest
-- salary tier company-wide”, show how using RANK() = 4 might yield no results, while
-- DENSE RANK() = 4 would correctly identify them.
SELECT 
	first_name,
	last_name,
	rank_,
	dense_rank_
FROM
	ranking_functions.employees r1
JOIN 
	(
		SELECT
			employee_id,
			RANK() OVER(ORDER BY salary) AS rank_,
			DENSE_RANK() OVER(ORDER BY salary) AS dense_rank_
		FROM
			ranking_functions.employees
	) AS r2
ON r1.employee_id = r2.employee_id
WHERE r2.rank_ = r2.dense_rank_; 	-- Note how just appear the first rank because gaps disalign all the 
									-- underlying ranks because rank perform its logic with categorical ranking
									-- that weights a degree of ranking with the same categorical value with
									-- the number of occurences of each rank: 1, 1, 3, 3, 5, 6 (weight 2 for
									-- rankings 1 and 3; weight 1 for 5 and 6), instead dense_rank uses
									-- continuous rankings (without weights): 1, 1, 2, 2, 3.
									-- Thus when the first rank with weight different of 1, both ranks start
									-- to be disaligned forever


--		2. Potential for confusion with complex ORDER BY in window definition
-- Problem: Employees are ranked within their department by salary (descending). For
-- employees with the same salary, their secondary sort key is hire date (ascending, earlier
-- hire gets better rank). Show this ranking using ROW_NUMBER(). Then, demonstrate how if
-- the secondary sort key (hire date) was mistakenly ordered descending, it would change
-- the row numbers for tied-salary employees, potentially leading to incorrect ”top” employee
-- identification if the secondary sort was critical for tie-breaking. Focus on employees in
-- departments and salary groups where ties exist.

SELECT * FROM
	(
		SELECT 
			*,
			ROW_NUMBER() OVER(PARTITION BY department ORDER BY salary DESC, hire_date ASC) row_number_
		FROM											-- Correct separation of concerns using different ordering
			ranking_functions.employees					-- ways within the ORDER BY clause making hire_date specifically
	) AS subquery										-- ascendant
ORDER BY department, row_number_;

SELECT * FROM
	(
		SELECT 
			*,
			ROW_NUMBER() OVER(PARTITION BY department ORDER BY salary, hire_date DESC) row_number_
		FROM
			ranking_functions.employees					-- Without separations of concerns not using different ordering
	) AS subquery										-- ways within the ORDER BY clause of the window where it's
ORDER BY department, row_number_ ASC;					-- possible to separate them to get the expected result.
														-- Despite changing ASC with DESC in the last ORDER BY statement
														-- as a solution to get the expected result, it's not straightforward


-- 		3. Conceptual disadvantage - Readability with many window functions
-- Problem: Display each employee’s salary, their salary rank within their department,
-- their overall salary rank in the company (dense), and a row number based on alphabetical
-- order of their full name (last name, then first name). The query itself will demonstrate
-- how multiple window functions can make the SELECT clause dense.

SELECT 
	*,
	RANK() OVER(PARTITION BY department ORDER BY salary DESC) dept_salary_ranking,
	DENSE_RANK() OVER(ORDER BY salary DESC) tot_salary_ranking,
	ROW_NUMBER() OVER(ORDER BY first_name, last_name ASC) by_name
FROM
	ranking_functions.employees
ORDER BY
	department, dept_salary_ranking, tot_salary_ranking, by_name DESC;

-- To understand this result is necessary highly strong focus if the meaning of tot_salary_ranking is
-- to obtain orderly the ranking of salary in the company in the order of salary ordered by department.
-- What's the meaning of it? Because such SQL queries are too complex, rare, and highly focus demanding
-- is not the case to see mixes different rankings methods using different variables.



