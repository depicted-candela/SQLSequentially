-- Example 4: Inefficient Alternatives
-- Scenario: Using subqueries instead of ranking functions.

-- -- First, drop existing table if needed
-- DROP TABLE IF EXISTS ranking_functions.sales_leaderboard;

-- -- Create enhanced table with sale_date
-- CREATE TABLE ranking_functions.sales_leaderboard (
--   salesperson VARCHAR(20),
--   region VARCHAR(10),
--   revenue INT,
--   sale_date DATE
-- );

-- -- Insert data with proper dates (spanning 6 months)
-- INSERT INTO ranking_functions.sales_leaderboard VALUES
-- ('Alice', 'West', 50000, '2023-01-15'),
-- ('Bob', 'West', 50000, '2023-02-20'),
-- ('Charlie', 'East', 30000, '2023-01-10'),
-- ('Diana', 'East', 70000, '2023-03-05'),
-- ('Eve', 'East', 70000, '2023-03-10'),
-- ('Frank', 'North', 90000, '2023-04-18'),
-- ('Grace', 'North', 60000, '2023-05-22'),
-- ('Henry', 'South', 40000, '2023-06-30'),
-- ('Ivy', 'South', 55000, '2023-02-28'); 

SELECT  
	s1.*,
    (
	    SELECT COUNT(*) + 1  
	    FROM ranking_functions.sales_leaderboard s2  
	    WHERE s2.region = s1.region  
	    AND s2.revenue > s1.revenue
    ) AS manual_rank, -- Naive approach (Inefficient because it needs to always compare each row with all the rest of rows).
    RANK() OVER (PARTITION BY s1.region ORDER BY s1.revenue DESC) smart_rank	-- Smart approach (Ranked efficiently because
FROM ranking_functions.sales_leaderboard s1										-- ranks using categorical variables and)
ORDER BY region, smart_rank;													-- then orders efficiently continuous vars
																				-- within each category, thus the number of
																				-- operations decreases.