# 📋 SQL Common Table Expressions (CTEs): Structuring Complex Queries 🏗️

Master Common Table Expressions (CTEs) in SQL! This guide explores basic, nested, and recursive CTEs, their advantages in readability and modularity, potential disadvantages, and how they compare to less efficient alternatives. Culminates in a hardcore problem combining various CTE applications.

---

## 1. Category (i): Practice Meanings, Values, Relations, and Advantages

*These exercises focus on understanding the fundamental meanings, values, and relational aspects of Common Table Expressions (CTEs). They demonstrate unique uses and advantages.*

### 1.1 Exercise 1: Basic CTE for Readability

> **Problem:** List all employees in the ’Technology’ department who earn more than $90,000. Show how a CTE can simplify selecting the department first.
>
> **Meaning:** A CTE (`WITH cte_name AS (...)`) defines a temporary, named result set that you can reference within a single SQL statement (SELECT, INSERT, UPDATE, DELETE).
> **Advantage:** Improves query readability and modularity by breaking down complex logic into smaller, understandable named blocks.

```sql
WITH TechnologicalEmployees AS (
    SELECT e.*
    FROM advanced_query_techniques.employeesi e -- Assuming 'employeesi' and 'departmentsi' are table names
    JOIN advanced_query_techniques.departmentsi di ON e.departmentId = di.departmentId -- Explicit JOIN preferred over NATURAL
    WHERE di.departmentName = 'Technology'
)
SELECT te.employeeId, te.firstName, te.lastName, te.salary -- Select specific columns
FROM TechnologicalEmployees te
WHERE te.salary > 90000;
```
*Note: Snippet used `NATURAL JOIN`. Explicit `JOIN ON` is generally safer.*

### 1.2 Exercise 2: CTE Referenced Multiple Times

> **Problem:** Find all employees whose salary is above the average salary of their respective department. Also, show the department’s average salary.
>
> **Advantage:** A CTE can be defined once and referenced multiple times within the main query, avoiding redundant subquery definitions. (Note: Some RDBMS might re-evaluate it, others might materialize it. Behavior can vary.)

```sql
WITH DepartmentalAverageSalary AS (
    SELECT
        e.departmentId,
        AVG(e.salary) AS departmentalAvgSalary
    FROM advanced_query_techniques.employeesi e -- Assuming 'employeesi'
    JOIN advanced_query_techniques.departmentsi di ON e.departmentId = di.departmentId -- Join not strictly needed if only using e.departmentId
    GROUP BY e.departmentId
)
SELECT
    e.employeeId, e.firstName, e.lastName, e.salary, -- Select specific columns
    das.departmentalAvgSalary -- Show department's average salary
FROM advanced_query_techniques.employeesi e
JOIN DepartmentalAverageSalary das ON e.departmentId = das.departmentId -- Explicit JOIN
WHERE e.salary > das.departmentalAvgSalary;
```
*Note: Snippet used `NATURAL JOIN`. `JOIN ON` is preferred. The join to `departmentsi` in the CTE was not necessary if `e.departmentId` is directly used for grouping.*

### 1.3 Exercise 3: Nested CTEs

> **Problem:** List employees from ’New York’ or ’London’ who were hired after 2019. First CTE for relevant departments, then a second CTE for employees in those departments hired after 2019.
>
> **Advantage:** CTEs can be nested or chained: one CTE can refer to a previously defined CTE within the same `WITH` clause, allowing for step-by-step logical construction.

```sql
WITH RelevantDepartments AS ( -- First CTE
    SELECT di.departmentId
    FROM advanced_query_techniques.departmentsi di -- Assuming 'departmentsi'
    WHERE di.locationcity IN ('New York', 'London')
),
EmployeesInRelevantDepartmentsHiredAfter2019 AS ( -- Second CTE referencing the first
    SELECT e.*
    FROM advanced_query_techniques.employeesi e -- Assuming 'employeesi'
    JOIN RelevantDepartments rd ON e.departmentId = rd.departmentId -- Join to first CTE
    WHERE EXTRACT(YEAR FROM e.hireDate) > 2019
)
SELECT eir.employeeId, eir.firstName, eir.lastName, eir.hireDate -- Select specific columns
FROM EmployeesInRelevantDepartmentsHiredAfter2019 eir;
```
*Note: Snippet's first CTE (`NYLEmployees`) selected all employee columns after joining. It's often cleaner to select only necessary columns (like `departmentId`) in intermediate CTEs if full data isn't needed by the next CTE.*

### 1.4 Exercise 4: Recursive CTE for Hierarchical Data

> **Problem:** Display the organizational hierarchy for ’Charlie Brown’ (employeeId 103), showing his reporting line up to the top manager. List employee ID, name, manager ID, and level.
>
> **Meaning:** A recursive CTE (`WITH RECURSIVE ...`) refers to itself. It consists of an *anchor member* (base case) and a *recursive member* (inductive step) combined by `UNION ALL`.
> **Advantage:** Essential for querying hierarchical data (e.g., org charts, bill of materials, social networks) of arbitrary depth.

```sql
WITH RECURSIVE SingularReportingLine AS (
    -- Anchor Member: Start with Charlie Brown
    SELECT employeeName, employeeId, managerId, 0 AS level
    FROM advanced_query_techniques.employeesi
    WHERE employeeName = 'Charlie Brown' -- Assuming employeeId 103 is 'Charlie Brown'
    -- OR WHERE employeeId = 103

    UNION ALL

    -- Recursive Member: Find the manager of the previous level's employee
    SELECT ei.employeeName, ei.employeeId, ei.managerId, srl.level + 1
    FROM advanced_query_techniques.employeesi ei
    JOIN SingularReportingLine srl ON ei.employeeId = srl.managerId -- Join current employee to previous level's managerId
    WHERE srl.managerId IS NOT NULL -- Stop if no more managers (optional, recursion stops if JOIN fails)
)
SELECT * FROM SingularReportingLine;
```

---

## 2. Category (ii): Practice Disadvantages of CTEs

*These exercises explore potential disadvantages or limitations associated with CTEs.*

### 2.1 Exercise 1: Potential Performance Issue (Optimization Fence / Materialization)

> **Problem:** Calculate total revenue for each product. Then retrieve this ONLY for 'Electronics' products. A CTE might calculate for ALL products first.
>
> **Disadvantage (Potential):** Some RDBMS might materialize the results of a CTE (treat it as an "optimization fence"), meaning they compute the entire CTE result before the outer query uses it. If the CTE produces a large intermediate result set and the outer query only needs a small subset, this can be inefficient. Modern optimizers often try to "push down" predicates from the outer query into the CTE, but this isn't always possible or done perfectly.

**Potentially Less Optimal (calculates revenue for all, then filters category):**
```sql
WITH ProductTotalRevenue AS ( -- Calculates for ALL products
    SELECT
        st.productId,
        p.categoryId, -- Need categoryId to join later
        -- AVG in snippet is likely a typo, should be SUM for total revenue per product
        SUM(p.basePrice * st.quantitySold * (1 - st.discount)) AS totalRevenue
    FROM advanced_query_techniques.ProductsII p
    JOIN advanced_query_techniques.SalesTransactionsII st ON p.productId = st.productId -- Explicit JOIN
    GROUP BY st.productId, p.categoryId
),
ElectronicProductsTotalRevenue AS ( -- Filters category AFTER revenue calculation
    SELECT
        ptr.productId, ptr.totalRevenue, ptr.categoryId, -- pc.categoryName selected in snippet
        pc.categoryName
    FROM ProductTotalRevenue ptr
    JOIN advanced_query_techniques.ProductCategoriesII pc ON ptr.categoryId = pc.categoryId -- Explicit JOIN
    WHERE pc.categoryName = 'Electronics'
)
SELECT eptr.productId, eptr.categoryName, eptr.totalRevenue -- Select specific columns
FROM ElectronicProductsTotalRevenue eptr;
```
> **Explanation from snippet:** Note that all totalRevenues were computed before to be filtered, thus a lot of calculations were made with any reason.

**Potentially More Optimal (filters category first, then calculates revenue):**
```sql
WITH ElectronicProducts AS ( -- Filter for 'Electronics' products FIRST
    SELECT p.productId, p.categoryId, p.basePrice
    FROM advanced_query_techniques.ProductsII p
    JOIN advanced_query_techniques.ProductCategoriesII pc ON p.categoryId = pc.categoryId
    WHERE pc.categoryName = 'Electronics'
),
ElectronicProductsTotalRevenue AS ( -- Calculate revenue ONLY for electronic products
    SELECT
        ep.productId,
        SUM(ep.basePrice * st.quantitySold * (1 - st.discount)) AS totalRevenue
        -- ep.categoryId -- also available if needed
    FROM ElectronicProducts ep
    JOIN advanced_query_techniques.SalesTransactionsII st ON ep.productId = st.productId
    GROUP BY ep.productId -- , ep.categoryId
)
SELECT productId, totalRevenue
FROM ElectronicProductsTotalRevenue;
```
> **Explanation from snippet:** This order makes the query faster.

### 2.2 Exercise 2: No Indexing on CTE Results

> **Problem:** Identify products sold in the month preceding current month. Use CTE for this. Conceptually use CTE result twice: list product names, then count distinct products.
>
> **Disadvantage:** CTEs are generally not indexed themselves (unlike temporary tables in some RDBMS). If a CTE's result is large and referenced multiple times in complex ways (e.g., joined to itself or other tables multiple times), the RDBMS might re-evaluate the CTE or scan its materialized (but unindexed) result multiple times, leading to poor performance.

```sql
WITH ProductsSoldLastMonth AS ( -- No DISTINCT in snippet's "interval" CTE
    SELECT DISTINCT productId -- Adding DISTINCT here if subsequent ops need unique product IDs
    FROM advanced_query_techniques.SalesTransactionsII
    WHERE DATE_TRUNC('month', saleDate) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
)
-- Usage 1: List product names
SELECT p.productName
FROM advanced_query_techniques.ProductsII p
WHERE p.productId IN (SELECT productId FROM ProductsSoldLastMonth) -- Referencing CTE
UNION ALL -- Snippet uses UNION ALL to combine two different kinds of results
-- Usage 2: Count distinct products from the CTE
SELECT CONCAT('Total distinct products sold last month: ', CAST(COUNT(productId) AS VARCHAR)) -- COUNT(productId) as it's already distinct
FROM ProductsSoldLastMonth; -- Referencing CTE again
```
> **Explanation from snippet:** In this scenario is used the same CTE twice but not meaningfully mapping and reducing separately data in a scenario of too much information in the tables for products and sales the query could be too expensive because CTEs are not indexed despite with `WITH interval AS (SELECT DISTINCT productId ...)` could be reduced the number of necessary steps.
*(The key is that `ProductsSoldLastMonth` might be re-calculated or its (unindexed) result scanned twice.)*

### 2.3 Exercise 3: CTE Scope Limitation

> **Problem:** Calculate total sales revenue for ’Books’. Use this total in two *separate subsequent independent queries*. Show CTE is not available in the next query. Demonstrate re-declaring.
>
> **Disadvantage:** The scope of a CTE is limited to the single SQL statement in which it is defined. It cannot be referenced by subsequent, separate SQL statements without being re-declared.

**Attempting to use CTE in separate queries (will fail for the second query):**
```sql
-- Query 1 (CTE is valid here)
WITH BooksTotalRevenue AS (
    SELECT SUM(p.basePrice * s.quantitySold * (1 - s.discount)) AS total
    FROM advanced_query_techniques.ProductCategoriesII c
    JOIN advanced_query_techniques.ProductsII p ON c.categoryId = p.categoryId
    JOIN advanced_query_techniques.SalesTransactionsII s ON p.productId = s.productId
    WHERE c.categoryName = 'Books'
)
SELECT total AS books_revenue FROM BooksTotalRevenue;

-- Query 2 (This will FAIL because BooksTotalRevenue is out of scope)
-- SELECT total * 0.1 AS ten_percent_of_books_revenue FROM BooksTotalRevenue;
```
> **Explanation from snippet:** These two queries performed not simultaneously in the same query will fail because in the second invoking the CTE wont exists.

**Solution (using CTE in a single statement for both calculations, or re-declaring):**
```sql
-- Option 1: Both calculations in one statement
WITH BooksTotalRevenue AS (
    SELECT SUM(p.basePrice * s.quantitySold * (1 - s.discount)) AS total
    FROM advanced_query_techniques.ProductCategoriesII c
    JOIN advanced_query_techniques.ProductsII p ON c.categoryId = p.categoryId
    JOIN advanced_query_techniques.SalesTransactionsII s ON p.productId = s.productId
    WHERE c.categoryName = 'Books'
)
SELECT total AS books_revenue, total * 0.1 AS ten_percent_of_books_revenue
FROM BooksTotalRevenue;

-- Option 2: Re-declaring for a conceptually separate (but still single if needed by some tools) operation
-- This would be literally two separate script executions if truly independent.
-- If within one script block but needing to be "separate":
-- WITH BooksTotalRevenue AS (...) SELECT total ...;
-- WITH BooksTotalRevenue AS (...) SELECT total * 0.1 ...;
```
> **Explanation from snippet (for combined solution):** This query is the solution because uses the same query [CTE definition] in the [same statement].

---

## 3. Category (iii): Practice Cases Avoiding Inefficient Basic Solutions

*These exercises demonstrate scenarios where CTEs offer significant advantages over more basic approaches.*

### 3.1 Exercise 1: Replacing Repeated Subqueries

> **Problem:** Find customers who ordered in both 2022 and 2023. List names and city. CTEs avoid repeating subquery logic.
>
> **Advantage:** CTEs make the query more readable and maintainable by defining the logic for "orders in 2022" and "orders in 2023" once.

```sql
WITH OrdersIn2022 AS (
    SELECT DISTINCT customerId -- DISTINCT customerId is enough
    FROM advanced_query_techniques.OrdersIII
    WHERE EXTRACT(YEAR FROM orderDate) = 2022 -- DATE_PART is PostgreSQL specific, EXTRACT is more standard
),
OrdersIn2023 AS (
    SELECT DISTINCT customerId
    FROM advanced_query_techniques.OrdersIII
    WHERE EXTRACT(YEAR FROM orderDate) = 2023
)
SELECT c.customerName, c.city -- Select specific columns
FROM advanced_query_techniques.CustomersIII c
WHERE
    EXISTS (SELECT 1 FROM OrdersIn2022 o22 WHERE c.customerId = o22.customerId)
    AND EXISTS (SELECT 1 FROM OrdersIn2023 o23 WHERE c.customerId = o23.customerId);
```
> **Explanation from snippet:** Without the CTEs must be necessary two subqueries within this creating a highly unreadable query.

### 3.2 Exercise 2: Simplifying Complex Joins and Filters

> **Problem:** List products (name, category) in orders shipped to ’North America’ with total order value > $600. CTEs break down logic.
>
> **Advantage:** Improves readability by separating concerns: first identify relevant orders, then calculate their total value, then join to products.

```sql
WITH NorthAmericaOrders AS (
    SELECT orderId, customerId -- Select only necessary columns
    FROM advanced_query_techniques.OrdersIII
    WHERE shipmentRegion = 'North America'
),
HighValueNorthAmericaOrders AS (
    SELECT nao.orderId
    FROM NorthAmericaOrders nao
    JOIN advanced_query_techniques.OrderItemsIII oi ON nao.orderId = oi.orderId
    GROUP BY nao.orderId
    HAVING SUM(oi.quantity * oi.pricePerUnit) > 600
)
SELECT DISTINCT p.productName, p.category -- DISTINCT in case a product is in multiple such orders
FROM advanced_query_techniques.ProductsMasterIII p
JOIN advanced_query_techniques.OrderItemsIII oi ON p.productId = oi.productId
JOIN HighValueNorthAmericaOrders hvnao ON oi.orderId = hvnao.orderId;

-- Snippet's TotalOrderValue CTE combined product details with order value calculation, which is also valid:
WITH USAOrders AS ( ... ),
 TotalOrderValue AS (
   SELECT u.orderId, p.productName, p.category, SUM(o.quantity * o.pricePerUnit) OVER (PARTITION BY u.orderId) AS orderTotalValue
   FROM USAOrders u
   JOIN advanced_query_techniques.OrderItemsIII o ON u.orderId = o.orderId
   JOIN advanced_query_techniques.ProductsMasterIII p ON o.productId = p.productId
 )
 SELECT productName, category FROM TotalOrderValue WHERE orderTotalValue > 600;
-- (The snippet's `TotalOrderValue` had a `|` typo and the aggregation for total order value was missing or needed a window function if per item)
```
> **Explanation from snippet:** Note how this CTE is useful to break from the beginning the number of necessary mappings in joins by filtering first by shipment region. Such breaking not only makes more readable the query but more performant.

### 3.3 Exercise 3: Avoiding Temporary Tables for Single-Query Scope

> **Problem:** Calculate avg total order value per `shipmentRegion`. List regions whose avg order value > overall avg order value. CTEs vs temp tables.
>
> **Advantage:** CTEs provide a clean, single-statement solution for multi-step calculations without the DDL overhead or transactional complexities of actual temporary tables, when the scope is just one query.

```sql
WITH OrderValues AS ( -- Calculate value for each order first
    SELECT
        o.orderId,
        o.shipmentRegion,
        SUM(oi.pricePerUnit * oi.quantity) AS totalOrderValue
    FROM advanced_query_techniques.OrdersIII o
    JOIN advanced_query_techniques.OrderItemsIII oi ON o.orderId = oi.orderId
    GROUP BY o.orderId, o.shipmentRegion
),
RegionAverageOrderValue AS ( -- Then average per region
    SELECT
        shipmentRegion,
        AVG(totalOrderValue) AS avgRegionOrderValue
    FROM OrderValues
    GROUP BY shipmentRegion
),
OverallAverageOrderValue AS ( -- Overall average
    SELECT AVG(totalOrderValue) AS overallAvgValue
    FROM OrderValues
)
SELECT raov.shipmentRegion, raov.avgRegionOrderValue
FROM RegionAverageOrderValue raov, OverallAverageOrderValue oaov -- Comma for CROSS JOIN (1 row)
WHERE raov.avgRegionOrderValue > oaov.overallAvgValue;

-- Snippet's approach (more concise using subquery in WHERE for overall average):
 WITH RegionizedValue AS (
 	SELECT o.shipmentRegion region, AVG(oi.pricePerUnit * oi.quantity) reg_value -- This AVG is not total order value, but avg item value per region per order item.
 	FROM advanced_query_techniques.OrderItemsIII oi
 	NATURAL JOIN advanced_query_techniques.OrdersIII o
 	GROUP BY o.shipmentRegion
 )
 SELECT *
 FROM RegionizedValue
 WHERE reg_value > (SELECT AVG(reg_value) FROM RegionizedValue);
-- The snippet's RegionizedValue calculates average of (price*qty) per region.
-- This is subtly different from "average total order value". The CTEs above address "average total order value".
```

### 3.4 Exercise 4: Step-by-Step Multi-Level Aggregations (Revised)

> **Problem:** For each product category, find the month (e.g., ’2023-04’) with the highest total sales quantity. Display category, best month, total quantity. Solve with CTEs (no window functions).
>
> **Advantage:** CTEs allow breaking down complex multi-level aggregations into understandable steps.

```sql
WITH MonthlyCategoryQuantity AS ( -- Step 1: Calculate total quantity per category per month
    SELECT
        p.category,
        TO_CHAR(o.orderDate, 'YYYY-MM') AS sale_month, -- Format month
        SUM(oi.quantity) AS total_monthly_quantity
    FROM advanced_query_techniques.productsMasterIII p
    JOIN advanced_query_techniques.orderItemsIII oi ON p.productId = oi.productId
    JOIN advanced_query_techniques.ordersIII o ON oi.orderId = o.orderId
    GROUP BY p.category, TO_CHAR(o.orderDate, 'YYYY-MM')
),
MaxMonthlyQuantityPerCategory AS ( -- Step 2: Find the max quantity for each category across its months
    SELECT
        category,
        MAX(total_monthly_quantity) AS max_quantity
    FROM MonthlyCategoryQuantity
    GROUP BY category
)
-- Step 3: Join back to find the month(s) that achieved that max quantity
SELECT
    mcq.category,
    mcq.sale_month AS best_month,
    mcq.total_monthly_quantity
FROM MonthlyCategoryQuantity mcq
JOIN MaxMonthlyQuantityPerCategory mmqpc
    ON mcq.category = mmqpc.category AND mcq.total_monthly_quantity = mmqpc.max_quantity
ORDER BY mcq.category, mcq.sale_month;

-- Snippet's approach used LATERAL, which is powerful but problem asked for CTEs for aggregation.
-- The snippet's CTE `categoricalMaximumTotalSales` calculated MAX(oi.quantity) per (category, orderDate),
-- which is max quantity of a single item in an order on a specific date, not total sales quantity for a month.
-- The LATERAL then picked the top one based on this item max quantity.
-- The solution above focuses on "total sales quantity for that category *in a month*".
```

---

## 4. Category (iv): Hardcore Combined Problem

*This problem requires combining various SQL concepts, focusing on CTEs in a complex scenario. No window functions.*

### 4.1 Hardcore Problem

> **Problem:** Identify top 2 departments by total salary of their ’Senior’ employees.
> ’Senior’ criteria: salary > $70k AND hired >= ’2020-01-01’ AND logged time on a task in a ’Critical’ project.
> ’Critical’ project: budget > $150k.
> For these top 2 depts:
> a. Dept Name.
> b. Total senior salary.
> c. Count of senior employees.
> d. For each, use `LATERAL` to find employee (any in dept) with most distinct projects logged; show name & count.
> For #1 dept (by total senior salary):
> e. Display org hierarchy for its dept head upwards.
> Constraints: Depts must have >= 2 qualified seniors. Use `FETCH` for top 2.

*(The provided snippet is extremely complex and attempts a recursive CTE for the hierarchy as part of one large `WITH` block. It has several CTEs leading up to the final result. It's a very ambitious single statement. We'll focus on the logic of each part.)*

**Conceptual Breakdown using CTEs (following problem structure):**

**Part 1: Identifying Senior Employees and their Departments**
```sql
WITH CriticalProjects AS (
    SELECT projectId
    FROM advanced_query_techniques.ProjectsIV
    WHERE budget > 150000
),
EmployeeTaskedOnCriticalProject AS ( -- Employees who logged time on any task of a critical project
    SELECT DISTINCT tl.employeeId
    FROM advanced_query_techniques.TimeLogsIV tl
    JOIN advanced_query_techniques.TasksIV t ON tl.taskId = t.taskId
    JOIN CriticalProjects cp ON t.projectId = cp.projectId
),
SeniorEmployees AS ( -- Qualified senior employees
    SELECT e.employeeId, e.departmentId, e.salary, e.employeeName -- Added name for later
    FROM advanced_query_techniques.EmployeesIV e
    JOIN EmployeeTaskedOnCriticalProject etcp ON e.employeeId = etcp.employeeId
    WHERE e.salary > 70000 AND e.hireDate >= DATE '2020-01-01'
),
DepartmentSeniorStats AS ( -- Aggregate senior stats per department
    SELECT
        departmentId,
        SUM(salary) AS total_senior_salary,
        COUNT(employeeId) AS count_senior_employees
    FROM SeniorEmployees
    GROUP BY departmentId
    HAVING COUNT(employeeId) >= 2 -- Constraint: Depts must have at least 2 seniors
),
Top2DepartmentsBySeniorSalary AS ( -- Get the top 2 departments
    SELECT dss.departmentId, dss.total_senior_salary, dss.count_senior_employees
    FROM DepartmentSeniorStats dss
    ORDER BY dss.total_senior_salary DESC
    FETCH FIRST 2 ROWS ONLY -- Standard SQL for LIMIT
)
-- Now, the main query for parts a, b, c, d would join Top2DepartmentsBySeniorSalary with DepartmentsIV
-- and then use a LATERAL join.
```

**Part 2: Main query for top 2 departments' details (a, b, c, d)**
```sql
-- (Assuming CTEs from Part 1 are defined above in the same WITH clause)
SELECT
    d.departmentName,
    t2d.total_senior_salary,
    t2d.count_senior_employees,
    most_active_emp.employeeName AS most_projects_employee_name,
    most_active_emp.distinct_project_count
FROM Top2DepartmentsBySeniorSalary t2d
JOIN advanced_query_techniques.DepartmentsIV d ON t2d.departmentId = d.departmentId
CROSS JOIN LATERAL ( -- Or JOIN LATERAL ... ON TRUE
    SELECT
        e_lat.employeeName,
        COUNT(DISTINCT t_lat.projectId) AS distinct_project_count,
        e_lat.employeeId -- For tie-breaking
    FROM advanced_query_techniques.EmployeesIV e_lat
    JOIN advanced_query_techniques.TimeLogsIV tl_lat ON e_lat.employeeId = tl_lat.employeeId
    JOIN advanced_query_techniques.TasksIV t_lat ON tl_lat.taskId = t_lat.taskId
    WHERE e_lat.departmentId = t2d.departmentId -- Employee in the current top department
    GROUP BY e_lat.employeeId, e_lat.employeeName
    ORDER BY distinct_project_count DESC, e_lat.employeeId ASC
    FETCH FIRST 1 ROW ONLY
) most_active_emp
ORDER BY t2d.total_senior_salary DESC;
```

**Part 3: Hierarchy for the #1 Department's Head (e)**
This would typically be a separate query or a more complex combined one. Let's assume we get the `headEmployeeId` of the #1 department from the previous result.
```sql
-- Assume #1_dept_head_id is known (e.g., from a subquery selecting the head of the top 1 dept from above)
-- For demonstration, let's say it's obtained like this:
WITH Top1DepartmentHead AS (
    SELECT d_head.headEmployeeId
    FROM Top2DepartmentsBySeniorSalary t2d_head -- Reusing CTE from above if possible
    JOIN advanced_query_techniques.DepartmentsIV d_head ON t2d_head.departmentId = d_head.departmentId
    ORDER BY t2d_head.total_senior_salary DESC
    FETCH FIRST 1 ROW ONLY
)
-- Recursive CTE for hierarchy
WITH RECURSIVE DepartmentHeadHierarchy AS (
    -- Anchor: The department head
    SELECT
        e_hier.employeeId,
        e_hier.employeeName,
        e_hier.managerId,
        0 AS level
    FROM advanced_query_techniques.EmployeesIV e_hier
    WHERE e_hier.employeeId = (SELECT headEmployeeId FROM Top1DepartmentHead)

    UNION ALL

    -- Recursive: Their manager, and so on
    SELECT
        manager.employeeId,
        manager.employeeName,
        manager.managerId,
        dhh.level + 1
    FROM advanced_query_techniques.EmployeesIV manager
    JOIN DepartmentHeadHierarchy dhh ON manager.employeeId = dhh.managerId
    WHERE dhh.managerId IS NOT NULL -- Stop if no more managers
)
SELECT * FROM DepartmentHeadHierarchy ORDER BY level;
```

**Critique of Snippet's Hardcore Problem Solution:**
The snippet's solution is extremely dense and attempts to solve almost everything within a single, very large `WITH RECURSIVE` block (even if only the second part is truly recursive).
*   **`taskedTimeLogs`**: Good start, joins `TimeLogsIV` and `TasksIV`.
*   **`projectsByEmployeeWithDepartments`**: Aggregates project counts per employee and joins department info. `ARRAY_AGG` is a nice touch but might not be needed if only count is used later.
*   **`taskedTimeLogsOfCriticalProjects`**: Correctly identifies tasks in critical projects.
*   **`departmentalTaskedLogsOfCriticalProjects`**: This CTE tries to link departments to critical project tasks and employees. The logic with `ANY(pbewd.projectsId)` is a bit complex; a direct join might be clearer.
*   **`topEmployeesByDepartments`**: This is where it gets very intricate. It uses `LATERAL` to get the top-salaried "senior" employee *per department-critical project combination* (due to `dtlocp` structure) which isn't quite "top 2 departments by total senior salary". The `FETCH NEXT 1 ROWS ONLY` inside the first LATERAL and then `FETCH NEXT 2 ROWS ONLY` outside seem to be mixing "top employee within a group" with "top departments". The second `LATERAL` (`l2`) correctly calculates total senior salary and count for the employees identified by `dtlocp.employeesId` (employees on tasks of a critical project in a dept). The problem wants top departments based on *all* their qualified seniors, not just those related to one critical project's tasks.
*   **`filteredDepartmentalProjectedTopEmployees`**: Tries to bring it together. The `LATERAL` for `most_active_emp` is correctly structured for that sub-problem.
*   **Recursive CTE `projectManagerHierarchy`**: The anchor condition `EXISTS (SELECT * FROM (SELECT * FROM filteredDepartmentalProjectedTopEmployees ORDER BY salary LIMIT 1) as sq WHERE sq.departmentId = div.departmentId)` is very complex. It tries to find the department head of the department that had the overall top-salaried *employee* from the `filteredDepartmentalProjectedTopEmployees` (which itself was derived from a complex `topEmployeesByDepartments`). This needs to be the head of the #1 *department* by *total senior salary*.

**General Comments on Snippet's Hardcore Solution:**
*   It's a valiant attempt to use many advanced features.
*   The definition of "Senior" employee (salary, hire date, AND logged time on critical project task) needs to be established first, then aggregated per department.
*   The snippet's structure for finding "top 2 departments" is not direct. It seems to find top employees/projects first and then try to derive top departments, which is the reverse of the problem statement.
*   The logic for identifying the #1 department head for the recursive CTE is deeply nested and might not accurately pick the head of the department with the highest *total senior salary*.

The conceptual breakdown provided *before* this critique offers a more staged approach, which is generally easier to develop, debug, and understand for such complex requirements.