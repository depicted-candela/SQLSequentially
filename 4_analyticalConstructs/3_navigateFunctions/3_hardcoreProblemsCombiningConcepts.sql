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
-- record using DENSE_RANK(). This rank should appear on all records for that em-
-- ployee.
-- Order results by employee name, then metric date.
-- WITH RECURSIVE slicer AS (
-- 	SELECT employee_id, employee_name, metric_date, sales_amount current_sales,
-- 		LAG(sales_amount, 1, 0) OVER(PARTITION BY employee_id ORDER BY metric_date) previous_sales,
-- 		LEAD(sales_amount, 1, 0) OVER(PARTITION BY employee_id ORDER BY metric_date) next_sales
-- 	FROM analytical_cons_navigate_functions.employee_performance
-- 	WHERE department = 'Sales'
-- ), binary_peaks AS (
-- 	SELECT
-- 	    slicer.*,
-- 	    (current_sales > previous_sales) AS is_better
-- 	FROM slicer ORDER BY employee_id, metric_date
-- ), identified_peaks AS (
-- 	SELECT *, ROW_NUMBER() OVER(ORDER BY employee_id, metric_date) - 1 peak_id FROM binary_peaks
-- ), recursive_grouping AS (
-- 	SELECT employee_id, is_better, peak_id, 0 AS streak_group_id
-- 	FROM identified_peaks WHERE peak_id = 0
-- 		UNION ALL
-- 	SELECT ip.employee_id, ip.is_better, ip.peak_id,
-- 		CASE
-- 			WHEN ip.is_better IS TRUE AND rg.is_better IS TRUE THEN rg.streak_group_id
-- 			WHEN ip.is_better IS FALSE AND rg.is_better IS TRUE THEN rg.streak_group_id + 1
-- 			ELSE rg.streak_group_id
-- 		END streak_group_id
-- 	FROM identified_peaks ip
-- 	JOIN recursive_grouping rg ON ip.peak_id = rg.peak_id + 1
-- ), grouped_for_rankings AS (
-- 	SELECT 
-- 		peak_id, employee_id, employee_name, metric_date, 
-- 		current_sales, previous_sales, next_sales, is_better, streak_group_id,
-- 		CASE WHEN is_better IS TRUE THEN streak_group_id ELSE NULL END grouped_peaks
-- 	FROM recursive_grouping NATURAL JOIN identified_peaks
-- ), ranked_peaks AS (
-- 	SELECT *, 
-- 		DENSE_RANK() OVER(PARTITION BY employee_id, grouped_peaks ORDER BY metric_date) peak,
-- 		SUM(current_sales) OVER(PARTITION BY employee_id, grouped_peaks ORDER BY metric_date) cumulative_sales
-- 	FROM grouped_for_rankings 
-- 	WHERE grouped_peaks IS NOT NULL
-- )
-- SELECT 
-- 	g.employee_id, g.employee_name, g.metric_date, g.current_sales,
-- 	g.previous_sales, g.next_sales, g.is_better, r.streak_group_id, cumulative_sales, l.*, 
-- 	DENSE_RANK() OVER(PARTITION BY g.employee_id ORDER BY g.current_sales) sales_rank_overall
-- FROM grouped_for_rankings g 
-- LEFT JOIN ranked_peaks r USING(peak_id), 
-- LATERAL(
-- 	SELECT ROUND(AVG(sales_amount), 2) avg_monthly_sales_for_employee
-- 	FROM analytical_cons_navigate_functions.employee_performance ep
-- 	WHERE ep.employee_id = g.employee_id AND DATE_TRUNC('month', ep.metric_date) = DATE_TRUNC('month', g.metric_date)
-- ) l ORDER BY g.employee_name, g.metric_date;


-- 		Exercise 4.2: Departmental Task Performance Analysis
-- Problem: For each department:
-- 1. Calculate total tasks monthly per employee per month (use DATE_TRUNC for month).
-- 2. For each employee’s total tasks monthly, show prev month tasks and next month tasks
-- for that employee. Default to 0 if no data for previous/next month.
-- 3. Calculate mom_task_change_pct (month-over-month percentage change in tasks).
-- Handle NULLs or zero previous month tasks appropriately (e.g., output NULL or
-- 100% if previous was 0 and current is > 0).
-- 4. Assign feb_task_rank_in_dept: a row number to each employee *within their de-
-- partment* based on their total tasks completed in February 2023 (month starting
-- ’2023-02-01’), ordered highest to lowest. This rank should only appear for February
-- data.
-- 5. Identify employees who had at least one month where their total tasks monthly
-- were 20% higher than their department’s average tasks completed for that same
-- month (dept avg tasks monthly). List employee name, month start date, their
-- total tasks monthly, and dept avg tasks monthly for these instances.
-- Order the final result for point 5 by department, employee name, and month.
WITH EmployeeMonthlyTasked AS (
	SELECT 
		employee_id, 
		EXTRACT(YEAR FROM DATE_TRUNC('month', metric_date)) as y, 
		EXTRACT(MONTH FROM DATE_TRUNC('month', metric_date)) as m, 
		SUM(tasks_completed) totalMonthlyTasks
	FROM analytical_cons_navigate_functions.employee_performance
	GROUP BY employee_id, DATE_TRUNC('month', metric_date)
), SequentialTotalMonthlyTasks AS (
	SELECT 
		*, 
		LAG(totalMonthlyTasks) OVER(PARTITION BY employee_id ORDER BY y, m) previousmonthlytasks,
		LEAD(totalMonthlyTasks) OVER(PARTITION BY employee_id ORDER BY y, m) nextmonthlytasks,
		ROW_NUMBER() OVER(PARTITION BY employee_id ORDER BY y, m) ranking
	FROM EmployeeMonthlyTasked
), MonthlyPercentageChange AS (
	SELECT *
	FROM SequentialTotalMonthlyTasks s1, LATERAL(
		SELECT ROUND(s2.totalMonthlyTasks::NUMERIC / s2.previousmonthlytasks, 2) * 100 mom_task_change_pct 
		FROM SequentialTotalMonthlyTasks s2 WHERE s1.employee_id = s2.employee_id AND s1.ranking = s2.ranking
	) l
), FebruaryRanking AS (
	SELECT employee_id, department, ROW_NUMBER() OVER(PARTITION BY department ORDER BY total_tasks_completed) feb_task_rank_in_dept FROM (
		SELECT employee_id, department, SUM(tasks_completed) total_tasks_completed
		FROM analytical_cons_navigate_functions.employee_performance
		WHERE EXTRACT(MONTH FROM metric_date) = 2
		GROUP BY department, employee_id
	) sq
), AvgDepartmentalTasks AS ( 
	SELECT department, AVG(tasks_completed) avg_tasks_completed
	FROM analytical_cons_navigate_functions.employee_performance i
	GROUP BY department
), EmployeeMonthlyPerformance AS (
    SELECT
        o.employee_id,
        o.employee_name,
        o.department,
        o.tasks_completed,
        o.metric_date,
        i.avg_tasks_completed
    FROM
        analytical_cons_navigate_functions.employee_performance o
    JOIN
        AvgDepartmentalTasks i ON o.department = i.department
), SuperMonths AS (
    SELECT
        emp.employee_id,
        emp.employee_name,
        emp.department,
        TO_CHAR(emp.metric_date, 'YYYY-MM') AS qualifying_month_year
    FROM
        EmployeeMonthlyPerformance emp
    WHERE
        emp.tasks_completed > emp.avg_tasks_completed * 1.2 
)

-- Point 5
SELECT
    sm.department,
    sm.employee_id,
    sm.employee_name,
    TRUE AS is_super,
    ARRAY_AGG(DISTINCT sm.qualifying_month_year ORDER BY sm.qualifying_month_year) AS months_meeting_condition
FROM
    SuperMonths sm
GROUP BY
    sm.department, sm.employee_id, sm.employee_name
ORDER BY
    sm.department, sm.employee_name;

