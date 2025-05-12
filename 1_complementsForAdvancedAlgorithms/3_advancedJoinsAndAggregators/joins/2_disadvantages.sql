		-- 1.2 (ii) Practice entirely their disadvantages of all its technical concepts
		
-- 		Exercise 1.2.1: (CROSS JOIN - Disadvantage)
-- Problem: You were asked to get a list of employees and their department names.
-- By mistake, you wrote a query that might produce an extremely large, unintended
-- result if not for the small size of the sample job grades table. Write this problem-
-- atic query using employees and job grades and explain the disadvantage. Then,
-- show how many rows it would produce if employees had 1,000 rows and job grades
-- had 10 rows.
SELECT *  -- Easier to make this for error
FROM advanced_joins_aggregators.employees e, advanced_joins_aggregators.job_grades;
SELECT *  -- Same result than the previous but the word CROSS is more explicit, thus hard
FROM advanced_joins_aggregators.employees  -- to use it for error
CROSS JOIN advanced_joins_aggregators.job_grades;
-- This creates the cartesian product between employees (15) and job_grades () with a size of
-- 75 items. If employees were 1000 and job grades 10: the cartesian product could have 10000
-- items

-- 		Exercise 1.2.2: (NATURAL JOIN - Disadvantage)
-- Problem: The product info natural table and product sales natural table
-- both have product id and common code columns. Demonstrate how using NATURAL
-- JOIN between them can lead to unexpected results or errors if the assumption about
-- common columns is incorrect or changes. Assume you only intended to join on
-- product id. What happens if common code values differ for the same product id
-- or if another common column is added later?
SELECT * 
FROM advanced_joins_aggregators.product_info_natural			-- Prone to errors because two column names
NATURAL JOIN advanced_joins_aggregators.product_sales_natural; 	-- between tables are common, if they're not
										-- dependent the result could be different to the expected behavior
										-- if just one of the columns is desired to be the linking one
