		-- 3 Practice Cases of Inefficient Alternatives

		
-- 		Exercise 3.1: Efficiently Finding Previous Sales Amount
-- Problem: For each employee performance record, find the sales amount from their
-- immediately preceding record. Using LAG is efficient. An inefficient alternative might
-- involve a correlated subquery to find the metric date less than the current metric date
-- for the same employee, and then another subquery or join to retrieve the sales amount
-- for that found date, which is more complex and typically slower. Display employee name,
-- metric date, current sales, and previous sales using both the inefficient and efficient (LAG)
-- ways.

 WITH subquery AS (
 	SELECT
 		perf_id, employee_id, metric_date, sales_amount,
 		DENSE_RANK() OVER(PARTITION BY employee_id ORDER BY metric_date) ranking
 	FROM navigate_functions.employee_performance
 )

 SELECT s1.*, s2.sales_amount previous_sales
 FROM subquery s1 JOIN subquery s2 ON s1.employee_id = s2.employee_id AND s1.ranking = s2.ranking - 1;

 SELECT employee_id, employee_name, metric_date, sales_amount current_sales,
 LAG(sales_amount) OVER(PARTITION BY employee_id ORDER BY metric_date ASC) previous_sales
 FROM navigate_functions.employee_performance ORDER BY employee_id, metric_date ASC;


-- 		Exercise 3.2: Efficiently Finding the Date of the Next Record
-- Problem: For each employee performance record, find the metric date of their next
-- performance record. Using LEAD is efficient. An inefficient alternative could be a corre-
-- lated subquery like (SELECT MIN(ep2.metric date) FROM EmployeePerformance ep2
-- WHERE ep2.employee id = ep1.employee id AND ep2.metric date > ep1.metric date).
-- Display employee name, current metric date, and the next metric date using the efficient
-- LEAD function.

 SELECT employee_id, employee_name, sales_amount, metric_date current_date_,
 LEAD(metric_date) OVER(PARTITION BY employee_id ORDER BY metric_date ASC) next_date
 FROM navigate_functions.employee_performance ORDER BY employee_id, current_date_;


-- 		Exercise 3.3: Identifying Sales Increases Efficiently
-- Problem: Identify all performance records where an employee’s sales amount was
-- greater than their sales amount in the immediately preceding record for that same em-
-- ployee. Using LAG within a Common Table Expression (CTE) or subquery, followed by
-- a WHERE clause, is efficient. Inefficient methods could involve complex self-joins and date
-- logic to identify and compare with the correct previous record. Display the employee
-- name, metric date, current sales, previous sales, and mark if it’s an increase.

SELECT sq.*, current_sales > previous_sales is_better FROM (
	SELECT employee_id, employee_name, metric_date, sales_amount current_sales,
	LAG(sales_amount) OVER(PARTITION BY employee_id ORDER BY metric_date) previous_sales
	FROM navigate_functions.employee_performance ORDER BY employee_id, metric_date
) AS sq WHERE current_sales > previous_sales;