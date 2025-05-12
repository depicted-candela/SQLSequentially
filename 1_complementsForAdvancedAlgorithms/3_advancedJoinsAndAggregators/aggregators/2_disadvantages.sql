		-- 2.2 (ii) Practice entirely their disadvantages of all its technical concepts

-- 		Exercise 2.2.1: (COUNT(DISTINCT column) - Disadvantage)
-- Problem: Explain a potential performance disadvantage of using COUNT(DISTINCT
-- column) on a very large table, especially if the column is not well-indexed or has
-- high cardinality. Why might it be slower than COUNT(*)?
-- Response:
-- 		* If the table is not indexed the amount of comparisons to couunt all the different values grows exponentially
-- 		* If the table is indexed with a high cardinality the condition in the previous option happens again
-- 
-- 		Exercise 2.2.2: (FILTER clause - Disadvantage)
-- Problem: While the FILTER clause is standard SQL, what could be a practical
-- disadvantage if you are working with an older version of a specific RDBMS that
-- doesn’t support it, or if you need to write a query that is portable across RDBMS
-- versions, some of which might not support FILTER? What would be the alternative
-- in such cases?
--Response: I would use cases

