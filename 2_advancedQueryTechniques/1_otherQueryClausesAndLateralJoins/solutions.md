# 📜 Advanced SQL: Other Query Clauses & LATERAL Joins 🚀

This guide delves into specialized SQL clauses like `FETCH`/`OFFSET` for pagination and `LATERAL` joins for complex row-by-row operations. We'll cover their meanings, advantages, disadvantages, common pitfalls, and tackle challenging problems that combine these concepts.

---

## Part 1: Other Query Clauses (`FETCH`, `OFFSET`)

### 1.1(i) Practice Meanings, Values, Relations, Unique Usage, and Advantages

#### 1.1.1 Exercise 1: Meaning of `OFFSET` and `FETCH`

> **Problem:** Retrieve product sales from the 6th to the 10th most recent sale (inclusive). Display `saleId`, `productName`, `saleDate`.
>
> **Meaning:**
> *   `ORDER BY`: Crucial for `OFFSET` and `FETCH` to make sense. It establishes a stable order for the rows.
> *   `OFFSET N ROWS`: Skips the first N rows from the ordered result set.
> *   `FETCH NEXT M ROWS ONLY` (or `LIMIT M` in some RDBMS): Returns the next M rows after the offset.
> **Advantage:** Provides a standard SQL way to implement pagination, allowing retrieval of specific "pages" of data.

*(Query commented out in snippet, but it's the standard solution)*
```sql
SELECT saleId, productName, saleDate
FROM advanced_query_techniques.productSales
ORDER BY saleDate DESC -- Most recent first
OFFSET 5 ROWS          -- Skip the first 5
FETCH NEXT 5 ROWS ONLY; -- Take the next 5 (rows 6, 7, 8, 9, 10)
```

#### 1.1.2 Exercise 2: Unique usage of `FETCH` with `OFFSET` for specific slicing

> **Problem:** List all employees, but skip the first 3 highest-paid employees and then show the next 5 highest-paid after those. Display `employeeId`, `firstName`, `lastName`, `salary`.
>
> **Unique Usage/Advantage:** Allows precise "slicing" of an ordered dataset, useful for leaderboards, top-N-after-M scenarios, etc.

*(Query commented out in snippet, but it's the standard solution)*
```sql
SELECT employeeId, firstName, lastName, salary
FROM advanced_query_techniques.employees
ORDER BY salary DESC -- Highest paid first
OFFSET 3 ROWS          -- Skip the top 3
FETCH NEXT 5 ROWS ONLY; -- Take the next 5 (employees ranked 4th to 8th by salary)
```

### 1.2(ii) Practice Disadvantages of `OFFSET`/`FETCH`

#### 1.2.1 Exercise 3: Disadvantage of `OFFSET` without `ORDER BY`

> **Problem:** Show the second page of 5 product sales using `OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY` but *without* an `ORDER BY` clause. Run multiple times. Are results always the same? Explain.
>
> **Disadvantage:** Without `ORDER BY`, the order of rows in a result set is not guaranteed by SQL. Databases are free to return rows in any order (e.g., based on physical storage, available indexes, parallelism). Using `OFFSET` without `ORDER BY` leads to unpredictable and inconsistent results, making pagination meaningless.

```sql
SELECT productName, saleDate                       -- Completely unmeaningful because it
FROM advanced_query_techniques.productSales        -- unless users are interested in to see
-- NO ORDER BY CLAUSE!                               -- randomly purchased by any person
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
```
> **Explanation from snippet:** Completely unmeaningful because it [returns rows randomly] unless users are interested in to see randomly purchased by any person. The results are *not* guaranteed to be the same across multiple executions.

#### 1.2.2 Exercise 4: Disadvantage of large `OFFSET` - Performance

> **Problem:** Imagine `ProductSales` has millions of rows. Explain potential performance disadvantage of fetching a page deep into the result (e.g., `OFFSET 1000000 ROWS FETCH NEXT 10 ROWS ONLY`) when ordered by `saleDate`.
>
> **Disadvantage:** With a large `OFFSET`, the database might still have to:
> 1.  Identify *all* rows that satisfy the query conditions.
> 2.  Sort these (potentially many) rows according to `ORDER BY`.
> 3.  Scan through and discard the `OFFSET` number of rows before finally fetching the desired few.
> This can be very inefficient as the work to sort and skip rows grows with the offset value, even if only a few rows are ultimately returned. This is often called "late row lookups" or "skip scan" inefficiency. Keyset pagination or seek methods are often preferred for deep pagination on very large tables.

**Answer from snippet (paraphrased and clarified):**
> The query becomes less meaningful for human understanding with huge offsets as `OFFSET`/`FETCH` are typically for viewing important (e.g., top/recent) subsets. These functions might not be optimized for skipping millions of rows. The database still has to materialize or effectively step over all the offset rows according to the `ORDER BY` clause, which is inefficient for large offsets. Other patterns (like keyset pagination using `WHERE (col1, col2) > (last_val1, last_val2) ORDER BY col1, col2 LIMIT N`) can be more efficient for deep pagination.

### 1.3(iii) Practice Cases Where People Use Inefficient Basic Solutions Instead

#### 1.3.1 Exercise 5: Inefficient pagination attempts vs. `OFFSET`/`FETCH`

> **Problem:** Display the 3rd ”page” of employees (3 employees per page) ordered by `hireDate` (oldest first). (Employees 7, 8, 9).
> a) Describe/implement less direct ways without `OFFSET`/`FETCH`.
> b. Solve with `OFFSET`/`FETCH`.
> c. Discuss why `OFFSET`/`FETCH` is preferred.

**a) Inefficient Alternatives:**
*   **Using `ROW_NUMBER()` (Window Function - actually efficient, but not `OFFSET`/`FETCH`):**
    ```sql
     SELECT employeeId, firstName, lastName, hireDate, salary       -- Window function solution
     FROM (
         SELECT
             employeeId, firstName, lastName, hireDate, salary,
             ROW_NUMBER() OVER (ORDER BY hireDate ASC) as rn
         FROM advanced_query_techniques.Employees
     ) AS Sub
     WHERE rn > 6 AND rn <= 9; -- For page 3 (rows 7, 8, 9)
    ```
*   **Fetching more and discarding in application:** Fetch `page_number * page_size` rows and then take the last `page_size` rows in the application (e.g., fetch 9 rows, discard first 6). Inefficient due to data transfer.
    ```sql
     SELECT employeeId, firstName, lastName, hireDate, salary         -- With upper limit but without lower
     FROM advanced_query_techniques.Employees                         -- bounding: making not responsive
     ORDER BY hireDate ASC LIMIT 9;                                   -- data for specific frontends
    -- (Client then takes rows 7,8,9)
    ```
*   **Complex subqueries (less common now):** Simulating row skipping with nested subqueries and `COUNTs` (very inefficient and complex).

**b) `OFFSET`/`FETCH` Solution:**
Page 3, 3 items per page. Skip (3-1) * 3 = 6 rows. Fetch next 3.
```sql
SELECT employeeId, firstName, lastName, hireDate, salary           -- With variable pagination where
FROM advanced_query_techniques.Employees                           -- 2 is the page number (0-indexed for formula)
ORDER BY hireDate ASC -- Oldest first
OFFSET (3 * 2) ROWS FETCH NEXT 3 ROWS ONLY;                         -- (page_size * (page_number - 1))
                                                                    -- Highly portable and efficient
```
*Snippet's formula `(3*2)` implies page number 2 if 0-indexed, or page 3 if 1-indexed `(3 * (3-1))`.*

**c) Why `OFFSET`/`FETCH` is preferred:**
*   **Standard SQL:** Widely supported and standard.
*   **Readability & Intent:** Clearly expresses the intent of pagination.
*   **Efficiency (generally):** More direct for the database to optimize for pagination compared to manual simulation (though deep pagination still has challenges, as noted in 1.2.2). `ROW_NUMBER()` is also efficient but `OFFSET/FETCH` is often more concise for simple pagination.

### 1.4(iv) Practice a Hardcore Problem Combining Previous Concepts

#### 1.4.1 Exercise 6: Hardcore `OFFSET`/`FETCH` with Joins, Set Operations, Subqueries, Filtering

> **Problem:**
> 1.  Combined list:
>     *   Group A: ’Engineering’ dept, salary >= $70,000.
>     *   Group B: ’Marketing’ dept, hire_date >= ’2020-01-01’.
> 2.  Remove duplicates by `employeeId` (`UNION` does this by default if all selected columns are the same).
> 3.  Order by `lastName` (A-Z), then `firstName` (A-Z).
> 4.  Retrieve 2nd to 3rd position (inclusive).
> 5.  Display `employeeId`, full name, `departmentName`, `salary`, `hireDate`.

```sql
SELECT employeeId, firstName || ' ' || lastName AS fullName, departmentName, salary, hireDate
FROM (
    -- Group A
    SELECT e.employeeId, e.firstName, e.lastName, d.departmentName, e.salary, e.hireDate
    FROM advanced_query_techniques.employees e
    JOIN advanced_query_techniques.departments d ON e.departmentId = d.departmentId -- Explicit JOIN
    WHERE d.departmentName = 'Engineering' AND e.salary >= 70000
    UNION -- Removes duplicates between Group A and Group B based on all selected columns
    -- Group B
    SELECT e.employeeId, e.firstName, e.lastName, d.departmentName, e.salary, e.hireDate
    FROM advanced_query_techniques.employees e
    JOIN advanced_query_techniques.departments d ON e.departmentId = d.departmentId -- Explicit JOIN
    WHERE d.departmentName = 'Marketing' AND e.hireDate >= DATE '2020-01-01'
) AS combined_list -- aliased subquery sq in snippet
ORDER BY lastName ASC, firstName ASC -- ASC is default
OFFSET 1 ROW -- Skip the 1st position to get to the 2nd
FETCH NEXT 2 ROWS ONLY; -- Retrieve 2nd and 3rd positions
-- Snippet: OFFSET 2 ROW FETCH NEXT 2 ROWS ONLY; (This would be 3rd and 4th positions)
-- For 2nd to 3rd: skip 1, take 2.
```
*Note on snippet's solution for 1.4.1:*
*   Used `NATURAL JOIN`. Explicit `JOIN ON` is generally safer.
*   `UNION` correctly handles deduplication if an employee falls into both groups A and B.
*   `OFFSET 2 ROW FETCH NEXT 2 ROWS ONLY` would retrieve the 3rd and 4th employees. For 2nd to 3rd, it's `OFFSET 1 ROW FETCH NEXT 2 ROWS ONLY`.

---

## Part 2: `LATERAL` Joins

### 2.1 (i) Practice Meanings, Values, Relations, Unique Usage, and Advantages

#### 2.1.1 Exercise 1: Meaning and unique usage of `LATERAL` - Top N per group

> **Problem:** For each department, list the top 2 employees with the highest salary. Use `LIMIT 2` in the `LATERAL` subquery. Display `departmentName`, `employeeId`, `firstName`, `lastName`, `salary`.
>
> **Meaning:** A `LATERAL` join allows a subquery in the `FROM` clause (the right side of the join) to reference columns from tables that appear earlier on the left side of the `LATERAL` join. The subquery is evaluated for each row of the left table.
> **Unique Usage/Advantage:** Powerful for "top-N-per-group" problems, applying table-valued functions, or complex correlated calculations where the subquery depends on values from the outer row.

```sql
SELECT d.departmentName, sq.employeeId, sq.firstName, sq.lastName, sq.salary -- d.departmentId also selected in snippet
FROM complementary_other_query_clauses_lateral_joins.departments AS d,
LATERAL ( -- Implicit CROSS JOIN LATERAL syntax (comma), explicit JOIN LATERAL is also common
    SELECT e.employeeId, e.firstName, e.lastName, e.salary -- e. aliasing in subquery
    FROM complementary_other_query_clauses_lateral_joins.employees e
    WHERE e.departmentId = d.departmentId -- Correlation: links employees to current department
    ORDER BY e.salary DESC
    LIMIT 2 -- Get top 2 per department
) AS sq;
-- Can also be written as:
-- FROM ...departments d JOIN LATERAL (...) sq ON TRUE
```

#### 2.1.2 Exercise 2: `LATERAL` with a function-like subquery producing multiple related rows

> **Problem:** For each 'Electronics' sale (>= '2023-03-01'), calculate total revenue. List up to 2 *earlier* sales for the *same product*, ordered by most recent of earlier sales. Display current sale info & prior sales info.
>
> **Advantage:** `LATERAL` allows the subquery to act like a function, taking parameters (correlated columns) from the outer query row and returning a set of related rows.

```sql
SELECT
    m.currentSaleId,
    m.currentProductName,
    m.currentTotalRevenue,
    o.previousSaleId,
    o.previousSaleDate,
    o.previousQuantitySold
FROM ( -- Outer query defining the main sales (m)
    SELECT
        ps.saleId AS currentSaleId,
        ps.saleDate AS currentSaleDate, -- Needed for correlation in LATERAL
        ps.productName AS currentProductName,
        (ps.quantitySold * ps.unitPrice) AS currentTotalRevenue,
        ps.category -- Used for filtering in lateral if needed, better to filter earlier
    FROM complementary_other_query_clauses_lateral_joins.productSales ps
    WHERE ps.category = 'Electronics' AND ps.saleDate >= DATE '2023-03-01'
) m
LEFT JOIN LATERAL ( -- Use LEFT JOIN LATERAL if you want to keep main sales even if no prior sales found
    SELECT
        prev_ps.saleId AS previousSaleId,
        prev_ps.saleDate AS previousSaleDate,
        prev_ps.quantitySold AS previousQuantitySold
    FROM complementary_other_query_clauses_lateral_joins.productSales prev_ps
    WHERE prev_ps.productName = m.currentProductName -- Correlate on product
      AND prev_ps.saleDate < m.currentSaleDate       -- Earlier sale
      -- AND prev_ps.category = 'Electronics' -- Redundant if m is already filtered, but safe
    ORDER BY prev_ps.saleDate DESC -- Most recent of the earlier sales first
    LIMIT 2
) o ON TRUE; -- ON TRUE is common for LATERAL joins not using explicit JOIN LATERAL syntax
-- Snippet's structure: SELECT sq.* FROM (SELECT * FROM (main_sales) m, LATERAL (other_sales) o) as sq;
-- This is okay, but explicitly selecting columns and using LEFT JOIN LATERAL is often clearer.
```

### 2.2 (ii) Practice Disadvantages of `LATERAL` Joins

#### 2.2.1 Exercise 3: Disadvantage of `LATERAL` - Potential Performance Impact

> **Problem:** For every employee, use `LATERAL` to find up to 3 other employees in the same department, hired before, with higher salary. Discuss performance disadvantage.
>
> **Disadvantage:** Since the `LATERAL` subquery is executed for each row of the outer table, if the outer table is large and the subquery is complex or operates on poorly indexed columns, the overall query can be very slow. It's similar to the N+1 problem with correlated subqueries in `SELECT`.

```sql
SELECT
    e.employeeId, e.firstName AS empFirstName, e.lastName AS empLastName, -- Aliased outer employee
    o.seniorFirstName, o.seniorLastName, o.seniorHireDate, o.seniorSalary
FROM complementary_other_query_clauses_lateral_joins.employees e
LEFT JOIN LATERAL ( -- Use LEFT JOIN LATERAL to keep all employees 'e'
    SELECT
        i.firstName AS seniorFirstName, i.lastName AS seniorLastName,
        i.hireDate AS seniorHireDate, i.salary AS seniorSalary
    FROM complementary_other_query_clauses_lateral_joins.employees i
    WHERE i.departmentId = e.departmentId -- Same department
      AND i.hireDate < e.hireDate       -- Hired before
      AND i.salary > e.salary           -- Higher salary
    ORDER BY i.salary DESC -- Or other relevant order for "up to 3"
    LIMIT 3
) o ON TRUE;
```
> **Explanation from snippet (paraphrased):**
> This is an example of how a badly designed query or database could create bad performance scenarios. If the correlated columns (`departmentId`, `hireDate`, `salary`) in the `LATERAL` subquery are not well-indexed, and especially if no pre-filtering is applied to the outer table `e`, the subquery execution for each of the (potentially many) rows in `e` can be costly. The snippet correctly points out that if `hireDate` and `salary` (continuous values) are used for correlation without good indexing or broad pre-filters, it can be highly inefficient for large tables.

#### 2.2.2 Exercise 4: Disadvantage - Readability/Complexity for simple cases

> **Problem:** Retrieve employees and their department names. Solve with `INNER JOIN`, then `LATERAL`. Explain why `LATERAL` is overkill here.
>
> **Disadvantage:** For simple lookups or joins that can be expressed with standard `JOIN` syntax, using `LATERAL` adds unnecessary complexity and verbosity, making the query harder to read and understand without providing any benefit.

**a) Simple `INNER JOIN`:**
```sql
SELECT e.*, d.departmentName
FROM complementary_other_query_clauses_lateral_joins.employees e
JOIN complementary_other_query_clauses_lateral_joins.departments d -- NATURAL JOIN in snippet
    ON e.departmentId = d.departmentId; -- Explicit join condition
```

**b) `LATERAL` Join:**
```sql
SELECT e.*, sq.departmentName
FROM complementary_other_query_clauses_lateral_joins.employees e,
LATERAL (
    SELECT d.departmentName
    FROM complementary_other_query_clauses_lateral_joins.departments d
    WHERE e.departmentId = d.departmentId
    -- LIMIT 1 -- Not strictly needed if (deptId -> deptName) is 1-to-1, but safe
) sq;
```
> **Explanation from snippet:** Despite speed being potentially similar (if `departmentId` is well-indexed), the `LATERAL` approach is more verbose and doesn't offer additional value for this simple lookup. A standard `JOIN` is much clearer and more idiomatic.

### 2.3 (iii) Practice Cases Where People Use Inefficient Basic Solutions Instead

#### 2.3.1 Exercise 5: Inefficient Top-1 per group without `LATERAL`

> **Problem:** For each `region` in `ProductSales`, find the single product sale with the highest total revenue (`qty*price`). Tie-break with latest `saleDate`. Display region, product, date, revenue.
> a) Describe/implement inefficient ways without `LATERAL`/window functions.
> b) Solve with `LATERAL`.
> c) Discuss why `LATERAL` (or window functions) is superior.

**a) Inefficient Alternatives:**
*   **Multiple correlated subqueries in `SELECT` (as in snippet):** For each distinct region, run separate subqueries to find the top product name, top revenue, top sale date. This is very repetitive and inefficient.
    ```sql
    -- Snippet's example of inefficient correlated subqueries:
    SELECT
        DISTINCT PS.region,
        (SELECT PS_inner.productName ... WHERE PS_inner.region = PS.region ORDER BY ... LIMIT 1) AS topProductName,
        (SELECT (PS_inner.quantitySold * PS_inner.unitPrice) ... WHERE PS_inner.region = PS.region ORDER BY ... LIMIT 1) AS topRevenue,
        (SELECT PS_inner.saleDate ... WHERE PS_inner.region = PS.region ORDER BY ... LIMIT 1) AS topSaleDate -- Added for completeness
    FROM complementary_other_query_clauses_lateral_joins.ProductSales PS;
    -- This needs three separate correlated subquery executions for each distinct region.
    ```
*   **Complex joins with self-joins and MAX/GROUP BY:** Can become very convoluted to correctly implement tie-breaking.

**b) Efficient `LATERAL` Solution:**
```sql
SELECT
    r.region,
    o.productName,
    o.saleDate,
    o.totalRevenue
FROM ( -- Get distinct regions
    SELECT DISTINCT region
    FROM complementary_other_query_clauses_lateral_joins.productSales
    -- Or use GROUP BY region if that's more intuitive, though DISTINCT is fine here
) r
CROSS JOIN LATERAL ( -- Or JOIN LATERAL (...) ON TRUE
    SELECT
        ps_lat.productName,
        ps_lat.saleDate,
        (ps_lat.quantitySold * ps_lat.unitPrice) AS totalRevenue
    FROM complementary_other_query_clauses_lateral_joins.productSales ps_lat
    WHERE ps_lat.region = r.region -- Correlate to the current region
    ORDER BY totalRevenue DESC, ps_lat.saleDate DESC -- Order by revenue, then by date for tie-breaking
    LIMIT 1
) o;
```
> **Explanation from snippet (for LATERAL):** This aggregates data directly in FROM avoiding the double (or triple) comparison of subqueries in SELECT. Now two subqueries are joined and data calculated in the second subquery LATERAL at the same time and just selected one time. *(More accurately, the LATERAL subquery is executed once per distinct region from `r`.)*

**c) Why `LATERAL` (or Window Functions) is Superior:**
*   **Readability:** More clearly expresses the "for each X, find top Y" logic.
*   **Efficiency:** Generally more efficient than multiple correlated subqueries in `SELECT` or complex self-joins, as the database can optimize the per-group operation better.
*   **Maintainability:** Easier to understand and modify.

### 2.4(iv) Practice a Hardcore Problem Combining Previous Concepts

#### 2.4.1 Exercise 6: Hardcore `LATERAL` with complex correlation, aggregation, filtering

> **Problem:** For each manager:
> 1.  Identify top 2 most recent project assignments for each *directly managed employee*.
> 2.  For these assignments (`hoursWorked > 50`), calculate `complexityScore = hoursWorked * MAX(1, YEAR(assignmentDate) - 2020)`.
> 3.  For each manager, sum these `complexityScores` from all considered projects of their direct reports.
> 4.  Display manager's `employeeId`, `firstName`, `lastName`, and total `sumComplexityScore`.
> 5.  Only managers with `sumComplexityScore > 100`.
> 6.  Order by `sumComplexityScore` DESC.

*(The snippet's approach uses a subquery `s1` to find managers, then a `LATERAL` join `l1` to get project assignments for those managers directly, not for their reports. The logic needs adjustment to iterate through reports of a manager, then projects of those reports.)*

**Revised Approach (Conceptual Outline):**
This is a multi-level `LATERAL` or nested CTE problem.
```sql
WITH Managers AS (
    SELECT DISTINCT e1.employeeId AS manager_id, e1.firstName AS manager_firstName, e1.lastName AS manager_lastName
    FROM complementary_other_query_clauses_lateral_joins.employees e1
    WHERE EXISTS (SELECT 1 FROM complementary_other_query_clauses_lateral_joins.employees e2 WHERE e2.managerId = e1.employeeId)
),
ManagerReportProjectScores AS (
    SELECT
        m.manager_id,
        m.manager_firstName,
        m.manager_lastName,
        COALESCE(report_project_data.complexityScore, 0) AS complexityScore -- Use COALESCE if LATERAL is LEFT JOIN
    FROM Managers m
    LEFT JOIN LATERAL ( -- Iterate through direct reports of manager 'm'
        SELECT
            dr.employeeId AS direct_report_id -- Direct Report ID
        FROM complementary_other_query_clauses_lateral_joins.employees dr
        WHERE dr.managerId = m.manager_id
    ) direct_reports ON TRUE
    LEFT JOIN LATERAL ( -- For each direct_report, get their top 2 recent relevant projects and calculate score
        SELECT
            ep.hoursWorked * GREATEST(EXTRACT(YEAR FROM ep.assignmentDate) - 2020, 1) AS complexityScore
        FROM complementary_other_query_clauses_lateral_joins.employeeProjects ep
        WHERE ep.employeeId = direct_reports.direct_report_id -- Project belongs to this direct report
          AND ep.hoursWorked > 50
        ORDER BY ep.assignmentDate DESC
        LIMIT 2
    ) report_project_data ON TRUE -- This part applies the core calculation logic
)
SELECT
    manager_id,
    manager_firstName,
    manager_lastName,
    SUM(complexityScore) AS total_sum_complexity_score
FROM ManagerReportProjectScores
GROUP BY manager_id, manager_firstName, manager_lastName
HAVING SUM(complexityScore) > 100
ORDER BY total_sum_complexity_score DESC;
```

**Critique of Snippet's 2.4.1 Query:**
```sql
-- Snippet:
SELECT s1.*, SUM(l1.complexityScore) sumComplexityScore -- s1 is the manager
FROM ( -- s1: Identifies managers
    SELECT DISTINCT e1.employeeId, e1.firstName, e1.lastName
    FROM complementary_other_query_clauses_lateral_joins.employees e1
    WHERE EXISTS(SELECT * FROM complementary_other_query_clauses_lateral_joins.employees e2 WHERE e1.employeeId = e2.managerId)
) s1, -- Comma implies CROSS JOIN LATERAL
LATERAL ( -- l1: Gets projects for the MANAGER (s1), not their reports.
    SELECT projectName, hoursWorked * GREATEST(EXTRACT(YEAR FROM assignmentDate) - 2020, 1) complexityScore
    FROM complementary_other_query_clauses_lateral_joins.employeeProjects ep
    WHERE s1.employeeId = ep.employeeId -- Project is assigned to the MANAGER (s1.employeeId)
      AND hoursWorked * GREATEST(EXTRACT(YEAR FROM assignmentDate) - 2020, 1) > 50 -- This condition is on complexityScore, not hoursWorked alone
    ORDER BY ep.assignmentDate DESC LIMIT 2
) l1
GROUP BY s1.employeeId, s1.firstName, s1.lastName
HAVING SUM(l1.complexityScore) > 100
ORDER BY sumComplexityScore DESC;
```
*   **Core Logic Flaw:** The `LATERAL` subquery `l1` finds projects for the *manager* (`s1.employeeId = ep.employeeId`), not for the employees they manage. The problem asks for projects of the *direct reports*.
*   **Complexity Score Condition:** The condition `hoursWorked * GREATEST(EXTRACT(YEAR FROM assignmentDate) - 2020, 1) > 50` is applied. The problem stated "Only consider projects with `hoursWorked > 50`" before calculating complexity. This should be `ep.hoursWorked > 50`.
*   The revised conceptual outline above attempts to address the "projects of direct reports" aspect, which would typically involve a nested `LATERAL` or multiple CTEs to bridge manager -> reports -> report's projects.
This problem is genuinely hardcore and requires careful layering of logic.