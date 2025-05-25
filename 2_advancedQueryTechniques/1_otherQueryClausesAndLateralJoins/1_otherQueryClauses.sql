		-- 1 Category: Other Query Clauses (FETCH, OFFSET)


-- 	1.1(i) Practice meanings, values, relations, unique usage, and advantages

-- 		1.1.1 Exercise 1: Meaning of OFFSET and FETCH

-- Problem: Retrieve the product sales from the 6th to the 10th most recent sale (inclusive).
-- Display ‘saleId‘, ‘productName‘, and ‘saleDate‘.
-- SELECT saleId, productName, saleDate
-- FROM advanced_query_techniques.productSales
-- ORDER BY saleDate DESC
-- OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

-- 		1.1.2 Exercise 2: Unique usage of FETCH with OFFSET for specific slicing
-- Problem: List all employees, but skip the first 3 highest paid employees and then show
-- the next 5 highest paid after those. Display ‘employeeId‘, ‘firstName‘, ‘lastName‘, and
-- ‘salary‘.
-- SELECT employeeId, firstName, lastName, salary
-- FROM advanced_query_techniques.employees
-- ORDER BY salary DESC
-- OFFSET 3 ROWS FETCH NEXT 5 ROWS ONLY;


-- 	1.2(ii) Practice disadvantages of all its technical concepts

-- 		1.2.1 Exercise 3: Disadvantage of OFFSET without ORDER BY
-- Problem: Show the second page of 5 product sales using OFFSET 5 ROWS FETCH NEXT
-- 5 ROWS ONLY but without an ORDER BY clause. Run the query multiple times. Are the
-- results always the same? Explain the disadvantage.
-- SELECT productName, saleDate						-- Completetly unmeaningful because it
-- FROM advanced_query_techniques.productSales		-- unless users are interested in to see
-- OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;			-- randomly purchased by any person

-- 		1.2.2 Exercise 4: Disadvantage of large OFFSET - Performance
-- Problem: Imagine the ‘ProductSales‘ table has millions of rows. Explain the poten-
-- tial performance disadvantage of fetching a page deep into the result set (e.g., OFFSET
-- 1000000 ROWS FETCH NEXT 10 ROWS ONLY) when ordered by ‘saleDate‘.
-- ANSWER: The meaning of the query turns to be nothing because these functions are to see most important
-- things of a set (ordered) and because importance tends to be modeled with the Paretto law and 
-- what's expected of these functions is to be used in data reduced through meaningful indexes using the
-- MapReduce pattern they're optimized for small limits not for reduction not humanly understandable.
-- Thus, in such giant cases these functions are unmeaningful and inefficient because other patterns
-- from SQL could give the same result more efficiently with just a few more verbose


-- 	1.3(iii) Practice cases where people use inefficient basic solutions instead

-- 1.3.1 Exercise 5: Inefficient pagination attempts vs. OFFSET/FETCH
-- Problem: Display the 3rd ”page” of employees (3 employees per page) when ordered
-- by ‘hireDate‘ (oldest first). A page means a set of 3 employees. The 3rd page would be
-- employees 7, 8, and 9 in the ordered list.
-- a) Describe or attempt to implement a common, but potentially less direct or effi-
-- cient, SQL-based way this might be solved if a developer is unaware of or avoids
-- OFFSET/FETCH. Consider approaches like using only LIMIT and fetching more data
-- than needed, or attempting to simulate row skipping through complex subqueries
-- (without using window functions like ROW NUMBER()).
-- b) Solve the same problem using OFFSET and FETCH.
-- c) Discuss why OFFSET/FETCH is generally preferred for pagination.
-- SELECT employeeId, firstName, lastName, hireDate, salary		-- Window function solution
-- FROM (
--     SELECT
--         employeeId, firstName, lastName, hireDate, salary,
--         ROW_NUMBER() OVER (ORDER BY hireDate ASC) as rn
--     FROM advanced_query_techniques.Employees
-- ) AS Sub
-- WHERE rn > 6 AND rn <= 9;
-- SELECT employeeId, firstName, lastName, hireDate, salary 		-- With upper limit but without lower
-- FROM advanced_query_techniques.Employees 						-- bounding: making not responsive
-- ORDER BY hireDate ASC LIMIT 9;									-- data for specific frontends

SELECT employeeId, firstName, lastName, hireDate, salary			-- With variable pagination where
FROM advanced_query_techniques.Employees							-- 2 is the number of the page (variable)
OFFSET (3 * 2) ROW FETCH NEXT 3 ROWS ONLY;							-- and 3 the size of the page
																	-- Highly portable and efficient

-- 	1.4(iv) Practice a hardcore problem combining previous concepts

		-- 1.4.1 Exercise 6: Hardcore OFFSET/FETCH with joins, set operations, sub-
-- queries, and filtering
-- Problem:
-- 1. Create a combined list of employees from two specific groups:
-- • Group A: All employees from the ’Engineering’ department whose salary is
-- $70,000 or more.
-- • Group B: All employees from the ’Marketing’ department whose hire date is
-- on or after ’2020-01-01’.
-- 2. From this combined list, remove any duplicates based on ‘employeeId‘.
-- 3. Order the resulting unique employees by their ‘lastName‘ alphabetically (A-Z), then
-- by ‘firstName‘ alphabetically (A-Z).
-- 4. From this final ordered list, retrieve the employees from the 2nd to the 3rd position
-- (inclusive).
-- 5. Display the ‘employeeId‘, full name (concatenated ‘firstName‘ and ‘lastName‘ with
-- a space), ‘departmentName‘, ‘salary‘, and ‘hireDate‘ for these selected employees.
SELECT employeeId, firstName || ' ' || lastName fullName, departmentName, salary, hireDate
FROM (
	SELECT employeeId, firstName, lastName, departmentName, salary, hireDate
	FROM advanced_query_techniques.employees
	NATURAL JOIN advanced_query_techniques.departments
	WHERE departmentName = 'Engineering' AND salary >= 70000
		UNION
	SELECT employeeId, firstName, lastName, departmentName, salary, hireDate
	FROM advanced_query_techniques.employees
	NATURAL JOIN advanced_query_techniques.departments
	WHERE departmentName = 'Marketing' AND hireDate >= DATE '2020-01-01'
) sq ORDER BY lastName, firstName
OFFSET 2 ROW FETCH NEXT 2 ROWS ONLY;


