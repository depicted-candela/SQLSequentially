		-- 1 Set Returning Functions (generate series, unnest)


-- 	1.1 Meaning, values, relations (with previous concepts), advantages

-- 		SRF.1.1 Monthly Active Subscription Report
-- Problem: For each serviceType in ServiceSubscriptions, generate a list of all
-- months (as the first day of the month) between January 2023 and December 2023. For
-- each of these generated months, count how many subscriptions of that serviceType were
-- active during that month. A subscription is active if the generated month falls within its
-- startDate and endDate (or if endDate is NULL, it's considered active indefinitely past
-- its startDate). Display the serviceType, the generated month, and the count of active
-- subscriptions.
-- Concept Focus: Using generate series to create a date series for reporting. Ad-
-- vantage: easily create time dimensions for temporal analysis. Relation: JOIN with existing
-- tables, GROUP BY for aggregation, date functions for comparison.
SELECT months, servicetype, COUNT(*) activeSubscriptions
FROM generate_series(TO_DATE('2023-01', 'YYYY-MM'), TO_DATE('2023-12', 'YYYY-MM'), INTERVAL '1 month') months,
data_transformation_and_aggregation.ServiceSubscriptions s
WHERE months BETWEEN s.startDate AND COALESCE(s.endDate, 'infinity')
GROUP BY months, servicetype;

-- 		SRF.1.2 Employee Skills Breakdown
-- Problem: List each employee and each of their individual skills on a separate row.
-- Also, show the employee's department. Exclude employees who have no listed skills.
-- Concept Focus: Using unnest to normalize array data into rows. Advantage: en-
-- ables relational operations (joins, filters) on individual array elements. Relation: JOIN
-- (implicitly with the same table via unnesting), SELECT specific columns.
SELECT employeeName, department, UNNEST(skills) skills
FROM data_transformation_and_aggregation.employees
WHERE skills IS NOT NULL;


-- 	1.2 Disadvantages of all its technical concepts

-- 		SRF.2.1 Potential Performance Issue with generate series
-- Problem: Imagine you need to generate a record for every second in a full year for
-- sensor data simulation. Write a query that *would* generate this series (but limit it to
-- 10 for safety in this exercise). Explain why running this for a full year without careful
-- planning (e.g., for direct insertion or large-scale processing) could be a disadvantage.
-- Concept Focus: Disadvantage of generate series - potential for creating exces-
-- sively large datasets.
-- Answer:
SELECT * FROM generate_series(CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 year', INTERVAL '1 seconds');
-- The query needs 2.716 seconds to create a list of 3153601 items with intervals of 10 seconds
------------------ 23.25 -------------------------- 31536001 ----------------------- 1 second
-- NOw imagine that not only is a single variable that needs these time series to be filled.
-- A part of the planning must be an indexation to the table using dates perhaps with trees
-- leveraging the hierarchical nature of timestamps as a common coloumn to be related to mul-
-- tiple columns or tables

-- 		SRF.2.2 Row Explosion with unnest
-- Problem: Consider the Employees table. If an employee had 100 skills, and you
-- unnest their skills and then JOIN this with a ProjectAssignments table where they are
-- on 10 projects, how many rows could this potentially generate for this single employee in
-- the combined result before any aggregation? Explain the disadvantage.
-- Concept Focus: Disadvantage of unnest - row explosion leading to performance
-- degradation if not handled correctly.
-- Answer: the core problem is to expand the unnest without a reason, if you can join before
-- to that both tables and then expand the skills to be joined with a Skills table the unnest
-- will be useful saving some memory storing keys from the skills table in arrays, but since
-- arrays in itself can be indexed and related using containing operators @>, such unnesting
-- would be unnecessary


-- 	1.3 Cases where people lose advantages due to inefficient solutions

-- 		SRF.3.1 Inefficiently Generating Date Sequences
-- Problem: A common task is to get a list of dates for a specific month. Show an
-- inefficient way to generate all days in January 2024 using a recursive CTE (a more complex
-- approach than generate series for this simple task). Then, provide the efficient solution
-- using generate series. Highlight why the generate series approach is advantageous.
-- Concept Focus: Contrasting generate series with a more verbose/complex recur-
-- sive CTE for simple series generation.
WITH RECURSIVE AllJan2024Days AS (		-- Complex and verbose alternative
	SELECT TO_DATE('2024-01-01', 'YYYY-MM-DD')::TIMESTAMP AS date
	UNION ALL
	SELECT (date + INTERVAL '1 day') AS date FROM AllJan2024Days a
	WHERE a.date + INTERVAL '1 day' < TO_DATE('2024-02-01', 'YYYY-MM-DD')
)
SELECT * FROM AllJan2024Days;
-- Efficient, simpler, cleaner and less verbose solution
SELECT * FROM generate_series(TO_DATE('2024-01-01', 'YYYY-MM-DD'), TO_DATE('2024-01-31', 'YYYY-MM-DD'), INTERVAL '1 day');

-- 		SRF.3.2 Inefficiently Handling Array Elements
-- Problem: An employee Alice Wonderland (employeeId 1) has skills stored in an
-- array. You want to find if she has the skill 'Python'. Show an inefficient way to check
-- this (e.g., by converting the array to a string and using LIKE). Then, show the efficient
-- way using array operators or unnest with a WHERE clause. Highlight the advantages of
-- the efficient SQL-native array approach.
-- Concept Focus: Contrasting inefficient string manipulation for array searching with
-- SQL-native array operations or unnest.
SELECT employeeName, skills					-- Inefficient alternative
FROM data_transformation_and_aggregation.Employees
WHERE employeeId = 1 AND array_to_string(skills, ', ') LIKE '%Python%';
Efficient solutions
SELECT employeeName, skills					-- With array operators
FROM data_transformation_and_aggregation.Employees
WHERE employeeId = 1 AND 'Python' = ANY(skills);
SELECT employeeName, skills					-- With array containment
FROM data_transformation_and_aggregation.Employees
WHERE employeeId = 1 AND ARRAY['Python'] <@ skills;


-- 	1.4 Hardcore problem combining previous concepts

-- 		SRF.4.1 Comprehensive Project Health and Skill Utilization Report
-- Problem: Generate a report for the first 6 months of 2023 (January to June). The
-- report should show:
-- 1. reportMonth (first day of each month).
-- 2. projectName.
-- 3. totalAssignedHours for that project in that month (sum of assignmentHours for
-- employees whose assignment *could* be active in that month – assume assignmentHours
-- are per month if the project is active). For simplicity, consider a project assignment
-- active if its employeeId is on a project.
-- 4. criticalProjectFlag (boolean, true if assignmentData ->> 'critical' is true
-- for *any* assignment on that project).
-- 5. listOfDistinctSkillsUtilized: A comma-separated string of all distinct skills
-- possessed by employees assigned to that project. Only include skills of employees
-- who were hired *before or during* the reportMonth.
-- 6. averageYearsOfService: Average years of service (from hireDate to reportMonth)
-- of employees assigned to that project and hired before or during the reportMonth.
-- Round to 2 decimal places.
WITH First2023Semester AS (
	SELECT * 
	FROM generate_series(TO_DATE('2023-01-01', 'YYYY-MM-DD'), TO_DATE('2023-06-01', 'YYYY-MM-DD'), INTERVAL '1 month') months
), ProjectedEmployees AS (
	SELECT projectName, projectId, hireDate, assignmentHours
	FROM data_transformation_and_aggregation.projectAssignments
	NATURAL JOIN data_transformation_and_aggregation.employees
), TabledSkillsForProjects AS (
	SELECT projectId, UNNEST(skills) tabledSkills
	FROM data_transformation_and_aggregation.projectAssignments
	NATURAL JOIN data_transformation_and_aggregation.employees
	WHERE skills @> ARRAY['Python']
), CardinalSkilledProjects AS (
	SELECT projectId, STRING_AGG(DISTINCT tabledSkills, ', ') uniqueSkills 
	FROM TabledSkillsForProjects sq GROUP BY projectId
)

SELECT 
	months, 
	projectName, 
	SUM(assignmentHours) totalAssignedHours, 
	COALESCE((
		SELECT (assignmentData ->> 'critical')::BOOLEAN
		FROM data_transformation_and_aggregation.projectassignments p 
		WHERE pe.projectId = p.projectId AND (assignmentData ->> 'critical')::BOOLEAN
		LIMIT 1
	), false) criticalProjectFlag,
	STRING_AGG(DISTINCT tabledSkills, ', ') uniqueSkills,
	ROUND(EXTRACT(EPOCH FROM AVG(fse.months - pe.hireDate)) / (365.25 * 24.0 * 60.0 * 60.0), 2) averageYearsOfService
FROM First2023Semester fse 
LEFT JOIN ProjectedEmployees pe 
	ON (fse.months::DATE, (fse.months + INTERVAL '1 month')::DATE) OVERLAPS (pe.hireDate::DATE, 'infinity')
JOIN TabledSkillsForProjects tsfp USING(projectId)
GROUP BY months, projectId, projectName
ORDER BY months, projectName;

-- Filter the report to include only projects that had at least one employee assigned who
-- possesses the skill 'Python'. Order the results by reportMonth and then by projectName.
-- Previous concepts to use: generate series, unnest, CTEs (basic or nested),
-- Joins (INNER, LEFT), Aggregations (SUM, AVG, STRING AGG), Date functions (DATE TRUNC,
-- EXTRACT or age calculation), String functions (CONCAT), Subqueries (possibly in
-- WHERE or SELECT), CASE statements, COALESCE.

