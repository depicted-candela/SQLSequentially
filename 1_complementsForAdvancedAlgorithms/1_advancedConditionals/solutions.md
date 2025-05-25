# 🚀 Advanced SQL WHERE Clause Techniques: A Practice Guide 🚀

This document consolidates a series of SQL practice problems focusing on advanced `WHERE` clause conditions, their meanings, advantages, disadvantages, and practical applications.

---

## 💡 1. Practice Meanings, Values, Relations, Advantages, and Unique Uses

### 1.1 Subquery with `IN`

> **Problem:** List the names and salaries of all employees who work in departments located in ’New York’.

```sql
SELECT emp_name, salary
FROM complementary.employees
WHERE dept_id IN (SELECT dept_id FROM complementary.departments WHERE dept_name = 'New York');
```

### 1.2 Subquery with `EXISTS`

> **Problem:** Find the names of departments that have at least one employee with a salary greater than $85,000.

```sql
SELECT *
FROM complementary.departments d
WHERE EXISTS (SELECT 1 FROM complementary.employees e WHERE salary > 85000 AND d.dept_id = d.dept_id);
```
*(Note: The condition `d.dept_id = d.dept_id` in the subquery is likely intended to be `e.dept_id = d.dept_id` for a correlated subquery relating employees to departments.)*

### 1.3 Subquery with `ANY`

> **Problem:** List employees whose salary is greater than `ANY` salary in the ’Support’ department. (This means their salary is greater than the minimum salary in the ’Support’ department).

```sql
SELECT *
FROM complementary.employees e1
WHERE salary > ANY (SELECT salary
FROM complementary.employees e2
JOIN complementary.departments d
ON d.dept_name = 'Support' AND e2.dept_id = d.dept_id);
```

### 1.4 Subquery with `ALL`

> **Problem:** Find employees in the ’Sales’ department whose salary is less than `ALL` salaries in the ’Technology’ department.

```sql
SELECT *
FROM complementary.employees e1
JOIN complementary.departments d1 ON d1.dept_name = 'Sales' AND e1.dept_id = d1.dept_id
WHERE salary < ALL (
SELECT salary
FROM complementary.employees e2
JOIN complementary.departments d2 ON d2.dept_name = 'Technology' AND e2.dept_id = d2.dept_id
);
```

### 1.5 `IS DISTINCT FROM`

> **Problem:** List employees whose performance rating is different from 3. This list should include employees who have a `NULL` performance rating (as `NULL` is distinct from 3).

```sql
SELECT * FROM complementary.employees WHERE performance_rating IS DISTINCT FROM 3;
```

### 1.6 `IS NOT DISTINCT FROM`

> **Problem:** Find pairs of employees (display their names) who have the exact same manager id, including cases where both employees have no manager (i.e., their manager id is `NULL`). Avoid listing an employee paired with themselves.

```sql
SELECT e1.emp_name emp1, e2.emp_name emp2, e2.manager_id
FROM complementary.employees e1
JOIN complementary.employees e2
ON e1.emp_id < e2.emp_id
WHERE e2.manager_id IS NOT DISTINCT FROM e1.manager_id;
```

---

## ⚠️ 2. Practice Disadvantages of All Its Technical Concepts

### 2.1 `NOT IN` with Subquery Returning `NULL`

> **Problem:** Attempt to list employees who are NOT leads on any project using the condition `emp_id NOT IN (SELECT lead_emp_id FROM projects)`. Observe the (potentially unexpected) result given that `projects.lead_emp_id` can be `NULL` (e.g., ’NoLead Project’). Explain why this happens.

```sql
SELECT *
FROM complementary.employees
WHERE emp_id NOT IN (
SELECT lead_emp_id FROM complementary.projects
);
```
> **Explanation:** Prone to errors because a single `NULL` value in the list returned by the subquery can cause the entire `NOT IN` condition to evaluate to unknown or false for all rows. This is because `X NOT IN (Y, Z, NULL)` is equivalent to `X != Y AND X != Z AND X != NULL`. Since `X != NULL` is unknown, the entire condition can be affected.

**Alternative 1 (Filtering NULLs in Subquery):**
```sql
SELECT *
FROM complementary.employees
WHERE emp_id NOT IN (
SELECT lead_emp_id FROM complementary.projects WHERE lead_emp_id IS NOT NULL
); -- Simpler alternative
```

**Alternative 2 (Using `NOT EXISTS`):**
```sql
SELECT *
FROM complementary.employees e1
WHERE NOT EXISTS (
SELECT 1 FROM complementary.projects p WHERE e1.emp_id = p.lead_emp_id
); -- Other alternative, generally safer and often more performant
```

### 2.2 `!= ANY` Misinterpretation

> **Problem:** Find employees whose salary is not equal to any salary found in the ’Intern Pool’ department. The ’Intern Pool’ department currently has one employee (’Intern Zero’) with a salary of $20,000. Consider what happens if the ’Intern Pool’ department had multiple distinct salaries (e.g., $20,000, $22,000). Explain the logical evaluation of `salary != ANY (subquery salaries)` in such a scenario.

The provided query uses `!= ALL`. The problem statement refers to `!= ANY`.
`salary != ANY (S)` means there is at least one salary `s` in set `S` such that `salary != s`. This is true for almost everyone unless their salary is the *only* salary in `S` and `S` contains only one distinct value.

The provided query demonstrates using `!= ALL`:
```sql
SELECT e1.*
FROM complementary.employees e1
WHERE e1.salary != ALL ( -- The problem with this is that a salary different to any
                         -- in the same set is the same set to be compared, thus ALL
                         -- statement must be used to get the difference between both sets
    SELECT e2.salary
    FROM complementary.employees e2
    JOIN complementary.departments d
    ON d.dept_name = 'Intern Pool' AND e1.dept_id = d.dept_id -- Note: This join condition likely intends e2.dept_id = d.dept_id
);
```
> **Explanation from original comment (referring to `!= ALL`):** The problem with this (referring to a hypothetical `!= ANY` for finding salaries *not* matching *any* intern salary) is that a salary different to any in the same set is the same set to be compared, thus `ALL` statement must be used to get the difference between both sets if you want salaries different from *every* salary in the set.

*   **Logical evaluation of `salary != ANY (subquery_salaries)`:**
    If subquery_salaries are `{S1, S2, S3}`, then `salary != ANY (subquery_salaries)` evaluates to `(salary != S1) OR (salary != S2) OR (salary != S3)`.
    This condition is true if the employee's salary is different from *at least one* salary in the subquery result.
    If 'Intern Pool' has salaries {$20,000, $22,000}:
    An employee with salary $20,000: `$20,000 != ANY ($20,000, $22,000)` -> `($20,000 != $20,000) OR ($20,000 != $22,000)` -> `FALSE OR TRUE` -> `TRUE`.
    An employee with salary $25,000: `$25,000 != ANY ($20,000, $22,000)` -> `($25,000 != $20,000) OR ($25,000 != $22,000)` -> `TRUE OR TRUE` -> `TRUE`.
    This means `!= ANY` is often not what's intended when trying to exclude salaries present in another set. `NOT IN` or `!= ALL` are typically used for such exclusion.

### 2.3 Performance of `IS DISTINCT FROM` vs. Standard Operators (Conceptual)

> **Problem:** Consider finding employees where `performance_rating` is 3.
> *   Compare conceptually querying this using `performance_rating = 3` versus `performance_rating IS NOT DISTINCT FROM 3`.
> *   When might the `IS NOT DISTINCT FROM` approach be slightly less optimal if `performance_rating` is indexed and guaranteed `NOT NULL`? Discuss potential minor overheads or familiarity issues for developers.

> **Explanation:** `IS DISTINCT FROM` and `IS NOT DISTINCT FROM` are designed to handle `NULL` values in a specific way (treating `NULL` as a comparable value).
> If a column like `performance_rating` is guaranteed `NOT NULL`:
> *   `performance_rating = 3` is the most direct and typically most performant way. Database optimizers are highly tuned for this common operator.
> *   `performance_rating IS NOT DISTINCT FROM 3` would effectively be equivalent to `performance_rating = 3` (since `performance_rating` cannot be `NULL`, and 3 is not `NULL`). However, the `IS NOT DISTINCT FROM` operator might involve a slightly more complex evaluation path internally, as it's designed for `NULL`-aware comparisons (`(X = Y) OR (X IS NULL AND Y IS NULL)`). If the column is indexed, `performance_rating = 3` can directly use the index. While `IS NOT DISTINCT FROM 3` might also use the index, there could be a marginal, often negligible, overhead due to the more generalized nature of the operator.
> *   **Familiarity:** Standard operators like `=` are more universally understood by developers than `IS DISTINCT FROM` / `IS NOT DISTINCT FROM`. Using the latter where not strictly necessary (i.e., when `NULL`s are not a concern or handled differently) can reduce readability for those less familiar with these specific SQL extensions.
>
> In summary, when a column is `NOT NULL` and you are comparing with a non-`NULL` value, standard equality (`=`) or inequality (`!=`, `<>`) operators are generally preferred for clarity and potentially optimal performance. `IS [NOT] DISTINCT FROM` shines when `NULL`s need to be treated as known values in comparisons.

### 2.4 Readability of `EXISTS` vs. `IN` for Simple Cases

> **Problem:** Retrieve employees who are in departments listed in a small, explicit list of department IDs (e.g., department IDs 1 and 2).
> *   Write a query fragment using `IN` with a literal list.
> *   Write a query fragment using `EXISTS` with a subquery that provides these values.
> *   Compare the readability and conciseness of these two approaches for this specific simple case.

**Using `IN` (with a subquery as provided in the file, though a literal list `IN (1,2)` is simpler for the described scenario):**
```sql
SELECT * FROM complementary.employees WHERE dept_id IN (SELECT dept_id FROM complementary.departments d WHERE d.dept_id IS NOT NULL); -- clearly cleaner (referring to IN being cleaner than EXISTS for this type of lookup)
```
*(For an explicit list, it would be: `WHERE dept_id IN (1, 2)`)*

**Using `EXISTS` (with a subquery as provided):**
```sql
SELECT * FROM complementary.employees e WHERE EXISTS (SELECT d.dept_id FROM complementary.departments d WHERE d.dept_id IS NOT NULL AND d.dept_id = d.dept_id);
```
*(Note: The condition `d.dept_id = d.dept_id` in the subquery is always true and doesn't correlate correctly. It should be `e.dept_id = d.dept_id`. For an explicit list via subquery: `WHERE EXISTS (SELECT 1 FROM (VALUES (1), (2)) AS dept_list(id) WHERE e.dept_id = dept_list.id)` or similar, depending on SQL dialect.)*

> **Comparison for simple cases (e.g., `dept_id IN (1,2)` vs. an `EXISTS` equivalent):**
> *   **`IN` with a literal list:** Highly readable and concise for small, fixed sets of values. `WHERE dept_id IN (1, 2)` is very direct.
> *   **`EXISTS` with a subquery:** Can be more verbose for this specific scenario. Constructing a subquery to represent a small literal list (e.g., using `VALUES` or a temporary table) adds boilerplate compared to the simple `IN` list.
>
> For the simple case of checking against a small, explicit list of IDs, `IN` is generally preferred for its superior readability and conciseness. `EXISTS` becomes more powerful and often more readable/performant for complex existence checks or when comparing against large sets derived from other tables.

---

## 🔄 3. Practice Inefficient/Incorrect Alternatives vs. Advanced WHERE Conditions

### 3.1 Inefficient `COUNT()` vs. `EXISTS` for Existence Check

> **Problem:** List department names that have at least one project associated with them (i.e., a project where `lead_emp_id` belongs to an employee in that department).
> *   **Task:** Write a query using an inefficient approach: a correlated subquery with `COUNT()` in the `WHERE` clause, checking if `COUNT() > 0`.
> *   **Consideration:** Why is using `EXISTS` generally more efficient for this type of ”is there at least one?” check?

**Inefficient Approach (`COUNT()`):**
```sql
SELECT d.dept_name        -- Inefficient
FROM complementary.departments d
WHERE (
SELECT COUNT (*) -- Note: COUNT() changed to COUNT(*) for SQL standard
FROM complementary.projects p
JOIN complementary.employees e ON p.lead_emp_id = e.emp_id
WHERE e.dept_id = d.dept_id
) > 0;
```

**Efficient Approach (`EXISTS`):**
```sql
SELECT d.dept_name        -- Efficient: uses less code and does not need to count all the things, just uses a bool
FROM complementary.departments d	-- value if data exists using 1 in SELECT
WHERE EXISTS (
SELECT 1
FROM complementary.projects p
JOIN complementary.employees e ON p.lead_emp_id = e.emp_id
WHERE e.dept_id = d.dept_id
);
```
> **Why `EXISTS` is more efficient:**
> `EXISTS` stops processing the subquery as soon as the first matching row is found, as it only cares about the existence of *at least one* such row.
> `COUNT(*)` in a subquery typically has to count *all* matching rows before the outer query can evaluate the `> 0` condition. This can be significantly more work, especially if many rows match the subquery's criteria.

### 3.2 Verbose/Incorrect `NULL` Handling vs. `IS DISTINCT FROM`

> **Problem:** Find employees whose `last_bonus` is not $5000.00. This list should include employees whose `last_bonus` is `NULL`, as `NULL` is considered different from $5000.00.
> *   **Task:** Write a query using a verbose approach: `(last_bonus <> 5000.00 OR last_bonus IS NULL)`.
> *   **Consideration:** How does `last_bonus IS DISTINCT FROM 5000.00` offer a more concise and less error-prone solution?

**Verbose Approach:**
```sql
SELECT emp_name, last_bonus 							-- Inefficient (in terms of verbosity and potential for error)
FROM complementary.employees
WHERE ( last_bonus <> 5000.00 OR last_bonus IS NULL );
```

**Concise Approach (`IS DISTINCT FROM`):**
```sql
SELECT emp_name, last_bonus 							-- Efficient: includes null values as different of 5000
FROM complementary.employees							-- because <> avoids unknown values (NULLs)
WHERE (last_bonus IS DISTINCT FROM 5000.00);
```
> **How `IS DISTINCT FROM` is better:**
> `value IS DISTINCT FROM X` evaluates to true if `value` is different from `X`, or if one is `NULL` and the other is not. It essentially treats `NULL` as a comparable value.
> This is more concise than the `(col <> X OR col IS NULL)` pattern.
> It's less error-prone because it directly expresses the logic of "is different, treating NULLs as values," reducing the chance of forgetting the `OR col IS NULL` part, which is a common mistake when using `<>`.

### 3.3 Complex `NULL`-aware Equality vs. `IS NOT DISTINCT FROM`

> **Problem:** Find all employees whose `manager_id` is the same as Peter Pan’s `manager_id`. (Peter Pan, `emp_id` 16, has a `NULL` `manager_id`). Do not include Peter Pan himself in the results.
> *   **Task:** Write a query using a complex approach: explicitly check for equality of `manager_id` with Peter Pan’s `manager_id`, AND explicitly check if both the employee’s `manager_id` and Peter Pan’s `manager_id` are `NULL`.
> *   **Consideration:** How does using `IS NOT DISTINCT FROM` simplify this `NULL`-aware equality check and make the query more robust and readable?

**Complex/Verbose Approach:**
```sql
SELECT emp_name , manager_id   		-- Inefficient (in terms of verbosity and complexity)
FROM complementary.employees
WHERE emp_id != 16
AND (
( manager_id = ( SELECT manager_id FROM complementary.employees WHERE emp_id = 16) )
OR
( manager_id IS NULL AND ( SELECT manager_id FROM complementary.employees WHERE emp_id = 16) IS NULL ));
```

**Simplified Approach (`IS NOT DISTINCT FROM`):**
```sql
SELECT emp_name , manager_id			-- Efficient (more readable, robust)
FROM complementary.employees
WHERE emp_id != 16
AND manager_id IS NOT DISTINCT FROM ( SELECT manager_id FROM complementary.employees WHERE emp_id = 16);
```
> **How `IS NOT DISTINCT FROM` simplifies:**
> `value1 IS NOT DISTINCT FROM value2` means `(value1 = value2) OR (value1 IS NULL AND value2 IS NULL)`. This directly implements `NULL`-aware equality.
> It's much more readable and less verbose than spelling out both conditions (direct equality and both are `NULL`).
> It's more robust because it correctly handles cases where Peter Pan's `manager_id` might change from `NULL` to a non-`NULL` value, or vice-versa, without needing to adjust the logic. The single `IS NOT DISTINCT FROM` condition covers all scenarios correctly.

### 3.4 Using `LEFT JOIN` and checking for `NULL` vs. `NOT EXISTS`

> **Problem:** Find departments that have no employees. (Note: The dataset includes an ’Empty Department’ specifically for this exercise).
> *   **Task:** Write a query using a common approach: `LEFT JOIN` the `departments` table with the `employees` table and then filter for departments where the employee’s primary key (or any non-nullable employee column from the join) is `NULL`. Another variant could use `GROUP BY` and `HAVING COUNT(e.emp_id) = 0`.
> *   **Consideration:** For the specific task of checking non-existence, how does `NOT EXISTS` compare in terms of directness and potential efficiency?

**Approach 1 (`LEFT JOIN ... IS NULL`):**
```sql
SELECT d.dept_name
FROM complementary.departments d
LEFT JOIN complementary.employees e ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;				-- Potentially Inefficient: it needs to perform the join operation first for all departments.
```
> *Original Comment:* Inefficient: it needs to make a cartesian product in the join (More accurately, it performs an outer join, which can be costly if the right table is large, before filtering).

**Approach 2 (`LEFT JOIN ... GROUP BY ... HAVING COUNT = 0`):**
```sql
SELECT d.dept_name
FROM complementary.departments d
LEFT JOIN complementary.employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING COUNT ( e.emp_id ) = 0;		-- Potentially Inefficient: it needs to join, then group, then count for all departments.
```
> *Original Comment:* Inefficient: it needs to count the number of rows before to return the value about existence.

**Approach 3 (`NOT EXISTS` - Often More Direct and Efficient):**
```sql
SELECT d.dept_name
FROM complementary.departments d
WHERE NOT EXISTS (
SELECT 1 FROM complementary.employees e WHERE d.dept_id = e.dept_id
);									-- Efficient: returns true if the subquery finds no rows, can stop early.
```
> *Original Comment:* Efficient: returns the bool value as the existence is checked.
> **Comparison:**
> `NOT EXISTS` is often more direct for checking non-existence. It clearly states "find departments for which no matching employees exist."
> Performance-wise, `NOT EXISTS` can be more efficient because the database can stop searching the `employees` table for a given department as soon as it finds *any* employee, thus determining that the department *does* have employees (making `NOT EXISTS` false for that department). For departments with no employees, it will scan relevant portions of the `employees` table to confirm non-existence.
> `LEFT JOIN / IS NULL` and `LEFT JOIN / COUNT` approaches might involve materializing a larger intermediate result set before filtering or aggregation. However, modern optimizers can sometimes transform these patterns into more efficient operations similar to `NOT EXISTS`.

---

## 🧩 4. Hardcore Problem Combining Previous Concepts

> **Problem Statement:**
> Identify ”Key Departments” based on the following criteria:
> 1.  The department name must contain either ’Tech’ or ’HR’ (case-sensitive as per standard SQL `LIKE`).
> 2.  The department’s `monthly_budget` IS `NULL`, OR its `monthly_budget` = 50000.00.
> 3.  The department must have at least one ”veteran” employee associated with it. This is determined by checking if there `EXISTS` such an employee in the department. A ”veteran” employee is defined as someone:
>     *   Hired more than 8 years ago from `CURRENT_DATE`.
>     *   Whose `performance_rating` `IS DISTINCT FROM` 1 (i.e., their rating is not 1, or their rating is `NULL`).
>
> For these ”Key Departments”, calculate the total hours assigned to all their employees for projects that started on or after ’2023-01-01’. If a department has no such employees or projects meeting this date criterion, their total hours should be displayed as 0.
>
> Display the `dept_name` and the calculated `total_project_hours`. Order the results in descending order of `total_project_hours`, then by `dept_name` alphabetically. Limit the result to the top 3 departments.

*(Optional setup query mentioned in file: `UPDATE complementary.departments SET monthly_budget = 50000.00 WHERE dept_name = 'Technology';`)*

```sql
SELECT sq1.dept_name dept_name, SUM(ep.hours_assigned) total_project_hours
FROM complementary.employee_projects ep
JOIN complementary.projects p ON p.proj_id = ep.proj_id
JOIN complementary.employees e ON ep.emp_id = e.emp_id
JOIN (
    SELECT dept_id, dept_name
    FROM complementary.departments d
    WHERE
        ( dept_name LIKE '%Tech%' OR dept_name LIKE '%HR%' )
        AND ( monthly_budget IS NOT DISTINCT FROM 50000 ) 
        -- Note: The problem states "monthly_budget IS NULL, OR its monthly_budget = 50000.00".
        -- `monthly_budget IS NOT DISTINCT FROM 50000` is equivalent to `monthly_budget = 50000`
        -- if 50000 is a non-NULL constant.
        -- To match the problem statement accurately, this should be:
        -- `(monthly_budget IS NULL OR monthly_budget = 50000.00)`
    AND EXISTS (
        SELECT 1 -- Changed from SELECT * for convention
        FROM complementary.employees e_vet -- aliased for clarity
        WHERE
            e_vet.dept_id IS NOT DISTINCT FROM d.dept_id -- Ensures correct join for veteran check
            AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, e_vet.hire_date)) > 8
            AND e_vet.performance_rating IS DISTINCT FROM 1
    )
) AS sq1 ON e.dept_id = sq1.dept_id
WHERE p.start_date >= TO_DATE('2023-01-01', 'YYYY-MM-DD')
GROUP BY sq1.dept_name 
ORDER BY total_project_hours; 
-- Note: The problem statement requires "ORDER BY total_project_hours DESC, dept_name ASC LIMIT 3".
-- The provided query is missing DESC, the secondary sort, and LIMIT.
-- A query fully matching the problem description would end with:
-- ORDER BY total_project_hours DESC, sq1.dept_name ASC
-- LIMIT 3; 
-- (Syntax for LIMIT might vary by SQL dialect, e.g., TOP 3 for SQL Server)
```