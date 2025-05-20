		-- 2 JSON and Array Functions (jsonb extract path text,
		-- jsonb array elements, jsonb build object, array append,
		-- array length)
		
-- Note: The dataset uses JSONB for JSON columns, so jsonb prefixed functions are gen-
-- erally applicable.


-- 	2.1 Meaning, values, relations (with previous concepts), advantages

-- 		JAF.1.1 Extracting Specific Log Information
-- Problem: From the SystemLogs table, extract the clientIp and userId for all
-- ’INFO’ level logs from ’AuthService’. The userId is nested within userContext in
-- logDetails. If userId is not present, display NULL.
-- Concept Focus: jsonb extract path text (or ->> operator) for pulling specific
-- values from JSON. Advantage: Direct access to nested JSON data without complex
-- parsing. Relation: WHERE clause for filtering.
-- SELECT 
-- 	logdetails ->> 'userId' userId, 
-- 	logdetails ->> 'clientIp' clientIp
-- FROM data_transformation_and_aggregation.systemlogs 
-- WHERE loglevel = 'INFO';

-- 		JAF.1.2 Expanding Performance Review Details
-- Problem: For each employee who has performance reviews, list each review on a
-- separate row, showing the employee’s name, the review year, and rating.
-- Concept Focus: jsonb array elements to transform a JSON array within a field
-- into multiple rows. Advantage: Normalizes JSON array data for relational processing.
-- Relation: JOIN (implicit with jsonb array elements).
-- SELECT employeeName, review -> 'year' reviewyear, review -> 'rating' rating
-- FROM data_transformation_and_aggregation.employees e, jsonb_array_elements(e.performanceReviews) AS review(performance)
-- WHERE performanceReviews IS NOT NULL 
-- 	AND jsonb_typeof(e.performanceReviews) = 'array' 
-- 	AND jsonb_array_length(e.performanceReviews) <> 0;

-- 		JAF.1.3 Constructing a Simplified Project Overview JSON
-- Problem: For each project in ProjectAssignments, create a new JSONB object
-- containing the projectName and a list of employeeIds assigned to it.
-- Concept Focus: jsonb build object to create JSON objects dynamically, ARRAY AGG
-- or jsonb agg (previous concept) to gather employee IDs. Advantage: Creating structured
-- JSON output from relational data. Relation: GROUP BY for aggregation.
-- SELECT 
-- 	JSONB_BUILD_OBJECT('projectName', projectName, 'employeesId', employeesId) projectedEmployees
-- FROM (
-- 	SELECT projectId, projectName, JSONB_BUILD_OBJECT('employeesIds', JSONB_AGG(employeeId)) employeesId
-- 	FROM data_transformation_and_aggregation.ProjectAssignments
-- 	GROUP BY projectId, projectName
-- ) sq;

-- 		JAF.1.4 Updating Event Resources and Checking Count
-- Problem: For the ’Tech Conference 2024’ event, add ’WiFi Access Point’ to its
-- bookedResources. Then, display the event name and the new total number of booked
-- resources for this event. (Simulate the update in a SELECT statement or describe the
-- UPDATE and then SELECT).
-- Concept Focus: array append to add an element to an array, array length to get
-- the size of an array. Advantage: Simple and efficient array manipulation.
-- SELECT 
-- 	expectedAttendees,
-- 	eventId, eventName, 
-- 	eventCategory, eventStartDate, eventEndDate, 
-- 	array_append(COALESCE(bookedresources, '{}'), 'WiFi Access Point') updatedBookedResources,
-- 	cardinality(array_append(COALESCE(bookedresources, '{}'), 'WiFi Access Point')) totalUpdatedBookedResources
-- FROM data_transformation_and_aggregation.EventCalendar
-- WHERE eventName = 'Tech Conference 2024';


-- 	2.2 Disadvantages of all its technical concepts

-- 		JAF.2.1 Performance of Complex JSON Queries vs. Normalized Data
-- Problem: Suppose the logDetails in SystemLogs often contains deeply nested
-- structures (e.g., 5-10 levels deep). Explain the disadvantage of frequently querying very
-- specific, deeply nested values from such JSONB columns compared to having those spe-
-- cific values in their own indexed relational columns.
-- Concept Focus: Disadvantage of JSON functions - potential performance overhead
-- for deeply nested or complex queries if not properly indexed (GIN/GiST) or if compared
-- to highly optimized relational access.
-- Answer: when arrays are not indexed, what postgresql do is linear search up to find
-- the desired objects with the necessary properties and features, very unoptimal. Comparing
-- the reduced scope of array indexes with the more developed, simpler (with the cost of some
-- memory usage) and understandable indexes for relational tables we need harder queries to
-- get the same results of a query under indexed relational tables of normalized data. If 
-- json data is highly nested the time of operation could be agumented exponentially, linearly.
-- or logarithmically for each nested level

-- 		JAF.2.2 Array Overuse and Normalization
-- Problem: The Employees table has a skills array. If these skills also had attributes
-- (e.g., ’skillLevel’, ’yearsOfExperienceWithSkill’), explain the disadvantage of trying to
-- store this richer skill information within the single TEXT[] array (e.g., by encoding it like
-- ’Python:Expert:5yrs’) versus creating a separate EmployeeSkills table.
-- Concept Focus: Disadvantage of arrays - can lead to denormalization and make
-- querying/updating complex attributes of array elements difficult.
-- Answer: the necessary query to make analysis and send data will be not only hard to be fast
-- but also harder because such string must be to partitioned even more using substrings to be
-- aggregated and then filtered and reduced, a real problem that should be solved in 5 minutes
-- with normalized data for categorical information


-- 	2.3 Cases where people lose advantages due to inefficient solutions

-- 		JAF.3.1 Inefficiently Querying JSON Data with String Matching
-- Problem: From SystemLogs, find all logs where the logDetails JSONB contains a
-- key orderId with a value of 123. Show an inefficient way to do this by casting logDetails
-- to text and using LIKE. Then, provide the efficient solution using JSONB operators.
-- Highlight the advantages of the JSONB-specific approach.
-- Concept Focus: Contrasting inefficient string matching on stringified JSON with
-- efficient JSONB operators.
-- EXPLAIN ANALYZE				-- Inefficient: needs for this case twice as the efficient way
-- SELECT logId, logDetails
-- FROM data_transformation_and_aggregation.SystemLogs
-- WHERE logDetails::TEXT LIKE '%"orderId": 123%';
-- EXPLAIN ANALYZE				-- Efficient
-- SELECT logId, logDetails
-- FROM data_transformation_and_aggregation.SystemLogs
-- WHERE (logDetails ->> 'orderId')::NUMERIC = 123;

-- 		JAF.3.2 Storing Multiple Flags as a Comma-Separated String Instead of JSON/Array
-- Problem: A common inefficient practice is storing multiple boolean flags or cat-
-- egorical tags as a single comma-separated string in a VARCHAR column (e.g., flags
-- VARCHAR(255) with value ’active,premium,verified’). Suppose we have such a col-
-- umn named userTags in a hypothetical Users table. Show how one might inefficiently
-- query for users who have the ’premium’ tag using LIKE. Then, describe how using a
-- TEXT[] (array) or a JSONB (e.g., {"active": true, "premium": true, "verified":
-- true}) would be more advantageous for querying and management.
-- Concept Focus: Contrasting comma-separated strings with arrays or JSONB for
-- storing multiple discrete values/flags.
-- Table Definition with Array
-- DROP TABLE IF EXISTS data_transformation_and_aggregation.Users; -- Clean up previous if exists
-- CREATE TABLE data_transformation_and_aggregation.Users (
--     userId INT PRIMARY KEY,
--     userTags TEXT[],
-- 	   userText TEXT
-- );
-- Inserting Data with Array Syntax
-- INSERT INTO data_transformation_and_aggregation.Users (userId, userTags, userText) VALUES
--     (1, '{"active", "premium", "verified"}', 'active,premium,verified'),
--     (2, '{"active", "verified"}', 'active,verified'),
--     (3, '{"premium"}', 'premium'),
--     (4, '{"superpremium", "active"}', 'superpremium,active'),
--     (5, '{"premium access", "verified"}', 'premium access,verified');
-- SELECT * FROM data_transformation_and_aggregation.Users WHERE userText LIKE '%premium%'; -- INEFFICIENT
-- SELECT * FROM data_transformation_and_aggregation.Users WHERE userTags @> ARRAY['premium']; -- EFFCICIENT
-- SELECT * FROM data_transformation_and_aggregation.Users WHERE 'premium' = ANY(userTags);


-- 	2.4 Hardcore problem combining previous concepts
-- 		JAF.4.1 Advanced Customer Subscription Feature Analysis and Aggregation
-- Problem: Generate a JSONB report for each customerName from ServiceSubscriptions.
-- The report should:
-- 1. Be a single JSONB object per customer.
-- 2. Top-level keys: customerName, totalMonthlyFee, activeServicesCount, serviceDetails
-- (a JSON array).
-- 3. totalMonthlyFee: Sum of monthlyFee for all *currently active* subscriptions (endDate
-- IS NULL or endDate > CURRENT DATE).
-- 4. activeServicesCount: Count of *currently active* subscriptions.
-- 5. serviceDetails: A JSON array, where each element is a JSONB object represent-
-- ing one of their subscriptions (both active and past). Each object should contain:
-- • serviceType
-- • status: ’Active’ or ’Expired’ (based on endDate vs CURRENT DATE).
-- • durationMonths: Number of full months the subscription lasted or has been
-- active. If endDate is NULL, calculate up to CURRENT DATE.
WITH CustomerServices AS (
	SELECT 
		customerName,
		monthlyFee, 
		features,
		serviceType,
		CASE WHEN endDate > CURRENT_TIMESTAMP OR endDate IS NULL THEN 'Active' ELSE 'Expired' END status,
		CASE 
			WHEN endDate IS NULL THEN EXTRACT(MONTH FROM AGE(CURRENT_TIMESTAMP, startDate))
			ELSE EXTRACT(MONTH FROM AGE(endDate, startDate))
		END durationMonths,
		COALESCE(features #> '{addons}', '[]'::jsonb) addons,
		COALESCE((features ->> 'prioritySupport')::bool, false) priority
	FROM data_transformation_and_aggregation.ServiceSubscriptions
), PrioritizedCustomers AS (
	SELECT customerName, priority
	FROM CustomerServices
	WHERE priority = true
)

SELECT 
	customerName, 
	JSON_BUILD_OBJECT(
		'customerName', customerName,
		'totalMonthlyFee', SUM(monthlyFee) FILTER(WHERE status = 'Active'),
		'activeServicesCount', COUNT(*) FILTER(WHERE status = 'Active'),
		'serviceDetails', JSON_AGG(
			JSON_BUILD_OBJECT(
				'serviceType', serviceType,
				'status', status,
				'durantionMonths', durationMonths,
				'featureList', addons,
				'hasPrioritySupport', priority
			)
		)
	)
FROM CustomerServices NATURAL JOIN PrioritizedCustomers
GROUP BY customerName
ORDER BY SUM(monthlyFee) FILTER(WHERE status = 'Active') DESC;
-- • featureList: A JSON array of strings derived from the addons array within
-- the features JSONB column. If addons doesn’t exist or is not an array, this
-- should be an empty JSON array [].
-- • hasPrioritySupport: Boolean, extracted from features ->> ’prioritySupport’.
-- Default to false if not present.
-- Filter results to include only customers who have at least one subscription with ’priority-
-- Support’ set to true in their features. Order customers by their totalMonthlyFee (for
-- active subscriptions) in descending order.
-- Previous concepts to use: jsonb build object, jsonb array elements text (for
-- processing features -> ’addons’), jsonb extract path text (or ->, ->>), jsonb agg,
-- COALESCE, CASE statements, SUM, COUNT, Date functions (AGE, EXTRACT, CURRENT DATE),
-- CTEs, Joins (if needed, though most can be done with aggregations and subqueries on
-- ServiceSubscriptions), FILTER clause in aggregation.
