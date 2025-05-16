		-- 2 Subqueries
		
-- 	2.1 Type (i): Meaning, values, relations, advantages

-- 		SQ-1.1: Employees Earning More Than Average (Scalar Subquery)
-- Problem: List the employeeId, firstName, lastName, and salary of all em-
-- ployees who earn more than the average salary of all employees. This demon-
-- strates a scalar subquery in the WHERE clause.
SELECT employeeId, firstName, lastName
FROM set_operations_subqueries.employees
WHERE salary > (SELECT AVG(salary) FROM set_operations_subqueries.employees);

-- 		SQ-1.2: Departments with Higher Than Average Project Budgets (Subquery
-- in FROM)
-- Problem: List department names and their average project budget, but only
-- for departments where their average project budget is greater than the overall
-- average budget of all projects. This demonstrates a subquery in the FROM clause
-- (derived table).
SELECT d.departmentId, d.departmentName, sq.avg_budget
FROM set_operations_subqueries.departments d
NATURAL JOIN (
	SELECT departmentId, AVG(budget) avg_budget
	FROM set_operations_subqueries.projects
	GROUP BY departmentId
	HAVING AVG(budget) > (SELECT AVG(budget) FROM set_operations_subqueries.projects)
) sq;

-- 		SQ-1.3: Employee’s Project Count (Subquery in SELECT - Correlated)
-- Problem: For each employee, display their employeeId, firstName, lastName,
-- and the total number of projects they are currently assigned to. This demon-
-- strates a correlated subquery in the SELECT clause.
SELECT e.employeeId, e.firstName, e.lastName, (
	SELECT COUNT(DISTINCT ep.projectId) 
	FROM set_operations_subqueries.employee_projects ep
	WHERE ep.employeeId = e.employeeId
)
FROM set_operations_subqueries.employees e
GROUP BY e.employeeId;

-- 		SQ-1.4: Employees in Departments Located in ’New York’ (Subquery in WHERE
-- with IN)
-- Problem: List the employeeId, firstName, and lastName of all employees who
-- work in departments located in ’New York’. Use a subquery with IN.
SELECT employeeId, firstName, lastName
FROM set_operations_subqueries.employees ep
WHERE departmentId IN (SELECT departmentId FROM set_operations_subqueries.departments WHERE locationCity = 'New York');

-- 		SQ-1.5: Departments with at Least One Project (Subquery in WHERE with
-- EXISTS)
-- Problem: List the departmentId and departmentName of all departments that
-- have at least one project associated with them. Use a subquery with EXISTS.
SELECT departmentId, departmentName 
FROM set_operations_subqueries.departments d
WHERE EXISTS(SELECT 1 FROM set_operations_subqueries.projects p WHERE p.departmentId = d.departmentId);

-- 		SQ-1.6: Employees Earning More Than Any Sales Intern (Subquery in WHERE
-- with ANY/SOME)
-- Problem: Find all employees whose salary is greater than any salary of an
-- employee with jobId = ’SALES_INTERN’.
SELECT e1.*
FROM set_operations_subqueries.employees e1
WHERE salary > ANY(
	SELECT salary 
	FROM set_operations_subqueries.employees
	WHERE LOWER(jobId) = 'sales_intern'
);

-- 		SQ-1.7: Employees Earning More Than All Sales Interns (Subquery in WHERE
-- with ALL)
-- Problem: Find all employees whose salary is greater than all salaries of em-
-- ployees with jobId = ’SALES_INTERN’.
SELECT e1.*
FROM set_operations_subqueries.employees e1
WHERE e1.salary > ALL(SELECT e2.salary FROM set_operations_subqueries.employees e2 WHERE LOWER(jobId) = 'sales_intern');


-- 	2.2	Type (ii): Disadvantages

-- 		SQ-2.1: Performance of Correlated Subquery in SELECT
-- Problem: Retrieve each employee’s employeeId, firstName, and the name of
-- the most expensive project their department is leading. Highlight that a corre-
-- lated subquery in SELECT might be re-executed for each employee, potentially
-- leading to performance issues. (An alternative join-based approach might be
-- more efficient).
SELECT 														-- N + 1 problem: inefficient
	e1.employeeId, 
	e1.firstName,
	(
		SELECT MAX(p.budget) 
		FROM set_operations_subqueries.projects p
		NATURAL JOIN set_operations_subqueries.departments d
		WHERE e1.departmentId = d.departmentId
	) most_expensive_departmental_project
FROM set_operations_subqueries.employees e1
ORDER BY e1.employeeId;

SELECT 													-- Simpler and efficient approach grouping by employeeId
	e1.employeeId, 										-- and getting the maximum budget for each project
	e1.firstName,
	MAX(p.budget) most_expensive_departmental_project
FROM set_operations_subqueries.employees e1
NATURAL JOIN set_operations_subqueries.departments d
NATURAL JOIN set_operations_subqueries.projects p
GROUP BY e1.employeeId
ORDER BY e1.employeeId;

-- 		SQ-2.2: Scalar Subquery Returning Multiple Rows (Error Scenario)
-- Problem: Attempt to find employees whose salary is equal to a salary from
-- the ’Sales’ department. Intentionally write a scalar subquery that could return
-- multiple rows to demonstrate the error. Then show a corrected version using
-- IN or ANY.

SELECT employeeId, firstName, salary					-- Incorrect query that should use a single row for a
FROM set_operations_subqueries.Employees				-- scalar subquery
WHERE salary = (
	SELECT DISTINCT salary 
	FROM set_operations_subqueries.Employees E 
	JOIN set_operations_subqueries.Departments D 
	ON E.departmentId = D.departmentId 
	WHERE LOWER(D.departmentName) = 'sales'
);

SELECT employeeId, firstName, salary					-- correct query that uses a single row coming
FROM set_operations_subqueries.Employees				-- from the scalar subquery
WHERE salary IN (
	SELECT E.salary 
	FROM set_operations_subqueries.Employees E 
	JOIN set_operations_subqueries.Departments D 
	ON E.departmentId = D.departmentId 
	WHERE LOWER(D.departmentName) = 'sales'
);

-- 	2.3 Type (iii): Inefficient alternatives

-- 		SQ-3.1: Finding Max Salary Without Scalar Subquery (Inefficient Application
-- Logic)
-- Problem: List employees who earn the maximum salary in the company. An
-- inefficient alternative would be to first query the max salary, then use that value
-- in a second query. Show the efficient SQL way using a scalar subquery.
SELECT * 
FROM set_operations_subqueries.employees
WHERE salary = (SELECT MAX(salary) FROM set_operations_subqueries.employees);

-- 		SQ-3.2: Checking Existence of Sales by Engineers (Inefficient: Fetching All
-- Sales Data)
-- Problem: Determine if any employee from the ’Engineering’ department has
-- ever made a sale. An inefficient approach would be to fetch all sales records
-- and then join/filter in application code or with complex client-side logic. Show
-- the efficient EXISTS subquery approach.
SELECT * FROM set_operations_subqueries.employees e
NATURAL JOIN set_operations_subqueries.departments d
WHERE LOWER(d.departmentName) = 'engineering' AND EXISTS(
	SELECT * FROM set_operations_subqueries.sales s WHERE s.employeeId = e.employeeId
);

-- 	2.4 Type (iv): Hardcore problem

-- 		Exercise SQ-4.1: Strategic Department Performance and High-Earner Identification Prob-
-- lem: For each department that manages at least one project and whose average employee
-- salary is above $65,000: Display the following information:

-- 1. departmentName.
-- 2. numManagedProjects: The total count of distinct projects managed by this depart-
-- ment.
-- 3. totalBudgetManaged: The sum of budgets for all projects managed by this depart-
-- ment. If no projects, this should be 0.
-- 4. avgSalaryInDept: The average salary of employees within this department.
-- 5. countAboveCompanyAvgSalaryAndProjectInvolved: The number of employees in
-- this department whose salary is greater than the overall average salary of all com-
-- pany employees AND who are assigned to at least one project (any project).
-- 6. mostExpensiveProjectName: The name of the project with the highest budget
-- managed by this department. If multiple have the same max budget, any one of
-- them. If no projects, NULL.

WITH minimal_department AS (
	SELECT departmentId 
	FROM set_operations_subqueries.departments d
	WHERE EXISTS(
		SELECT 1 
		FROM set_operations_subqueries.projects p
		WHERE p.departmentId = d.departmentId
	) AND EXISTS(
		SELECT 1 
		FROM set_operations_subqueries.employees e
		WHERE e.departmentId = d.departmentId
		HAVING AVG(e.salary) > 65000
	)
)

SELECT 
	d.departmentName, 
	(
		SELECT COUNT(DISTINCT projectId) 
		FROM set_operations_subqueries.projects p
		WHERE d.departmentId = p.departmentId
	) num_managed_projects,
	(
		SELECT SUM(p.budget) 
		FROM set_operations_subqueries.projects p
		WHERE d.departmentId = p.departmentId
	) total_budget_managed,
	(
		SELECT AVG(e.salary) 
		FROM set_operations_subqueries.employees e
		WHERE d.departmentId = e.departmentId
	) avg_salary_in_dept,
	(
		SELECT COUNT(DISTINCT e.employeeId) 
		FROM set_operations_subqueries.employees e
		WHERE d.departmentId = e.departmentId
		AND e.salary > (SELECT AVG(salary) FROM set_operations_subqueries.employees e2)
		AND EXISTS(SELECT 1 FROM set_operations_subqueries.employee_projects ep WHERE ep.employeeId = e.employeeId)
	) count_above_company_avgsalary_and_project_involved,
	(
		SELECT p.projectName 
		FROM set_operations_subqueries.projects p 
		WHERE p.departmentId = d.departmentId 
		AND p.budget = (
			SELECT MAX(p2.budget) 
			FROM set_operations_subqueries.projects p2 
			WHERE p2.departmentId = d.departmentId 
		)
	) most_expensive_project,
	(
		SELECT SUM(budget) FROM set_operations_subqueries.projects p WHERE p.departmentId = d.departmentId
	) / (
		SELECT SUM(budget) FROM set_operations_subqueries.projectS
	) company_budget_percentage
FROM set_operations_subqueries.departments d
NATURAL JOIN minimal_department;

