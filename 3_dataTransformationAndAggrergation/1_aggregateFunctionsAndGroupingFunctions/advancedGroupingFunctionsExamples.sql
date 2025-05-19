-- SELECT
-- 	EXTRACT ( YEAR FROM saleDate ) AS saleYear ,
-- 	EXTRACT ( QUARTER FROM saleDate ) AS saleQuarter ,
-- 	EXTRACT ( MONTH FROM saleDate ) AS saleMonth ,
-- 	SUM ( quantity ) AS totalQuantity ,
-- 	GROUPING ( 
-- 		EXTRACT ( YEAR FROM saleDate ) , 
-- 		EXTRACT ( QUARTER FROM saleDate ) , 
-- 		EXTRACT ( MONTH FROM saleDate ) 
-- 	) AS groupingLevel
-- FROM data_transformation_and_aggregation.Sales
-- GROUP BY ROLLUP (
-- 	EXTRACT ( YEAR FROM saleDate ) ,
-- 	EXTRACT ( QUARTER FROM saleDate ) ,
-- 	EXTRACT ( MONTH FROM saleDate )
-- ) ORDER BY saleYear NULLS LAST , saleQuarter NULLS LAST , saleMonth NULLS LAST;

-- SELECT
-- 	r.regionName ,
-- 	p.category AS productCategory ,
-- 	SUM ( s.quantity ) AS totalQuantity ,
-- 	GROUPING ( r.regionName, p.category ) AS groupingIndicator
-- FROM data_transformation_and_aggregation.Sales s
-- NATURAL JOIN data_transformation_and_aggregation.Products p
-- NATURAL JOIN data_transformation_and_aggregation.Regions r
-- GROUP BY CUBE ( r.regionName, p.category )
-- ORDER BY r.regionName NULLS LAST, p.category NULLS LAST;

-- SELECT
-- 	d.departmentName,
-- 	r.regionName,
-- 	SUM (s.quantity) AS totalSales,
-- 	GROUPING (d.departmentName, r.regionName) AS groupingIndicator
-- FROM data_transformation_and_aggregation.Sales s
-- JOIN data_transformation_and_aggregation.Employees e ON s.employeeId = e.employeeId
-- JOIN data_transformation_and_aggregation.Departments d ON e.departmentId = d.departmentId
-- JOIN data_transformation_and_aggregation.Regions r ON s.regionId = r.regionId
-- GROUP BY GROUPING SETS (
-- 	(d.departmentName, r.regionName),
-- 	(r.regionName),
-- 	()
-- ) ORDER BY d.departmentName NULLS LAST, r.regionName NULLS LAST;

-- SELECT
--     CASE GROUPING(d.departmentName)
--         WHEN 1 THEN 'All Departments Total'
--         ELSE d.departmentName
--     END AS department,
--     SUM(e.salary) AS totalSalary
-- FROM
--     advanced_query_techniques.EmployeesI e
-- JOIN
--     advanced_query_techniques.DepartmentsI d ON e.departmentId = d.departmentId
-- GROUP BY
--     ROLLUP (d.departmentName)
-- ORDER BY
--     GROUPING(d.departmentName),
--     d.departmentName;

-- Example 1: ROLLUP with One Column
-- Purpose: To calculate aggregate values (employee count, total salary) for each department
--          and a grand total across all departments.
-- `ROLLUP (d.departmentName)` creates two levels of aggregation:
--   1. Per d.departmentName
--   2. Grand total (d.departmentName is NULL in this grouping context)
SELECT
    -- The CASE statement uses GROUPING(d.departmentName) to determine the label.
    -- GROUPING(d.departmentName) returns:
    --   0 if d.departmentName is part of the current grouping key (i.e., a specific department row).
    --   1 if d.departmentName is aggregated/rolled up (i.e., the grand total row where d.departmentName is conceptually NULL).
    CASE GROUPING(d.departmentName)
        WHEN 1 THEN 'All Departments - Grand Total' -- Label for the grand total row
        ELSE d.departmentName                     -- Actual department name for department-specific rows
    END AS department_group,

    -- Explicitly showing the GROUPING() value for clarity.
    -- This helps understand how the CASE statement above works.
    GROUPING(d.departmentName) AS grouping_dept_name_value,

    COUNT(e.employeeId) AS employee_count,
    SUM(e.salary) AS total_salary
FROM
    advanced_query_techniques.EmployeesI e
JOIN
    advanced_query_techniques.DepartmentsI d ON e.departmentId = d.departmentId
GROUP BY
    ROLLUP (d.departmentName) -- Generates subtotals for departmentName and a grand total.
ORDER BY
    -- Sorts the grand total row (GROUPING=1) before individual department rows (GROUPING=0).
    GROUPING(d.departmentName),
    -- Then sorts individual departments alphabetically.
    d.departmentName;




-- Example 2: ROLLUP with Two Columns
-- Purpose: To calculate aggregates at multiple levels:
--          1. Per (departmentName, locationCity) - most granular.
--          2. Per departmentName (summing across its locationCities) - subtotal.
--          3. Grand total (summing across all departments and cities).
-- `ROLLUP (d.departmentName, d.locationCity)` follows a hierarchy:
--   (d.departmentName, d.locationCity)
--   (d.departmentName)  -- d.locationCity is rolled up
--   ()                  -- d.departmentName and d.locationCity are rolled up
SELECT
    -- Labeling for the department level.
    -- GROUPING(d.departmentName) = 1 only for the grand total row.
    CASE GROUPING(d.departmentName)
        WHEN 1 THEN 'All Departments & Cities - Grand Total'
        ELSE d.departmentName
    END AS department_group,

    -- Labeling for the city level.
    -- GROUPING(d.locationCity) = 1 if locationCity is rolled up. This happens for:
    --   a) Department subtotals (departmentName is present, city is rolled up).
    --   b) The grand total (both departmentName and city are rolled up).
    CASE GROUPING(d.locationCity)
        WHEN 1 THEN
            -- Further distinguish if this "All Cities" is for a specific department or the grand total.
            CASE GROUPING(d.departmentName)
                WHEN 1 THEN '' -- For grand total, city part is implied by department's grand total.
                ELSE 'All Cities in Department' -- For department subtotal.
            END
        ELSE d.locationCity -- Actual city name if not rolled up.
    END AS city_group,

    -- Explicitly showing the GROUPING() values.
    GROUPING(d.departmentName) AS grouping_dept_name_value,   -- 0 for specific dept, 1 for grand total.
    GROUPING(d.locationCity) AS grouping_location_city_value, -- 0 for specific city, 1 if city is subtotaled/grandtotaled.

    COUNT(e.employeeId) AS employee_count,
    SUM(e.salary) AS total_salary
FROM
    advanced_query_techniques.EmployeesI e
JOIN
    advanced_query_techniques.DepartmentsI d ON e.departmentId = d.departmentId
GROUP BY
    ROLLUP (d.departmentName, d.locationCity) -- Rolls up from right to left: (dept, city), (dept), ()
ORDER BY
    -- Order ensures logical presentation: Grand total, then department subtotals, then city details.
    GROUPING(d.departmentName),   -- Grand total first
    d.departmentName,             -- Then by department name
    GROUPING(d.locationCity), -- Department subtotals before specific cities within that dept
    d.locationCity;               -- Then by city name





-- Example 3: CUBE with Two Columns
-- Purpose: To calculate aggregates for all possible combinations of grouping sets
--          from the specified columns (d.departmentName, d.locationCity).
-- `CUBE (d.departmentName, d.locationCity)` generates:
--   1. (d.departmentName, d.locationCity) - most granular.
--   2. (d.departmentName) - subtotal per department (locationCity rolled up).
--   3. (d.locationCity) - subtotal per city (departmentName rolled up). *This is what CUBE adds over ROLLUP*.
--   4. () - grand total (both rolled up).
SELECT
    -- Label for department based on whether d.departmentName is rolled up.
    -- GROUPING(d.departmentName) = 1 if departmentName is aggregated (for city subtotals or grand total).
    CASE GROUPING(d.departmentName)
        WHEN 1 THEN 'Overall (All Departments Aggregate)'
        ELSE d.departmentName
    END AS department_group,

    -- Label for city based on whether d.locationCity is rolled up.
    -- GROUPING(d.locationCity) = 1 if locationCity is aggregated (for department subtotals or grand total).
    CASE GROUPING(d.locationCity)
        WHEN 1 THEN 'Overall (All Cities Aggregate)'
        ELSE d.locationCity
    END AS city_group,

    -- Explicitly showing GROUPING() values.
    GROUPING(d.departmentName) AS grouping_dept_name_value,
    GROUPING(d.locationCity) AS grouping_location_city_value,

    COUNT(e.employeeId) AS employee_count,
    SUM(e.salary) AS total_salary
FROM
    advanced_query_techniques.EmployeesI e
JOIN
    advanced_query_techniques.DepartmentsI d ON e.departmentId = d.departmentId
GROUP BY
    CUBE (d.departmentName, d.locationCity) -- Generates all combinations of groupings.
ORDER BY
    -- Order to make the output more readable.
    GROUPING(d.departmentName),
    d.departmentName,
    GROUPING(d.locationCity),
    d.locationCity;



-- Example 4: GROUPING SETS to Define Custom Aggregation Levels
-- Purpose: To explicitly define the exact combinations of columns for which subtotals are needed.
--          This provides fine-grained control over the aggregation levels.
-- Here, we're replicating the behavior of CUBE for two columns by specifying all sets.
SELECT
    -- This complex CASE structure creates descriptive labels for 'department_label'
    -- by checking the GROUPING status of both departmentName and locationCity.
    CASE
        -- Level 1: Most granular (departmentName, locationCity)
        WHEN GROUPING(d.departmentName) = 0 AND GROUPING(d.locationCity) = 0 THEN d.departmentName
        -- Level 2: Subtotal for departmentName (locationCity is aggregated)
        WHEN GROUPING(d.departmentName) = 0 AND GROUPING(d.locationCity) = 1 THEN d.departmentName
        -- Level 3: Subtotal for locationCity (departmentName is aggregated)
        WHEN GROUPING(d.departmentName) = 1 AND GROUPING(d.locationCity) = 0 THEN 'All Departments for this City'
        -- Level 4: Grand Total (both are aggregated)
        WHEN GROUPING(d.departmentName) = 1 AND GROUPING(d.locationCity) = 1 THEN 'Grand Total'
    END AS department_label,

    -- Similar complex CASE for 'city_label'.
    CASE
        WHEN GROUPING(d.departmentName) = 0 AND GROUPING(d.locationCity) = 0 THEN d.locationCity
        WHEN GROUPING(d.departmentName) = 0 AND GROUPING(d.locationCity) = 1 THEN 'All Cities in this Dept'
        WHEN GROUPING(d.departmentName) = 1 AND GROUPING(d.locationCity) = 0 THEN d.locationCity
        WHEN GROUPING(d.departmentName) = 1 AND GROUPING(d.locationCity) = 1 THEN 'All Cities Overall'
    END AS city_label,

    -- Explicit GROUPING values for inspection.
    GROUPING(d.departmentName) AS g_dept_val,
    GROUPING(d.locationCity) AS g_city_val,

    COUNT(e.employeeId) AS employee_count,
    SUM(e.salary) AS total_salary
FROM
    advanced_query_techniques.EmployeesI e
JOIN
    advanced_query_techniques.DepartmentsI d ON e.departmentId = d.departmentId
GROUP BY
    GROUPING SETS (
        (d.departmentName, d.locationCity), -- Group by both department and city.
        (d.departmentName),                 -- Group by department only (subtotal for department).
        (d.locationCity),                   -- Group by city only (subtotal for city).
        ()                                  -- Grand total (group by nothing).
    )
ORDER BY
    -- Ordering to make the various grouping sets appear in a logical sequence.
    g_dept_val, department_label, g_city_val, city_label;





-- Example 5: Using the Bitmask Property of GROUPING()
-- Purpose: To demonstrate how GROUPING(colA, colB, ...) returns a single integer (bitmask)
--          representing the aggregation status of all specified columns.
-- The bitmask is formed as:
--   ... + (GROUPING(colA) * 2^N) + ... + (GROUPING(colY) * 2^1) + (GROUPING(colZ) * 2^0)
-- For GROUPING(d.departmentName, d.locationCity):
--   Bit 0 (value 1) is for d.locationCity.
--   Bit 1 (value 2) is for d.departmentName.
SELECT
    -- Displaying the original columns. These will be NULL if the column is aggregated for that row.
    d.departmentName,
    d.locationCity,

    -- The bitmask value itself.
    GROUPING(d.departmentName, d.locationCity) AS grouping_bitmask,

    -- Manually deciphering the bitmask using bitwise AND to check individual bits.
    -- This shows what the single GROUPING(colA, colB) call implicitly combines.
    -- (grouping_bitmask & 2) > 0 means the bit for departmentName (position 1, value 2) is set.
    CASE WHEN (GROUPING(d.departmentName, d.locationCity) & 2) > 0 THEN 1 ELSE 0 END AS is_dept_name_aggregated_from_mask,
    -- (grouping_bitmask & 1) > 0 means the bit for locationCity (position 0, value 1) is set.
    CASE WHEN (GROUPING(d.departmentName, d.locationCity) & 1) > 0 THEN 1 ELSE 0 END AS is_location_city_aggregated_from_mask,

    -- Using the bitmask directly in a CASE statement for labeling.
    CASE GROUPING(d.departmentName, d.locationCity)
        WHEN 0 THEN 'Detail: (' || COALESCE(d.departmentName, 'N/A') || ', ' || COALESCE(d.locationCity, 'N/A') || ')' -- Binary 00: Both not aggregated (d.deptName active, d.locCity active)
        WHEN 1 THEN 'Subtotal for Dept: ' || d.departmentName || ' (City Aggregated)'           -- Binary 01: d.locCity aggregated (d.deptName active)
        WHEN 2 THEN 'Subtotal for City: ' || d.locationCity || ' (Dept Aggregated)'             -- Binary 10: d.deptName aggregated (d.locCity active)
        WHEN 3 THEN 'Grand Total (Both Dept & City Aggregated)'                                 -- Binary 11: Both aggregated
    END AS aggregation_level_description,

    COUNT(e.employeeId) AS employee_count,
    SUM(e.salary) AS total_salary
FROM
    advanced_query_techniques.EmployeesI e
JOIN
    advanced_query_techniques.DepartmentsI d ON e.departmentId = d.departmentId
GROUP BY
    CUBE (d.departmentName, d.locationCity) -- CUBE is used here as it generates all 2^N combinations
                                            -- that map directly to the bitmask values from 0 to 2^N - 1.
ORDER BY
    grouping_bitmask, -- Order by the bitmask to see the levels clearly.
    d.departmentName, -- Secondary sort for readability within each bitmask level.
    d.locationCity;   -- Tertiary sort.





	
