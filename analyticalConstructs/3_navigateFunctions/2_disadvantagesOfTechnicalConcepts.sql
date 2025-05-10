		-- 2 Practice Disadvantages of Technical Concepts

-- 		Exercise 2.1: Handling NULLs from LAG at Partition Boundaries
-- Problem: For each performance record, show the employee name, metric date, current
-- sales amount, and the sales amount from the previous record. Calculate the difference
-- (current sales - previous sales). Observe the NULLs for the first record of each employee
-- and how it affects the difference calculation. Order by employee name, then metric date.

-- SELECT *, sq.current_sales - sq.previous_sales lag_difference
-- FROM (
-- 	SELECT employee_name, metric_date, sales_amount current_sales,
-- 	(LAG(sales_amount, 1) OVER(ORDER BY metric_date)) previous_sales
-- 	FROM navigate_functions.employee_performance
-- ) AS sq ORDER BY employee_name, metric_date;   -- Null is reproduced in lag_difference

-- 		Exercise 2.2: Impact of Incorrect ORDER BY in OVER()
-- Clause
-- Problem: Display ’Alice Smith’s performance records showing her metric date, tasks
-- completed, and next tasks correct order (tasks from the next chronological record).
-- Then, show next tasks incorrect order by mistakenly using ORDER BY metric date
-- DESC in the LEAD function’s OVER() clause. Observe how next tasks incorrect order
-- now represents the tasks from the *previous* chronological record.

-- SELECT metric_date, tasks_completed, LEAD(tasks_completed) OVER(ORDER BY metric_date DESC)
-- FROM navigate_functions.employee_performance 
-- WHERE employee_name = 'Alice Smith' ORDER BY metric_date DESC; 	-- Clearly the query is counterintuitive,
-- 																-- for a counterintuitive query

-- 		Exercise 2.3: Impact of Omitting PARTITION BY
-- Problem: For ’Bob Johnson’, retrieve his metric date, sales amount, and the previous sales amount
-- (using LAG partitioned by employee id). Also retrieve previous sales amount unpartitioned
-- (using LAG *without* PARTITION BY employee id, but still ordered by employee id,
-- metric date globally to ensure some row comes before Bob if not partitioned). Compare
-- the previous sales amount unpartitioned for Bob’s first record (’2023-01-08’) with
-- previous sales amount partitioned.

SELECT metric_date, sales_amount,
LAG(sales_amount) OVER(PARTITION BY employee_id ORDER BY metric_date),
LAG(sales_amount) OVER(ORDER BY employee_id)
FROM navigate_functions.employee_performance 		-- The result is the same because a partition over
WHERE employee_name = 'Bob Johnson'					-- an independent space (employee_id) is the same to
ORDER BY metric_date;								-- an ordering. This leads to two ways to do the same,
													-- misleading concepts up to confusion


