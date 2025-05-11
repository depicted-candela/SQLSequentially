	-- 4 Hardcore Problem Combining Concepts

-- 		Exercise 4.1: Employee Sales Streak and Monthly Comparison Analysis
-- Problem: For each employee in the ’Sales’ department:
-- 1. Retrieve employee name, metric date, current sales amount.
-- 2. Show previous sales (using LAG) and next sales (using LEAD). Default previous
-- sales to 0 for calculation.
-- 3. Determine if the current sales amount is greater than the previous sales (is increase
-- - boolean).
-- 4. Assign a streak group id. A new streak of increases starts if is increase is true
-- and the previous record was not an increase (or it’s the first record and it’s an
-- increase over 0). This ID should increment for each new streak for an employee.
-- (Hint: sum a marker that is 1 when a streak starts).
-- 5. Calculate the running sales in streak: the cumulative sales amount within the
-- current streak group id for that employee.
-- 6. For each record, show the employee’s average sales amount for the calendar month
-- of that metric date (avg monthly sales for employee).
-- 7. Assign a sales rank overall to each employee based on their highest single sales amount
-- record using DENSE RANK(). This rank should appear on all records for that em-
-- ployee.
-- Order results by employee name, then metric date.
SELECT *,
	CASE
		WHEN
			binary_peaks.is_better = 1 
			AND (
				LAG(binary_peaks.is_better) OVER(PARTITION BY binary_peaks.employee_id ORDER BY binary_peaks.metric_date) = 1
			OR
				LAG(binary_peaks.is_better) OVER(PARTITION BY binary_peaks.employee_id ORDER BY binary_peaks.metric_date) IS NULL
			) THEN SUM(binary_peaks.is_better) OVER(PARTITION BY binary_peaks.employee_id ORDER BY binary_peaks.metric_date) 
		ELSE 0
	END
FROM (
	SELECT
		sq.*,
		CASE
			WHEN 
				((
					LAG(current_sales > previous_sales) OVER(PARTITION BY employee_id ORDER BY metric_date)
				) OR
				(
					LAG(current_sales > previous_sales) OVER (PARTITION BY employee_id ORDER BY metric_date) IS NULL
					OR LAG(current_sales > previous_sales) OVER (PARTITION BY employee_id ORDER BY metric_date) IS FALSE
				)) AND current_sales > previous_sales
			THEN 1
			ELSE 0
		END AS is_better
	FROM (
		SELECT employee_id, employee_name, metric_date, sales_amount current_sales,
			LAG(sales_amount, 1, 0) OVER(PARTITION BY employee_id ORDER BY metric_date) previous_sales,
			LEAD(sales_amount, 1, 0) OVER(PARTITION BY employee_id ORDER BY metric_date) next_sales
		FROM navigate_functions.employee_performance
			WHERE department = 'Sales'
	) AS sq ORDER BY employee_id, metric_date
) AS binary_peaks;


















-- 		Exercise 4.2: Departmental Task Performance Analysis
-- Problem: For each department:
-- 1. Calculate total tasks monthly per employee per month (use DATE TRUNC for month).
-- 2. For each employee’s total tasks monthly, show prev month tasks and next month tasks
-- for that employee. Default to 0 if no data for previous/next month.
-- 3. Calculate mom task change pct (month-over-month percentage change in tasks).
-- Handle NULLs or zero previous month tasks appropriately (e.g., output NULL or
-- 100% if previous was 0 and current is ¿0).
-- 4. Assign feb task rank in dept: a row number to each employee *within their de-
-- partment* based on their total tasks completed in February 2023 (month starting
-- ’2023-02-01’), ordered highest to lowest. This rank should only appear for February
-- data.
-- 5. Identify employees who had at least one month where their total tasks monthly
-- were 20% higher than their department’s average tasks completed for that same
-- month (dept avg tasks monthly). List employee name, month start date, their
-- total tasks monthly, and dept avg tasks monthly for these instances.
-- Order the final result for point 5 by department, employee name, and month.