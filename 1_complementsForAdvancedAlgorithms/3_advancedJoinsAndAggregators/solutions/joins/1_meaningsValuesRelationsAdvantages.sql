		-- 3. Advanced Joins And Aggregators: Joins

-- 	1.1(i) Practice meanings, values, relations, advantages of all its technical concepts
		
-- 		Exercise 1.1.1: (CROSS JOIN - Meaning & Advantage)
-- Problem: The company wants to create a list of all possible pairings of employee
-- first names and available shift schedules to evaluate potential staffing options. Dis-
-- play the employee’s first name and the shift name for every combination.
SELECT e.first_name, s.schedule_id
FROM advanced_joins_aggregators.employees e
CROSS JOIN advanced_joins_aggregators.shift_schedules s;

-- 		Exercise 1.1.2: (NATURAL JOIN - Meaning & Advantage)
-- Problem: List all projects and their corresponding department names. The
-- projects table has a department id column, and the departments table also
-- has a department id column (which is its primary key). Use the most concise join
-- syntax available for this specific scenario where column names are identical and
-- represent the join key.
SELECT p.project_name, d.department_name 
FROM advanced_joins_aggregators.projects p
NATURAL JOIN advanced_joins_aggregators.departments d
ORDER BY p.project_name;

-- 		Exercise 1.1.3: (SELF JOIN - Meaning & Advantage)
-- Problem: Display a list of all employees and the first and last name of their
-- respective managers. Label the manager’s name columns as manager first name
-- and manager last name. Include employees who do not have a manager (their
-- manager’s name should appear as NULL).
SELECT 
 	e1.first_name || ' ' || e1.last_name full_name, 
 	CASE 
 		WHEN e2.first_name || ' ' || e2.last_name = e1.first_name || ' ' || e1.last_name THEN NULL 
 		ELSE e2.first_name || ' ' || e2.last_name
 	END
FROM advanced_joins_aggregators.employees e1
LEFT JOIN advanced_joins_aggregators.employees e2
ON e1.manager_id IS NULL OR e2.employee_id IS NOT DISTINCT FROM e1.manager_id;

-- 		Exercise 1.1.4: (USING clause - Meaning & Advantage)
-- Problem: List all employees (first name, last name) and the name of the depart-
-- ment they belong to. Use the USING clause for the join condition, as both employees
-- and departments tables share a department id column for this relationship.