-- Example 3: Common Mistakes
-- Scenario: Misusing ROW_NUMBER when ties matter.

-- Incorrect: Assigning unique IDs to tied sales
-- Correct: Use RANK or DENSE_RANK for ties
SELECT 
  region,
  sales,
  ROW_NUMBER() OVER (ORDER BY sales DESC) AS row_num, -- without meaning
  DENSE_RANK() OVER (ORDER BY sales DESC) AS correct_rank
FROM sales_teams;