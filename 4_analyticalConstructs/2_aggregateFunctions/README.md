# 📊 SQL Aggregate Functions: From Basics to Advanced Analysis 📈

Master SQL aggregate functions! This guide covers fundamental aggregates (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`), string/array/JSON aggregation (`STRING_AGG`, `ARRAY_AGG`, `JSON_AGG`), statistical functions (`PERCENTILE_CONT`, `MODE`, `CORR`, `VARIANCE`, `STDDEV`, `REGR_SLOPE`), and window aggregates. We'll explore meanings, advantages, disadvantages, efficient usage, and tackle complex problems combining these powerful tools.

---

## 1. Practice Meanings, Values, Relations, and Advantages

### Exercise i.1: Overall Company Metrics

> **Problem:** Calculate total employees, total salary, average, min, and max salary across all employees. Advantage of aggregate functions?
>
> **Aggregate Functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`):** Perform calculations on a set of values and return a single summary value.
> **Advantage:** Provide a concise and efficient way to summarize large datasets directly within the database, avoiding manual calculation or fetching all data to the client for processing.

```sql
SELECT
    COUNT(DISTINCT employee_id) AS total_unique_employees, -- Counts unique employees
    SUM(salary) AS total_salary_expenditure,
    AVG(salary) AS average_salary,
    MIN(salary) AS minimum_salary,
    MAX(salary) AS maximum_salary
FROM aggregate_functions.employees;
```

### Exercise i.2: Department Employee Listing

> **Problem:** For each department: name, number of employees, comma-separated list of employee first names (ordered alphabetically). How does `STRING_AGG` help?
>
> **`STRING_AGG(expression, separator ORDER BY ...)`:** Concatenates string values from multiple rows.
> **Advantage:** Useful for creating denormalized string summaries, like lists of related items, for display or simple reporting, directly in SQL.

```sql
SELECT
    d.department_name, -- d.* in snippet includes department_id too
    COALESCE(departmental_summary.number_of_workers, 0) AS number_of_workers, -- Handle depts with no employees
    COALESCE(departmental_summary.departmental_names_list, 'No employees') AS departmental_names_list -- Handle depts with no employees
FROM aggregate_functions.departments AS d
LEFT JOIN ( -- Use LEFT JOIN to include departments with no employees
    SELECT
        department_id,
        COUNT(employee_id) AS number_of_workers, -- COUNT(employee_id) if employee_id is PK
        STRING_AGG(first_name, ', ' ORDER BY first_name) AS departmental_names_list
    FROM aggregate_functions.employees
    GROUP BY department_id
) AS departmental_summary ON d.department_id = departmental_summary.department_id;
```
*Note: Snippet used `COUNT(DISTINCT employee_id)`. If `employee_id` is a primary key, `COUNT(employee_id)` is sufficient and clearer. `LEFT JOIN` ensures all departments are listed.*

### Exercise i.3: Understanding Different `COUNT`s

> **Problem:** Find total employees, number with `bonus_percentage`, number of distinct `performance_rating` values. Explain differences.
>
> **`COUNT(expression)`:** Counts rows where `expression` is NOT NULL.
> **`COUNT(*)` or `COUNT(column_with_no_nulls_like_pk)`:** Counts all rows in the group.
> **`COUNT(DISTINCT expression)`:** Counts unique non-NULL values of `expression`.

```sql
SELECT
    COUNT(employee_id) AS total_employees, -- Counts employees (assuming employee_id is PK and NOT NULL)
    COUNT(bonus_percentage) AS employees_with_bonus_recorded, -- Counts only non-NULL bonus_percentage values
    COUNT(DISTINCT performance_rating) AS distinct_performance_rating_values -- Counts unique non-NULL performance ratings
FROM aggregate_functions.employees;
```
**Explanation:**
*   `COUNT(employee_id)`: Total number of employees (if `employee_id` is always present).
*   `COUNT(bonus_percentage)`: Number of employees for whom a `bonus_percentage` is known (not `NULL`).
*   `COUNT(DISTINCT performance_rating)`: How many different performance rating scores exist in the company (e.g., if ratings are 1, 2, 3, 3, 4, `NULL`, this would be 4).

### Exercise i.4: Median Salary and Mode Performance Rating

> **Problem:** Median salary for 'Engineering' dept. Mode performance rating for company. Value of `PERCENTILE_CONT` and `MODE`?
>
> **`PERCENTILE_CONT(fraction) WITHIN GROUP (ORDER BY ...)`:** Computes a percentile based on a continuous distribution of the column values. `PERCENTILE_CONT(0.5)` gives the median.
> **`MODE() WITHIN GROUP (ORDER BY ...)`:** Returns the most frequent value (mode).
> **Value:** These functions provide robust statistical measures (median for central tendency less affected by outliers, mode for most common value) directly in SQL.

```sql
SELECT
    (
        SELECT MODE() WITHIN GROUP (ORDER BY performance_rating)
        FROM aggregate_functions.employees
    ) AS company_performance_mode,
    (
        SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.salary)
        FROM aggregate_functions.employees e
        JOIN aggregate_functions.departments d ON e.department_id = d.department_id
        WHERE d.department_name = 'Engineering'
    ) AS engineering_median_salary;
```
> **Explanation from snippet:** `MODE()` finds the most repeated `performance_rating`. `PERCENTILE_CONT(0.5)` calculates the median salary, which lies at the 50th percentile of the data distribution.

### Exercise i.5: Project Task Hours Distribution

> **Problem:** For each project: name, total hours, variance & std dev of hours on tasks. How do `VARIANCE` & `STDDEV` help?
>
> **`VARIANCE(expression)` & `STDDEV(expression)` (or `STDDEV_POP`/`STDDEV_SAMP`):** Measure the dispersion or spread of a set of values.
> **Value:** Help understand data distribution:
> *   Low variance/std dev: Data points tend to be close to the mean.
> *   High variance/std dev: Data points are spread out over a wider range. Useful for consistency checks, identifying outliers.

```sql
SELECT
    p.project_name,
    et.total_hours_spent,
    et.variance_hours,
    et.stddev_hours
FROM aggregate_functions.projects p
JOIN (
    SELECT
        project_id,
        SUM(hours_spent) AS total_hours_spent,
        VARIANCE(hours_spent) AS variance_hours,
        STDDEV(hours_spent) AS stddev_hours  -- STDDEV is usually sample standard deviation
    FROM aggregate_functions.employee_tasks
    GROUP BY project_id
) AS et ON p.project_id = et.project_id;
```

### Exercise i.6: Departmental and Cumulative Salaries

> **Problem:** Total salary per department. Cumulative salary within dept by `hire_date` (earliest first). Advantage of window aggregate?
>
> **Window Aggregate Functions (`SUM(...) OVER (PARTITION BY ... ORDER BY ...)`):** Perform calculations across a set of table rows that are somehow related to the current row. Unlike regular aggregates, they do not collapse rows.
> **Advantage:** Allow calculation of running totals, moving averages, rankings within groups, etc., while retaining individual row detail, which is very difficult or inefficient with only `GROUP BY` aggregates.

```sql
SELECT
    department_id,
    hire_date,
    employee_id,
    salary,
    SUM(salary) OVER (PARTITION BY department_id) AS departmental_total_salary, -- Total salary for the dept
    SUM(salary) OVER (PARTITION BY department_id ORDER BY hire_date ASC, employee_id ASC ROWS UNBOUNDED PRECEDING) AS departmental_cumulative_salary -- Running total
    -- Added ROWS UNBOUNDED PRECEDING for standard cumulative sum frame. Default is usually correct for ORDER BY.
FROM aggregate_functions.employees
ORDER BY department_id, hire_date, employee_id; -- Order final output for readability
```
> **Explanation from snippet:** The window function simplifies a lot because it partitions first by departments and then uses important orders like `hire_date` for the cumulative sum. Other less simple/efficient solutions (e.g., recursive CTE) are too complex in comparison.

---

## 2. Practice Disadvantages and Potential Pitfalls

### Exercise ii.1: Loss of Detail with Average

> **Problem:** Calculate avg salary for 'Engineering'. What info is lost?
>
> **Disadvantage:** An average (a measure of central tendency) summarizes data into a single value, thereby losing information about the distribution, range (min/max), specific individual values, and presence of outliers.

```sql
SELECT
    d.department_name, -- D.* selects all columns from departments
    avg_s.avg_salary_in_dept -- avg_s.AVG from snippet
FROM aggregate_functions.departments AS d
JOIN (
    SELECT
        department_id,
        AVG(salary) AS avg_salary_in_dept
    FROM aggregate_functions.employees
    GROUP BY department_id
) AS avg_s ON d.department_id = avg_s.department_id
WHERE d.department_name = 'Engineering';
```
**Information Lost:** Individual salaries, salary range (min/max), salary distribution (e.g., are salaries clustered or spread out?), number of employees, specific high/low earners.

### Exercise ii.2: Misleading Aggregate without `GROUP BY`

> **Problem:** Query: `SELECT department_id, MAX(salary) FROM employees;`. Why misleading/incorrect if user wants max salary *for each* department?
>
> **Pitfall/Misleading Behavior:** When an aggregate function (like `MAX(salary)`) is used in `SELECT` with non-aggregated columns (like `department_id`), standard SQL requires all non-aggregated columns to be in a `GROUP BY` clause.
> *   If `GROUP BY` is omitted, some RDBMS (like older MySQL versions with specific modes, or SQLite) might return one arbitrary `department_id` along with the overall `MAX(salary)` for the entire table. This is *not* the max salary for that specific department shown.
> *   Most RDBMS (including PostgreSQL and standard SQL) will raise an error stating that `department_id` must appear in the `GROUP BY` clause or be used in an aggregate function.

> **Explanation from snippet:**
> Despite it being logical to think such query is getting the max salary for each department it's ambiguous because the query could also be interpreted as printing [an arbitrary] `department_id` and the maximum salary for all departments across all `department_id`s. That's why the query returns an error [in standard SQL]; because it's ambiguous, a `GROUP BY` clause is necessary for aggregation.

Correct query: `SELECT department_id, MAX(salary) FROM employees GROUP BY department_id;`

### Exercise ii.3: `NULL` Handling in `AVG()`

> **Problem:** Calculate `AVG(bonus_percentage)`. How does `AVG()` handle `NULL`s, and how could this be misleading?
>
> **`NULL` Handling:** Aggregate functions like `AVG()`, `SUM()`, `COUNT(column)` generally ignore `NULL` values. `AVG(bonus_percentage)` is `SUM(bonus_percentage) / COUNT(bonus_percentage)`, where both `SUM` and `COUNT` only consider non-NULL values.
> **Misleading If:** If `NULL` is intended to mean zero (e.g., no bonus), then `AVG()` will calculate the average only for those who received a bonus, potentially inflating the perceived average bonus across *all* employees. If `NULL` means data is missing but a bonus *might* have occurred, the average is based on incomplete data.

```sql
SELECT AVG(bonus_percentage) FROM aggregate_functions.employees;
-- To treat NULLs as 0:
-- SELECT AVG(COALESCE(bonus_percentage, 0)) FROM aggregate_functions.employees;
-- This will lower the average if there are many NULLs treated as 0.
```
> **Explanation from snippet:** `AVG()` treats `NULL` as nothing, then skips it. If the system's logic stores `NULL` when the value is 0, then such skips are problematic because the average is `sum() / n` where `n` (in `COUNT(column)`) does not count rows with `NULL` (which should have been 0).

### Exercise ii.4: Aggregate in `WHERE` Clause

> **Problem:** Find depts where avg employee performance < 3.5. User tries: `SELECT ... WHERE AVG(performance_rating) < 3.5 GROUP BY ...;`. Why fail?
>
> **Mistake/Disadvantage:** Aggregate functions cannot be used directly in a `WHERE` clause. The `WHERE` clause filters rows *before* aggregation and grouping. To filter groups based on aggregate values, the `HAVING` clause must be used.

**Incorrect Query (will fail):**
`SELECT department_id, AVG(performance_rating) FROM employees WHERE AVG(performance_rating) < 3.5 GROUP BY department_id;`

**Correct Query (using `HAVING`):**
```sql
SELECT department_id, AVG(performance_rating) AS avg_performance
FROM aggregate_functions.employees
GROUP BY department_id
HAVING AVG(performance_rating) < 3.5;
```
> **Explanation from snippet:** In such cases, `HAVING` must be used.

---

## 3. Inefficient vs. Efficient Aggregate Usage

### Exercise iii.1: Counting Tasks Inefficiently

> **Problem:** Junior analyst finds total tasks for 'Project Alpha' by fetching all task IDs to app, then counts in app code. Provide efficient SQL.
>
> **Efficient SQL:** Use `COUNT()` with a `WHERE` clause.

```sql
SELECT COUNT(et.task_id) AS alpha_project_task_count
FROM aggregate_functions.employee_tasks et
JOIN aggregate_functions.projects p ON et.project_id = p.project_id
WHERE p.project_name = 'Project Alpha';
```

### Exercise iii.2: Calculating Average Salary Inefficiently

> **Problem:** Developer queries all salaries for employees hired in 2020, then sums and divides in programming language. Provide efficient SQL.
>
> **Efficient SQL:** Use `AVG()` with a `WHERE` clause.

```sql
SELECT AVG(salary) AS avg_salary_hired_2020
FROM aggregate_functions.employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;
```

### Exercise iii.3: Finding Max Salary Per Department Inefficiently

> **Problem:** Data scientist gets max salary per dept by running separate queries for each department ID. Provide single, efficient SQL.
>
> **Efficient SQL:** Use `MAX()` with `GROUP BY department_id`.

```sql
SELECT department_id, MAX(salary) AS max_salary_in_dept
FROM aggregate_functions.employees
GROUP BY department_id;
```

### Exercise iii.4: Filtering by Total Hours Inefficiently

> **Problem:** HR needs employees with > 150 total task hours. Fetches all tasks per employee, sums in spreadsheet, then filters. Provide efficient SQL with `HAVING`.
>
> **Efficient SQL:** Use `SUM()` with `GROUP BY employee_id` and `HAVING` clause.

```sql
SELECT
    e.first_name || ' ' || e.last_name AS employee_with_over_150_hours,
    hours_summary.total_hours_spent
FROM (
    SELECT employee_id, SUM(hours_spent) AS total_hours_spent
    FROM aggregate_functions.employee_tasks
    GROUP BY employee_id
    HAVING SUM(hours_spent) > 150
) AS hours_summary -- Renamed from more_than_150
JOIN aggregate_functions.employees e ON e.employee_id = hours_summary.employee_id;
```

---

## 4. Hardcore Problem Combining Concepts

### Exercise iv.1: Top Employees by Salary per Department with Aggregates and Ranking

> **Problem:** For each dept: top 2 employees by salary. Show full name, dept name, salary, dept salary rank (dense), total dept salary expenditure, salary as % of dept total. Only depts with >= 3 employees. Order by dept name, rank.
> *(Constraint "Only include departments with at least 3 employees" was not in the snippet's query, added conceptually).*

```sql
WITH DepartmentEmployeeCounts AS ( -- CTE to count employees per department
    SELECT department_id, COUNT(*) AS num_employees
    FROM aggregate_functions.employees
    GROUP BY department_id
    HAVING COUNT(*) >= 3 -- Filter for departments with at least 3 employees
),
DepartmentSalaryExpenditure AS ( -- CTE for total salary per department
    SELECT
        department_id,
        SUM(salary) AS dept_total_salary_expenditure
    FROM aggregate_functions.employees
    WHERE department_id IN (SELECT department_id FROM DepartmentEmployeeCounts) -- Only for eligible depts
    GROUP BY department_id
),
RankedSalariesInDept AS ( -- CTE for ranking salaries within eligible departments
    SELECT
        department_id,
        employee_id,
        salary,
        DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_salary_rank -- DESC for top paid
    FROM aggregate_functions.employees
    WHERE department_id IN (SELECT department_id FROM DepartmentEmployeeCounts)
)
SELECT
    (e.first_name || ' ' || e.last_name) AS fullname,
    d.department_name,
    e.salary,
    rsd.dept_salary_rank,
    dse.dept_total_salary_expenditure,
    ROUND((e.salary / dse.dept_total_salary_expenditure) * 100.0, 2) AS salary_percentage_of_dept_total
FROM aggregate_functions.employees AS e
JOIN RankedSalariesInDept rsd
    ON e.employee_id = rsd.employee_id AND rsd.dept_salary_rank <= 2 -- Top 2 salary ranks (dense)
JOIN DepartmentSalaryExpenditure dse
    ON e.department_id = dse.department_id
JOIN aggregate_functions.departments d
    ON e.department_id = d.department_id -- Changed from dse.department_id to e.department_id for join clarity
WHERE e.department_id IN (SELECT department_id FROM DepartmentEmployeeCounts) -- Ensure department is eligible
ORDER BY d.department_name, rsd.dept_salary_rank, e.salary DESC;

-- Snippet's query was:
-- DENSE_RANK() OVER(PARTITION BY department_id ORDER BY salary) dept_salary_rank
-- For "top 2 employees by salary", the order should be `ORDER BY salary DESC`.
-- It joined employees, ranked salaries, and department expenditure in the main query.
-- The "at least 3 employees" constraint was missing.
```

### Exercise iv.2: Project Metrics, Budget Ranking, and Cumulative Budget

> **Problem:** List projects: name, budget, total hours, avg hours/task. Rank projects by budget (highest first). For 2023 projects, show running total of budgets by `start_date`.
> *(Assuming `RANK()` for budget ranking as it's not specified otherwise)*

```sql
WITH ProjectTaskHours AS (
    SELECT
        project_id,
        COALESCE(SUM(hours_spent), 0) AS total_project_hours,
        ROUND(COALESCE(AVG(hours_spent), 0), 2) AS avg_hours_per_task
    FROM aggregate_functions.employee_tasks
    GROUP BY project_id
)
SELECT
    p.project_name,
    p.budget,
    pth.total_project_hours,
    pth.avg_hours_per_task,
    RANK() OVER (ORDER BY p.budget DESC) AS budget_rank,
    p.start_date,
    CASE
        WHEN EXTRACT(YEAR FROM p.start_date) = 2023
        THEN SUM(p.budget) OVER (
                 PARTITION BY EXTRACT(YEAR FROM p.start_date) -- Ensure running total is only for 2023 projects
                 ORDER BY p.start_date ASC
                 ROWS UNBOUNDED PRECEDING
             )
        ELSE NULL
    END AS running_total_budget_2023
FROM aggregate_functions.projects p
LEFT JOIN ProjectTaskHours pth ON p.project_id = pth.project_id -- LEFT JOIN if projects might have no tasks
ORDER BY budget_rank, p.start_date;

-- Snippet's query:
-- `SUM(budget) OVER(ORDER BY start_date ASC)` without `PARTITION BY` year of start_date
-- would make the running total across all projects if not filtered by year first.
-- Adding `PARTITION BY EXTRACT(YEAR FROM start_date)` and then filtering for year 2023 rows
-- or using a CASE expression as above ensures the running total is specific to 2023 projects.
-- The `CASE WHEN EXTRACT(YEAR FROM start_date) = 2023` correctly limits the running total display.
```

### Exercise iv.3: Employees Above Department Average Salary with Ranking

> **Problem:** Display employee full name, dept name, salary, dept avg salary, salary rank in dept (`ROW_NUMBER`). Filter: salary > dept avg AND hire_date > '2020-01-01'. Order by dept name, salary desc.

```sql
SELECT *
FROM (
    SELECT
        e.first_name || ' ' || e.last_name AS full_name,
        d.department_name,
        e.salary,
        e.hire_date,
        AVG(e.salary) OVER (PARTITION BY e.department_id) AS dept_salary_avg,
        ROW_NUMBER()  OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS dept_employee_salary_row_num
    FROM aggregate_functions.employees e
    JOIN aggregate_functions.departments d ON e.department_id = d.department_id
) AS subquery
WHERE subquery.salary > subquery.dept_salary_avg
  AND subquery.hire_date > DATE '2020-01-01' -- Explicit DATE cast
ORDER BY department_name, salary DESC;
```
*This query is well-structured and directly uses window functions for department average and ranking, then filters in the outer query. The snippet's solution is correct and efficient for this problem.*