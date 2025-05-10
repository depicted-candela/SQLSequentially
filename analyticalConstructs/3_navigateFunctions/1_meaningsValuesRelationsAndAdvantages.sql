		-- 1 Practice Meanings, Values, Relations, and Advantages

-- 		Exercise 1.1: Next Sales Amount Per Employee
-- Problem: For each performance record, display the employee’s name, metric date, cur-
-- rent sales amount, and the sales amount from their immediate next performance record.
-- Order results by employee name and then by metric date.

-- SELECT employee_name, metric_date, sales_amount current_sales, LEAD(sales_amount) OVER(ORDER BY metric_date) next_sales
-- FROM navigate_functions.employee_performance ORDER BY employee_name, metric_date;

-- 		Exercise 1.2: Previous Tasks Completed Per Employee within
-- Department with Default
-- Problem: For each performance record, display the department, employee name, metric
-- date, current tasks completed, and the tasks completed from their immediate previous
-- performance record within the same department. If there is no previous record for that
-- employee in that department, display 0 for previous tasks. Order results by department,
-- employee name, and metric date.

-- SELECT department, employee_name, metric_date, tasks_completed current_task,
-- LAG(tasks_completed, 1, 0) OVER(ORDER BY metric_date) next_task
-- FROM navigate_functions.employee_performance
-- ORDER BY department, employee_name, metric_date;

-- 		Exercise 1.3: Sales Lookback and Lookahead for a Specific
-- Employee
-- Problem: For ’Alice Smith’, display her metric date, current sales amount, the sales
-- amount from two performance records prior, and the sales amount from two performance
-- records ahead. If such prior or ahead records do not exist, their values should be NULL.
-- Order by metric date.

-- SELECT metric_date, sales_amount current_sales,
-- LAG(sales_amount, 2) OVER(ORDER BY metric_date) two_previous_sales,
-- LEAD(sales_amount, 2) OVER(ORDER BY metric_date) two_next_sales
-- FROM navigate_functions.employee_performance WHERE employee_name = 'Alice Smith';

-- 		Exercise 1.4: Date of Next Performance Entry
-- Problem: For each performance record, display the employee’s name, current metric
-- date, and the date of their next performance entry. If there is no next entry, display
-- NULL. Order by employee name and then current metric date.

-- SELECT employee_name, metric_date current_metric_date, LEAD(metric_date) OVER(ORDER BY metric_date) next_metric_date
-- FROM navigate_functions.employee_performance ORDER BY employee_name, metric_date;