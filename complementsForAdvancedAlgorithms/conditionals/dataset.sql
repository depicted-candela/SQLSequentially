-- Drop tables if they exist to ensure a clean setup
DROP TABLE IF EXISTS complementary.employee_projects CASCADE;
DROP TABLE IF EXISTS complementary.projects CASCADE;
DROP TABLE IF EXISTS complementary.employees CASCADE;
DROP TABLE IF EXISTS complementary.departments CASCADE;

-- Create Departments Table
CREATE TABLE complementary.departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    location VARCHAR(50),
    monthly_budget NUMERIC(10,2) NULL
);

-- Create Employees Table
CREATE TABLE complementary.employees (
    emp_id SERIAL PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    dept_id INTEGER REFERENCES complementary.departments(dept_id),
    salary NUMERIC(10,2) NOT NULL,
    manager_id INTEGER REFERENCES complementary.employees(emp_id) NULL,
    performance_rating INTEGER NULL CHECK (performance_rating IS NULL OR performance_rating BETWEEN 1 AND 5),
    last_bonus NUMERIC(8,2) NULL,
    hire_date DATE NOT NULL
);

-- Create Projects Table
CREATE TABLE complementary.projects (
    proj_id SERIAL PRIMARY KEY,
    proj_name VARCHAR(100) NOT NULL,
    lead_emp_id INTEGER REFERENCES complementary.employees(emp_id) NULL,
    budget NUMERIC(12,2),
    start_date DATE NOT NULL,
    end_date DATE NULL
);

-- Create Employee_Projects Junction Table
CREATE TABLE complementary.employee_projects (
    emp_id INTEGER REFERENCES complementary.employees(emp_id),
    proj_id INTEGER REFERENCES complementary.projects(proj_id),
    role VARCHAR(50),
    hours_assigned INTEGER NULL,
    PRIMARY KEY (emp_id, proj_id)
);

-- Populate Departments
INSERT INTO complementary.departments (dept_name, location, monthly_budget) VALUES
('Human Resources', 'New York', 50000.00),
('Technology', 'San Francisco', 75000.00),
('Sales', 'Chicago', 60000.00),
('Support', 'Austin', 40000.00),
('Research', 'Boston', NULL), -- Budget is NULL
('Operations', 'New York', 50000.00);

-- Populate Employees
-- Top Managers (no manager_id)
INSERT INTO complementary.employees (emp_name, dept_id, salary, manager_id, performance_rating, last_bonus, hire_date) VALUES
('Alice Wonderland', 1, 90000.00, NULL, 5, 10000.00, '2010-03-15'),
('Bob The Builder', 2, 95000.00, NULL, 4, 8000.00, '2008-07-01');

-- Other Employees
INSERT INTO complementary.employees (emp_name, dept_id, salary, manager_id, performance_rating, last_bonus, hire_date) VALUES
('Charlie Brown', 1, 60000.00, 1, 3, 3000.00, '2012-05-20'), -- HR
('Diana Prince', 2, 75000.00, 2, 5, 7000.00, '2015-11-01'), -- Tech
('Edward Scissorhands', 2, 70000.00, 2, 2, NULL, '2016-02-10'), -- Tech, NULL bonus, low rating
('Fiona Apple', 3, 65000.00, NULL, 4, 5000.00, '2018-08-01'), -- Sales, no manager_id in this context
('George Jetson', 3, 55000.00, 6, 3, 2500.00, '2019-01-15'), -- Sales
('Hannah Montana', 4, 50000.00, 1, NULL, 1500.00, '2020-06-01'), -- Support, NULL rating
('Ivan Drago', 4, 48000.00, 8, 2, 1000.00, '2021-03-10'), -- Support
('Julia Child', 5, 80000.00, NULL, 5, NULL, '2011-09-05'), -- Research, NULL bonus
('Kevin McCallister', 1, 58000.00, 1, 4, 2000.00, '2013-07-22'), -- HR
('Laura Palmer', 2, 82000.00, 2, 3, 4000.00, '2014-01-30'), -- Tech
('Michael Knight', 3, 68000.00, 6, 5, 6000.00, '2017-04-11'), -- Sales
('Nancy Drew', 4, 52000.00, 8, 4, NULL, '2019-10-01'), -- Support, NULL bonus
('Oscar Wilde', 5, 78000.00, 10, NULL, 7500.00, '2022-01-20'); -- Research, NULL rating

UPDATE complementary.employees SET manager_id = 1 WHERE emp_name = 'Charlie Brown';
UPDATE complementary.employees SET manager_id = 1 WHERE emp_name = 'Kevin McCallister';
UPDATE complementary.employees SET manager_id = 2 WHERE emp_name = 'Diana Prince';
UPDATE complementary.employees SET manager_id = 2 WHERE emp_name = 'Edward Scissorhands';
UPDATE complementary.employees SET manager_id = 2 WHERE emp_name = 'Laura Palmer';
UPDATE complementary.employees SET manager_id = 6 WHERE emp_name = 'George Jetson';
UPDATE complementary.employees SET manager_id = 6 WHERE emp_name = 'Michael Knight';
INSERT INTO complementary.employees (emp_name, dept_id, salary, manager_id, performance_rating, last_bonus, hire_date) VALUES
('Peter Pan', NULL, 30000.00, NULL, 3, NULL, '2023-01-01'); -- No department, NULL bonus

-- Populate Projects
INSERT INTO complementary.projects (proj_name, lead_emp_id, budget, start_date, end_date) VALUES
('Alpha Launch', 4, 150000.00, '2023-01-01', '2023-12-31'), -- Lead: Diana Prince (Tech)
('Beta Test', 5, 80000.00, '2023-03-01', '2023-09-30'), -- Lead: Edward Scissorhands (Tech)
('Gamma Initiative', 1, 200000.00, '2022-06-01', NULL), -- Lead: Alice Wonderland (HR)
('Delta Rollout', 13, 120000.00, '2024-02-01', NULL), -- Lead: Michael Knight (Sales)
('Epsilon Research', 10, 90000.00, '2023-05-01', '2024-05-01'), -- Lead: Julia Child (Research)
('NoLead Project', NULL, 50000.00, '2023-07-01', NULL); -- NULL lead_emp_id

-- Populate Employee_Projects
INSERT INTO complementary.employee_projects (emp_id, proj_id, role, hours_assigned) VALUES
(4, 1, 'Developer', 160), -- Diana on Alpha
(5, 1, 'QA Engineer', 120), -- Edward on Alpha
(12, 1, 'UI Designer', 100), -- Laura on Alpha
(5, 2, 'Lead Tester', 150), -- Edward on Beta
(9, 2, 'Tester', 80), -- Ivan on Beta
(1, 3, 'Project Manager', 200), -- Alice on Gamma
(3, 3, 'Coordinator', NULL), -- Charlie on Gamma, NULL hours
(11, 3, 'Analyst', 100), -- Kevin on Gamma
(13, 4, 'Sales Lead', 180), -- Michael on Delta
(7, 4, 'Sales Rep', 140), -- George on Delta
(10, 5, 'Lead Researcher', 190), -- Julia on Epsilon
(15, 5, 'Researcher', NULL); -- Oscar on Epsilon, NULL hours

-- Add an employee in a department that will be used for NOT IN examples
INSERT INTO complementary.departments (dept_name, location, monthly_budget) VALUES ('Intern Pool', 'Remote', 10000.00);
INSERT INTO complementary.employees (emp_name, dept_id, salary, manager_id, performance_rating, last_bonus, hire_date) VALUES
('Intern Zero', (SELECT dept_id FROM complementary.departments WHERE dept_name = 'Intern Pool'), 20000.00, NULL, NULL, NULL, '2024-06-01');