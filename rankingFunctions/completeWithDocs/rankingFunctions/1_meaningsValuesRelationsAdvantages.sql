
-- 1 Basic ROW NUMBER()
-- Assign a unique sequential number to each employee based on their hire date (oldest first).
SELECT first_name, last_name, hire_date, ROW_NUMBER() OVER(ORDER BY hire_date ASC) FROM ranking_functions.employees;

-- 2 Basic RANK()
-- Rank employees based on their salary in descending order. Show how ties are handled (gaps in rank).
SELECT first_name, last_name, salary, RANK() OVER(ORDER BY salary DESC) FROM ranking_functions.employees;
-- There exists gaps in ranks 3, 5, and 11s where orders for 4 does not exists as one gap in rank 3 is occupying it

-- 3 Basic DENSE_RANK()
-- Rank employees based on their salary in descending order using dense ranking. Show how ties are handled differently
-- from RANK() (no gaps in rank).
SELECT first_name, last_name, salary, DENSE_RANK() OVER(ORDER BY salary DESC) FROM ranking_functions.employees;
-- Differently to RANK(), the first repeated rank in 3 does not skips the rank 4, thus ranks 3 and 4 are repeated

-- 4 Comparing ROW NUMBER(), RANK(), DENSE RANK() within partitions
-- For each department, assign a unique row number, rank (with gaps), and dense rank (no gaps) to employees based on their
-- salary in descending order.
SELECT first_name, last_name, salary,
	ROW_NUMBER() OVER(ORDER BY salary DESC), -- Creates unique numbers for each row, thus the ranking is the 'row number'
	RANK() OVER(ORDER BY salary DESC), -- Creates ranks with gaps when orders for the same rank are repeated
	DENSE_RANK() OVER(ORDER BY salary DESC) -- Creates ranks without gaps assuring a continuous range of ranks as ranking
FROM ranking_functions.employees;

-- 5 Advantage - Top N per group
-- Identify the top 2 highest-paid employees in each department.

SELECT
	department, salary, first_name, last_name, rn
FROM
	(
		SELECT
			*, ROW_NUMBER() OVER(PARTITION BY department ORDER BY salary DESC) rn
		FROM
			ranking_functions.employees
	) AS subquery
WHERE rn IN (1, 2)
ORDER BY department, salary DESC;
