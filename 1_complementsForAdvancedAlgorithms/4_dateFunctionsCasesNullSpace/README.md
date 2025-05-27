```markdown
# 📅 SQL Mastery: Dates, Cases, and NULLs 🌌

Navigate the complexities of SQL with this guide focusing on Date Functions, `CASE` expressions, and `NULL` value handling. We'll explore meanings, advantages, disadvantages, and practical scenarios, including the `OVERLAPS` operator and advanced conditional logic.

---

## 🗓️ Part 1: Date Functions & `OVERLAPS`

### (i) Meaning, Values, Relations, Advantages

#### Exercise 1.1: Project Timeline Extension and Next Month Check

> **Problem:** For all projects, calculate their planned end date if extended by 2 months and 15 days. Also, determine if the original planned end date falls within February 2024. Display project name, original planned end date, extended planned end date, and a boolean indicating if it’s planned for Feb 2024.
>
> **Concepts:** Date arithmetic (`+ INTERVAL`), date extraction (`EXTRACT`).
> **Advantage:** SQL provides intuitive syntax for date manipulations and conditional checks on date parts.

```sql
SELECT
    project_name,
    planned_end_date AS original_planned_end_date, -- Added alias for clarity
    planned_end_date + INTERVAL '2 months' + INTERVAL '15 days' AS adjusted_end_date, -- Alias
    -- The original query's WHERE clause filters *only* for Feb 2024 projects.
    -- To display all projects and a boolean flag, the check should be in SELECT:
    (EXTRACT(MONTH FROM planned_end_date) = 2 AND EXTRACT(YEAR FROM planned_end_date) = 2024) AS is_feb_2024_planned
FROM advanced_dates_cases_and_null_space.projects;
-- Original WHERE clause:
-- WHERE EXTRACT(MONTH FROM planned_end_date) = 2 AND EXTRACT(YEAR FROM planned_end_date) = 2024;
```

#### Exercise 1.2: Identifying Concurrent Project Assignments for Employees

> **Problem:** Identify employees who are assigned to multiple projects whose active periods on those projects overlap. An employee’s active period on a project is from `assigned_date` to `COALESCE(completion_date, 'infinity')`. List the employee’s name and the names of the two overlapping projects along with their assignment and completion dates.
>
> **Concepts:** `OVERLAPS` operator, `COALESCE`, `SELF JOIN` pattern on `employee_projects`.
> **Advantage:** `OVERLAPS` provides a concise and readable way to check for intersecting time periods, handling complex date range comparisons elegantly.

*(Two slightly different queries were provided in the snippet. The second one using `<>` is more general for distinct projects for the same employee.)*
```sql
SELECT
    e.emp_id, e.emp_name,
    p1.project_name AS project1_name, ep1.assigned_date AS p1_assigned, ep1.completion_date AS p1_completed, -- Aliased for clarity
    p2.project_name AS project2_name, ep2.assigned_date AS p2_assigned, ep2.completion_date AS p2_completed  -- Aliased for clarity
FROM advanced_dates_cases_and_null_space.employees e
-- NATURAL JOIN advanced_dates_cases_and_null_space.employee_projects ep1 -- Assuming emp_id is the join key
JOIN advanced_dates_cases_and_null_space.employee_projects ep1 ON e.emp_id = ep1.emp_id -- Explicit join
JOIN advanced_dates_cases_and_null_space.employee_projects ep2
    ON e.emp_id = ep2.emp_id -- Both assignments must belong to the same employee
    AND ep1.project_id <> ep2.project_id -- Ensure we are comparing two different project assignments
                                         -- Using ep1.project_id < ep2.project_id avoids duplicate pairs (p1,p2) and (p2,p1)
    AND (ep1.assigned_date, COALESCE(ep1.completion_date, 'infinity'::DATE)) -- Assuming DATE, adjust if TIMESTAMP
        OVERLAPS
        (ep2.assigned_date, COALESCE(ep2.completion_date, 'infinity'::DATE))
JOIN advanced_dates_cases_and_null_space.projects p1
    ON p1.project_id = ep1.project_id
JOIN advanced_dates_cases_and_null_space.projects p2
    ON p2.project_id = ep2.project_id
ORDER BY e.emp_name, p1.project_name, p2.project_name; -- Added more specific ordering
```
*Note on provided query 1.2:*
*   The first query `ON ep1.project_id > ep2.project_id` is a good way to avoid duplicate pairs and self-comparison.
*   The `NATURAL JOIN` between `employees` and `employee_projects ep1` assumes `emp_id` is the only common column, which is likely but `JOIN ON` is safer.
*   The join `JOIN advanced_dates_cases_and_null_space.projects p2 ON p2.project_id = ep1.project_id` in the first variant was a typo, it should be `ON p2.project_id = ep2.project_id`. The second variant had it correct.

### (ii) Disadvantages of Date Concepts

#### Exercise 1.3: `OVERLAPS` with identical start/end points (zero-duration intervals)

> **Problem:** The `OVERLAPS` operator definition is `(S1, E1) OVERLAPS (S2, E2)` is true if `S1 < E2 AND S2 < E1`. What happens if `E1` is the same as `S1` (a zero-duration interval)? Explain the behavior and potential misinterpretation. Show a query.
>
> **Behavior:** If `S1 = E1`, the condition `S1 < E1` (part of `S2 < E1` effectively) can cause issues. For `(S1, S1) OVERLAPS (S2, E2)`, it becomes `S1 < E2 AND S2 < S1`. This means a zero-duration interval `(S1,S1)` will *not* overlap any interval `(S2,E2)` where `S2 >= S1`. It will only overlap if the point `S1` is strictly *within* `(S2, E2)`, i.e., `S2 < S1 < E2`.
> **Misinterpretation:** One might expect a single point in time (represented as a zero-duration interval) to "overlap" a period if that point falls anywhere within the period, including its boundaries. However, `OVERLAPS` treats intervals as open on one end or requires strict inequality, so boundary conditions might not behave as naively expected.

```sql
-- Example: Project starts on a day an employee is on approved leave.
-- Incorrectly using (start_date, start_date) for OVERLAPS
SELECT
    p.project_name,
    p.start_date AS project_start, -- Aliased
    e.emp_name,
    lr.leave_start_date,
    lr.leave_end_date,
    -- Incorrect: (S1, S1) OVERLAPS (S2, E2) -> S1 < E2 AND S2 < S1
    (p.start_date, p.start_date) OVERLAPS (lr.leave_start_date, lr.leave_end_date) AS overlaps_test_empty_interval,

    -- Correct way to check if a single date point falls within a range [inclusive start, exclusive end for typical date ranges]
    -- (p.start_date >= lr.leave_start_date AND p.start_date < lr.leave_end_date) AS point_in_range_standard,
    -- Or, if leave_end_date is inclusive:
    (p.start_date >= lr.leave_start_date AND p.start_date <= lr.leave_end_date) AS point_in_range_inclusive_end,

    -- Provided snippet's "corrected" OVERLAPS by extending the interval by 1 day
    -- This changes the meaning to "does the day of project_start overlap with the leave period?"
    (p.start_date, p.start_date + INTERVAL '1 day')
        OVERLAPS
    (lr.leave_start_date, lr.leave_end_date) AS overlaps_corrected_interval_p_extended
    -- Note: The snippet also extended lr.leave_end_date by '1 day' in one example.
    -- The effect of extending depends on whether dates are inclusive/exclusive.
FROM advanced_dates_cases_and_null_space.projects p
JOIN advanced_dates_cases_and_null_space.employee_projects ep ON p.project_id = ep.project_id
JOIN advanced_dates_cases_and_null_space.employees e ON ep.emp_id = e.emp_id
JOIN advanced_dates_cases_and_null_space.leave_requests lr ON e.emp_id = lr.emp_id
WHERE lr.status = 'Approved'
  AND p.project_name = 'Project Alpha' -- Example filter
  AND e.emp_name = 'Alice Wonderland' -- Example filter
LIMIT 1;
```
> **Explanation from snippet:** Nothing can overlap period of zero, then the comparison gives FALSE and thus skipped when not necessarily should be in that way. *(This is generally true unless the zero-duration point falls strictly *within* the other interval).*

#### Exercise 1.4: Time Zone Issues in Date Arithmetic without Explicit Time Zone Handling

> **Problem:** If `CURRENT_TIMESTAMP` is used in date arithmetic (e.g., `CURRENT_TIMESTAMP + INTERVAL ’1 day’`) in a system with users/data from different time zones, without explicit time zone conversion (e.g., `AT TIME ZONE`), discuss potential disadvantages.
>
> **Disadvantages:**
> *   **`TIMESTAMP WITHOUT TIME ZONE`**: Arithmetic is purely chronological. `+ INTERVAL '1 day'` adds exactly 24 hours. The *meaning* of this timestamp (e.g., "9 AM next day") is ambiguous without knowing the assumed time zone. Comparisons between such timestamps from different implicit time zones are meaningless.
> *   **`TIMESTAMP WITH TIME ZONE`**: Values are stored in UTC (typically). Arithmetic like `+ INTERVAL '24 hours'` adds a fixed duration. `+ INTERVAL '1 day'` might be more complex across DST transitions as it aims for "same time next day, local".
>     *   **DST Issues**: Adding `'1 day'` across a DST change where clocks spring forward might result in a UTC time that is 23 hours later, or 25 hours later if clocks fall back. This ensures the local time-of-day appears consistent.
>     *   **Inconsistencies**: Without careful `AT TIME ZONE` conversions, displaying or interpreting these UTC timestamps in different local time zones can lead to confusion if the context isn't clear. Operations based on local calendar days vs. fixed durations can yield different UTC results.

```sql
-- Conceptual example from snippet (TIMESTAMP WITHOUT TIME ZONE comparison)
WITH example_times AS (
  SELECT
    '2024-01-31 22:00:00'::TIMESTAMP WITHOUT TIME ZONE AS china_time_val,  -- Implicitly China Time (UTC+8)
    '2024-01-31 10:00:00'::TIMESTAMP WITHOUT TIME ZONE AS colombia_time_val -- Implicitly Colombia Time (UTC-5)
)
SELECT
  china_time_val AS original_china_time,
  colombia_time_val AS original_colombia_time,
  china_time_val + INTERVAL '4 hours' AS china_plus_4h,   -- Becomes Feb 1st 02:00 (China)
  colombia_time_val + INTERVAL '4 hours' AS colombia_plus_4h, -- Becomes Jan 31st 14:00 (Colombia)
  EXTRACT(MONTH FROM (china_time_val + INTERVAL '4 hours')) AS china_new_month, -- Month becomes 2
  EXTRACT(MONTH FROM (colombia_time_val + INTERVAL '4 hours')) AS colombia_new_month, -- Month remains 1
  -- (china_time_val + INTERVAL '4 hours') = (colombia_time_val + INTERVAL '4 hours') AS naive_comparison -- This would be FALSE
  -- The original snippet's example of naive_comparison being true is if the resulting timestamps were coincidentally equal,
  -- which requires the initial timestamps and interval to align perfectly, not shown here.
  -- The point is that arithmetic is done on the face values, oblivious to underlying time zone differences.
FROM example_times;

-- TIMESTAMP WITH TIME ZONE example across potential DST (behavior specific to RDBMS and session time zone)
-- For example, if 'America/New_York' observes DST on March 10, 2024:
-- SELECT
--    TIMESTAMP WITH TIME ZONE '2024-03-10 01:00:00 America/New_York' AS ts_before_dst,
--    TIMESTAMP WITH TIME ZONE '2024-03-10 01:00:00 America/New_York' + INTERVAL '1 day' AS ts_plus_1_day_dst;
-- Output might be '2024-03-11 01:00:00-04' (if it's now EDT, -04), which is 23 actual hours later in UTC.
```
> **Explanation from snippet:** If a TIMESTAMP does not have TIME ZONE means that adding a day and then extract the next time measurement (MONTH) expected to change to its next value could not be the case because a day in different time zones vary. Is incorrect to add 4 hours comparing date times from China and Colombia. *(This highlights the ambiguity and potential for misinterpretation with `TIMESTAMP WITHOUT TIME ZONE`.)*

### (iii) Inefficient Alternatives vs. Advanced Date Usage

#### Exercise 1.5: Inefficiently Finding Projects Active During a Specific Period

> **Problem:** Find all projects active (start_date to COALESCE(actual_end_date, planned_end_date)) at any point during Q1 2023 (Jan 1, 2023 to Mar 31, 2023). Show an inefficient method using multiple `OR` conditions, then the efficient `OVERLAPS` solution.

**Inefficient Method (Multiple `OR` conditions):**
```sql
SELECT                  -- High complexities with verbosities prone to errors
    project_name,
    start_date,
    COALESCE(actual_end_date, planned_end_date) AS relevant_end_date
FROM advanced_dates_cases_and_null_space.projects
WHERE
    -- Project starts within Q1
    (start_date BETWEEN '2023-01-01' AND '2023-03-31') OR
    -- Project ends within Q1
    (COALESCE(actual_end_date, planned_end_date) BETWEEN '2023-01-01' AND '2023-03-31') OR
    -- Project spans the entirety of Q1
    (start_date < '2023-01-01' AND COALESCE(actual_end_date, planned_end_date) > '2023-03-31');
```

**Efficient `OVERLAPS` Solution:**
```sql
SELECT                  -- How overlapping solves verbosity and unreadable complexity
    project_name,
    start_date,
    COALESCE(actual_end_date, planned_end_date) AS relevant_end_date
FROM advanced_dates_cases_and_null_space.projects
WHERE
    (start_date, COALESCE(actual_end_date, planned_end_date, 'infinity'::DATE)) -- Ensure end date is not NULL for OVERLAPS
    OVERLAPS
    (DATE '2023-01-01', DATE '2023-03-31'); -- Using DATE literals is cleaner
    -- Original: (TO_DATE('2023-01-01', 'YYYY-MM-DD'), TO_DATE('2023-03-31', 'YYYY-MM-DD'));
    -- Note: If end date of Q1 period is exclusive, it would be (DATE '2023-01-01', DATE '2024-04-01').
    -- Assuming inclusive end for Q1 as '2023-03-31'.
    -- Postgres OVERLAPS is (S1, E1) OVERLAPS (S2, E2) iff S1 < E2 AND S2 < E1.
    -- To make it inclusive of the end date '2023-03-31', the Q1 period should be (DATE '2023-01-01', DATE '2023-03-31' + INTERVAL '1 day')
    -- or (DATE '2023-01-01', DATE '2024-04-01') if Q1 period is [start, end).
    -- Or, ensure project's end date is also shifted if necessary.
    -- For typical inclusive date ranges, the logic is (ProjectStart <= PeriodEnd) AND (ProjectEnd >= PeriodStart)
    -- OVERLAPS is (S1, E1) OVERLAPS (S2, E2)  is true if S1 < E2 AND S2 < E1.
    -- If Q1 is [DATE '2023-01-01', DATE '2023-03-31'],
    -- then to use OVERLAPS for this inclusive range, query should be:
    -- (start_date, COALESCE(actual_end_date, planned_end_date, 'infinity'::DATE) + INTERVAL '1 day')
    -- OVERLAPS (DATE '2023-01-01', DATE '2023-03-31' + INTERVAL '1 day')
    -- A simpler non-OVERLAPS approach for inclusive ranges is often:
    -- start_date <= DATE '2023-03-31' AND COALESCE(actual_end_date, planned_end_date) >= DATE '2023-01-01'
```

---

## 🧩 Part 2: `CASE` Expressions

### (i) Meaning, Values, Relations, Advantages

#### Exercise 2.1: Project Status Categorization

> **Problem:** Categorize projects: ’Upcoming’ (starts after ’2024-01-15’), ’Ongoing’ (started on/before ’2024-01-15’ and actual_end_date IS NULL or after ’2024-01-15’), ’Completed Early/On-Time’ (actual_end_date <= planned_end_date), ’Completed Late’ (actual_end_date > planned_end_date). Use searched `CASE`.
>
> **Concepts:** Searched `CASE` expression for conditional logic. `CASE` in `GROUP BY`.
> **Advantage:** `CASE` allows complex conditional logic directly within SQL queries, enabling dynamic categorization, transformations, and pivoting.

```sql
SELECT
    -- STRING_AGG(project_name, ', ') AS projects_in_status, -- Original groups by status
    project_name, -- To show each project and its status
    CASE
        WHEN start_date > DATE '2024-01-15' THEN 'Upcoming'
        -- Order of WHEN clauses matters for overlapping conditions.
        -- 'Ongoing' should check actual_end_date before 'Completed' checks.
        WHEN start_date <= DATE '2024-01-15' AND (actual_end_date IS NULL OR actual_end_date > DATE '2024-01-15') THEN 'Ongoing'
        WHEN actual_end_date IS NOT NULL AND planned_end_date IS NOT NULL AND actual_end_date <= planned_end_date THEN 'Completed Early/On-Time'
        WHEN actual_end_date IS NOT NULL AND planned_end_date IS NOT NULL AND actual_end_date > planned_end_date THEN 'Completed Late'
        ELSE 'Undefined/Other' -- Fallback for unhandled cases
    END AS status
FROM advanced_dates_cases_and_null_space.projects;
-- Original GROUP BY part:
-- GROUP BY status; -- (where status is the alias for the CASE expression)
-- Grouping by the CASE expression itself is valid if you want counts per status.
```
*Note on Ex 2.1:* The original query grouped projects by the derived status. The modified query above lists each project with its status. The `CASE` logic was reordered for correctness as `Ongoing` conditions might overlap with `Completed` conditions if not carefully structured.

#### Exercise 2.2: Sorting Employees by Custom Priority

> **Problem:** List all employees. Sort by: 1st managers (is manager_id for someone or has no manager_id), then non-managers. Within managers, sort by salary desc. Within non-managers, by hire_date asc. Use `CASE` in `ORDER BY`.
>
> **Concepts:** `CASE` in `ORDER BY` for custom sort logic.
> **Advantage:** Enables complex, multi-level sorting priorities that go beyond simple column ordering.

```sql
SELECT
    e.*, -- Select all columns from employees
    CASE
        WHEN e.manager_id IS NULL OR EXISTS (SELECT 1 FROM advanced_dates_cases_and_null_space.employees e_sub WHERE e_sub.manager_id = e.emp_id) THEN 'Manager Role'
        -- Original logic used project lead status:
        -- WHEN EXISTS(SELECT 1 FROM advanced_dates_cases_and_null_space.projects p WHERE p.lead_emp_id = e.emp_id) OR e.manager_id IS NOT NULL THEN 'Manager'
        -- The problem statement says "is manager_id for someone OR have no manager_id themselves"
        ELSE 'Non-Manager Role'
    END AS role_status -- For display, not used in sort directly by this name
FROM advanced_dates_cases_and_null_space.employees e
ORDER BY
    CASE -- Primary sort: Managers first
        WHEN e.manager_id IS NULL OR EXISTS (SELECT 1 FROM advanced_dates_cases_and_null_space.employees e_sub WHERE e_sub.manager_id = e.emp_id) THEN 0
        ELSE 1
    END ASC,
    CASE -- Secondary sort for Managers: Salary DESC
        WHEN e.manager_id IS NULL OR EXISTS (SELECT 1 FROM advanced_dates_cases_and_null_space.employees e_sub WHERE e_sub.manager_id = e.emp_id) THEN e.salary
        ELSE NULL -- Non-managers get NULL here, salary sort N/A for them in this tier
    END DESC NULLS LAST, -- NULLS LAST ensures non-managers are effectively ignored by this salary sort
    CASE -- Tertiary sort for Non-Managers: Hire Date ASC
        WHEN NOT (e.manager_id IS NULL OR EXISTS (SELECT 1 FROM advanced_dates_cases_and_null_space.employees e_sub WHERE e_sub.manager_id = e.emp_id)) THEN e.hire_date
        ELSE NULL -- Managers get NULL here, hire date sort N/A for them in this tier
    END ASC NULLS LAST; -- NULLS LAST ensures managers are effectively ignored by this hire date sort
```
*Note on Ex 2.2:* The original query had complex `CASE` conditions involving project leads and `e.manager_id IS NOT NULL` (which means they *have* a manager, so they are not managers themselves in that sense). The revised query aligns more closely with the problem description "is manager_id for someone OR have no manager_id themselves". The `ORDER BY` clause has been structured to apply salary sort only to managers and hire date sort only to non-managers.

#### Exercise 2.3: Grouping Projects by Budget Ranges

> **Problem:** Group projects by budget: ’Low’ (<= 50000), ’Medium’ (50001 - 150000), ’High’ (> 150000), ’Undefined’ (budget IS NULL). Count projects and sum budgets. Use `CASE` in `GROUP BY`.
>
> **Concepts:** `CASE` in `GROUP BY` for dynamic grouping.
> **Advantage:** Allows aggregation based on derived categories rather than raw column values.

```sql
SELECT
    CASE
        WHEN budget IS NULL THEN 'Undefined' -- Should be checked first
        WHEN budget <= 50000 THEN 'Low'
        WHEN budget > 50000 AND budget <= 150000 THEN 'Medium' -- Corrected range: 50001 to 150000
        WHEN budget > 150000 THEN 'High'
        -- ELSE 'Undefined' -- If budget IS NULL was not first, this could be a fallback.
    END AS budget_category, -- Aliased for clarity
    COUNT(project_id) AS project_count, -- Count projects
    SUM(budget) AS total_budget_in_category -- Sum budgets
    -- Original: STRING_AGG(project_name, ', ') projects_in_category, SUM(budget) total_budget
FROM advanced_dates_cases_and_null_space.projects
GROUP BY budget_category; -- Group by the alias (supported in many RDBMS) or the full CASE expression
-- Original GROUP BY used "financial_project" which was the alias in the SELECT.
-- The CASE expression in the provided snippet for 'Medium' was budget BETWEEN 50000 AND 150000,
-- and 'High' was budget > 150000. This creates an overlap for 50000 if not handled carefully.
-- Corrected ranges: Low (<=50000), Medium (50001-150000), High (>150000).
-- The provided snippet has "WHEN budget BETWEEN 50000 AND 150000 THEN 'High'". This is likely a typo and meant 'Medium'.
-- It also had "WHEN budget > 150000 THEN 'High'".
-- Corrected logic:
-- Low: budget <= 50000
-- Medium: budget > 50000 AND budget <= 150000 (or BETWEEN 50001 AND 150000)
-- High: budget > 150000
-- Undefined: budget IS NULL
```

### (ii) Disadvantages of `CASE` Expressions

#### Exercise 2.4: Overly Nested `CASE` Expressions for Readability

> **Problem:** Create a complex employee ”profile string” using `CASE`. If salary > 100k, profile starts ”High Earner”. If also in Eng dept (ID 2), append ”, Key Engineer”. If also rating 5, append ”, Top Performer”. Otherwise, profile is ”Standard”. Discuss readability impact.
>
> **Disadvantage:** Deeply nested or numerous `WHEN` conditions in `CASE` expressions can significantly reduce query readability and maintainability. The logic becomes hard to follow and debug.

```sql
SELECT
    emp_id, emp_name,
    CASE
        WHEN salary > 100000 THEN
            'High Earner' ||
            CASE
                WHEN dept_id = 2 THEN -- Assuming dept_id 2 is Engineering
                    ', Key Engineer' ||
                    CASE
                        WHEN performance_rating = 5 THEN ', Top Performer'
                        ELSE '' -- No additional string if not top performer
                    END
                ELSE '' -- No additional string if not in Eng dept
            END
        ELSE 'Standard'
    END AS profile_string -- Renamed alias from "title"
FROM advanced_dates_cases_and_null_space.employees;
-- The commented out part in the snippet was almost there but missed some ELSE branches for concatenation.
-- The snippet commented: "Too complex to be easily readed because the nested logic grows exponentially in the number of necessary commands"
-- While not "exponentially", it certainly becomes much harder to parse.
```

#### Exercise 2.5: `CASE` in `GROUP BY` Causing Performance Issues with Non-SARGable Conditions

> **Problem:** Group employees by category derived from email: ’Internal’ (ends with ’@example.com’), ’External’ (otherwise). Use `CASE` in `GROUP BY`. If `CASE` uses `SUBSTRING` or `LIKE ’%pattern’` on an unindexed or inappropriately indexed column, discuss performance.
>
> **Disadvantage:** If the `CASE` expression in `GROUP BY` (or `WHERE`) applies functions or patterns (like `LIKE '%...'` or `SUBSTRING`) to a column in a way that prevents the database from using an index effectively (non-SARGable), it can lead to full table scans and slow performance, especially on large tables.

*(Query for 2.5 was commented out in snippet, but here's a reconstruction):*
```sql
SELECT
    CASE
        WHEN email LIKE '%@example.com' THEN 'Internal'
        ELSE 'External'
    END AS email_type,
    COUNT(*) AS employee_count
    -- Original: STRING_AGG(email, ', ')
FROM advanced_dates_cases_and_null_space.employees
GROUP BY email_type; -- Or GROUP BY the full CASE expression
-- Performance discussion: LIKE '%@example.com' (leading wildcard) is generally non-SARGable.
-- The database would likely have to scan all email values and apply the pattern.
-- Grouping on the result of this computation can be slow if the table is large.
```

### (iii) Inefficient Alternatives vs. `CASE`

#### Exercise 2.6: Multiple `UNION ALL` Queries vs. `CASE` in `GROUP BY` for Segmented Counts

> **Problem:** Count employees in ’Engineering’ (dept_id=2), ’Sales’ (dept_id=3), and others as ’Other’. Show inefficient `UNION ALL` method, then efficient `CASE` in `GROUP BY`.

*(Inefficient `UNION ALL` - Conceptual description from problem)*
```sql
-- Inefficient UNION ALL approach:
SELECT 'Engineering' AS department_category, COUNT(*) AS employee_count
FROM advanced_dates_cases_and_null_space.employees WHERE dept_id = 2
UNION ALL
SELECT 'Sales' AS department_category, COUNT(*) AS employee_count
FROM advanced_dates_cases_and_null_space.employees WHERE dept_id = 3
UNION ALL
SELECT 'Other' AS department_category, COUNT(*) AS employee_count
FROM advanced_dates_cases_and_null_space.employees WHERE dept_id NOT IN (2, 3) OR dept_id IS NULL;
```

*(Efficient `CASE` in `GROUP BY` - Query not provided in snippet for this, but would be:)*
```sql
SELECT
    CASE
        WHEN dept_id = 2 THEN 'Engineering'
        WHEN dept_id = 3 THEN 'Sales'
        ELSE 'Other'
    END AS department_category,
    COUNT(*) AS employee_count
FROM advanced_dates_cases_and_null_space.employees
GROUP BY
    CASE
        WHEN dept_id = 2 THEN 'Engineering'
        WHEN dept_id = 3 THEN 'Sales'
        ELSE 'Other'
    END;
-- Or simply GROUP BY department_category (if alias is allowed in GROUP BY)
```

---

## 🌌 Part 3: `NULL` Space (Handling `NULL`s)

### (i) Meaning, Values, Relations, Advantages

#### Exercise 3.1: Safe Bonus Calculation Using `NULLIF`

> **Problem:** Calculate bonus as `salary * 0.10 / performance_rating`. If `performance_rating` is 0 (or 1 for this example), use `NULLIF` to prevent division by zero.
>
> **Concepts:** `NULLIF(value1, value2)` returns `NULL` if `value1 = value2`, otherwise returns `value1`.
> **Advantage:** `NULLIF` provides a concise way to replace a specific value with `NULL`, often used to prevent errors like division by zero or to treat certain values as missing/not applicable.

```sql
SELECT
    emp_id,
    salary, performance_rating, -- Added for context
    (salary * 0.1) / NULLIF(performance_rating, 1) AS bonus_based_on_rating -- Using 1 as per problem adaptation
FROM advanced_dates_cases_and_null_space.employees;
```

#### Exercise 3.2: Average Billing Rate Excluding Internal/Non-Billable Roles

> **Problem:** Calculate `AVG(billing_rate)` from `employee_projects`. `billing_rate` can be `NULL`. Discuss how `AVG()` handles `NULL`s.
>
> **Concepts:** Aggregate functions like `AVG()`, `SUM()`, `COUNT(column)` ignore `NULL` values by default.
> **Advantage:** This is usually the desired behavior as `NULL` often means "unknown" or "not applicable," and including it as zero (for example) would skew the average.

```sql
SELECT
    project_id, -- Added project_id to make sense of GROUP BY
    AVG(billing_rate) AS standard_avg_billing_rate,
    -- The snippet's "grained_avg" is equivalent to AVG(billing_rate)
    SUM(billing_rate) / COUNT(billing_rate) AS manual_avg_excluding_nulls,
    -- The snippet's "avg2" treats NULLs as 0, which is different:
    SUM(COALESCE(billing_rate, 0)) / COUNT(*) AS avg_treating_null_as_zero, -- Counts all rows in denominator
    COUNT(emp_id) AS total_project_assignments,
    COUNT(billing_rate) AS assignments_with_billing_rate
    -- Original: COUNT(emp_id) = COUNT(billing_rate) billing_rates_as_employees (This is a boolean comparison, not a count)
FROM advanced_dates_cases_and_null_space.employee_projects
GROUP BY project_id;
```
> **Explanation from snippet:** As you can check, the billing rates are not always the same but AVG does not count the number of null values in the ratio for the AVG. Despite this is not the case, could be that null values should be treated as 0 values as shown in avg2.
*(Correct, `AVG(expr)` is `SUM(expr) / COUNT(expr)`, where `COUNT(expr)` only counts non-NULL `expr` values.)*

#### Exercise 3.3: Listing Projects by Actual End Date, Undefined Last

> **Problem:** List projects by `actual_end_date` ascending, but `NULL` `actual_end_date` (not completed) should appear last.
>
> **Concepts:** `ORDER BY ... NULLS LAST` (or `NULLS FIRST`).
> **Advantage:** Provides explicit control over the sort order of `NULL` values, which is often necessary for meaningful reports.

```sql
SELECT project_name, actual_end_date -- selecting relevant columns
FROM advanced_dates_cases_and_null_space.projects
ORDER BY actual_end_date ASC NULLS LAST; -- ASC is default, but explicit is fine
```

### (ii) Disadvantages of `NULL` Handling Concepts

#### Exercise 3.4: `NULLIF` with Unintended Type Coercion or Comparison Issues

> **Problem:** If `performance_rating` was `VARCHAR` and could contain ’N/A’ or be `NULL`. `NULLIF(performance_rating, 0)` (string to integer comparison). Discuss issues.
>
> **Disadvantage:** Comparing values of different data types (e.g., `VARCHAR` with `INTEGER`) in `NULLIF` or other comparisons can lead to:
> *   **Type Coercion Errors:** The database might raise an error if it cannot implicitly convert one type to another (e.g., converting 'N/A' to an integer).
> *   **Unexpected Behavior:** If implicit conversion happens, it might not be what you expect (e.g., '10' string vs 10 number might work, but 'abc' vs 10 won't). This can make `NULLIF` return the original value when you expected `NULL`, or vice-versa, if the comparison logic is flawed due to type issues.

**Answer from Snippet (Paraphrased):**
> Bad database design might use `VARCHAR` for numerical values, including non-numeric strings like 'N/A'. If `NULLIF` compares a `VARCHAR` column with a numeric literal (e.g., `NULLIF(varchar_col, 0)`), and the `VARCHAR` column contains non-convertible strings, errors can occur. Even if coercion is possible for some strings (e.g., '0'), the comparison might not make sense if the intent for 'N/A' was to also treat it as something to be nullified related to the numeric 0.

#### Exercise 3.5: Aggregates over Mostly `NULL` Data Yielding Misleading Results

> **Problem:** If a dept has 10 employees, 1 has `performance_rating` (e.g., 5), rest are `NULL`. `AVG(performance_rating)` would be 5. This could be misleading. Discuss and show query.
>
> **Disadvantage (Interpretation Issue):** Standard aggregate functions ignore `NULL`s. While mathematically correct by definition, an `AVG` of 5 based on a single rated employee out of many might not represent the "average performance" of the department if taken out of context. It's crucial to present such aggregates alongside counts of total vs. non-NULL values.

```sql
SELECT
    d.dept_name, -- Added for context
    AVG(e.performance_rating) AS standard_avg_rating, -- Ignores NULLs
    -- The snippet's "real_avg" using COALESCE(billing_rate,0) / COUNT(COALESCE(billing_rate,0))
    -- is not what's typically needed for rating. AVG(COALESCE(rating, some_default_rating_for_unrated)) would be more common
    -- Or showing counts:
    COUNT(e.emp_id) AS total_employees_in_dept,
    COUNT(e.performance_rating) AS rated_employees_count
    -- Original snippet had:
    -- SUM(COALESCE(billing_rate, 0)) / COUNT(COALESCE(billing_rate, 0)) real_avg, -- This is for billing_rate
    -- COUNT(billing_rate) billing_rates,
    -- COUNT(emp_id) = COUNT(billing_rate) billing_rates_as_employees
FROM advanced_dates_cases_and_null_space.employees e -- Aliased for clarity
JOIN advanced_dates_cases_and_null_space.departments d ON e.dept_id = d.dept_id -- Standard join
-- Original snippet used NATURAL JOINs which is okay if schema matches.
WHERE d.dept_name = 'Human Resources'; -- Example department
-- Group by dept_name if you want this per department without WHERE filter:
-- GROUP BY d.dept_name;
```

### (iii) Inefficient/Verbose Alternatives vs. Concise `NULL` Handling

#### Exercise 3.6: Using `CASE WHEN expr = val THEN NULL ELSE expr END` instead of `NULLIF(expr, val)`

> **Problem:** User wants to convert empty string `reason` in `leave_requests` to `NULL`. Show verbose `CASE` and concise `NULLIF`.

**Verbose `CASE` Method:**
```sql
SELECT emp_name, -- Added for context
    CASE WHEN reason = '' THEN NULL ELSE reason END AS reason_cleaned_case
FROM advanced_dates_cases_and_null_space.leave_requests lr
JOIN advanced_dates_cases_and_null_space.employees e ON lr.emp_id = e.emp_id -- Standard join
-- Original snippet used NATURAL JOIN
WHERE e.emp_name = 'Kevin McCallister';
```

**Concise `NULLIF` Method:**
```sql
SELECT emp_name, -- Added for context
    NULLIF(reason, '') AS reason_cleaned_nullif
FROM advanced_dates_cases_and_null_space.leave_requests lr
JOIN advanced_dates_cases_and_null_space.employees e ON lr.emp_id = e.emp_id -- Standard join
-- Original snippet used NATURAL JOIN
WHERE e.emp_name = 'Kevin McCallister';
```
> `NULLIF(reason, '')` is clearly more concise and directly expresses the intent of nullifying a specific value.

---

## 🏋️ Part 4: Hardcore Problem (Combining Concepts)

### Exercise 4.1: Comprehensive Departmental Project Health and Employee Engagement Report

> **Problem:** Generate a report as of ’2024-01-15’ (’current report date’) assessing project health and employee engagement for each department.
> (Detailed criteria for total active employees, avg tenure, projects info string, avg rating adjusted, employees on leave percentage).
> Order by `projects_info` (custom), then `dept_name`. Limit to top 5.

*(The provided solution in the snippet is quite complex with many CTEs. It's a good approach for breaking down such a problem. Below is a slightly cleaned-up version of the final query structure based on the snippet, with comments on potential areas.)*

```sql
-- The provided query is complex and relies heavily on CTEs.
-- This is a good strategy. The key is to ensure each CTE is correct and joins properly.

WITH context AS (SELECT DATE '2024-01-15' AS report_date),
active_workers AS (
    SELECT e1.*, c.report_date -- Added report_date for use in this CTE
    FROM advanced_dates_cases_and_null_space.employees e1, context c
    WHERE e1.termination_date IS NULL OR e1.termination_date > c.report_date
),
active_workers_on_leave AS (
    SELECT DISTINCT aw.emp_id, aw.dept_id -- Select from active_workers to ensure they are active
    FROM active_workers aw
    JOIN advanced_dates_cases_and_null_space.leave_requests lr USING(emp_id)
    JOIN context c ON TRUE -- To use report_date for leave period check
    WHERE lr.status = 'Approved' AND c.report_date BETWEEN lr.leave_start_date AND lr.leave_end_date -- Check if leave period covers report_date
),
active_managers AS (
    SELECT aw.*
    FROM active_workers aw
    WHERE aw.manager_id IS NULL -- Top-level managers
       OR EXISTS (SELECT 1 FROM advanced_dates_cases_and_null_space.employees e2 WHERE e2.manager_id = aw.emp_id) -- Manages someone
),
active_projects AS (
    SELECT p.*
    FROM advanced_dates_cases_and_null_space.projects p, context c
    WHERE p.actual_end_date IS NULL OR p.actual_end_date > c.report_date
),
-- Projects led by active managers from a specific department
department_active_manager_projects AS (
    SELECT d.dept_id, d.dept_name, p.project_id, p.start_date, p.planned_end_date, p.actual_end_date
    FROM advanced_dates_cases_and_null_space.departments d
    JOIN active_managers am ON d.dept_id = am.dept_id -- Manager is in this department
    JOIN advanced_dates_cases_and_null_space.employee_projects ep ON am.emp_id = ep.emp_id -- Manager is assigned to a project (as lead?)
                                                                    -- Problem says "projects led by active managers"
                                                                    -- Assuming lead_emp_id on projects table or a role on employee_projects
    JOIN active_projects p ON ep.project_id = p.project_id
    WHERE p.lead_emp_id = am.emp_id -- Critical: ensures the manager LEADS the project
),
department_overlap_info AS (
    SELECT DISTINCT dmp1.dept_id, 'High Overlap Risk' AS project_risk_status
    FROM department_active_manager_projects dmp1
    JOIN department_active_manager_projects dmp2
        ON dmp1.dept_id = dmp2.dept_id
        AND dmp1.project_id < dmp2.project_id -- Different projects, same department
    WHERE (dmp1.start_date, COALESCE(dmp1.actual_end_date, dmp1.planned_end_date, 'infinity'::DATE))
          OVERLAPS
          (dmp2.start_date, COALESCE(dmp2.actual_end_date, dmp2.planned_end_date, 'infinity'::DATE))
),
department_critical_deadline_info AS (
    SELECT dept_id, 'Multiple Critical Deadlines' AS project_risk_status
    FROM department_active_manager_projects dmp, context c
    WHERE dmp.planned_end_date BETWEEN c.report_date AND (c.report_date + INTERVAL '30 days')
    GROUP BY dept_id
    HAVING COUNT(DISTINCT dmp.project_id) > 1 -- More than one such project
)

SELECT
    d.dept_name,
    COUNT(DISTINCT aw.emp_id) AS total_active_employees,
    ROUND(AVG(EXTRACT(EPOCH FROM (c.report_date - aw.hire_date)) / (365.25 * 86400)), 2) AS avg_employee_tenure_years,
    -- AVG((c.report_date - aw.hire_date) / 365.25) can also work if interval/numeric division is okay
    COALESCE(doi.project_risk_status, dcdi.project_risk_status, 'Normal Load') AS projects_info,
    ROUND(AVG(COALESCE(aw.performance_rating, 2)), 2) AS avg_rating_adjusted,
    ROUND(
        (COUNT(DISTINCT awol.emp_id) * 100.0) / NULLIF(COUNT(DISTINCT aw.emp_id), 0)
    , 2) AS employees_on_leave_percentage
FROM advanced_dates_cases_and_null_space.departments d
LEFT JOIN active_workers aw ON d.dept_id = aw.dept_id
LEFT JOIN active_workers_on_leave awol ON aw.emp_id = awol.emp_id -- Join on emp_id, ensure awol is also from same dept
LEFT JOIN department_overlap_info doi ON d.dept_id = doi.dept_id
LEFT JOIN department_critical_deadline_info dcdi ON d.dept_id = dcdi.dept_id AND doi.project_risk_status IS NULL -- Only if not high overlap
CROSS JOIN context c
GROUP BY d.dept_id, d.dept_name, c.report_date, doi.project_risk_status, dcdi.project_risk_status
ORDER BY
    CASE COALESCE(doi.project_risk_status, dcdi.project_risk_status, 'Normal Load')
        WHEN 'High Overlap Risk' THEN 1
        WHEN 'Multiple Critical Deadlines' THEN 2
        ELSE 3
    END ASC,
    d.dept_name ASC
LIMIT 5;

-- Snippet's main query structure:
-- SELECT * FROM (
-- 	SELECT
-- 		d.dept_id, d.dept_name,
-- 		COUNT(DISTINCT aw.emp_id) total_active,
-- 		ROUND(AVG((c.report_date - e.hire_date) / 365.25), 2) avg_tenure, -- e is from base employees, should be aw
-- 		CASE
-- 			WHEN d.dept_id IN (SELECT odamap.dept_id FROM overlapped_departmental_actively_managed_active_projects odamap)
-- 				THEN 'High Overlap Risk'
-- 			WHEN 0 < ( -- This count should be COUNT(DISTINCT project_id) > 1
-- 				SELECT COUNT(*) -- this subquery needs to be specific about projects for *this* department
-- 				FROM departmental_actively_managed_active_projects damap, context c
-- 				WHERE damap.dept_id = d.dept_id AND damap.planned_end_date BETWEEN c.report_date AND (c.report_date + INTERVAL '30 days')
-- 			) THEN 'Multiple Critical Deadlines' -- Original query: `INTERVAL '30 days' + c.report_date`
-- 			ELSE 'Normal Loads' -- Typo 'Normal Loads' vs 'Normal Load'
-- 		END project_info,
-- 		NULLIF(ROUND(AVG(COALESCE(e.performance_rating, 2)), 2), 0) avg_performance_rating, -- e from base, should be aw
-- 		ROUND(COUNT(DISTINCT awl.emp_id)::numeric / NULLIF(COUNT(DISTINCT aw.emp_id),0), 2) * 100 actives_leaving_percentage -- NULLIF for division by zero
-- 	FROM advanced_dates_cases_and_null_space.employees e -- This e is problematic if aw (active_workers) is intended
-- 	NATURAL JOIN advanced_dates_cases_and_null_space.departments d
-- 	JOIN active_workers aw ON aw.dept_id = d.dept_id -- Original: ON aw.dept_id = e.dept_id
-- 	LEFT JOIN active_workers_on_leave awl ON awl.dept_id = d.dept_id -- Correct
-- 	CROSS JOIN context c
-- 	WHERE e.termination_date IS NULL OR e.termination_date > c.report_date -- This filter should be on active_workers, not base e
-- 	GROUP BY d.dept_id, d.dept_name -- Missing c.report_date if used in aggregates
-- ) AS mainSubQuery ORDER BY
-- 	CASE
-- 		WHEN project_info = 'High Overlap Risk' THEN 1
-- 		WHEN project_info = 'Multiple Critical Deadlines' THEN 2
-- 		ELSE 3
-- 	END ASC,
-- 	dept_name ASC
-- LIMIT 5;
```
**Critique of Snippet's Hardcore Problem Query:**
*   **CTEs are good**: The breakdown into CTEs (`active_workers`, `active_managers`, etc.) is a solid approach.
*   **`overlapped_departmental_actively_managed_active_projects`**: The join condition `AND ap1.dept_id = ap1.dept_id` is a typo, should be `AND ap1.dept_id = ap2.dept_id`. The `COALESCE` for `ap1.actual_end_date` was used for `ap2`'s end date in the `OVERLAPS` call.
*   **Main Subquery Issues (`mainSubQuery`)**:
    *   It joins `employees e NATURAL JOIN departments d`, then `JOIN active_workers aw ON aw.dept_id = e.dept_id`. This means `e` represents *all* employees, not just active ones for calculations like tenure or performance rating, which is incorrect as per problem statement ("active employees"). Calculations should consistently use `aw`.
    *   The `WHERE e.termination_date ...` clause is redundant if `active_workers` (aliased `aw`) is correctly used for employee data.
    *   `project_info` logic for 'Multiple Critical Deadlines': `WHEN 0 < (SELECT COUNT(*)...)` should be `WHEN (SELECT COUNT(DISTINCT project_id) ... FROM departmental_actively_managed_active_projects ... WHERE damap.dept_id = d.dept_id ... ) > 1`. The original subquery wasn't checking for distinct projects or > 1.
    *   `NULLIF(..., 0)` for `avg_performance_rating`: If all ratings (after COALESCE to 2) average to 0, it becomes NULL. Problem asked for NULL if no rated employees (even after COALESCE), which `AVG` handles by returning `NULL` if all inputs are `NULL`. If after `COALESCE(..., 2)` no employees exist, `AVG` of `2`s would still be `2`. It's subtle.
*   The CTEs for `actively_managed_active_projects` and `departmental_actively_managed_active_projects` could be combined or refined. The key is ensuring that projects are linked to *active managers* from the *specific department* being reported on.

The refined CTE structure provided before the snippet analysis aims to address these structural and logical points for a more robust solution. This type of problem requires careful step-by-step construction and testing of each CTE.