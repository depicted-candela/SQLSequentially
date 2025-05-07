-- 2. Practice Disadvantages of Technical Concepts

-- 		1. Misinterpretation of RANK() vs DENSE_RANK() for Nth distinct value
-- Problem: A manager wants to identify all employees who are in the top 2 distinct
-- salary tiers within the company. Demonstrate this by comparing results from RANK()
-- and DENSE_RANK(). Specifically, if the requirement is ”employees in the 4th highest
-- salary tier company-wide”, show how using RANK() = 4 might yield no results, while
-- DENSE RANK() = 4 would correctly identify them.
-- SELECT 
-- 	first_name,
-- 	last_name,
-- 	rank_,
-- 	dense_rank_
-- FROM
-- 	ranking_functions.employees r1
-- JOIN 
-- 	(
-- 		SELECT
-- 			employee_id,
-- 			RANK() OVER(ORDER BY salary) AS rank_,
-- 			DENSE_RANK() OVER(ORDER BY salary) AS dense_rank_
-- 		FROM
-- 			ranking_functions.employees
-- 	) AS r2
-- ON r1.employee_id = r2.employee_id
-- WHERE r2.rank_ = r2.dense_rank_; 	-- Note how just appear the first rank because gaps disalign all the 
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

SELECT
	*
FROM
(
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY department ORDER BY salary DESC) row_number_
	FROM
		ranking_functions.employees
) AS subquery
WHERE row_number_ = 1
ORDER BY hire_date ASC;








