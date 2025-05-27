# 🚀 SQL Query Optimization & Performance: Indexing, EXPLAIN, and Advanced Functions ⚙️

This guide explores crucial SQL concepts for optimizing query performance, including various indexing strategies (B-tree, GIN, GiST, BRIN, Hash), understanding `EXPLAIN` plans, and efficiently using window functions and aggregates. Each section covers meanings, advantages, disadvantages, inefficient alternatives, and culminates in a hardcore problem.

---

## Part 1: Indexing Strategies

### 1.2.1 Exercise IS-1: Meaning, Values, Advantages of B-tree Indexes

> **Problem:** HR frequently searches for employees by exact `jobTitle`. Query is slow.
> 1. Query `jobTitle = 'Data Analyst'`.
> 2. `EXPLAIN ANALYZE` before index.
> 3. Create B-tree index on `jobTitle`.
> 4. `EXPLAIN ANALYZE` after index. Describe changes.
>
> **B-tree Index:** Default index type in many RDBMS. Stores data in a sorted tree structure, allowing efficient equality and range searches (e.g., `=`, `>`, `<`, `BETWEEN`, `LIKE 'prefix%'`).
> **Advantage:** Speeds up queries filtering on indexed columns, especially for equality and range lookups with good selectivity. Reduces the number of disk blocks to read.

**1. Query:**
```sql
SELECT *
FROM query_optimizations_and_performance.employees
WHERE jobtitle = 'Data Analyst';
```

**2. `EXPLAIN ANALYZE` (Before Index - Snippet Output):**
```
QUERY PLAN
Seq Scan on employees  (cost=0.00..862.00 rows=5000 width=92) (actual time=0.034..14.065 rows=5000 loops=1)
  Filter: ((jobtitle)::text = 'Data Analyst'::text)
  Rows Removed by Filter: 25000
Planning Time: 0.223 ms
Execution Time: 14.739 ms
```
> *Observation: Uses a `Seq Scan` (Sequential Scan), reading the whole table.*

**3. Create Index:**
```sql
CREATE INDEX idxEmployeeJobTitle -- Renamed from snippet for clarity
ON query_optimizations_and_performance.employees (jobtitle);
```

**4. `EXPLAIN ANALYZE` (After Index - Snippet Output):**
```
QUERY PLAN
Bitmap Heap Scan on employees  (cost=59.04..608.54 rows=5000 width=92) (actual time=0.434..1.967 rows=5000 loops=1)
  Recheck Cond: ((jobtitle)::text = 'Data Analyst'::text)
  Heap Blocks: exact=487
  ->  Bitmap Index Scan on idxEmployeeJobTitle  (cost=0.00..57.79 rows=5000 width=0) (actual time=0.328..0.328 rows=5000 loops=1)
        Index Cond: ((jobtitle)::text = 'Data Analyst'::text)
Planning Time: 0.189 ms
Execution Time: 2.318 ms
```
> **Change Description:** The plan changed from `Seq Scan` to `Bitmap Heap Scan` using a `Bitmap Index Scan` on `idxEmployeeJobTitle`. Execution time dropped significantly (14.7ms to 2.3ms).
> **Why B-tree helps:** The B-tree index allows the database to quickly locate rows matching `jobTitle = 'Data Analyst'` without scanning the entire table. The `Bitmap Index Scan` finds all matching index entries, creates a bitmap of row locations, and then the `Bitmap Heap Scan` fetches these rows from the table. This is much faster for selective queries.

*(Snippet also shows a partial index `WHERE jobtitle = 'Data Analyst'`, which further refines the index for this specific value, leading to slightly better performance for this exact query but less general utility.)*

### 1.2.2 Exercise IS-2: Disadvantages of Indexes / When B-tree Indexes are Not Optimal

> **Problem:**
> 1.  **Write Overhead:** 5,000 new `Employees`. 10 indexes vs. 2 indexes. Describe `INSERT` performance difference.
> 2.  **Low Selectivity / Small Table:** `Departments` table (10 rows). Find `location = 'Building A, Floor 1'`. Index on `location`. Does optimizer use it? Why seq scan on small table/common value?
> 3.  **Leading Wildcard `LIKE`:** Find `email LIKE '%user123%'`. B-tree on `email`. Does it use index effectively?

**1. Write Overhead:**
> **Disadvantage:** Indexes improve read performance but incur overhead on write operations (`INSERT`, `UPDATE`, `DELETE`). Each index must be updated when data changes. More indexes mean more work during writes.
> **Difference:** `INSERT` performance would be significantly slower with 10 indexes compared to 2. For each of the 5,000 new rows, all 10 indexes need to be updated to include the new data. With only 2 indexes, this update work is much less.
> **Explanation from snippet (paraphrased):** Indexes must be updated for new rows. 10 indexes mean 10 updates per new row, plus potential rebalancing for existing rows. Careful selection of indexes is needed to avoid overhead, especially with frequent writes.

**2. Low Selectivity / Small Table:**
```sql
-- Before index on location (snippet)
EXPLAIN ANALYZE SELECT * FROM query_optimizations_and_performance.departments WHERE location = 'Building A, Floor 1';
-- "Seq Scan on departments ... (actual time=0.017..0.022 rows=1 loops=1)"

CREATE INDEX idxDepartmentsLocation ON query_optimizations_and_performance.departments(location);

-- After index on location (snippet)
EXPLAIN ANALYZE SELECT * FROM query_optimizations_and_performance.departments WHERE location = 'Building A, Floor 1';
-- "Seq Scan on departments ... (actual time=0.068..0.078 rows=1 loops=1)"
```
> **Does optimizer use index?** In the snippet's example, it still chose a `Seq Scan`.
> **Why Seq Scan?**
> *   **Small Table:** For very small tables (like 10 rows), reading the entire table sequentially from disk (which might already be in memory) can be faster than the overhead of an index lookup (reading parts of the index, then fetching the row from the table).
> *   **Low Selectivity (Very Common Value):** If the indexed value is very common (e.g., `status = 'Active'` and 90% of rows are active), an index scan might identify a large portion of the table. A sequential scan might be deemed more efficient by the planner than fetching many rows via an index.
> **Explanation from snippet (paraphrased):** An index adds complexity. For small tables, the overhead of using the index might not be worth it, like "paying for a helicopter to go to the park in your neighborhood."

**3. Leading Wildcard `LIKE`:**
```sql
EXPLAIN ANALYZE SELECT * FROM query_optimizations_and_performance.employees WHERE email LIKE '%user123%';
-- (Likely shows Seq Scan or a less efficient index scan if available for other parts of email)
```
> **Does B-tree index work effectively for `LIKE '%user123%'`?** No.
> **Why?** Standard B-tree indexes are organized like a dictionary, sorted from the beginning of the string. A leading wildcard (`%`) means the search can start anywhere in the string, so the B-tree cannot be used efficiently to jump to potential matches. It would require checking every entry.
> **Explanation from snippet:** It does not use the B-tree index because the most appropriate index to do so is the GIN or GiST indices (for trigram or full-text search).

### 1.2.3 Exercise IS-3: Inefficient Alternatives / GIN & GiST Indexes for Full-Text Search

> **Problem:** Search `projectDescription` for "innovation" AND "strategy".
> 1. Query with `LIKE '%innovation%' AND LIKE '%strategy%'`. `EXPLAIN ANALYZE`.
> 2. Create GIN index on `projectDescription` using `to_tsvector`.
> 3. Rewrite query using GIN index (e.g., `@@ to_tsquery`).
> 4. `EXPLAIN ANALYZE` FTS query. Compare. Explain GIN advantage.
>
> **GIN (Generalized Inverted Index) / GiST (Generalized Search Tree):** Index types suitable for composite values (like arrays, JSON) or full-text search. For FTS, they index lexemes (words) and their locations.
> **Advantage for FTS:** GIN indexes allow very fast searching for documents containing specific words or combinations of words, much more efficiently than `LIKE` with wildcards on large text fields.

**1. Inefficient `LIKE` query (Snippet Output):**
```sql
EXPLAIN ANALYZE SELECT * FROM query_optimizations_and_performance.projects
WHERE projectDescription LIKE '%innovation%' AND projectDescription LIKE '%strategy%';
-- "Seq Scan on projects ... (actual time=1.200..85.178 rows=500 loops=1)"
-- Execution Time: 85.270 ms
```
> *Observation: Seq Scan, slow.*

**2. Create GIN Index:**
```sql
CREATE INDEX idxDescriptionsOnProjects ON query_optimizations_and_performance.projects
USING GIN(to_tsvector('english', projectDescription));
```

**3. FTS Query:**
```sql
SELECT * FROM query_optimizations_and_performance.projects
WHERE to_tsvector('english', projectDescription) @@ to_tsquery('english', 'innovation & strategy');
```

**4. `EXPLAIN ANALYZE` FTS query (Snippet Output):**
```
-- "Bitmap Heap Scan on projects ... (actual time=2.591..6.133 rows=1500 loops=1)"
-- "  ->  Bitmap Index Scan on idxdescriptionsonprojects ... (actual time=2.038..2.039 rows=1500 loops=1)"
-- Execution Time: 6.556 ms
```
> **Comparison:** Changed from `Seq Scan` to `Bitmap Index Scan` using the GIN index. Performance improved dramatically (85ms to 6.5ms).
> **GIN Advantage:** GIN creates an inverted index of words. `to_tsquery` looks up these words efficiently in the index to find matching documents. `LIKE '%...%'` on a B-tree indexed column (if it were just text) would still be a full scan or very inefficient.

### 1.2.4 Exercise IS-4 (Hardcore Problem - Comprehensive Indexing Strategy)

> **Problem:** Report: 'Active' employees in 'Engineering' or 'Product Management', hired 2015-2020, `performanceScore >= 3.5`. List full name, job title, dept name, hire date, # projects. Order: dept, #projects desc, hire date desc.
> 1. Write query.
> 2. List columns for indexing.
> 3. Propose single-column B-tree indexes.
> 4. Create, `EXPLAIN ANALYZE`. Describe plan.

**1. SQL Query (from snippet, slightly adapted for clarity):**
```sql
WITH EmployeeProjectCounts AS (
    SELECT ep.employeeId, COUNT(DISTINCT ep.projectId) AS project_count
    FROM query_optimizations_and_performance.employeeProjects ep
    GROUP BY ep.employeeId
)
SELECT
    d.departmentName,
    e.hireDate,
    (e.firstName || ' ' || e.lastName) AS fullName,
    e.jobTitle, -- Added jobTitle as requested
    COALESCE(epc.project_count, 0) AS projects_assigned -- Use COALESCE if employee might have no projects
FROM query_optimizations_and_performance.employees e
JOIN query_optimizations_and_performance.departments d
    ON e.departmentId = d.departmentId
LEFT JOIN EmployeeProjectCounts epc ON e.employeeId = epc.employeeId -- LEFT JOIN
WHERE e.status = 'Active'
  AND d.departmentName IN ('Engineering', 'Product Management')
  AND e.hireDate BETWEEN DATE '2015-01-01' AND DATE '2020-12-31'
  AND e.performanceScore >= 3.5
ORDER BY d.departmentName ASC, projects_assigned DESC, e.hireDate DESC;
```

**2. Columns for Indexing:**
*   `Employees`: `status`, `departmentId` (for join), `hireDate`, `performanceScore`, `employeeId` (for join & subquery), `firstName`, `lastName`.
*   `Departments`: `departmentId` (PK, for join), `departmentName` (for filter).
*   `EmployeeProjects`: `employeeId` (for join/grouping in CTE), `projectId` (for distinct count).

**3. Proposed Indexes (Snippet's analysis leads to a powerful composite partial index):**
The snippet correctly identifies that while individual indexes help, a composite index tailored to the `Employees` table filters is most impactful.
*   **`Departments.departmentName`**: (Usually covered if `departmentName` is UNIQUE or PK component). `CREATE INDEX idx_dept_name ON Departments(departmentName);`
*   **`EmployeeProjects(employeeId, projectId)`**: Crucial for the CTE. Often a PK or UNIQUE constraint covers this. `CREATE INDEX idx_ep_emp_proj ON EmployeeProjects(employeeId, projectId);`
*   **For `Employees` table (most critical):**
    A composite partial index as suggested by the snippet's detailed analysis is excellent:
    ```sql
    CREATE INDEX idx_employees_active_main_query_covering
    ON query_optimizations_and_performance.employees (hireDate, performanceScore, departmentId) -- Key filter/join columns
    INCLUDE (employeeId, firstName, lastName) -- Covering columns for SELECT and subquery join
    WHERE status = 'Active';
    ```
    *   `WHERE status = 'Active'`: Makes index smaller and targeted.
    *   `hireDate`, `performanceScore`, `departmentId`: Order matters for how well the index can serve multiple conditions. For this query, `(departmentId, hireDate, performanceScore)` might also be good if `departmentId` (after join) is filtered first. Or, if `status` is highly selective, `(status, departmentId, hireDate, performanceScore)` as a non-partial index. The snippet's choice with partial on `status` is good.
    *   `INCLUDE`: Avoids heap fetches for these columns if the index is used.

**4. `EXPLAIN ANALYZE` and Plan Description (Conceptual):**
*   **Departments Table:** Likely an Index Scan on `departmentName` (if indexed) or a Seq Scan (if small) to find 'Engineering' and 'Product Management' `departmentId`s.
*   **EmployeeProjects CTE:** Hash Aggregate on an Index Scan (or Seq Scan if small) of `EmployeeProjects` using `idx_ep_emp_proj`.
*   **Employees Table:** This is key. With `idx_employees_active_main_query_covering`, the planner would ideally use an Index Scan (or Bitmap Index Scan) on this index.
    *   The `status = 'Active'` is handled by the partial index predicate.
    *   `hireDate BETWEEN ...` and `performanceScore >= 3.5` can be efficiently applied using the index.
    *   `departmentId` needed for the join can be read from the index.
    *   `employeeId`, `firstName`, `lastName` can be read from the index (due to `INCLUDE` or being part of index key), potentially making it an "Index Only Scan" for these parts if all needed columns are in the index.
*   **Joins:**
    *   `Employees` to `Departments`: Likely a Hash Join or Merge Join, using `Employees.departmentId` and an index on `Departments.departmentId`.
    *   Result to `EmployeeProjectCounts` CTE: Likely a Hash Left Join.
*   **Sort:** A final Sort operation for `ORDER BY`.
The overall plan would show significantly reduced costs and actual times for scanning `Employees` compared to sequential scans or less optimal index usage.

### 1.2.5 Exercise IS-5 (BRIN Indexes for Time-Series Data)

> **Problem:** `Projects` table large, queries filter `startDate > '2023-01-01'`. `startDate` is sequential. BRIN index might be better than B-tree.
> 1. Query `startDate > '2023-01-01'`.
> 2. `EXPLAIN ANALYZE` before BRIN.
> 3. Create BRIN index on `startDate`.
> 4. `EXPLAIN ANALYZE` after. Compare. Explain BRIN advantage.
>
> **BRIN (Block Range INdex):** Stores summary info (min/max) for blocks of table pages. Small, fast to build/update. Good for columns highly correlated with physical storage order (like auto-incrementing IDs or timestamps in append-only tables).
> **Advantage:** For large, physically ordered data, BRIN can quickly exclude large numbers of blocks that don't contain matching values, with much less storage and maintenance overhead than a B-tree.

**1. Query:**
```sql
SELECT * FROM query_optimizations_and_performance.projects WHERE startDate > DATE '2023-01-01';
```

**2. Before BRIN (Snippet Output):**
```
-- "Seq Scan on projects ... (actual time=0.030..16.947 rows=10050 loops=1)"
-- Execution Time: 17.911 ms
```

**3. Create BRIN Index (Snippet shows partial and complete):**
```sql
-- Complete BRIN is generally what's intended unless there's a strong reason for partial.
CREATE INDEX idxProjectsStartDateBRIN ON query_optimizations_and_performance.projects USING BRIN(startDate);
```

**4. After BRIN (Snippet Output, for complete BRIN):**
```
-- "Seq Scan on projects ... (actual time=0.010..3.616 rows=10050 loops=1)"
-- "  Filter: (startdate > '2023-01-01'::date)"
-- Execution Time: 4.183 ms
```
> **Change & Advantage:** The snippet's output *still shows a Seq Scan* even after creating the BRIN index, though execution time improved. This is unusual if the BRIN index were to be effective. A BRIN index scan would typically appear as `Bitmap Heap Scan` using a `Bitmap Index Scan` on the BRIN index.
> *   **Why still Seq Scan in snippet?** Possible reasons:
>     *   The table is not large enough for the planner to prefer BRIN over Seq Scan after considering costs.
>     *   The `startDate` values might not be well-correlated with physical storage order *in the test data*. BRIN relies on this. If data was inserted randomly by `startDate`, BRIN is ineffective.
>     *   The query planner estimated that scanning the blocks identified by BRIN would still be more work than a Seq Scan.
> *   **Intended BRIN Advantage:** If `startDate` is well-correlated with physical order (e.g., older projects are physically stored before newer projects), BRIN quickly tells the DB "rows matching `startDate > '2023-01-01'` can only be in these page ranges". The DB then only scans those relevant page ranges. This significantly reduces I/O for large tables compared to a full Seq Scan. It's much smaller than a B-tree.
>
> *The snippet's result showing Seq Scan even with BRIN suggests an issue with data characteristics or planner choice in that specific test environment for that dataset size. The execution time did improve, which might be due to other factors or the filter being applied more efficiently during the seq scan due to some memory effect.*

### 1.2.6 Exercise IS-6 (Hash Indexes and Advanced Options for Equality Lookups)

> **Problem:** Frequent exact `email` search. B-tree exists (UNIQUE). Test Hash index for faster equality. Use `CONCURRENTLY`.
> 1. Query `email = 'user100@example.com'`.
> 2. `EXPLAIN ANALYZE` (B-tree used).
> 3. Drop UNIQUE, `CREATE INDEX CONCURRENTLY ... USING HASH`, restore UNIQUE.
> 4. `EXPLAIN ANALYZE`. Does planner use Hash? Why Hash faster for equality? Why `CONCURRENTLY` useful?
>
> **Hash Index:** Stores hash values of indexed column. Excellent for exact equality (`=`) lookups. Not useful for range queries.
> **`CREATE INDEX CONCURRENTLY`:** Builds index without taking strong locks on the table, allowing concurrent writes. Useful for adding indexes to busy production tables.
> **Advantage (Hash for Equality):** Potentially faster than B-tree for pure equality because it directly calculates the hash and goes to the location, versus B-tree's tree traversal (though B-trees are very fast too).
> **Advantage (`CONCURRENTLY`):** Minimizes downtime/impact when adding indexes to production systems.

**1. & 2. Query with B-tree (Snippet Output):**
```sql
EXPLAIN ANALYZE SELECT * FROM query_optimizations_and_performance.employees WHERE email = 'user100@example.com';
-- "Index Scan using employees_email_key on employees ... (actual time=0.052..0.055 rows=1 loops=1)"
-- Execution Time: 0.092 ms
```

**3. Create Hash Index Concurrently:**
```sql
ALTER TABLE IF EXISTS query_optimizations_and_performance.employees DROP CONSTRAINT IF EXISTS employees_email_key;
-- CREATE INDEX CONCURRENTLY idx_employee_email_hash ON query_optimizations_and_performance.employees USING HASH (email); -- Correct HASH syntax
-- Snippet created a B-tree index idx_employee_email concurrently, not a HASH index.
-- For this exercise, we assume a HASH index was intended and created.
-- ALTER TABLE query_optimizations_and_performance.employees ADD CONSTRAINT employees_email_key UNIQUE (email); -- Restore
```

**4. After Hash Index (Snippet's output is for a B-tree created concurrently):**
The snippet's `CREATE INDEX CONCURRENTLY idx_employee_email ON ... (email);` creates another B-tree index. A Hash index would be `USING HASH (email)`.
```sql
EXPLAIN ANALYZE SELECT * FROM query_optimizations_and_performance.employees WHERE email = 'user100@example.com';
-- If Hash index `idx_employee_email_hash` was created and chosen:
-- Plan might show "Index Scan using idx_employee_email_hash ..."
-- Or, "Hash Join" if part of a larger query where hashing is beneficial.
-- For a simple lookup, it would still be an Index Scan, but on the hash index.
```
> **Why Hash might be faster for equality:** Direct hash computation and lookup, potentially fewer steps than B-tree traversal, especially if B-tree is deep.
> **Why `CONCURRENTLY` is useful:** Builds the index without exclusive locks, allowing normal table operations (`INSERT`, `UPDATE`, `DELETE`) to continue. Requires more CPU/time to build but is crucial for live systems.

### 1.2.7 Exercise IS-7 (Full-Text Search with Stored `tsvector` and Covering Indexes)

> **Problem:** Search `projectDescription` for "agile" AND "release". Retrieve `projectName`, `startDate` without table access. Use stored `tsvector` and covering GIN index.
> 1. Alter `Projects` to add generated `tsvector` column.
> 2. Create GIN index on `tsvector` column, *covering* `projectName`, `startDate`.
> 3. Query for "agile" AND "release", select `projectName`, `startDate`.
> 4. `EXPLAIN ANALYZE`. Confirm Index Only Scan. Explain advantage.
>
> **Stored Generated `tsvector` Column:** Pre-computes the `tsvector` representation, saving computation time at query execution.
> **Covering Index (with `INCLUDE` for GIN/GiST where supported, or by indexing all needed columns):** Allows query to be satisfied entirely from the index without accessing the main table (heap), leading to "Index Only Scan".
> **Advantage:**
> *   Stored `tsvector`: Faster queries as `to_tsvector` isn't run per query.
> *   Covering GIN + Index Only Scan: Significantly reduces I/O by avoiding table heap fetches, especially if many rows match FTS but only few columns are needed.

**1. Alter Table:**
```sql
ALTER TABLE query_optimizations_and_performance.projects
ADD COLUMN described_ts TSVECTOR
GENERATED ALWAYS AS (to_tsvector('english', projectDescription)) STORED;
```

**2. Create GIN Covering Index:**
*(Standard GIN indexes in PostgreSQL don't directly support `INCLUDE` in the same way B-trees do for making them covering for arbitrary columns. To achieve an "Index Only Scan" like behavior with GIN for FTS, you'd typically query the `tsvector` and then, if needed, join back to the table for other columns, or rely on the GIN index being efficient enough for the FTS part and accept heap fetches for other columns. The snippet's index creation is standard for GIN on a `tsvector`.)*
```sql
CREATE INDEX idx_gin_projects_described_ts -- Renamed from snippet
ON query_optimizations_and_performance.projects
USING GIN(described_ts);
-- To make it "covering" for projectName, startDate with GIN for FTS is tricky.
-- A common pattern is a GIN on tsvector, and separate B-tree indexes on projectName, startDate if those are frequently selected.
-- The most an "Index Only Scan" would apply to is if you select the tsvector column itself or columns part of a composite GIN key (less common for FTS).
-- The snippet's index: idx_describedproject_on_agility_and_release implies a specific naming not matching the CREATE.
```

**3. Query:**
```sql
SELECT projectName, startDate -- Select only these
FROM query_optimizations_and_performance.projects
WHERE described_ts @@ to_tsquery('english', 'agile & strategy'); -- Use the stored tsvector column, 'strategy' not 'release' in snippet
-- Snippet query used to_tsvector('english', projectDescription) which would not use the stored generated column's index as effectively.
```

**4. `EXPLAIN ANALYZE` (Conceptual for Index Only Scan):**
*If an Index Only Scan were possible and chosen (e.g., if `projectName` and `startDate` were part of a composite GIN key in a way that allowed it, which is not standard for this use case, or if the planner decided all data could come from the index due to other circumstances):*
The plan would show `Index Only Scan using idx_gin_projects_described_ts`.
> **Advantage of Stored `tsvector`:** Avoids recomputing `to_tsvector(projectDescription)` for every query, making the FTS condition faster to evaluate.
> **Advantage of (Hypothetical) Covering GIN Index leading to Index Only Scan:** If an Index Only Scan is achieved, it means the database doesn't need to visit the main table (heap) at all, reading all required data (`projectName`, `startDate`) directly from the index. This is a massive I/O saving.
> *Actual plan with just GIN on `described_ts`*: Likely `Bitmap Heap Scan` using `Bitmap Index Scan on idx_gin_projects_described_ts`. This is still very efficient for the FTS part.

---

## Part 2: EXPLAIN Plans

### 2.2.1 Exercise EP-1: Meaning, Values of `EXPLAIN` - Basic Scan & Join Types

> **Problem:** List employees from 'Sales' dept and their `jobTitle`.
> 1. Query joining `Employees`, `Departments`.
> 2. `EXPLAIN`. Identify scan types, join type.
> 3. What do "cost", "rows", "width" represent?

**1. Query:**
```sql
SELECT e.firstName, e.lastName, e.jobTitle, d.departmentName
FROM query_optimizations_and_performance.Employees e
JOIN query_optimizations_and_performance.Departments d ON e.departmentId = d.departmentId
WHERE d.departmentName = 'Sales';
```

**2. `EXPLAIN` (Interpreting Snippet's description):**
*(Snippet provides textual interpretation of a hypothetical EXPLAIN output)*
*   **Scan type on Employees:** Bitmap Heap Scan (implies a Bitmap Index Scan on `idxEmployeesDepartmentId`).
*   **Scan type on Departments:** Seq Scan (suggests `Departments` is small or `departmentName` filter isn't using an index optimally for this part).
*   **Join type:** Nested Loop.

**3. "cost", "rows", "width" meaning:**
*   **`cost=startup_cost..total_cost`**:
    *   `startup_cost`: Estimated cost to retrieve the *first* row.
    *   `total_cost`: Estimated cost to retrieve *all* rows for that node. Units are arbitrary but relative (often related to disk page fetches).
*   **`rows`**: Estimated number of rows output by that plan node.
*   **`width`**: Estimated average width (in bytes) of rows output by that node.

### 2.2.2 Exercise EP-2: Disadvantages/Misinterpretations of `EXPLAIN` - Stale Statistics & Actual Time

> **Problem:** `EXPLAIN` vs. `EXPLAIN ANALYZE`.
> 1. `EXPLAIN ANALYZE SELECT * FROM Employees WHERE salary > 150000;`
> 2. `EXPLAIN` on this. Note estimated rows.
> 3. `INSERT` a high earner. *DO NOT* run `ANALYZE Employees;`.
> 4. Re-run `EXPLAIN`. Estimated rows change? Why (stale stats)?
> 5. `EXPLAIN ANALYZE` again. Compare actual time/rows vs. estimated. Value of `ANALYZE`?

*(Snippet provides before/after values for estimates and actuals)*

**Before `INSERT` (from snippet):**
*   `EXPLAIN`: `Seq Scan ... rows=3`
*   `EXPLAIN ANALYZE`: `Seq Scan ... rows=3 ... (actual time=1.760..12.763 rows=2 loops=1)` (Actual rows was 2)

**After `INSERT` (NO `ANALYZE TABLE`) (from snippet):**
*   `EXPLAIN`: `Seq Scan ... rows=3` (Estimated rows *did not change significantly*).
> **Why estimated rows didn't change?** `EXPLAIN` uses stored statistics about table data. If these statistics are not updated (via `ANALYZE TABLE` or auto-analyze daemon), the planner's estimates will be based on old, stale data and won't reflect recent changes like the `INSERT`. This is a disadvantage of relying only on `EXPLAIN`.

**After `INSERT` with `EXPLAIN ANALYZE` (from snippet):**
*   `EXPLAIN ANALYZE`: `Seq Scan ... rows=3 ... (actual time=0.910..9.448 rows=3 loops=1)` (Actual rows is now 3).
> **Value `ANALYZE` adds to `EXPLAIN`:** `EXPLAIN ANALYZE` *executes* the query and provides *actual* run times, *actual* row counts, loop counts, etc., for each node. This allows comparison against estimates and reveals true bottlenecks or misestimations by the planner due to stale stats or complex conditions. It's invaluable for performance tuning.
> **Snippet's observation:** "There exists an augment in the number of rows and evident different in planning and execution times [actuals reflect the new row]."

### 2.2.3 Exercise EP-3: Inefficient Alternatives & `EXPLAIN` for Correlated Subqueries vs. `JOIN`s

> **Problem:** List employee and `projectName` if on 'Project Alpha 1'.
> 1. Use correlated subquery in `SELECT` to fetch `projectName`. Filter for employees on 'Project Alpha 1'.
> 2. `EXPLAIN ANALYZE`.
> 3. Rewrite with `LEFT JOIN`.
> 4. `EXPLAIN ANALYZE` JOIN version. Compare. Why JOIN better?

**1. Correlated Subquery Version (from snippet):**
```sql
 EXPLAIN ANALYZE
 SELECT
     e.employeeId, e.firstName, e.lastName,
     (SELECT p.projectName
      FROM query_optimizations_and_performance.Projects p
      JOIN query_optimizations_and_performance.EmployeeProjects epFind ON p.projectId = epFind.projectId
      WHERE epFind.employeeId = e.employeeId AND p.projectName = 'Project Alpha 1'
      LIMIT 1) AS projectAlphaName
 FROM query_optimizations_and_performance.Employees e
 WHERE EXISTS ( -- This WHERE EXISTS is to filter for employees actually on the project
     SELECT 1
     FROM query_optimizations_and_performance.EmployeeProjects epChk
     JOIN query_optimizations_and_performance.Projects pChk ON epChk.projectId = pChk.projectId
     WHERE epChk.employeeId = e.employeeId AND pChk.projectName = 'Project Alpha 1'
 );
```
**2. `EXPLAIN ANALYZE` for Correlated (Snippet Output):**
> Execution Time: 24.176 ms. Plan involves `Nested Loop` and subplans. The subplan for `projectAlphaName` "never executed" in the snippet's example because the `WHERE EXISTS` returned 0 rows overall. If it had executed per outer row, it would be slow.

**3. `LEFT JOIN` Version (from snippet):**
```sql
 EXPLAIN ANALYZE
 SELECT e.employeeId, e.firstName, e.lastName, p.projectName
 FROM query_optimizations_and_performance.Employees e
 JOIN query_optimizations_and_performance.EmployeeProjects ep ON e.employeeId = ep.employeeId -- Should be LEFT JOIN if want all employees then see project
 JOIN query_optimizations_and_performance.Projects p ON ep.projectId = p.projectId
 WHERE p.projectName = 'Project Alpha 1';
 -- If you want all employees and only show project name if it's 'Project Alpha 1':
 /*
 SELECT e.employeeId, e.firstName, e.lastName, p_filtered.projectName
 FROM query_optimizations_and_performance.Employees e
 LEFT JOIN query_optimizations_and_performance.EmployeeProjects ep ON e.employeeId = ep.employeeId
 LEFT JOIN query_optimizations_and_performance.Projects p_filtered ON ep.projectId = p_filtered.projectId AND p_filtered.projectName = 'Project Alpha 1';
 */
```
**4. `EXPLAIN ANALYZE` for JOIN (Snippet Output):**
> Execution Time: 16.498 ms. Simpler plan with `Nested Loop` and `Hash Join`.
> **Why JOIN generally better?**
> *   Database optimizers are usually much better at optimizing declarative `JOIN` operations. They can choose various join algorithms (hash, merge, nested loop) based on costs and statistics.
> *   Correlated subqueries in `SELECT` are often executed iteratively (once per outer row), which is like a procedural loop (N+1 problem) and scales poorly with the size of the outer table.
> *   `JOINs` allow for more holistic query planning.
> **Snippet's Note:** "Note how the query without the correlated query is simpler in strategy and faster..."

### 2.2.4 Exercise EP-4 (Hardcore Problem - Analyzing and Improving Complex Query Plan)

> **Problem:** Find depts where avg salary of 'Software Engineer's hired after '2018-01-01' > $75,000. List dept name, count of such engineers, avg salary.
> 1. `EXPLAIN (ANALYZE, BUFFERS)` on query.
> 2. Identify most time-consuming ops.
> 3. Check estimated vs. actual rows discrepancies.
> 4. Look at Buffers: high `read` count?
> 5. Suggest 2 improvements (index, rewrite, tweak) & why.

**Query (from snippet):**
```sql
EXPLAIN (ANALYZE, BUFFERS) -- Snippet also uses FORMAT JSON
SELECT
  d.departmentName,
  COUNT(e.employeeId) as numEngineers,
  AVG(e.salary) as avgSalary
FROM query_optimizations_and_performance.Departments d
JOIN query_optimizations_and_performance.Employees e ON d.departmentId = e.departmentId
WHERE e.jobTitle = 'Software Engineer' AND e.hireDate > '2018-01-01'
GROUP BY d.departmentId, d.departmentName -- d.departmentId for unique grouping
HAVING AVG(e.salary) > 75000
ORDER BY avgSalary DESC;
```

**Analysis based on Snippet's Detailed Walkthrough:**
*   **Most Time-Consuming (Initial):** `Bitmap Heap Scan on employees e` for the `WHERE` clause filters (`jobTitle`, `hireDate`). Snippet indicates this took a large percentage of time and buffer hits.
*   **Estimated vs. Actual Rows:** Snippet states "Not really big differences ... statistics are not highly stale." This is good.
*   **Buffers High Read Count:** A high `read` count for a table/index scan suggests data wasn't in shared buffers and had to be fetched from disk, which is slow. `shared hit` is good (data found in cache). The snippet notes `Bitmap Heap Scan on employees e ... shared Buffer hit of 487` meaning 3.8MB was read from cache for this operation.
*   **Suggested Improvements (from Snippet):**
    1.  **Composite Index on `Employees`:**
        ```sql
        CREATE INDEX idx_employees_hiredate_title
        ON query_optimizations_and_performance.Employees (jobTitle, hireDate, departmentId) -- Order matters
        INCLUDE (salary); -- Covering index for salary
        ```
        *Why:* `jobTitle` for equality, `hireDate` for range. `departmentId` helps join. `INCLUDE(salary)` allows fetching salary from index for `AVG` and `HAVING`, potentially enabling an Index Only Scan for parts of the `Employees` access if `employeeId` for `COUNT` is also covered or not strictly needed (e.g. `COUNT(*)` within a group of found employees).
    2.  **Partial Composite Index on `Employees` (More targeted):**
        ```sql
        CREATE INDEX idx_employees_departmental_partial
        ON query_optimizations_and_performance.Employees (departmentId) -- For grouping and joining
        INCLUDE (salary)
        WHERE jobTitle = 'Software Engineer' AND hireDate > '2018-01-01';
        ```
        *Why:* Smaller index, highly specific to the query's `WHERE` clause filters. `departmentId` helps group, `INCLUDE(salary)` for `AVG`. This would be very effective if this exact query pattern is common.
    3.  **Rewriting with CTE (as shown in snippet's attempts):**
        ```sql
        WITH NewEngineers AS (
            SELECT e.departmentId, AVG(e.salary) AS avgSalary, COUNT(e.employeeId) AS numEngineers
            FROM query_optimizations_and_performance.Employees e
            WHERE e.jobTitle = 'Software Engineer' AND e.hireDate > DATE '2018-01-01'
            GROUP BY e.departmentId
            HAVING AVG(e.salary) > 75000 -- Filter departments here
        )
        SELECT d.departmentName, ne.numEngineers, ne.avgSalary
        FROM query_optimizations_and_performance.Departments d
        JOIN NewEngineers ne ON d.departmentId = ne.departmentId -- NATURAL JOIN in snippet
        ORDER BY ne.avgSalary DESC;
        ```
        *Why:* Breaks down logic. The `NewEngineers` CTE pre-aggregates and filters. If the indexes above are created, the CTE benefits from them. Applying `HAVING` inside the CTE reduces rows before joining to `Departments`.

---

## Part 3: Optimizing Window Functions and Aggregates

### 3.2.1 Exercise OWA-1: Window Functions - Contextual Aggregation

> **Problem:** For each sale, display `totalAmount` alongside avg `totalAmount` of all transactions by same `customerId`.
> 1. Query using `AVG(...) OVER (PARTITION BY ...)`
> 2. Explain advantage vs. `LEFT JOIN` to subquery.
>
> **Advantage of Window Function:** More concise and often more efficient. It calculates the aggregate per partition while retaining all original rows, avoiding a separate aggregation step and join which can be more verbose and sometimes less optimized.

**1. Window Function Query (Snippet - Efficient):**
```sql
SELECT
    transactionId, customerId,
    totalAmount, transactionDate,
    AVG(totalAmount) OVER (PARTITION BY customerId) AS customer_avg_total_amount
FROM query_optimizations_and_performance.salesTransactions;
```

**Inefficient Alternative (Snippet - `LEFT JOIN` to subquery):**
```sql
EXPLAIN (ANALYZE)            -- Inefficient
WITH CustomerAvgTotalAmount AS ( -- Renamed from UseredAVGTotalAmount
    SELECT customerId, AVG(totalAmount) AS avgTotalAmount
    FROM query_optimizations_and_performance.salesTransactions
    GROUP BY customerId
)
SELECT st.transactionId, st.customerId, st.totalAmount, st.transactionDate, cat.avgTotalAmount
FROM query_optimizations_and_performance.salesTransactions st -- aliased o in snippet
LEFT JOIN CustomerAvgTotalAmount cat ON st.customerId = cat.customerId -- aliased l in snippet
ORDER BY st.customerId;
```
> **Snippet's Explanation:** The window function query gives data already ordered by user (if `ORDER BY` is added to outer query), simplifies query. Mentions it's "1sec slower but improvable with indexes" - this depends heavily on dataset size and RDBMS. Window functions are generally well-optimized.

### 3.2.2 Exercise OWA-2: Disadvantages of Window Functions - Cost of Sorting & Large Partitions

> **Problem:** For every sale (1.5M rows), rank by `totalAmount` across *all* transactions.
> 1. Query with `RANK() OVER (ORDER BY totalAmount DESC)`.
> 2. `EXPLAIN ANALYZE`. Focus on `WindowAgg` & `Sort` nodes. Disadvantage for large, unpartitioned window?
> 3. How would `PARTITION BY productId` change workload?

**1. Query (Unpartitioned Large Window):**
```sql
EXPLAIN ANALYZE
SELECT transactionId, RANK() OVER (ORDER BY totalAmount DESC) AS overall_sales_rank
FROM query_optimizations_and_performance.salesTransactions;
```
**2. Disadvantage:**
> For a large, unpartitioned window, the database must sort the *entire* 1.5M rows by `totalAmount` to compute the ranks. This sort operation can be very expensive in terms of CPU, memory (potentially spilling to disk if `work_mem` is insufficient), and time. The `WindowAgg` node itself then processes these sorted rows.
> **Snippet observation:** "High actual time created by too many rows: 1.5M"

**3. Impact of `PARTITION BY productId`:**
```sql
EXPLAIN ANALYZE
SELECT productId, RANK() OVER (PARTITION BY productId ORDER BY totalAmount DESC) AS rank_within_product
FROM query_optimizations_and_performance.salesTransactions;
```
> **Conceptual Change:**
> *   The workload is broken down. Instead of one massive sort, the database sorts data *within each `productId` partition*.
> *   If there are many products and each partition is relatively small, these smaller sorts are much faster and require less memory individually.
> *   Parallelism might be used more effectively across partitions.
> **Potential Reduction of Disadvantage:** The "disadvantage" of a massive single sort is mitigated. Total work might be similar if all rows are still processed, but it's done in smaller, more manageable chunks. This often leads to better overall performance.
> **Snippet observation:** "With this the query can be improved through composed indexes for productId and totalAmount simultaneously where parallelism is useful because there exists multiple parallel workers ordering each well indexed partition." (A composite index `(productId, totalAmount)` would be very beneficial here).

### 3.2.3 Exercise OWA-3: Inefficient Alternatives vs. Optimized Approach - Running Totals

> **Problem:** For each customer, monthly sales in 2022 and a running total of sales month-by-month.
> 1.  Inefficient Sketch: Correlated subquery for running total. Why bad?
> 2.  Optimized Query: CTE for monthly sales, then `SUM(...) OVER (...)` for running total.
> 3.  Beneficial indexes for CTE aggregation?

**1. Inefficient Sketch (Correlated Subquery):**
```sql
-- For each row (customer, month, monthly_sales):
-- running_total = (SELECT SUM(sales) FROM Sales s2
--                  WHERE s2.customer = current_row.customer
--                    AND s2.sale_month <= current_row.sale_month
--                    AND s2.sale_year = 2022)
```
> **Why bad?** The subquery is executed for *every customer-month combination*. If a customer has 12 months of sales, the subquery sums 1 month, then 2 months, then 3, etc., re-scanning data repeatedly. This is highly inefficient (O(N^2) character).
> **Snippet's Answer 1:** "the query that does not use window functions necessarily needs to have too many correlated queries... highly verbose and time consuming... not optimized constructs for repetitive tasks..."

**2. Optimized Query (CTE and Window Function):**
```sql
WITH CustomerMonthlySales2022 AS ( -- Renamed from SalesOf2022
    SELECT
        customerId,
        EXTRACT(MONTH FROM transactionDate) AS transaction_month, -- aliased from transactionalMonth
        SUM(totalAmount) AS monthly_sales_amount -- aliased from monthlyAmount
    FROM query_optimizations_and_performance.salesTransactions
    WHERE EXTRACT(YEAR FROM transactionDate) = 2022 -- Snippet had 2020, problem says 2022
    GROUP BY customerId, EXTRACT(MONTH FROM transactionDate)
)
SELECT
    c.customerName, -- Joined to get customer name
    cms.transaction_month,
    cms.monthly_sales_amount,
    SUM(cms.monthly_sales_amount) OVER (PARTITION BY cms.customerId ORDER BY cms.transaction_month ASC
                                    ROWS UNBOUNDED PRECEDING) AS running_total_sales
FROM CustomerMonthlySales2022 cms
JOIN query_optimizations_and_performance.customers c ON cms.customerId = c.customerId
ORDER BY c.customerName, cms.transaction_month;
```

**3. Beneficial Indexes for CTE Aggregation:**
> For `CustomerMonthlySales2022` CTE:
> An index on `SalesTransactions(transactionDate, customerId)` would be very helpful.
> `CREATE INDEX idx_sales_txdate_custid ON query_optimizations_and_performance.salesTransactions (transactionDate, customerId);`
> If `totalAmount` can be included (covering index):
> `CREATE INDEX idx_sales_txdate_custid_incl_amt ON query_optimizations_and_performance.salesTransactions (transactionDate, customerId) INCLUDE (totalAmount);`
> This helps filter by `EXTRACT(YEAR FROM transactionDate)` (though functions on columns can sometimes limit index use, some DBs handle `DATE_TRUNC` or `EXTRACT` well with date indexes) and then efficiently group by `customerId` and `EXTRACT(MONTH FROM transactionDate)`.
> **Snippet's Answer 3:** "Indexes to be made on SalesTransactions are partially composed with the functional EXTRACT(MONTH FROM transactionDate) and customerId with totalAmount as the covering value attached to the composed index where EXTRACT(YEAR FROM transactionDate) = 2022 is the partial order." (This describes a partial index on an expression, which is advanced and good if supported and chosen by planner).

### 3.2.4 Exercise OWA-4 (Hardcore Problem - Complex Analytics with Optimized Window Functions)

> **Problem:** For 2022, for each Product Category & Region:
> 1.  Total sales amount (category-region).
> 2.  Rank of category-region by total sales (vs. all other cat-region combos).
> 3.  % contribution to total sales of its Region.
> 4.  % contribution to total sales of its Product Category.
> Filter: cat-region total sales > $10,000. Order by overall rank.

*(The snippet provides a good CTE-based structure.)*
```sql
WITH CategoryRegionSales2022 AS ( -- Renamed from SalesOf2022 for clarity
    SELECT
        p.category,
        r.regionId, -- Keep ID for joins, get name later
        r.regionName, -- Added for final display
        SUM(st.totalAmount) AS total_cat_region_sales
    FROM query_optimizations_and_performance.salesTransactions st
    JOIN query_optimizations_and_performance.products p ON st.productId = p.productId
    JOIN query_optimizations_and_performance.customers c ON st.customerId = c.customerId -- Needed for regionId in snippet's schema
    JOIN query_optimizations_and_performance.regions r ON c.regionId = r.regionId       -- Snippet joins customers to regions
    WHERE EXTRACT(YEAR FROM st.transactionDate) = 2022
    GROUP BY p.category, r.regionId, r.regionName
    HAVING SUM(st.totalAmount) > 10000 -- Filter condition from problem
),
TotalSalesByRegion2022 AS ( -- Renamed from RegionalizedSalesOf2022
    SELECT
        regionId,
        SUM(total_cat_region_sales) AS total_regional_sales
    FROM CategoryRegionSales2022
    GROUP BY regionId
),
TotalSalesByCategory2022 AS ( -- Renamed from CategorizedSalesOf2022
    SELECT
        category,
        SUM(total_cat_region_sales) AS total_category_sales
    FROM CategoryRegionSales2022
    GROUP BY category
)
SELECT
    crs.category,
    crs.regionName,
    crs.total_cat_region_sales,
    RANK() OVER (ORDER BY crs.total_cat_region_sales DESC) AS overall_cat_region_rank, -- Point 2
    ROUND((crs.total_cat_region_sales / tsr.total_regional_sales) * 100.0, 2) AS pct_contribution_to_region, -- Point 3
    ROUND((crs.total_cat_region_sales / tsc.total_category_sales) * 100.0, 2) AS pct_contribution_to_category -- Point 4
FROM CategoryRegionSales2022 crs
JOIN TotalSalesByRegion2022 tsr ON crs.regionId = tsr.regionId
JOIN TotalSalesByCategory2022 tsc ON crs.category = tsc.category
ORDER BY overall_cat_region_rank;

-- Snippet's query for overall_cat_region_rank:
-- RANK() OVER(PARTITION BY s.category, s.regionId ORDER BY s.totalAmount) regionalizedCategoricalSales
-- This rank is partitioned by category AND region, meaning it ranks sales *within* that specific category-region pair.
-- Since totalAmount is already unique for a category-region pair after grouping, this rank will always be 1.
-- The problem asks for rank "compared to all other category-region combinations", so the PARTITION BY should be omitted from this rank.
```
**Critique of Snippet's OWA-4:**
*   **CTEs:** `SalesOf2022`, `RegionalizedSalesOf2022`, `CategorizedSalesOf2022` are well-structured for breaking down the problem.
*   **Joins in `SalesOf2022`:** Assumes `customers` table links to `regions`. This is schema-dependent. If `salesTransactions` has `regionId`, the join to `customers` for region info is not needed.
*   **Filtering `totalAmount > 10000`:** Correctly done in `CategoryRegionSales2022` (or can be in outer query). Snippet had `> 1000`.
*   **`regionalizedCategoricalSales` Rank:** The `RANK() OVER(PARTITION BY s.category, s.regionId ORDER BY s.totalAmount)` in the snippet will always produce a rank of 1 for every row, because `s.totalAmount` is already the sum for that unique `s.category, s.regionId` group. For an overall rank of category-region combinations, it should be `RANK() OVER (ORDER BY s.totalAmount DESC)`.
*   **Percentage Calculations:** Correctly structured as `(specific_sales / broader_total_sales) * 100`.

The revised query above adjusts the ranking logic and clarifies CTE names.