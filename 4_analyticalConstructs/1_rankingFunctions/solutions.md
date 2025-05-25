# 🏆 SQL Ranking Functions: Mastering `ROW_NUMBER`, `RANK`, and `DENSE_RANK` 🏅

Dive into SQL's powerful ranking window functions: `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()`. This guide explores their meanings, how they handle ties, advantages in scenarios like top-N-per-group, potential disadvantages or misinterpretations, and contrasts them with less efficient alternatives. Culminates in a comprehensive problem combining these concepts.

---

## 1. Basic Ranking Functions

### 1.1 `ROW_NUMBER()`

> **Problem:** Assign a unique sequential number to each employee based on their `hire_date` (oldest first).
>
> **`ROW_NUMBER() OVER (ORDER BY ...)`:** Assigns a unique, sequential integer to each row within its partition (or entire dataset if no `PARTITION BY`). Order is determined by the `ORDER BY` clause within `OVER()`. Ties are broken arbitrarily by the database if the `ORDER BY` isn't unique, but row numbers will still be unique.

```sql
SELECT
    first_name,
    last_name,
    hire_date,
    ROW_NUMBER() OVER (ORDER BY hire_date ASC) AS row_num_by_hire_date
FROM analytical_cons_ranking_functions.employees;
```

### 1.2 `RANK()`

> **Problem:** Rank employees based on their `salary` in descending order. Show how ties are handled (gaps in rank).
>
> **`RANK() OVER (ORDER BY ...)`:** Assigns a rank to each row within its partition. Rows with the same value in the `ORDER BY` columns receive the same rank. The next rank after a group of tied rows will be the previous rank plus the number of tied rows, leading to gaps in the ranking sequence.

```sql
SELECT
    first_name,
    last_name,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM analytical_cons_ranking_functions.employees;
```
> **Explanation from snippet:** There exists gaps in ranks 3, 5, and 11s where orders for 4 does not exists as one gap in rank 3 is occupying it. *(If rank 3 has two people, the next rank will be 3 + 2 = 5. Rank 4 is skipped).*

### 1.3 `DENSE_RANK()`

> **Problem:** Rank employees based on `salary` descending using dense ranking. Show how ties are handled (no gaps).
>
> **`DENSE_RANK() OVER (ORDER BY ...)`:** Similar to `RANK()`, assigns a rank based on `ORDER BY` columns, and tied rows get the same rank. However, `DENSE_RANK()` does *not* create gaps in the ranking sequence. The next rank after a tie is always the immediately following integer.

```sql
SELECT
    first_name,
    last_name,
    salary,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_salary_rank
FROM analytical_cons_ranking_functions.employees;
```
> **Explanation from snippet:** Differently to `RANK()`, the first repeated rank in 3 does not skips the rank 4, thus ranks 3 and 4 are repeated. *(If rank 3 has two people, the next distinct value gets rank 4. The "ranks 3 and 4 are repeated" comment is slightly misphrased; it means if two people have the 3rd highest salary, they both get rank 3, and the person with the 4th highest salary gets rank 4.)*

### 1.4 Comparing `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()` within Partitions

> **Problem:** For each department, assign unique row number, rank (with gaps), and dense rank (no gaps) to employees based on salary descending.
>
> **`PARTITION BY ...`**: Divides the rows of the result set into partitions. The window function is applied independently to each partition.

```sql
SELECT
    first_name,
    last_name,
    department, -- Added for context of partitioning
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_row_number,
    RANK()       OVER (PARTITION BY department ORDER BY salary DESC) AS dept_salary_rank,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_dense_salary_rank
FROM analytical_cons_ranking_functions.employees
ORDER BY department, salary DESC; -- Order final result for readability
```
> **Explanations from snippet:**
> *   `ROW_NUMBER()`: Creates unique numbers for each row [within partition], thus the ranking is the 'row number'.
> *   `RANK()`: Creates ranks with gaps when orders for the same rank are repeated [within partition].
> *   `DENSE_RANK()`: Creates ranks without gaps assuring a continuous range of ranks as ranking [within partition].

### 1.5 Advantage - Top N per group

> **Problem:** Identify the top 2 highest-paid employees in each department.
>
> **Advantage:** Ranking functions, especially `ROW_NUMBER()` or `RANK()`/`DENSE_RANK()` (depending on tie-handling needs), are excellent for "Top N per group" problems when used in a subquery and then filtered in the outer query.

```sql
SELECT department, salary, first_name, last_name, rn AS rank_in_department
FROM (
    SELECT
        department, salary, first_name, last_name,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
        -- If ties for 2nd place should all be included, use RANK() or DENSE_RANK() <= 2
        -- e.g., DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS drn
    FROM analytical_cons_ranking_functions.employees
) AS subquery
WHERE rn <= 2 -- For strictly top 2 individuals, even if ties extend beyond.
-- If using DENSE_RANK as drn, WHERE drn <= 2 would include all in top 2 salary tiers.
ORDER BY department, salary DESC;
```

---

## 2. Practice Disadvantages of Technical Concepts

### 2.1 Misinterpretation of `RANK()` vs `DENSE_RANK()` for Nth distinct value

> **Problem:** Manager wants employees in top 2 distinct salary tiers. If "4th highest salary tier" is needed, show how `RANK() = 4` might yield no results, while `DENSE_RANK() = 4` would work.
>
> **Disadvantage/Confusion:** `RANK()` can have gaps. If you're looking for the Nth *distinct value tier*, `DENSE_RANK()` is appropriate. If you're looking for the Nth person based on a ranking that skips numbers for ties, `RANK()` might be used, but it's often less intuitive for "Nth tier".

```sql
WITH EmployeeSalariesRanked AS (
    SELECT
        employee_id,
        first_name,
        last_name,
        salary,
        RANK()       OVER (ORDER BY salary DESC) AS rank_val,       -- Ranks with gaps
        DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank_val  -- Ranks without gaps
    FROM analytical_cons_ranking_functions.employees
)
-- To find employees in the 4th highest salary TIER:
SELECT employee_id, first_name, last_name, salary, dense_rank_val
FROM EmployeeSalariesRanked
WHERE dense_rank_val = 4; -- This correctly gets the 4th distinct salary tier

-- To illustrate RANK() potentially missing the 4th tier:
-- SELECT employee_id, first_name, last_name, salary, rank_val
-- FROM EmployeeSalariesRanked
-- WHERE rank_val = 4;
-- This might return no rows if, e.g., salaries are 100k (rank 1), 90k (rank 2), 80k (rank 3, 2 people), 70k (next rank is 5).
```
> **Explanation from snippet (paraphrased):**
> `RANK()` handles ties by skipping subsequent ranks (e.g., 1, 1, 3, 3, 5). `DENSE_RANK()` does not skip (e.g., 1, 1, 2, 2, 3). If the 4th rank is skipped by `RANK()` due to ties at higher ranks, `RANK() = 4` will find nothing. `DENSE_RANK() = 4` will always find the 4th distinct salary level if it exists. The snippet's `WHERE r2.rank_ = r2.dense_rank_` only shows rows where ranks align, which stops after the first tie that causes a gap in `RANK()`.

### 2.2 Potential for confusion with complex `ORDER BY` in window definition

> **Problem:** Rank employees in dept by salary (desc), then `hire_date` (asc for ties) using `ROW_NUMBER()`. Show how mistake in `hire_date` order (desc) changes row numbers for tied-salary employees.
>
> **Disadvantage/Risk:** The `ORDER BY` clause within the `OVER()` clause is critical. A mistake in specifying secondary (or tertiary, etc.) sort orders for tie-breaking can lead to incorrect or unintended row numbering or ranking, which can affect subsequent logic that relies on these ranks (e.g., selecting top N).

**Correct Tie-Breaking (`hire_date ASC`):**
```sql
SELECT department, employee_id, first_name, salary, hire_date,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC, hire_date ASC) AS row_num_correct_tiebreak
FROM analytical_cons_ranking_functions.employees
ORDER BY department, salary DESC, hire_date ASC;
```

**Incorrect Tie-Breaking (`hire_date DESC` leading to different row numbers for ties):**
```sql
SELECT department, employee_id, first_name, salary, hire_date,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC, hire_date DESC) AS row_num_incorrect_tiebreak
    -- Snippet's error: ORDER BY salary, hire_date DESC (missing DESC on salary for primary sort)
    -- Corrected to reflect intended problem: Primary salary DESC, secondary hire_date DESC (mistake)
FROM analytical_cons_ranking_functions.employees
ORDER BY department, salary DESC, hire_date DESC;
```
> **Explanation from snippet (paraphrased):**
> Correct separation of concerns (ordering directions like `DESC` for salary, `ASC` for `hire_date`) within the `OVER (ORDER BY ...)` clause is crucial. If the secondary sort direction is wrong, employees with the same primary sort value (salary) will get different row numbers than intended, impacting "top N" selections if that tie-breaker was important.

### 2.3 Conceptual disadvantage - Readability with many window functions

> **Problem:** Display employee salary, dept salary rank, overall company salary rank (dense), and row number by full name. Show how multiple window functions make `SELECT` dense.
>
> **Disadvantage:** While powerful, using many window functions in a single `SELECT` clause can make the query verbose and harder to read and understand at a glance. Each window function has its own `OVER()` clause, which can be lengthy.

```sql
SELECT
    employee_id,
    first_name,
    last_name,
    department,
    salary,
    RANK()       OVER (PARTITION BY department ORDER BY salary DESC) AS department_salary_rank,
    DENSE_RANK() OVER (ORDER BY salary DESC)                         AS overall_company_salary_rank,
    ROW_NUMBER() OVER (ORDER BY last_name ASC, first_name ASC)       AS name_alpha_row_number
FROM analytical_cons_ranking_functions.employees
ORDER BY department, department_salary_rank; -- Example ordering for readability
```
> **Explanation from snippet (paraphrased):**
> To understand the result, strong focus is needed. The meaning of combining various ranks (e.g., "overall salary rank when the data is primarily ordered by department salary rank") can become obscure. Such complex queries are rare and demand high focus, potentially indicating the need to break down the analysis or clarify requirements.

---

## 3. Practice Cases of Inefficient Alternatives

### 3.1 Find the employee(s) with the highest salary in each department

> **Problem:** List employee(s) with highest salary per dept (ties included). Show inefficient subquery/MAX approach vs. efficient ranking function.
>
> **Advantage of Ranking Functions:** More concise, often more readable, and generally more performant for "Top N per group" (here N=1 salary tier) than correlated subqueries or joins to aggregated subqueries.

**Inefficient (Subquery with `MAX` and `JOIN`):**
```sql
-- EXPLAIN ANALYZE -- Snippet uses this
SELECT e1.* -- dept_max_salary also selected in snippet
FROM analytical_cons_ranking_functions.employees AS e1
JOIN (
    SELECT department, MAX(salary) AS dept_max_salary
    FROM analytical_cons_ranking_functions.employees
    GROUP BY department
) AS e2 ON e1.department = e2.department AND e1.salary = e2.dept_max_salary;
```
> **Explanation from snippet (paraphrased):** Verbose and not highly efficient. Needs to aggregate to find max salary per department, then join back to employees and filter.

**Efficient (Ranking Function):**
```sql
-- EXPLAIN ANALYZE -- Snippet uses this
SELECT *
FROM (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_salary_dense_rank
        -- RANK() could also be used if "highest salary" means the first rank even with gaps.
        -- DENSE_RANK() = 1 specifically targets the highest salary tier.
    FROM analytical_cons_ranking_functions.employees
) AS subquery
WHERE subquery.dept_salary_dense_rank = 1;
```
> **Explanation from snippet (paraphrased):** Creates a rank partitioning by department, ordered by salary. Filtering on rank = 1 in an outer query is direct and efficient. PostgreSQL optimizes window functions well.
> *(Snippet mentions index creation for massive datasets, which is good practice but performance difference might be small on small datasets. `EXPLAIN ANALYZE` results from snippet show minor diff: 0.278ms vs 0.215ms)*

### 3.2 Assign sequential numbers to records

> **Problem:** Unique sequential number for product sales (ordered by `sale_date` then `sale_id`). Show inefficient correlated subquery `COUNT` vs. `ROW_NUMBER()`.
>
> **Advantage of `ROW_NUMBER()`:** Highly efficient and specifically designed for assigning sequential numbers. Correlated subquery `COUNT` is very inefficient (O(N^2) complexity in naive execution).

**Inefficient (Correlated Subquery `COUNT`):**
```sql
SELECT
    ps1.*,
    (
        SELECT COUNT(*) -- No +1 needed if we want 0-indexed preceding count, or depends on definition
        FROM analytical_cons_ranking_functions.product_sales AS ps2
        WHERE (ps2.sale_date < ps1.sale_date) OR -- Count rows strictly before
              (ps2.sale_date = ps1.sale_date AND ps2.sale_id < ps1.sale_id)
    ) + 1 AS manual_rank_inefficient -- +1 for 1-based rank
FROM analytical_cons_ranking_functions.product_sales AS ps1
ORDER BY manual_rank_inefficient;
-- Snippet's WHERE clause was slightly off for "preceding": (ps2.sale_date > ps1.sale_date) OR (ps2.sale_date = ps1.sale_date AND ps2.sale_id > ps2.sale_id)
-- This would count succeeding records if aiming for a descending rank. For ascending rank (older first), it should be <.
```
> **Explanation from snippet (paraphrased):** Highly inefficient (many comparisons), not easily readable. Correlated subquery adds redundancy.

**Efficient (`ROW_NUMBER()`):**
```sql
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY sale_date ASC, sale_id ASC) AS auto_sequential_number
FROM analytical_cons_ranking_functions.product_sales AS ps1
ORDER BY auto_sequential_number; -- Or by sale_date, sale_id
```
> **Explanation from snippet (paraphrased):** Highly efficient and simplified, based on ordering without redundant data processing.

### 3.3 Ranking based on an aggregate

> **Problem:** Rank product categories by total sales amount (desc). Show inefficient correlated subquery/complex logic for ranking vs. ranking function on aggregated results.
>
> **Advantage of Ranking Functions on Aggregates:** Apply ranking directly to the results of a `GROUP BY` operation (often via a subquery or CTE), which is clean and efficient.

**Inefficient (Correlated Subquery for Ranking after Aggregation):**
```sql
WITH OrderedCategories AS ( -- CTE for reusability
    SELECT category, SUM(sale_amount) AS total_sales
    FROM analytical_cons_ranking_functions.product_sales
    GROUP BY category
)
SELECT
    oc2.*,
    (
        SELECT COUNT(*) + 1 -- Count categories with strictly greater total_sales
        FROM OrderedCategories AS oc1
        WHERE oc1.total_sales > oc2.total_sales
    ) AS manual_rank
FROM OrderedCategories AS oc2
ORDER BY manual_rank;
```
> **Explanation from snippet (paraphrased):** Despite CTE simplifying, the select needs many comparisons within its subquery to assign ranks.

**Efficient (Ranking Function on Aggregated Subquery):**
```sql
SELECT
    category,
    total_sales,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS auto_sales_rank
    -- RANK() could also be used, DENSE_RANK() ensures no gaps in category sales ranking.
FROM (
    SELECT category, SUM(sale_amount) AS total_sales
    FROM analytical_cons_ranking_functions.product_sales
    GROUP BY category
) AS aggregated_categories -- Renamed from ordered_categories for clarity
ORDER BY auto_sales_rank ASC;
```
> **Explanation from snippet (paraphrased):** Uses a subquery as source for ranking function. Ranking functions are optimized (e.g., tree/hash based).

---

## 4. Practice Hardcore Combined Problem

### Comprehensive Employee Analysis

> **Problem:** For each department:
> 1.  Identify employee(s) with highest salary in that department.
> 2.  For these top-paid employees, determine their salary rank across the entire company (`RANK()`).
> 3.  Show their department’s average salary.
> 4.  Calculate difference between their salary and department’s average.
> 5.  Identify employee hired immediately after them in same department (name & hire date). NULL if last hired.

*(The snippet uses CTEs and joins effectively to solve this. `departmental_hiring_sequence` CTE is good for the "next hire" part.)*

```sql
WITH DepartmentalStats AS ( -- Pre-calculate department average salary
    SELECT
        department,
        AVG(salary) AS avg_dept_salary
    FROM analytical_cons_ranking_functions.employees
    GROUP BY department
),
RankedEmployees AS ( -- Rank employees within department by salary and overall by salary
    SELECT
        employee_id,
        first_name,
        last_name,
        department,
        salary,
        hire_date,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_salary_rank, -- For top-paid in dept
        RANK()       OVER (ORDER BY salary DESC)                         AS company_salary_rank -- Overall company rank
    FROM analytical_cons_ranking_functions.employees
),
TopPaidInDepartment AS ( -- Filter for the highest salary tier in each department
    SELECT *
    FROM RankedEmployees
    WHERE dept_salary_rank = 1
),
EmployeeHireSequenceInDept AS ( -- Determine hiring sequence within department
    SELECT
        employee_id,
        department,
        first_name || ' ' || last_name AS full_name,
        hire_date,
        -- Use LEAD to find the next hired employee's details
        LEAD(employee_id, 1, NULL) OVER (PARTITION BY department ORDER BY hire_date ASC) AS next_hired_employee_id,
        LEAD(first_name || ' ' || last_name, 1, NULL) OVER (PARTITION BY department ORDER BY hire_date ASC) AS next_hired_full_name,
        LEAD(hire_date, 1, NULL) OVER (PARTITION BY department ORDER BY hire_date ASC) AS next_hired_hire_date
    FROM analytical_cons_ranking_functions.employees
)
SELECT
    tp.employee_id AS top_employee_id,
    tp.first_name || ' ' || tp.last_name AS top_employee_full_name,
    tp.department,
    tp.salary AS top_employee_salary,
    tp.company_salary_rank,
    ds.avg_dept_salary,
    tp.salary - ds.avg_dept_salary AS salary_diff_from_dept_avg,
    ehs_next.next_hired_employee_id, -- Details of the next hire
    ehs_next.next_hired_full_name,
    ehs_next.next_hired_hire_date
FROM TopPaidInDepartment tp
JOIN DepartmentalStats ds ON tp.department = ds.department
LEFT JOIN EmployeeHireSequenceInDept ehs_next ON tp.employee_id = ehs_next.employee_id -- Join to get next hire details for the top paid employee
ORDER BY tp.department, tp.salary DESC, tp.employee_id;

-- Snippet's approach:
-- CTE `departmental_hiring_sequence` used RANK() on hire_date DESC, then tried to match rank = rank-1.
-- Using LEAD() is more direct for "next hired".
-- Main query in snippet:
--  - Subquery `e1` for `d_rank` (dept salary rank) and `c_rank` (company salary rank). Good.
--  - Join to `avg_salaries` (similar to `DepartmentalStats`). Good.
--  - Join to `departmental_hiring_sequence` (aliased `current_hiring_sequence`) for current employee's hire rank.
--  - LEFT JOIN to `departmental_hiring_sequence` again (aliased `next_hiring_sequence`) trying to find next by `current_hiring_sequence.hiring_rank = next_hiring_sequence.hiring_rank - 1`. This is clever way to simulate LEAD if `hiring_rank` was based on `ASC` hire_date. If `DESC` as in snippet, it would be `rank = rank + 1`.
--  - `WHERE e1.d_rank = 1` correctly filters for top-paid in department.
```
**Comments on Snippet's Hardcore Solution:**
*   The use of a CTE (`departmental_hiring_sequence`) to rank employees by hire date within their department is a good step for the "next hired" logic.
*   The main query correctly identifies top-paid employees per department (`e1.d_rank = 1`) and their company-wide salary rank.
*   It correctly calculates and joins department average salary.
*   The logic for finding the "next hired" employee by joining `departmental_hiring_sequence` to itself and comparing ranks (`current_hiring_sequence.hiring_rank = next_hiring_sequence.hiring_rank - 1`) is an alternative to using the `LEAD()` window function. For this to work as "next hired (later date)", the `hiring_rank` in `departmental_hiring_sequence` should be `ORDER BY hire_date ASC`. The snippet used `DESC`, so it finds the *previously* hired. If `ASC` was used, `current.rank = next.rank - 1` would be correct. The `LEAD()` function is generally more straightforward for this specific task.

The revised solution above uses `LEAD()` for clarity and directness in finding the next hired employee.