		-- 1 Set Operations
		
-- 	1.1 Type (i): Meaning, values, relations, advantages

-- 		SO-1.1: Unified List of All Current and Potential Engineering Staff
-- Problem: The company wants a single, unique list of full names (firstName
-- lastName) of all current employees in the ’Engineering’ department and all
-- candidates who applied for an ’ENG LEAD’ or ’ENG JR’ position. The list
-- should be ordered by full name. This demonstrates UNION for combining differ-
-- ent sources and ensuring uniqueness.
SELECT firstname || ' ' || lastname fullname
FROM set_operations_subqueries.candidate_employees
WHERE appliedposition IN ('ENG LEAD', 'ENG JR')
UNION
SELECT firstname || ' ' || lastname fullname
FROM set_operations_subqueries.employees
WHERE departmentid IN (
	SELECT departmentid 
	FROM set_operations_subqueries.departments
	WHERE departmentname = 'Engineering'
)
ORDER BY fullname;

-- 		SO-1.2: Log of All Employee-Project Assignments and Recent Terminations
-- Problem: Create a comprehensive log showing employee IDs. Include all current
-- employee-project assignments (employeeId and projectId as ’activityIdentifier’)
-- and employee IDs of those who left the company in 2023 (employeeId and ter-
-- minationDate as ’activityIdentifier’). Include duplicates if an employee is on
-- multiple projects. This demonstrates UNION ALL where duplicates are mean-
-- ingful.
SELECT ep.employeeid
FROM set_operations_subqueries.employee_projects ep
UNION ALL
SELECT od.employeeid
FROM set_operations_subqueries.old_employees od;

-- 		SO-1.3: Employees in Sales and Marketing Departments
-- Problem: Identify employees (employeeId, firstName, lastName) who are part
-- of both the ’Sales’ department team for project ’Gamma Sales Drive’ and also
-- have skills recognized by the ’Marketing’ department (assume this means they
-- are in the marketing department currently). This demonstrates INTERSECT for
-- finding commonalities.
SELECT e.employeeid, e.firstname, e.lastname
FROM set_operations_subqueries.employees e
NATURAL JOIN set_operations_subqueries.departments d
WHERE d.departmentname = 'sales'
INTERSECT
SELECT e.employeeid, e.firstname, e.lastname
FROM set_operations_subqueries.employees e
NATURAL JOIN set_operations_subqueries.employee_projects ep
NATURAL JOIN set_operations_subqueries.projects p
WHERE p.projectname = 'Gamma Sales Drive'
INTERSECT
SELECT e.employeeid, e.firstname, e.lastname
FROM set_operations_subqueries.employees e
NATURAL JOIN set_operations_subqueries.departments d
WHERE d.departmentname = 'Marketing';

-- 		SO-1.4: Active Engineers Not Assigned to ’Omega Security Update’ Project
-- Problem: List the employeeId, firstName, and lastName of all current employees
-- in the ’Engineering’ department who are not assigned to the ’Omega Security
-- Update’ project. This demonstrates EXCEPT for finding differences.
SELECT e.employeeid, e.firstname, e.lastname FROM set_operations_subqueries.employees e
NATURAL JOIN set_operations_subqueries.departments d
WHERE d.departmentname = 'Engineering'
EXCEPT
SELECT e.employeeid, e.firstname, e.lastname FROM set_operations_subqueries.employees e
NATURAL JOIN set_operations_subqueries.employee_projects ep
NATURAL JOIN set_operations_subqueries.projects p
WHERE p.projectname = 'Omega Security Update'
ORDER BY employeeid;


-- 	1.2 Type (ii): Disadvantages

-- 		SO-2.1: Mismatched Column Data Types in Union
-- Problem: Try to create a unified list showing employeeId and their salary, and
-- candidateId and their expectedSalary. Intentionally try to select hireDate for
-- employees instead of salary to demonstrate a data type mismatch error that
-- UNION would typically cause if not handled. Then, show the corrected version
-- by casting. This highlights the column compatibility disadvantage.
SELECT employeeid, EXTRACT(YEAR FROM hiredate) salary
FROM set_operations_subqueries.employees
UNION
SELECT candidateid as employeeid, expectedsalary salary
FROM set_operations_subqueries.candidate_employees;

-- 		SO-2.2: Performance of UNION vs UNION ALL with Large Datasets (Con-
-- ceptual)
-- Problem: Explain a scenario where using UNION instead of UNION ALL could sig-
-- nificantly degrade performance. Retrieve all first names from Employees and
-- CandidateEmployees. First with UNION ALL, then with UNION. Imagine these
-- tables have millions of rows.
-- Answer 1: getting all products from many sales tables categorized by date 
-- and then count the total will not degrade performance but also will make the
-- subsequent counting unmeaningful if the analyst want to count all selled products
-- from all dates
SELECT candidateid employeeid, expectedsalary salary 	-- Answer 2: for the query 'List all
FROM set_operations_subqueries.candidate_employees		-- people interested to work with us
UNION ALL												-- in any nature: looking for a new job'
SELECT employeeid, salary 								-- or keeping their job' this query exists.
FROM set_operations_subqueries.employees;				-- In such case UNION deletes the counting
														-- paramater that divides interest in natures
														
-- 	1.3 Type (iii): Inefficient alternatives

-- 		SO-3.1: Simulating EXCEPT with NOT IN (and its NULL pitfall)
-- Problem: Find all employees from the ’Engineering’ department (employeeId)
-- who are not listed in the OnLeaveEmployees table. First, attempt this using NOT
-- IN with a subquery, and then show the more robust EXCEPT (or NOT EXISTS) so-
-- lution, highlighting the NULL issue with NOT IN if OnLeaveEmployees.employeeId
-- could be NULL.
SELECT e.employeeId, e.firstName, e.lastName		-- Complex and verbose solution
FROM set_operations_subqueries.employees e
JOIN set_operations_subqueries.departments D ON e.departmentId = d.departmentId
WHERE d.departmentName = 'Engineering'
  AND e.employeeId NOT IN (SELECT ol.employeeId FROM set_operations_subqueries.on_leave_employees ol);
  -- If ol.employeeId could be NULL and is returned, NOT IN behaves unexpectedly.
  
SELECT e.employeeId, e.firstName, e.lastName     -- Cleanear and faster alternative
FROM set_operations_subqueries.employees e
JOIN set_operations_subqueries.departments D ON e.departmentId = d.departmentId
WHERE d.departmentName = 'Engineering'
	EXCEPT
SELECT e.employeeId, e.firstName, e.lastName
FROM set_operations_subqueries.employees e
NATURAL JOIN set_operations_subqueries.on_leave_employees ole
ORDER BY employeeId;

-- 		SO-3.2: Simulating INTERSECT with Multiple Joins/WHERE conditions
-- Problem: Find employees (employeeId, firstName) who are in the ’Engineering’
-- department AND are working on the ’Beta Platform’ project. Show how this
-- can be done with INTERSECT and then with a more traditional JOIN approach.
-- Discuss when INTERSECT might be clearer.

SELECT DISTINCT E.employeeId, E.firstName					-- Verbose, complex and inefficient solution
FROM Employees E
JOIN Departments D ON E.departmentId = D.departmentId
JOIN EmployeeProjects EP ON E.employeeId = EP.employeeId
JOIN Projects P ON EP.projectId = P.projectId
WHERE D.departmentName = 'Engineering' AND P.projectName = 'Beta Platform'
ORDER BY E.employeeId;
																-- Clear, understandable and fast alternative
SELECT employeeid, firstname FROM set_operations_subqueries.employees
NATURAL JOIN set_operations_subqueries.departments e WHERE e.departmentName = 'Engineering'
INTERSECT
SELECT employeeid, firstname FROM set_operations_subqueries.employees
NATURAL JOIN set_operations_subqueries.employee_projects e 
NATURAL JOIN set_operations_subqueries.projects p
WHERE p.projectName = 'Beta Platform';

-- 	1.4 Type (iv): Hardcore problem

-- 		SO-4.1: Consolidated List of High-Value Personnel Not On Leave, Ranked
-- Problem: Create a consolidated list of personnel who are either:
-- a. Current employees with a salary greater than $70,000.
-- b. Former employees (from OldEmployees) whose final salary was greater
-- than $75,000 and left for ’New Opportunity’ or ’Retired’.
-- Exclude any personnel from this consolidated list if their employeeId appears
-- in the OnLeaveEmployees table. For the resulting list, display employeeId,
-- firstName, lastName, their relevant salary (current or final), a personnelType
-- (’Current Employee’ or ’Former Employee’), and rank them within their personnelType
-- based on their salary in descending order.
(
	SELECT employeeId, firstName, lastName, salary, 'Current Employee' personnelType 
	FROM set_operations_subqueries.employees WHERE salary > 70000
		UNION
	SELECT employeeId, firstName, lastName, finalsalary salary, 'Former Employee' personnelType 
	FROM set_operations_subqueries.old_employees 
	WHERE finalSalary > 75000 AND reasonForLeaving IN ('New Opportunity', 'Retired')
)
EXCEPT (
	SELECT e.employeeId, e.firstName, e.lastName, e.salary, 'Curent Employee' personnelType 
	FROM set_operations_subqueries.on_leave_employees 
	NATURAL JOIN set_operations_subqueries.employees e
) ORDER BY personnelType ASC, salary DESC;









