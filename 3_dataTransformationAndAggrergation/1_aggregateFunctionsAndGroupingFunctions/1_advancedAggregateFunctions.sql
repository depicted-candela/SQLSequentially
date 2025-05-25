		-- Advanced Aggregate Functions


-- 	1.1 STRING AGG(expression, separator [ORDER BY ...])

-- 		1.1.1 Practice Meaning, Values, Relations, Advantages
-- • Problem: For each department, list the department name and a comma-separated
-- string of its employees’ first names, ordered alphabetically by first name. Employees
-- with no department should be handled gracefully.
SELECT d.departmentId, d.departmentName, COALESCE(STRING_AGG(e.firstName, ', ' ORDER BY e.firstName), 'No employees') employeesId
FROM data_transformation_and_aggregation.departments d
NATURAL JOIN data_transformation_and_aggregation.employees e
GROUP BY d.departmentId;

-- 		1.1.2 Practice Disadvantages
-- • Problem: What is a potential disadvantage of using STRING AGG if the concatenated
-- string becomes very long or if individual components need to be queried later in
-- SQL? Show an alternative query structure if the goal is to list department names
-- and individual employee first names for further relational processing, rather than a
-- concatenated string.
-- Answer: sending an immense string with many separations does not have sense because
-- to be represented in a custom user screen will be necessary postprocessing in the
-- user machine to order the string by breaking it in representable chunks for a normal
-- screen, then why not breaking it directly in the server and storing it in a single
-- object to be easily unwrapped in user's machines with JSON_AGG or a table relationing all
-- first names with their related departments?
SELECT 	-- option a
	d.departmentId, d.departmentName, 
	COALESCE(JSON_AGG(DISTINCT e.firstName ORDER BY e.firstName), '[]'::json) employees
FROM data_transformation_and_aggregation.departments d
NATURAL JOIN data_transformation_and_aggregation.employees e
GROUP BY d.departmentId;
SELECT -- option b
	COALESCE ( d.departmentName, 'No Department Assigned') AS
	departmentName,
	e.firstName
FROM data_transformation_and_aggregation.Employees e
LEFT JOIN data_transformation_and_aggregation.Departments d ON e.departmentId = d.departmentId
ORDER BY COALESCE (d.departmentName, 'No Department Assigned') NULLS FIRST, e.firstName;


-- 		1.1.3 Practice Inefficient Alternatives Avoidance
-- • Problem: A user needs to create a semicolon-separated list of all unique skills
-- possessed by employees in the ’Engineering’ department. They might consider
-- fetching all skills and programmatically concatenating them. Show the efficient
-- STRING AGG approach, possibly using UNNEST if skills are in an array.
SELECT sq.departmentId, COALESCE(STRING_AGG(sq.allSkills, '; '), 'Department without skills')
FROM (
	SELECT d.departmentId, UNNEST(e.skills) allSkills
	FROM data_transformation_and_aggregation.employees e
	JOIN data_transformation_and_aggregation.departments d
		ON d.departmentName = 'Engineering' AND e.departmentId = d.departmentId
) sq GROUP BY sq.departmentId;


-- 1.2 ARRAY AGG(expression [ORDER BY ...])

-- 1.2.1 Practice Meaning, Values, Relations, Advantages
-- • Problem: For each project, list the project name and an array of employeeIds
-- of those who worked on it. The employeeIds in the array should be sorted in
-- ascending order.
SELECT 
	p.projectId,
	p.projectName,
	ARRAY_AGG(e.employeeId ORDER BY e.employeeId) employeesId
FROM data_transformation_and_aggregation.projects p
NATURAL JOIN data_transformation_and_aggregation.employees e
GROUP BY p.projectId, p.projectName;

-- 1.2.2 Practice Disadvantages
-- • Problem: If you use ARRAY_AGG to store a list of employee IDs for each project, what
-- is a disadvantage if you frequently need to find projects where a specific employee
-- ID is, for example, the *first* person assigned (first in the aggregated array)? How
-- does this compare to a normalized structure?
-- Answer: the aggregated array does not have features for FETCH AND OFFSET and indexes
-- for high speeds, thus in such scenarios is not good idea the usage of such arrays
-- rather than normalized tables prone to be indexed, lagged, filtered and lateralized.
-- Despite positions within arrays as array[position:int] extract the value is not performant
-- and the power of SQL does not lie there

-- 1.2.3 Practice Inefficient Alternatives Avoidance
-- • Problem: An application needs to display each product category along with a list
-- of all product names within that category. A naive approach might be to query all
-- categories, then for each category, execute another query to get its products, then
-- assemble these lists in the application. Show how ARRAY_AGG can do this efficiently
-- in one SQL query.
-- Answer: the inefficient way involves fetching for every category a related column with
-- all their products to be fused with the UNION statement (UNION appears as categories
-- exist), this is the N+1 problem: always prone to be avoided
SELECT p.category, ARRAY_AGG(p.productName)
FROM data_transformation_and_aggregation.products p
GROUP BY p.category;


-- 1.3 JSON_AGG(expression [ORDER BY ...])

-- 1.3.1 Practice Meaning, Values, Relations, Advantages
-- • Problem: For each department located in ’San Francisco’, create a JSON array.
-- Each element of the array should be a JSON object representing an employee,
-- containing their firstName, lastName, and salary. Employees should be ordered
-- by salary in descending order within the JSON array.
SELECT 
	p.departmentName, 
	JSONB_AGG(
		JSON_BUILD_OBJECT(
			'firstName', firstName, 
			'lastName', lastName, 
			'salary', salary
		) ORDER BY salary DESC
	) employees
FROM data_transformation_and_aggregation.employees e
JOIN data_transformation_and_aggregation.departments p 
	ON p.locationCity = 'San Francisco' AND e.departmentId = p.departmentId
GROUP BY p.departmentName;

-- 1.3.2 Practice Disadvantages
-- • Problem: What is a potential performance issue when using JSON_AGG to aggregate
-- a very large number of complex objects into a single JSON array for many groups?
-- Also, comment on type checking when consuming this JSON.
-- Answer: JSON to be constructed neeeds lots of memory because it needs additional
-- memory to write the properties of their features. If the json object is too complex
-- needs more memory to be stored in primary memory, computation to be modeled, and 
-- bandwidth to be transmitted

-- 1.3.3 Practice Inefficient Alternatives Avoidance
-- • Problem: To create a JSON feed of products and their sales, a developer might query
-- all products. Then, in a loop, query sales for each product and manually construct
-- JSON strings or objects in application code. Show how JSON AGG (possibly with
-- JSON_BUILD_OBJECT) can produce this more directly.
SELECT 
	p.productId, 
	JSONB_AGG(
		JSON_BUILD_OBJECT(
			'id', s.saleId, 
			'product', s.productId, 
			'employee', s.employeeId, 
			'date', s.saleDate, 
			'quantity', s.quantity, 
			'region', s.regionId, 
			'notes', s.notes
		)
	) FILTER(WHERE s.saleId IS NOT NULL) jsonSales
FROM data_transformation_and_aggregation.products p
NATURAL JOIN data_transformation_and_aggregation.sales s
GROUP BY p.productId;


-- 1.4 PERCENTILE_CONT(fraction) WITHIN GROUP (ORDER BY sort expression)

-- 1.4.1 Practice Meaning, Values, Relations, Advantages
-- • Problem: For each product category, calculate the 25th, 50th (median), and 75th
-- percentile of listPrice. Ignore products without a category.
SELECT
	category,
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY listPrice) percent25,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY listPrice) percent50,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY listPrice) percent75
FROM data_transformation_and_aggregation.products
GROUP BY category;

-- 1.4.2 Practice Disadvantages
-- • Problem: If PERCENTILE_CONT is used on a column with very few distinct values
-- within a group (e.g., performance scores that are all integers 1, 2, 3, 4, 5), how
-- does interpolation affect the result, and why might PERCENTILE_DISC sometimes be
-- preferred in such cases?
-- Answer: when there exists very few elements in the variable is common to have highly
-- biased interpolation if the range is big contrasted with the desired detail. In such
-- scenarios PERCENTILE_DISC selects the closest value to the interpolated percentile

-- 1.4.3 Practice Inefficient Alternatives Avoidance
-- • Problem: To find the median salary for each department, an analyst exports all
-- employee salaries by department to a spreadsheet, then sorts and manually finds
-- or uses a spreadsheet function for the median for each department. Show how
-- PERCENTILE_CONT simplifies this.
SELECT departmentId, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY salary) medianSalary
FROM data_transformation_and_aggregation.employees
GROUP BY departmentId;


-- 1.5 CORR(Y, X)

-- 1.5.1 Practice Meaning, Values, Relations, Advantages
-- • Problem: Calculate the correlation coefficient between the quantity of products
-- sold and their listPrice from the Sales and Products tables. Do this overall,
-- not per group.
SELECT CORR(p.listprice, s.quantity)
FROM data_transformation_and_aggregation.products p
NATURAL JOIN data_transformation_and_aggregation.sales s;

-- 1.5.2 Practice Disadvantages
-- • Problem: CORR(Y,X) indicates the strength and direction of a linear relationship.
-- What does a correlation coefficient near 0 imply, and what kind of strong relation-
-- ship might it fail to capture?
-- Answer: a correlation coefficient near to 0 imply 0 linear relationship, but such
-- index is biased if elements are categorized and thus probably related but within
-- specific categories. Because the measured relationship is linear, not linear rela-
-- tionships must be measured differently to get the correct number

-- 1.5.3 Practice Inefficient Alternatives Avoidance
-- • Problem: To determine if there’s a relationship between employee salary and
-- performanceScore, a user exports this data for all employees into a statistical
-- software package just to compute the Pearson correlation coefficient. Show the
-- direct SQL method.
SELECT CORR(salary, performanceScore) pearsonCorrelation
FROM data_transformation_and_aggregation.employees;


-- 1.6 REGR_SLOPE(Y, X)

-- 1.6.1 Practice Meaning, Values, Relations, Advantages
-- • Problem: For ’Electronics’ products, estimate how much the average quantity sold
-- changes for each one-dollar increase in listPrice. Use REGR SLOPE considering
-- quantity as Y (dependent) and listPrice as X (independent).
SELECT REGR_SLOPE(avgQuantitySold, listPrice) listPriceChangingAvgQuantitySold FROM (
	SELECT p.productId, AVG(s.quantity) avgQuantitySold, p.listprice
	FROM data_transformation_and_aggregation.sales s
	JOIN data_transformation_and_aggregation.products p 
	ON p.category = 'Electronics' AND s.productId = p.productId
	GROUP BY p.productId
) sq;

-- 1.6.2 Practice Disadvantages
-- • Problem: REGR_SLOPE(Y,X) gives the slope of a best-fit linear line. What important
-- information about the relationship does it *not* provide, which would be crucial
-- for judging the reliability of this slope? (Hint: think about goodness of fit).
-- Answer: the slope just creates linearly the the most appropriate relationship between
-- variables but not necessarily in a signficant way because data could be sparsed along
-- the 2D space, metrics like R2 and the significativity measures the quality of such
-- linear relation, not directly provided by REGR_SLOPE(Y, X). Besides, a model linearly
-- structured also have information regarding to the intercept of the line in 0, prone to
-- have measures about significativity with p-values, to be computed with the available
-- mathematical and statistical functions in postgresql

-- 1.6.3 Practice Inefficient Alternatives Avoidance
-- • Problem: A manager wants to quickly see if higher employee salaries in the ’Sales’
-- department are generally associated with higher performance scores by looking at
-- the trend. They export salary and performance scores to Excel to plot them and
-- add a linear trendline to see its slope. Show how REGR_SLOPE can provide this slope
-- directly.
SELECT REGR_SLOPE(e.performanceScore, e.salary) salariesNotPerforming 
FROM data_transformation_and_aggregation.departments d
JOIN data_transformation_and_aggregation.employees e 
	ON d.departmentName = 'Sales' AND d.departmentId = e.departmentId;
-- The salaray does not mean performance score