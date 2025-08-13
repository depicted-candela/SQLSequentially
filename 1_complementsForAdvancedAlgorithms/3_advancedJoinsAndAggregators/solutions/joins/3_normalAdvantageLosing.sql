		-- 1.3 (iii) Practice entirely cases where people in general does not use these approaches losing their advantages,
-- relations and values because of the easier, basic, common or easily understandable but highly inefficient solutions

-- 		Exercise 1.3.1: (CROSS JOIN - Inefficient Alternative)
-- Problem: A junior developer needs to generate all possible pairings of 3 specific
-- employees (’Alice Smith’, ’Bob Johnson’, ’Charlie Williams’) with all available shift
-- schedules. Instead of using CROSS JOIN, they write three separate queries and plan
-- to combine the results manually in their application or using UNION ALL. Show this
-- inefficient approach and then the efficient CROSS JOIN solution.

-- Explicitly, using UNION ALL :
-- More explicitly, using UNION ALL :
SELECT e.first_name, e.last_name, ss.shift_name
FROM advanced_joins_aggregators.employees e, advanced_joins_aggregators.shift_schedules ss
WHERE e.first_name = 'Alice' AND e.last_name = 'Smith'
UNION ALL
SELECT e.first_name, e.last_name, ss.shift_name
FROM advanced_joins_aggregators.employees e, advanced_joins_aggregators.shift_schedules ss
WHERE e.first_name = 'Bob' AND e.last_name = 'Johnson'
UNION ALL
SELECT e.first_name, e.last_name, ss.shift_name
FROM advanced_joins_aggregators.employees e, advanced_joins_aggregators.shift_schedules ss
WHERE e.first_name = 'Charlie' AND e.last_name = 'Williams';

SELECT * 										-- Highly cleanear but because the filtering is made before to 
FROM advanced_joins_aggregators.employees e		-- the cross join, all the cartesian product must be done => could be
CROSS JOIN advanced_joins_aggregators.shift_schedules ss	-- less fast
WHERE
	(e.first_name = 'Alice' AND e.last_name = 'Smith') OR
	(e.first_name = 'Bob' AND e.last_name = 'Johnson') OR
	(e.first_name = 'Charlie' AND e.last_name = 'Williams')
ORDER BY
e.last_name, e.first_name, ss.shift_name;

-- 		Exercise 1.3.2: (NATURAL JOIN - Avoiding for ”Safety” by being overly verbose)
-- Problem: A developer needs to join product info natural and product sales natural.
-- They know both tables have product id and common code and they intend to join
-- on both. They avoid NATURAL JOIN due to general warnings about its use and in-
-- stead write a verbose INNER JOIN ON clause. Show this verbose solution and then
-- the concise NATURAL JOIN (acknowledging that in this *specific* case, if the intent
-- is to join on *all* common columns, NATURAL JOIN is concise, though still risky for
-- future changes).
SELECT							-- Highly verbose when tables has the same name
	pi.product_id,
	pi.common_code,
	pi.description,
	ps.sale_date,
	ps.quantity_sold
FROM advanced_joins_aggregators.product_info_natural pi
INNER JOIN advanced_joins_aggregators.product_sales_natural ps
	ON pi.product_id = ps.product_id AND pi.common_code = ps.common_code;
SELECT							-- Less verbosity with less flexibility
	pi.product_id,
	pi.common_code,
	pi.description,
	ps.sale_date,
	ps.quantity_sold
FROM advanced_joins_aggregators.product_info_natural pi
NATURAL JOIN advanced_joins_aggregators.product_sales_natural ps;

-- 		Exercise 1.3.3: (SELF JOIN - Inefficient Alternative: Multiple Queries)
-- Problem: To get each employee’s name and their manager’s name, a developer
-- decides to first fetch all employees. Then, for each employee with a manager id, they
-- run a separate query to find that manager’s name. Describe this highly inefficient
-- N+1 query approach and contrast it with the efficient SELF JOIN.

-- Getting first every employee in a list to iterate along it to get their manager's name means N (number of employees) jobs
-- and then select from the same table the employee coinciding with the manager's id duplicate the original selection of all
-- employee's id with another selection: N + 1. This can be done copying and pasting the same sentence several times as is
-- necessary or iteratively with procedural programming, but why if you can make a SELF JOIN?

SELECT  e1.first_name || ' ' || e1.last_name full_name, 		-- Simpler and highly less verbose with self join 
	CASE 
		WHEN e2.first_name || ' ' || e2.last_name = e1.first_name || ' ' || e1.last_name THEN NULL 
		ELSE e2.first_name || ' ' || e2.last_name
	END
FROM advanced_joins_aggregators.employees e1
LEFT JOIN advanced_joins_aggregators.employees e2
ON e2.employee_id IS NOT DISTINCT FROM e1.manager_id;

-- 		Exercise 1.3.4: (USING clause - Inefficient Alternative: Always typing full ON clause)
-- Problem: A developer needs to join employees and departments on department id.
-- Both tables have this column name. Instead of the concise USING(department id),
-- they always write the full ON e.department id = d.department id. While not
-- performance-inefficient, discuss how this makes the query longer and potentially
-- misses a small readability/maintenance advantage of USING.
SELECT e.first_name, e.last_name, d.department_name
FROM advanced_joins_aggregators.employees e
INNER JOIN advanced_joins_aggregators.departments d
	ON e.department_id = d.department_id; 	-- This line adds the verbosity

SELECT e.first_name, e.last_name, d.department_name
FROM advanced_joins_aggregators.employees e
JOIN advanced_joins_aggregators.departments d
	USING(department_id);					-- This line reduces verbosity