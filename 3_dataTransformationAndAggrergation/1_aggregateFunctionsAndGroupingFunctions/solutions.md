# 📊 Advanced SQL: Aggregate Functions & Grouping Operations 📈

Unlock sophisticated data analysis with SQL's advanced aggregate functions (`STRING_AGG`, `ARRAY_AGG`, `JSON_AGG`, `PERCENTILE_CONT`, `CORR`, `REGR_SLOPE`) and advanced grouping operations (`GROUPING SETS`, `ROLLUP`, `CUBE`). This guide covers their meanings, advantages, disadvantages, and tackles a complex reporting problem.

---

## Part 1: Advanced Aggregate Functions

### 1.1 `STRING_AGG(expression, separator [ORDER BY ...])`

#### 1.1.1 Practice Meaning, Values, Relations, Advantages

> **Problem:** For each department, list department name and a comma-separated string of its employees’ first names, ordered alphabetically. Handle employees with no department.
>
> **Meaning:** `STRING_AGG` concatenates values from multiple rows into a single string, with a specified separator. An optional `ORDER BY` within the function controls the concatenation order.
> **Advantage:** Useful for creating denormalized string representations of related items, often for display or simple reporting.

```sql
SELECT
    d.departmentId,
    d.departmentName,
    COALESCE(STRING_AGG(e.firstName, ', ' ORDER BY e.firstName), 'No employees') AS employees_list -- Renamed alias
FROM data_transformation_and_aggregation.departments d
LEFT JOIN data_transformation_and_aggregation.employees e ON d.departmentId = e.departmentId -- LEFT JOIN to include depts with no employees
-- Original snippet used NATURAL JOIN which would exclude depts with no employees or employees with no depts
GROUP BY d.departmentId, d.departmentName; -- departmentName also in GROUP BY
```
*Note: If "Employees with no department should be handled gracefully" means listing them under a "No Department" category, the query structure would need to change (e.g., `RIGHT JOIN` or a `UNION` for employees with `departmentId IS NULL`). The query above lists departments and their employees; `COALESCE` handles departments with no employees.*

#### 1.1.2 Practice Disadvantages

> **Problem:** Disadvantage of `STRING_AGG` if string becomes very long or individual components need querying later? Alternative for relational processing?
>
> **Disadvantages:**
> *   **Length Limits:** Very long strings might exceed database limits or be unwieldy for applications.
> *   **Querying Components:** Searching or joining on individual elements within the concatenated string is inefficient and complex (requires string parsing).
> *   **Data Integrity:** Denormalization can lead to update anomalies if the source data changes and the string isn't regenerated.
>
> **Alternatives for Relational Processing:**
> *   **`JSON_AGG`:** Aggregates into a JSON array, which can be more structured and sometimes easier for applications to parse than a simple string.
> *   **Normalized Structure (Separate Rows):** Keep data normalized (e.g., department and individual employee names in separate rows via a join) for standard relational operations.

**Answer from snippet (paraphrased):**
> An immense string is hard to display and requires client-side post-processing. `JSON_AGG` can create a more structured object. Keeping data in a normalized table structure (separate rows) is best for further relational processing.

**Alternative 1 (from snippet - `JSON_AGG`):**
```sql
SELECT
    d.departmentId, d.departmentName,
    COALESCE(JSON_AGG(e.firstName ORDER BY e.firstName), '[]'::json) AS employees_json_array
FROM data_transformation_and_aggregation.departments d
LEFT JOIN data_transformation_and_aggregation.employees e ON d.departmentId = e.departmentId
GROUP BY d.departmentId, d.departmentName;
```

**Alternative 2 (from snippet - Normalized Rows):**
```sql
SELECT
    COALESCE(d.departmentName, 'No Department Assigned') AS departmentName,
    e.firstName
FROM data_transformation_and_aggregation.Employees e
LEFT JOIN data_transformation_and_aggregation.Departments d ON e.departmentId = d.departmentId
ORDER BY departmentName NULLS FIRST, e.firstName;
```

#### 1.1.3 Practice Inefficient Alternatives Avoidance

> **Problem:** Create a semicolon-separated list of unique skills for 'Engineering' dept. Naive: fetch all skills, concatenate programmatically. Show `STRING_AGG` with `UNNEST`.
>
> **Advantage of `STRING_AGG`:** Performs concatenation efficiently within the database, avoiding data transfer and client-side processing for this task.

```sql
SELECT
    -- sq.departmentId, -- Only one department ('Engineering'), so departmentId might be redundant here
    COALESCE(STRING_AGG(DISTINCT sq.skill_name, '; ' ORDER BY sq.skill_name), 'Department without skills') AS engineering_skills
FROM (
    SELECT d.departmentId, UNNEST(e.skills) AS skill_name -- Assuming skills is an array column
    FROM data_transformation_and_aggregation.employees e
    JOIN data_transformation_and_aggregation.departments d
        ON e.departmentId = d.departmentId -- Join condition
    WHERE d.departmentName = 'Engineering' -- Filter for department
) sq
GROUP BY sq.departmentId; -- Group by departmentId if you want to ensure one row per department if it was not filtered
-- If skills are already unique per employee or you want all listed skills (even duplicates from different employees), remove DISTINCT from STRING_AGG.
-- The problem asks for "unique skills", so DISTINCT inside STRING_AGG or in the subquery after UNNEST is appropriate.
```
*Note: The snippet's `sq.allSkills` implies the unnested column name. `DISTINCT` within `STRING_AGG` is good for uniqueness.*

### 1.2 `ARRAY_AGG(expression [ORDER BY ...])`

#### 1.2.1 Practice Meaning, Values, Relations, Advantages

> **Problem:** For each project, list project name and an array of `employeeId`s who worked on it, sorted ascending.
>
> **Meaning:** `ARRAY_AGG` aggregates values from multiple rows into an array. An optional `ORDER BY` within the function controls the order of elements in the array.
> **Advantage:** Useful for collecting related items into a structured array type directly within SQL, good for denormalization where appropriate or for passing structured data to applications.

```sql
SELECT
    p.projectId,
    p.projectName,
    ARRAY_AGG(e.employeeId ORDER BY e.employeeId) AS employee_ids_on_project
FROM data_transformation_and_aggregation.projects p
JOIN data_transformation_and_aggregation.employees e ON p.leadEmployeeId = e.employeeId -- Assuming this join means "worked on it"
-- Or if there's an employee_projects bridge table:
-- JOIN data_transformation_and_aggregation.employee_projects ep ON p.projectId = ep.projectId
-- JOIN data_transformation_and_aggregation.employees e ON ep.employeeId = e.employeeId
GROUP BY p.projectId, p.projectName;
```
*Note: Snippet used `NATURAL JOIN data_transformation_and_aggregation.employees e`. The join condition needs to be specific (e.g., via `employee_projects` table or if `projects` table has an `employeeId` foreign key like `leadEmployeeId`).*

#### 1.2.2 Practice Disadvantages

> **Problem:** Disadvantage of `ARRAY_AGG` for employee IDs if you need to find projects where a specific ID is the *first* assigned?
>
> **Disadvantages:**
> *   **Querying Array Elements:** Searching for specific elements or their positions within an array using SQL can be less efficient and more complex than querying normalized data with indexes. `array[1]` (for the first element) is possible but doesn't leverage standard indexing well for searching across many arrays.
> *   **Data Integrity/Normalization:** Storing lists in arrays is a form of denormalization. If the "first assigned" status is critical relational information, it might be better modeled explicitly (e.g., a dedicated column, a specific row in a join table with a sequence number).

**Answer from snippet (paraphrased):**
> Aggregated arrays lack features like `FETCH`/`OFFSET` (within the array itself for querying) and direct indexing benefits of normalized tables. While accessing `array[position]` is possible, it's not as performant or flexible as SQL operations on normalized data for complex queries.

#### 1.2.3 Practice Inefficient Alternatives Avoidance

> **Problem:** Application needs product category with a list of product names in it. Naive: query categories, then for each, query its products, assemble in app. Show `ARRAY_AGG`.
>
> **Advantage of `ARRAY_AGG`:** Avoids the N+1 query problem by fetching all required data in a single database query, improving efficiency and reducing database load.

**Efficient `ARRAY_AGG` Approach:**
```sql
SELECT
    p.category,
    ARRAY_AGG(p.productName ORDER BY p.productName) AS products_in_category -- Added ORDER BY for consistency
FROM data_transformation_and_aggregation.products p
GROUP BY p.category;
```
> **Explanation from snippet:** The inefficient way involves fetching for every category its products (N queries for N categories after 1 query for categories), which is the N+1 problem. `ARRAY_AGG` avoids this.

### 1.3 `JSON_AGG(expression [ORDER BY ...])`

#### 1.3.1 Practice Meaning, Values, Relations, Advantages

> **Problem:** For 'San Francisco' depts, create a JSON array of employee objects (firstName, lastName, salary), ordered by salary desc within the array.
>
> **Meaning:** `JSON_AGG` aggregates values into a JSON array. Often used with `JSON_BUILD_OBJECT` or similar functions to create JSON objects for each row before aggregation.
> **Advantage:** Powerful for constructing nested JSON structures directly in SQL, useful for API responses or when applications expect JSON data. `JSONB_AGG` is often preferred for efficiency with binary JSON.

```sql
SELECT
    d.departmentName, -- Renamed from p.departmentName
    JSONB_AGG(
        JSON_BUILD_OBJECT(
            'firstName', e.firstName, -- e. aliasing
            'lastName', e.lastName,   -- e. aliasing
            'salary', e.salary        -- e. aliasing
        ) ORDER BY e.salary DESC -- e. aliasing
    ) AS employees_json
FROM data_transformation_and_aggregation.employees e
JOIN data_transformation_and_aggregation.departments d -- Renamed from p
    ON e.departmentId = d.departmentId -- Explicit join
WHERE d.locationCity = 'San Francisco'
GROUP BY d.departmentName;
```

#### 1.3.2 Practice Disadvantages

> **Problem:** Potential performance issue of `JSON_AGG` for many complex objects? Type checking when consuming?
>
> **Disadvantages:**
> *   **Performance/Memory:** Aggregating a large number of rows, especially if each row is converted into a complex JSON object, can be memory-intensive and CPU-intensive, both for the database constructing the JSON and for the application parsing it.
> *   **Type Checking:** JSON is schema-less by nature. While the database might generate JSON with consistent types (e.g., numbers as JSON numbers, strings as JSON strings), the consuming application needs to handle parsing and type validation carefully, as there's no database-enforced schema within the JSON structure itself.
> *   **Large JSON Documents:** Transmitting and parsing very large JSON documents can be inefficient.

**Answer from snippet (paraphrased):**
> Constructing JSON requires memory for properties and values. Complex objects need more memory, computation, and bandwidth.

#### 1.3.3 Practice Inefficient Alternatives Avoidance

> **Problem:** Create JSON feed of products and their sales. Developer queries products, then loops to query sales for each, manually constructing JSON in app. Show `JSON_AGG`.
>
> **Advantage of `JSON_AGG`:** Avoids N+1 queries and manual JSON string manipulation in application code, which is error-prone and inefficient.

```sql
SELECT
    p.productId,
    p.productName, -- Added for context
    JSONB_AGG(
        JSON_BUILD_OBJECT(
            'saleId', s.saleId,         -- s. aliasing
            -- 'product', s.productId,  -- Redundant as it's grouped by p.productId
            'employeeId', s.employeeId, -- s. aliasing
            'saleDate', s.saleDate,       -- s. aliasing
            'quantity', s.quantity,     -- s. aliasing
            'regionId', s.regionId,     -- s. aliasing
            'notes', s.notes           -- s. aliasing
        ) ORDER BY s.saleDate -- Optional: order sales within the JSON array
    ) FILTER (WHERE s.saleId IS NOT NULL) AS sales_json -- FILTER is good if LEFT JOIN is used
FROM data_transformation_and_aggregation.products p
LEFT JOIN data_transformation_and_aggregation.sales s ON p.productId = s.productId -- Use LEFT JOIN to include products with no sales
-- Original snippet used NATURAL JOIN, which would exclude products with no sales.
GROUP BY p.productId, p.productName;
```

### 1.4 `PERCENTILE_CONT(fraction) WITHIN GROUP (ORDER BY sort_expression)`

#### 1.4.1 Practice Meaning, Values, Relations, Advantages

> **Problem:** For each product category, calculate 25th, 50th (median), and 75th percentile of `listPrice`.
>
> **Meaning:** `PERCENTILE_CONT(fraction)` is an inverse distribution function that assumes a continuous distribution model. It interpolates the value at the specified fraction (percentile) within the sorted group.
> **Advantage:** Provides a standard way to calculate percentiles, including medians, which are robust measures of central tendency.

```sql
SELECT
    category,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY listPrice) AS p25_list_price,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY listPrice) AS median_list_price, -- p50 is median
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY listPrice) AS p75_list_price
FROM data_transformation_and_aggregation.products
WHERE category IS NOT NULL -- To ignore products without a category as per problem
GROUP BY category;
```

#### 1.4.2 Practice Disadvantages

> **Problem:** `PERCENTILE_CONT` on column with few distinct values (e.g., integer scores 1-5). How does interpolation affect result? Why `PERCENTILE_DISC` sometimes preferred?
>
> **Disadvantage of `PERCENTILE_CONT` with discrete/few values:** Interpolation can result in values that do not actually exist in the dataset (e.g., a median score of 2.5 if data is 1,2,3,4).
> **`PERCENTILE_DISC`:** Assumes a discrete distribution model. It returns the first value in the sorted set whose position in the ordering is >= the specified fraction. This means it always returns an actual value from the dataset.
> **Preference:** `PERCENTILE_DISC` is often preferred when the data is inherently discrete and an interpolated value would be meaningless or misleading.

**Answer from snippet (paraphrased):**
> With few elements, interpolation can be biased if the range is large compared to desired detail. `PERCENTILE_DISC` selects the closest actual value to the interpolated percentile.

#### 1.4.3 Practice Inefficient Alternatives Avoidance

> **Problem:** Find median salary per department. Analyst exports data, sorts, finds median in spreadsheet. Show `PERCENTILE_CONT`.
>
> **Advantage of `PERCENTILE_CONT`:** Calculates median directly and efficiently in SQL, avoiding manual export and external tool dependency.

```sql
SELECT
    departmentId,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary
FROM data_transformation_and_aggregation.employees
WHERE departmentId IS NOT NULL -- Or handle NULL departmentId as a separate group
GROUP BY departmentId;
```

### 1.5 `CORR(Y, X)`

#### 1.5.1 Practice Meaning, Values, Relations, Advantages

> **Problem:** Calculate correlation coefficient between `quantity` sold and `listPrice` overall.
>
> **Meaning:** `CORR(Y, X)` returns the Pearson correlation coefficient between two numeric expressions, ranging from -1 (perfect negative linear correlation) to +1 (perfect positive linear correlation). 0 indicates no linear correlation.
> **Advantage:** Provides a standard statistical measure of linear association directly in SQL.

```sql
SELECT CORR(s.quantity, p.listprice) AS quantity_price_correlation -- Y is quantity, X is listPrice
FROM data_transformation_and_aggregation.products p
JOIN data_transformation_and_aggregation.sales s ON p.productId = s.productId; -- Explicit JOIN
```

#### 1.5.2 Practice Disadvantages

> **Problem:** What does `CORR` near 0 imply, and what strong relationship might it fail to capture?
>
> **Disadvantages/Limitations:**
> *   **Linearity:** `CORR` only measures *linear* relationships. A strong non-linear relationship (e.g., U-shaped, exponential) might have a correlation coefficient near 0.
> *   **Outliers:** Pearson correlation is sensitive to outliers.
> *   **Correlation vs. Causation:** Correlation does not imply causation.
> *   **Confounding Variables:** A correlation might be spurious or influenced by hidden confounding variables.

**Answer from snippet (paraphrased):**
> Correlation near 0 implies no *linear* relationship. It might miss non-linear relationships or relationships that exist only within specific categories (Simpson's paradox context).

#### 1.5.3 Practice Inefficient Alternatives Avoidance

> **Problem:** User exports salary and `performanceScore` to statistical software just for Pearson correlation. Show SQL method.
>
> **Advantage of `CORR`:** Direct calculation in SQL avoids data export and reliance on external tools for this specific statistic.

```sql
SELECT CORR(performanceScore, salary) AS performance_salary_correlation -- Y is performanceScore, X is salary
FROM data_transformation_and_aggregation.employees;
```

### 1.6 `REGR_SLOPE(Y, X)`

#### 1.6.1 Practice Meaning, Values, Relations, Advantages

> **Problem:** For 'Electronics' products, estimate how `avgQuantitySold` (Y) changes for each one-dollar increase in `listPrice` (X).
>
> **Meaning:** `REGR_SLOPE(Y, X)` calculates the slope of the linear regression line fitting the pairs of (X, Y) values. It represents the average change in Y for a one-unit change in X.
> **Advantage:** Provides a direct way to estimate the linear relationship's slope in SQL.

```sql
SELECT REGR_SLOPE(sq.avgQuantitySold, sq.listprice_val) AS price_effect_on_avg_quantity -- Aliased listprice_val
FROM (
    SELECT
        p.productId,
        AVG(s.quantity) AS avgQuantitySold,
        p.listprice AS listprice_val -- Ensure consistent naming or aliasing
    FROM data_transformation_and_aggregation.sales s
    JOIN data_transformation_and_aggregation.products p
        ON s.productId = p.productId
    WHERE p.category = 'Electronics'
    GROUP BY p.productId, p.listprice -- listprice must be in GROUP BY or come from an unaggregated source per productId
) sq;
```

#### 1.6.2 Practice Disadvantages

> **Problem:** What important info about the relationship does `REGR_SLOPE` *not* provide for judging reliability? (Hint: goodness of fit).
>
> **Disadvantages/Limitations:**
> *   **Goodness of Fit:** `REGR_SLOPE` only gives the slope. It doesn't indicate how well the linear model fits the data (e.g., R-squared value, `REGR_R2`).
> *   **Significance:** It doesn't provide p-values or confidence intervals for the slope, so statistical significance isn't directly assessed.
> *   **Assumptions:** Linear regression has underlying assumptions (linearity, independence of errors, homoscedasticity, normality of errors) that `REGR_SLOPE` doesn't check.
> *   **Intercept:** Does not directly give the intercept (`REGR_INTERCEPT` does).

**Answer from snippet (paraphrased):**
> The slope indicates the linear relationship but not its significance or quality (e.g., R-squared). Other metrics like p-values for intercept and slope assess reliability, which `REGR_SLOPE` alone doesn't offer. PostgreSQL has other `REGR_` functions for more stats.

#### 1.6.3 Practice Inefficient Alternatives Avoidance

> **Problem:** Manager exports 'Sales' dept salary and performance scores to Excel for trendline slope. Show `REGR_SLOPE`.
>
> **Advantage of `REGR_SLOPE`:** Direct calculation in SQL avoids data export and manual steps in external tools.

```sql
SELECT REGR_SLOPE(e.performanceScore, e.salary) AS salary_impact_on_performance
FROM data_transformation_and_aggregation.departments d
JOIN data_transformation_and_aggregation.employees e
    ON d.departmentId = e.departmentId
WHERE d.departmentName = 'Sales';
```
> **Comment from snippet:** The salary does not mean performance score. *(This implies the result of the regression might show little or inverse correlation, which is a valid outcome of the analysis.)*

---

## Part 2: Advanced Grouping Operations

### 2.1 `GROUPING SETS ((set1), (set2), ...)`

#### 2.1.1 Practice Meaning, Values, Relations, Advantages

> **Problem:** Calculate total sales qty and `sum(listPrice * quantity)` with groupings: 1. (category, regionName), 2. (category), 3. (regionName), 4. Grand total ().
>
> **Meaning:** `GROUPING SETS` allows you to define multiple grouping criteria in a single query. The database generates results equivalent to a `UNION ALL` of several `GROUP BY` queries.
> **Advantage:** More efficient and concise than writing multiple `GROUP BY` queries and `UNION ALL`ing them. `GROUPING()` function helps identify aggregation level.

```sql
SELECT
    COALESCE(p.category, 'All Categories') AS product_category, -- Using COALESCE for NULLs from grouping
    COALESCE(r.regionName, 'All Regions') AS region_name,    -- Using COALESCE
    SUM(p.listPrice * s.quantity) AS totalListPriceValue,
    SUM(s.quantity) AS total_sales_quantity, -- Added as per problem desc
    GROUPING(p.category, r.regionName) AS grp_cat_reg, -- Shows which combination is active
    GROUPING(p.category) AS grp_cat,
    GROUPING(r.regionName) AS grp_reg
FROM data_transformation_and_aggregation.sales s
JOIN data_transformation_and_aggregation.products p ON s.productId = p.productId   -- Explicit JOINs
JOIN data_transformation_and_aggregation.regions r ON s.regionId = r.regionId     -- Explicit JOINs
GROUP BY GROUPING SETS (
    (p.category, r.regionName),
    (p.category),
    (r.regionName),
    () -- Grand total
)
ORDER BY grp_cat DESC, grp_reg DESC, product_category, region_name; -- Meaningful order
-- Snippet's CASE GROUPING(...) is a good way to label.
```

#### 2.1.2 Practice Disadvantages

> **Problem:** Disadvantages if many complex grouping sets are defined? (e.g., `GROUPING SETS ((a,b,c), (a,d,e), ...)`).
>
> **Disadvantages:**
> *   **Query Complexity:** The `GROUPING SETS` clause itself can become very long and hard to read/debug if there are many intricate sets.
> *   **User Error:** High chance of errors in defining the exact combinations required, or missing some.
> *   **Result Set Size/Interpretation:** Can produce a large number of rows, making the output difficult to interpret if not carefully handled in reporting.
> *   **Performance:** While more efficient than `UNION ALL` of many queries, generating numerous aggregation levels can still be computationally intensive.

**Answer from snippet (paraphrased):**
> A grouping set with too many columns/combinations can be unmeaningful for direct human observation but might be useful for intermediate computational processes (e.g., graph operations). It can consume high memory and compute resources.

#### 2.1.3 Practice Inefficient Alternatives Avoidance

> **Problem:** User needs total sales qty by (year, category) and by (year) only. Writes two queries with `UNION ALL`. Show `GROUPING SETS`.
>
> **Advantage of `GROUPING SETS`:** More efficient (single pass over data usually) and concise.

```sql
SELECT
    EXTRACT(YEAR FROM s.saleDate) AS sale_year,
    COALESCE(p.category, 'All Categories for Year') AS product_category,
    SUM(s.quantity) AS totalSales,
    GROUPING(EXTRACT(YEAR FROM s.saleDate), p.category) AS grp_level -- To distinguish levels
FROM data_transformation_and_aggregation.products p
JOIN data_transformation_and_aggregation.sales s ON p.productId = s.productId
GROUP BY GROUPING SETS (
    (EXTRACT(YEAR FROM s.saleDate), p.category),
    (EXTRACT(YEAR FROM s.saleDate))
)
ORDER BY sale_year, grp_level; -- Order to see year totals after its categories
-- Snippet used CONCAT in CASE GROUPING, which is a good display technique.
```

### 2.2 `ROLLUP (col1, col2, ...)`

#### 2.2.1 Practice Meaning, Values, Relations, Advantages

> **Problem:** Hierarchical summary of `total hoursWorked`: `departmentName` → `projectName`. Include subtotals for each dept and grand total.
>
> **Meaning:** `ROLLUP(col1, col2, col3)` generates grouping sets for a hierarchy: `(col1, col2, col3)`, `(col1, col2)`, `(col1)`, and `()`. It "rolls up" from the most detailed level.
> **Advantage:** Simplifies generation of hierarchical subtotals.

```sql
SELECT
    COALESCE(d.departmentName, 'Overall Total') AS department_name_rollup,
    CASE
        WHEN d.departmentName IS NOT NULL AND p.projectName IS NULL THEN 'Department Total'
        WHEN d.departmentName IS NOT NULL AND p.projectName IS NOT NULL THEN p.projectName
        ELSE NULL -- For the grand total row where projectName is also NULL due to rollup
    END AS project_name_rollup,
    SUM(ep.hoursWorked) AS hierarchized_working_hours,
    GROUPING(d.departmentName, p.projectName) AS grp_level
FROM data_transformation_and_aggregation.projects p
JOIN data_transformation_and_aggregation.departments d ON p.departmentId = d.departmentId -- Assuming this link
JOIN data_transformation_and_aggregation.employeeProjects ep ON p.projectId = ep.projectId
GROUP BY ROLLUP(d.departmentName, p.projectName)
ORDER BY department_name_rollup NULLS LAST, project_name_rollup NULLS LAST;
-- Snippet used NATURAL JOINs and CASE GROUPING.
```

#### 2.2.2 Practice Disadvantages

> **Problem:** `ROLLUP(country, state, city)`. What if you need subtotal for `(country, city)` irrespective of state, or just `(city)`?
>
> **Disadvantage/Limitation:** `ROLLUP` is strictly hierarchical. It generates subtotals by removing columns from right to left in the `ROLLUP` list. It cannot generate arbitrary combinations like `(country, city)` if `state` is between them in the list, nor can it produce a subtotal for just `(city)` if `country` and `state` are listed before it. For such non-hierarchical or partial rollups, `GROUPING SETS` is needed.

**Answer from snippet (paraphrased):**
> `ROLLUP` is a special hierarchical case of `GROUPING SETS`. It won't create combinations of non-adjacent pairs like `(country, city)` from `ROLLUP(country, state, city)`. For that, use `GROUPING SETS` explicitly.

#### 2.2.3 Practice Inefficient Alternatives Avoidance

> **Problem:** Sales report: total qty sold, subtotals for `regionName` → `productCategory` → `productName`. Analyst uses `UNION ALL`. Show `ROLLUP`.
>
> **Advantage of `ROLLUP`:** Significantly simplifies queries for hierarchical summaries compared to multiple `UNION ALL` statements.

```sql
SELECT
    COALESCE(r.regionName, 'All Regions') AS region_rollup,
    CASE WHEN r.regionName IS NOT NULL THEN COALESCE(p.category, 'All Categories in Region') ELSE NULL END AS category_rollup,
    CASE WHEN p.category IS NOT NULL THEN COALESCE(p.productName, 'All Products in Category') ELSE NULL END AS product_rollup,
    SUM(s.quantity) AS total_quantity_sold
FROM data_transformation_and_aggregation.sales s
JOIN data_transformation_and_aggregation.regions r ON s.regionId = r.regionId
JOIN data_transformation_and_aggregation.products p ON s.productId = p.productId
GROUP BY ROLLUP(r.regionName, p.category, p.productName)
ORDER BY region_rollup NULLS LAST, category_rollup NULLS LAST, product_rollup NULLS LAST;
```

### 2.3 `CUBE (col1, col2, ...)`

#### 2.3.1 Practice Meaning, Values, Relations, Advantages

> **Problem:** Cross-tabular summary of `total sales quantity` for all combinations of `EXTRACT(YEAR FROM saleDate)` and `productCategory`. Include all subtotals.
>
> **Meaning:** `CUBE(col1, col2, col3)` generates grouping sets for all possible combinations of the listed columns, including the empty set (grand total). For N columns, it generates 2^N grouping sets.
> **Advantage:** Useful for creating cross-tabulation reports or data cubes where all possible subtotal combinations are needed.

```sql
SELECT
    COALESCE(CAST(EXTRACT(YEAR FROM s.saleDate) AS TEXT), 'All Years') AS sale_year_cube,
    COALESCE(p.category, 'All Categories') AS product_category_cube,
    SUM(s.quantity) AS total_sold_quantity,
    GROUPING(EXTRACT(YEAR FROM s.saleDate), p.category) AS grp_yr_cat,
    GROUPING(EXTRACT(YEAR FROM s.saleDate)) AS grp_yr,
    GROUPING(p.category) AS grp_cat
FROM data_transformation_and_aggregation.sales s
JOIN data_transformation_and_aggregation.products p ON s.productId = p.productId
GROUP BY CUBE(EXTRACT(YEAR FROM s.saleDate), p.category)
ORDER BY grp_yr DESC, grp_cat DESC, sale_year_cube, product_category_cube;
-- Snippet used CASE GROUPING for labeling.
```

#### 2.3.2 Practice Disadvantages

> **Problem:** `CUBE(colA, colB, colC, colD)` generates 2^4=16 grouping sets. Disadvantage if many cross-totals are not needed?
>
> **Disadvantage:**
> *   **Performance:** Generates many grouping sets, which can be computationally expensive if not all are needed.
> *   **Output Size/Complexity:** Produces a large number of rows, potentially making the output overwhelming and difficult to use if only a few specific aggregations were required. `GROUPING SETS` offers more control if only a subset of `CUBE`'s combinations are needed.

**Answer from snippet (paraphrased):**
> It's like verbosity or too much data presented without focus. Machine power is for processing lots of data under well-designed concepts to reduce it to meaningful knowledge for specific human objectives.

#### 2.3.3 Practice Inefficient Alternatives Avoidance

> **Problem:** User wants sales quantities by (region, category), by region, by category, and grand total. Might run 4 queries. Show `CUBE`.
>
> **Advantage of `CUBE`:** Provides all these combinations in a single, more efficient query.

```sql
SELECT
    COALESCE(r.regionName, 'All Regions') AS region_cube,
    COALESCE(p.category, 'All Categories') AS category_cube,
    SUM(s.quantity) AS total_quantity_sold
FROM data_transformation_and_aggregation.sales s
JOIN data_transformation_and_aggregation.regions r ON s.regionId = r.regionId
JOIN data_transformation_and_aggregation.products p ON s.productId = p.productId
GROUP BY CUBE(r.regionName, p.category)
ORDER BY region_cube NULLS LAST, category_cube NULLS LAST;
```

---

## Part 3: Hardcore Combined Problem (Multi-level Analytical Report)

> **Problem:** For 2023, create a multi-level report (Employee Detail, Department Summary, Grand Total) with columns: `reportingLevel`, `departmentName`, `employeeFullName`, `employeeHireYear`, `skillsList`, `projectsParticipated`, `totalHoursOnProjects`, `totalRevenueGenerated2023`, `salesQtyVsSatisfactionCorr2023`, `medianSalaryInDepartment`, `departmentPerformanceOverviewJson`.
> Use CTEs, advanced aggregates, `GROUPING SETS` (or `ROLLUP` for hierarchy).

*(The provided snippet is a very comprehensive attempt, building several CTEs for individual metrics and then trying to combine them using `GROUP BY ROLLUP` on `departmentId, employeeId` in the final aggregation step. This is a valid and complex approach.)*

**General Strategy Critique & Refinement Notes for Snippet's Hardcore Solution:**
1.  **CTEs for Base Metrics:**
    *   `EmployeeSkills`: Good, uses `STRING_AGG` and `UNNEST`.
    *   `ProjectedEmployee`: Good, `STRING_AGG` for projects, `SUM` for hours.
    *   `SellingEmployees`: Good, calculates total revenue for 2023.
    *   `SatisfactionPurchasing`: Calculates `CORR`. Needs careful handling of `(notes ->> 'customerSatisfaction')::NUMERIC` for `NULL` or non-numeric notes. A `WHERE (notes ->> 'customerSatisfaction') ~ '^[0-9\.]+$'` (regex for numbers) before casting can prevent errors. Also, `CORR` requires at least two pairs of non-null data points.
    *   `medianSalaryInDepartment`: Good, uses `PERCENTILE_CONT`. Handles `NULL` `departmentId` by grouping them (effectively 'No Department Assigned' group).
    *   `departmentPerformanceOverviewJson`: Good, uses `JSONB_AGG` and `JSON_BUILD_OBJECT`.

2.  **Final Aggregation (`summary` CTE in snippet using `GROUP BY ROLLUP`):**
    *   `GROUP BY ROLLUP(departmentId, employeeId)` is a good way to get the three levels:
        *   `(departmentId, employeeId)` -> Employee Detail
        *   `(departmentId)` -> Department Summary
        *   `()` -> Grand Total
    *   The `CASE GROUPING(...)` logic correctly identifies `reportingLevel`.

3.  **Joining CTEs to `summary`:**
    *   The final `SELECT` joins `summary` back to `employees` (`eo`), `departments` (`dto`), and all the metric CTEs using `LEFT JOIN ... USING(employeeId)` or `ON summary.departmentId IS NOT DISTINCT FROM metric_cte.departmentId`.
    *   This is where complexity arises because some metrics are per-employee (and should be `NULL` for summary rows), some are per-department (and should be `NULL` for employee/grand total rows).

4.  **Display Logic in Final `SELECT`:**
    *   `departmentName`: The `CASE reportingLevel ...` logic is good.
    *   `employeeFullName`, `employeeHireYear`, `skillsList`, `projectsParticipated`: These are employee-specific. Should be `NULL` when `reportingLevel` is 'Department Summary' or 'Grand Total'. This is naturally handled if `eo.firstName` is `NULL` for those summary rows from the `LEFT JOIN`.
    *   `totalHoursOnProjects`, `totalRevenueGenerated2023`: These need to be *summed* at department and grand total levels. The snippet's final `SELECT` directly takes these values from the CTEs joined on `employeeId`. This means it will show employee-level values or `NULL`s for summary rows. The aggregation for these sums should happen *within* the `summary` CTE itself.
        ```sql
        -- Corrected summary CTE for sums:
        SELECT
            CASE ... END AS reportingLevel,
            departmentId, employeeId, -- Grouping columns
            SUM(COALESCE(pe.totalHoursOnProjects, 0)) AS sum_totalHoursOnProjects,
            SUM(COALESCE(se.totalRevenueGenerated2023, 0)) AS sum_totalRevenueGenerated2023,
            AVG(e.performanceScore) AS avg_performance_score -- Example for summary.salesPerformance
        FROM data_transformation_and_aggregation.employees e
        LEFT JOIN ProjectedEmployee pe ON e.employeeId = pe.employeeId
        LEFT JOIN SellingEmployees se ON e.employeeId = se.employeeId
        GROUP BY ROLLUP(e.departmentId, e.employeeId)
        ```
    *   `quantityForSatisfaction`: Employee-specific, `NULL` for summaries.
    *   `medianSalary`: The `CASE WHEN eo.firstName IS NULL AND reportingLevel = 'Department Summary'` is a good way to show it only for department summaries.
    *   `departmentalPerformances`: Similar `CASE` logic as `medianSalary`.

5.  **Ordering:** The final `ORDER BY` needs to correctly sort `departmentName` with 'No Department Assigned' first and 'Overall Summary' last. This typically requires a `CASE` in the `ORDER BY`.

**Simplified Structure for the Final `SELECT` based on a `summary` CTE that pre-aggregates sums:**
```sql
-- ... (All metric CTEs: EmployeeSkills, ProjectedEmployee, SellingEmployees, SatisfactionPurchasing, medianSalaryInDepartment, departmentPerformanceOverviewJson are defined above)

WITH AggregatedSummary AS (
    SELECT
        d.departmentId, -- Department ID for joining
        e.employeeId,   -- Employee ID for joining (NULL for department/grand totals)
        COALESCE(d.departmentName, 'No Department Assigned') AS effective_department_name,
        e.firstName, e.lastName, EXTRACT(YEAR FROM e.hireDate) AS hireYear, -- Base employee info

        -- Aggregates that sum up
        SUM(COALESCE(pe.totalHoursOnProjects, 0)) AS agg_totalHoursOnProjects,
        SUM(COALESCE(se.totalRevenueGenerated2023, 0)) AS agg_totalRevenueGenerated2023,
        -- CORR needs to be handled carefully if it's to be shown at employee level only
        -- For this example, assume it's only at employee level and brought in by later join

        -- Grouping level indicators
        GROUPING(d.departmentName, e.employeeId, e.firstName, e.lastName, e.hireDate) AS grp_all,
        GROUPING(d.departmentName) AS grp_dept,
        GROUPING(e.employeeId) AS grp_emp -- To distinguish dept summary from employee detail
    FROM data_transformation_and_aggregation.employees e
    LEFT JOIN data_transformation_and_aggregation.departments d ON e.departmentId = d.departmentId
    LEFT JOIN ProjectedEmployee pe ON e.employeeId = pe.employeeId
    LEFT JOIN SellingEmployees se ON e.employeeId = se.employeeId
    GROUP BY GROUPING SETS (
        (d.departmentName, e.departmentId, e.employeeId, e.firstName, e.lastName, e.hireDate), -- Employee Detail
        (d.departmentName, e.departmentId), -- Department Summary
        () -- Grand Total
    )
)
SELECT
    CASE
        WHEN s.grp_emp = 0 THEN 'Employee Detail'       -- Most detailed level (employeeId is NOT grouped)
        WHEN s.grp_dept = 0 THEN 'Department Summary'   -- departmentName is NOT grouped, but employeeId IS
        ELSE 'Overall Summary'                          -- Grand total (both departmentName and employeeId are grouped)
    END AS reportingLevel,
    CASE
        WHEN s.grp_dept = 0 THEN s.effective_department_name
        ELSE 'Overall Summary'
    END AS departmentName,
    CASE WHEN s.grp_emp = 0 THEN s.firstName || ' ' || s.lastName ELSE NULL END AS employeeFullName,
    CASE WHEN s.grp_emp = 0 THEN s.hireYear ELSE NULL END AS employeeHireYear,
    CASE WHEN s.grp_emp = 0 THEN es.s_skills ELSE NULL END AS skillsList,
    CASE WHEN s.grp_emp = 0 THEN COALESCE(pe_final.projects, 'None') ELSE NULL END AS projectsParticipated,
    s.agg_totalHoursOnProjects AS totalHoursOnProjects, -- Already summed
    s.agg_totalRevenueGenerated2023 AS totalRevenueGenerated2023, -- Already summed
    CASE WHEN s.grp_emp = 0 THEN sp.quantityForSatisfaction ELSE NULL END AS salesQtyVsSatisfactionCorr2023,
    CASE WHEN s.grp_emp = 1 AND s.grp_dept = 0 THEN msid.medianSalary ELSE NULL END AS medianSalaryInDepartment,
    CASE WHEN s.grp_emp = 1 AND s.grp_dept = 0 THEN dpoj.departmentalPerformances ELSE NULL END AS departmentPerformanceOverviewJson
FROM AggregatedSummary s
LEFT JOIN EmployeeSkills es ON s.employeeId = es.employeeId AND s.grp_emp = 0 -- Join only for detail rows
LEFT JOIN ProjectedEmployee pe_final ON s.employeeId = pe_final.employeeId AND s.grp_emp = 0
LEFT JOIN SatisfactionPurchasing sp ON s.employeeId = sp.employeeId AND s.grp_emp = 0
LEFT JOIN medianSalaryInDepartment msid ON s.departmentId IS NOT DISTINCT FROM msid.departmentId AND s.grp_emp = 1 AND s.grp_dept = 0
LEFT JOIN departmentPerformanceOverviewJson dpoj ON s.departmentId IS NOT DISTINCT FROM dpoj.departmentId AND s.grp_emp = 1 AND s.grp_dept = 0
ORDER BY
    CASE
        WHEN s.grp_dept = 1 AND s.grp_emp = 1 THEN 3 -- Grand Total last
        WHEN s.effective_department_name = 'No Department Assigned' THEN 1 -- 'No Dept' first
        ELSE 2 -- Actual departments
    END,
    departmentName,
    CASE
        WHEN s.grp_emp = 0 THEN 1 -- Employee Detail
        ELSE 2                    -- Department Summary
    END,
    employeeFullName;
```
This is a very challenging problem to get all details and aggregations perfectly aligned in a single query output using `GROUPING SETS`. The snippet's `ROLLUP(departmentId, employeeId)` approach for the main summary structure is simpler for hierarchy but less flexible if arbitrary sets are needed. `GROUPING SETS` is more explicit. The key is how the `SUM()` aggregates are handled for different levels.
The snippet's final `SELECT` uses many `LEFT JOIN`s to the metric CTEs. This is good, but the aggregated values (`totalHoursOnProjects`, `totalRevenueGenerated2023`) must be summed *within* the `GROUPING SETS` or `ROLLUP` logic, not just picked from employee-level CTEs for summary rows.

The problem is an excellent test of understanding how different aggregations and joins interact at various grouping levels.