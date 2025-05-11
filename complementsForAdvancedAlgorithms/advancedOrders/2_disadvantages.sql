		-- 2 Practice Disadvantages

-- 		Exercise 2.1: Disadvantage of Overly Complex Sorting (Readability/Maintainability)
-- An analyst needs to sort employees using multiple criteria. They constructed the follow-
-- ing ‘ORDER BY‘ clause:
-- ORDER BY department ASC, (CASE WHEN hire date < ’2021-01-01’ THEN 0 ELSE 1
-- END) ASC, salary DESC NULLS LAST, (bonus percentage IS NULL) ASC, last name
-- ASC;
-- While this clause might be functionally correct for a specific complex requirement, what
-- is a general disadvantage of such highly intricate ‘ORDER BY‘ clauses in terms of query
-- development and teamwork, especially when simpler, more direct ”Advanced ORDER
-- BY” features might cover parts of the logic more clearly?

-- These advanced ordering statements make more redable SQL queries

-- 		Exercise 2.2: Disadvantage of Potentially Misleading Prioritization with NULLS FIRST/LAST
-- Imagine a scenario where a report is generated to identify employees eligible for a special
-- program, and a key sorting criterion is ‘bonus percentage‘. If ‘ORDER BY bonus percentage
-- ASC NULLS FIRST‘ is used, and a significant number of employees in the ‘employees‘
-- table have a ‘NULL‘ ‘bonus percentage‘ (perhaps because it’s not applicable or not yet
-- determined), what is a potential disadvantage or misinterpretation that could arise from
-- this sorting strategy?

-- Not unique keys as indicators are unmeaningful
