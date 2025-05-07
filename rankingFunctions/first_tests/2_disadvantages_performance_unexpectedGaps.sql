-- Example 2: Disadvantages (Performance, Unexpected Gaps)
-- Scenario: Ranking 100,000 rows without optimization.


-- DDL
-- CREATE TABLE ranking_functions.large_sales (
--   sale_id SERIAL PRIMARY KEY,
--   region VARCHAR(20),
--   sales NUMERIC(10,2)
-- );

-- Insert 100,000 rows with random data
-- INSERT INTO ranking_functions.large_sales (region, sales)
-- SELECT 
--   CASE WHEN random() < 0.5 THEN 'North' ELSE 'South' END,
--   (random() * 200000 + 50000)::NUMERIC(10,2)
-- FROM generate_series(1, 100000);

-- SELECT * FROM ranking_functions.large_sales;

-- EXPLAIN ANALYZE
-- SELECT *, RANK() OVER (ORDER BY sales) 	-- This consumes 2x more time than the Window partitionated by a
--											-- categorical column (region) in planning time because sort
-- FROM ranking_functions.large_sales;		-- nesting things and dont treat every row (region) as a category in
--											-- itself. And is slighty slower (2.22%) than the partitionated one
--											-- because his hashing is know (categories of size 1 in sales)
--											-- thus faster than te partitioned approach but with a highly
--											-- not meaningful hash

-- EXPLAIN ANALYZE
-- SELECT region, RANK() OVER (PARTITION BY region ORDER BY sales)
-- FROM ranking_functions.large_sales;

-- DROP INDEX IF EXISTS ranking_functions.idx_region_for_large_sales;

-- The most efficient solution is this because of now is not only focused raking in a categorical variable
-- is also about a hashed group made on the categorical variable (region): 20% faster than the approach two without
-- categorical variable labeled (region)
CREATE INDEX idx_region_for_large_sales ON ranking_functions.large_sales(region);
EXPLAIN ANALYZE
SELECT *, RANK() OVER (PARTITION BY region ORDER BY sales)
FROM ranking_functions.large_sales;