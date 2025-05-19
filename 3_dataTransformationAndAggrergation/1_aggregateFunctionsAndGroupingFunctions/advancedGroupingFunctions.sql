		-- 2 Category: Advanced Grouping Operations


-- 	2.1 GROUPING SETS ((set1), (set2), ...)

-- 		2.1.1 Practice Meaning, Values, Relations, Advantages
-- • Problem: Calculate the total sales quantity and sum of listPrice (as totalListPriceValue,
-- sum of p.listPrice * s.quantity) with the following groupings in a single query:
-- 1. By (productCategory, regionName)
-- 2. By (productCategory) only
-- 3. By (regionName) only
-- 4. Grand total ()
-- Use COALESCE to label aggregated dimensions appropriately (e.g., ’All Categories’).
SELECT
	CASE GROUPING(category) WHEN 0 THEN category ELSE 'Grand categorical total' END byCategory,
	CASE GROUPING(regionName) WHEN 0 THEN regionName ELSE 'Grand regional total' END byRegionName,
	GROUPING(category, regionName) totalGrouping,
	GROUPING(category) categorizedGrouping,
	GROUPING(regionName) regionizedGroupin,
	SUM(listPrice * quantity) totalListPrice
FROM data_transformation_and_aggregation.sales d
NATURAL JOIN data_transformation_and_aggregation.products p
NATURAL JOIN data_transformation_and_aggregation.regions r
GROUP BY GROUPING SETS((category, regionName), (category), (regionName))
ORDER BY GROUPING(category, regionName), GROUPING(category), GROUPING(regionName);

-- 		2.1.2 Practice Disadvantages
-- • Problem: If you define many complex grouping sets, e.g., GROUPING SETS ((a,b,c),
-- (a,d,e), (b,f), (c,g,h,i), ...), what are the disadvantages in terms of query
-- complexity and potential for user error in defining the sets?
-- A cube grouping set with too much columns to be observed by a human is un meaningful
-- but could be useful within a computational process like for graph operations where
-- is necessary such aggregation despite it could be complex, consuming high memory and computing
-- there are cases when more power can be used if the information is valuable for a bigger
-- process

-- 		2.1.3 Practice Inefficient Alternatives Avoidance
-- • Problem: A user needs total sales quantity by (EXTRACT(YEAR FROM saleDate),
-- category) and also by (EXTRACT(YEAR FROM saleDate)) only. They write two
-- separate queries with GROUP BY and UNION ALL them. Show how GROUPING SETS
-- provides a more efficient and concise solution.
SELECT 
	CASE GROUPING(EXTRACT(YEAR FROM saleDate), category)
		WHEN 0
			THEN CONCAT(EXTRACT(YEAR FROM saleDate)::TEXT, ': ', category)
		ELSE CONCAT('Grand total for: ', EXTRACT(YEAR FROM saleDate)::TEXT)
	END combinedCase,
	SUM(quantity) totalSales
FROM data_transformation_and_aggregation.products
NATURAL JOIN data_transformation_and_aggregation.sales
GROUP BY GROUPING SETS(
	(EXTRACT(YEAR FROM saleDate), category), 
	(EXTRACT(YEAR FROM saleDate)))
ORDER BY GROUPING(EXTRACT(YEAR FROM saleDate), category), GROUPING(EXTRACT(YEAR FROM saleDate));


-- 	2.2 ROLLUP (col1, col2, ...)

-- 		2.2.1 Practice Meaning, Values, Relations, Advantages
-- • Problem: Generate a hierarchical summary of total hoursWorked on projects. The
-- hierarchy is: departmentName → projectName. Include subtotals for each depart-
-- ment and a grand total.
SELECT 
	CASE GROUPING(departmentName)
		WHEN 0 THEN departmentName
		ELSE 'Grand departmental total'
	END departmentalCat,
	CASE GROUPING(projectName)
		WHEN 0 THEN projectName
		ELSE 'Grand projected total'
	END projectedCat,
	SUM(hoursWorked) hierarchizedWorkingHours
FROM data_transformation_and_aggregation.projects
NATURAL JOIN data_transformation_and_aggregation.departments
NATURAL JOIN data_transformation_and_aggregation.employeeProjects
GROUP BY ROLLUP(departmentName, projectName);

-- 		2.2.2 Practice Disadvantages
-- • Problem: ROLLUP(country, state, city) generates subtotals for (country, state,
-- city), (country, state), (country), and (). What if you also need a subtotal
-- for (country, city) irrespective of state, or just (city) total? Can ROLLUP do
-- this directly, and what’s the implication?
-- Because ROLLUP() is a special hierarchized of first degree case of GROUPING_SETS()
-- it will never do anything different that combinations of not adjacent pairs in the
-- list (country, state, city), thus to get the additional combination (country, city)
-- you need GROUPING_SETS((country, state, city), (country, city), (country, state), (country), ()) 

-- 		2.2.3 Practice Inefficient Alternatives Avoidance
-- • Problem: A manager needs a sales report showing total quantity sold, with subto-
-- tals for each regionName, then further subtotals for each productCategory within
-- that region, and finally by productName within category/region. This is a clear hi-
-- erarchy. An analyst unfamiliar with ROLLUP might try to construct this with several
-- UNION ALL statements. Show the ROLLUP simplification.
SELECT regionName, category, productName, SUM(quantity)
FROM data_transformation_and_aggregation.sales
NATURAL JOIN data_transformation_and_aggregation.regions
NATURAL JOIN data_transformation_and_aggregation.products
GROUP BY ROLLUP(regionName, category, productName)
ORDER BY regionName, category, productName;


-- 	2.3 CUBE (col1, col2, ...)

-- 		2.3.1 Practice Meaning, Values, Relations, Advantages
-- • Problem: Create a cross-tabular summary of total sales quantity (SUM(s.quantity))
-- for all possible combinations of EXTRACT(YEAR FROM saleDate) and productCategory.
-- This should include subtotals for each year across all categories, for each category
-- across all years, and a grand total.
SELECT 
	CASE GROUPING(EXTRACT(YEAR FROM saleDate))
		WHEN 0 THEN EXTRACT(YEAR FROM saleDate)::TEXT
		ELSE 'Grand total for year'
	END cubedYear,
	CASE GROUPING(category)
		WHEN 0 THEN category
		ELSE 'Grand total for category'
	END cubedCategory,
	GROUPING(EXTRACT(YEAR FROM saleDate), category) totalCubed,
	GROUPING(EXTRACT(YEAR FROM saleDate)) cubedYear,
	GROUPING(category) cubedCategory,
	SUM(s.quantity) totalSoldQuantity
FROM data_transformation_and_aggregation.sales s
NATURAL JOIN data_transformation_and_aggregation.products p
GROUP BY CUBE(EXTRACT(YEAR FROM saleDate), category)
ORDER BY GROUPING(EXTRACT(YEAR FROM saleDate)) DESC, GROUPING(category) DESC;

-- 		2.3.2 Practice Disadvantages
-- • Problem: If CUBE(colA, colB, colC, colD) is used, it generates 24 = 16 different
-- grouping sets. What is the primary disadvantage if many of these detailed cross-
-- totals are not actually needed by the user?
-- It's like verbosity, or chunks of data presented in the screen rather than meaningful
-- and ease to read indexes of meaningful knowledge for specific objectives. THe power
-- of machines lies in processing lots of data under well designed concepts by humans
-- to reduce the data for humans

-- 		2.3.3 Practice Inefficient Alternatives Avoidance
-- • Problem: A user wants to explore sales data by looking at total quantities broken
-- down by (regionName, category), then by regionName alone, then by category
-- alone, and also the grand total. Without CUBE (or GROUPING SETS), they might run
-- four separate queries. Show how CUBE provides all these in one go.
SELECT 
	SUM(quantity),
	CASE GROUPING(regionName)
		WHEN 0 THEN regionName
		ELSE 'Grand total for region'
	END cubedRegion,
	CASE GROUPING(category)
		WHEN 0 THEN category
		ELSE 'Grand total for category'
	END cubedCategory
FROM data_transformation_and_aggregation.sales
NATURAL JOIN data_transformation_and_aggregation.regions
NATURAL JOIN data_transformation_and_aggregation.products
GROUP BY CUBE(regionName, category)
ORDER BY regionName, category;


