-- Drop tables if they exist to ensure a clean setup
DROP TABLE IF EXISTS advanced_dates_cases_and_null_space.leave_requests CASCADE;
DROP TABLE IF EXISTS advanced_dates_cases_and_null_space.employee_projects CASCADE;
DROP TABLE IF EXISTS advanced_dates_cases_and_null_space.projects CASCADE;
DROP TABLE IF EXISTS advanced_dates_cases_and_null_space.employees CASCADE;
DROP TABLE IF EXISTS advanced_dates_cases_and_null_space.departments CASCADE;

-- advanced_dates_cases_and_null_space.departments Table
CREATE TABLE advanced_dates_cases_and_null_space.departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    creation_date DATE NOT NULL,
    location VARCHAR(50)
);

-- advanced_dates_cases_and_null_space.employees Table
CREATE TABLE advanced_dates_cases_and_null_space.employees (
    emp_id SERIAL PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    salary NUMERIC(10, 2),
    dept_id INT REFERENCES advanced_dates_cases_and_null_space.departments(dept_id),
    manager_id INT REFERENCES advanced_dates_cases_and_null_space.employees(emp_id), -- Self-reference for manager
    termination_date DATE, -- NULL if currently employed
    email VARCHAR(100) UNIQUE,
    performance_rating INT CHECK (performance_rating BETWEEN 1 AND 5 OR performance_rating IS NULL)
);

-- advanced_dates_cases_and_null_space.projects Table
CREATE TABLE advanced_dates_cases_and_null_space.projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    planned_end_date DATE NOT NULL,
    actual_end_date DATE, -- NULL if not completed
    budget NUMERIC(12, 2),
    lead_emp_id INT REFERENCES advanced_dates_cases_and_null_space.employees(emp_id),
    CONSTRAINT check_project_dates CHECK (planned_end_date >= start_date)
);

-- advanced_dates_cases_and_null_space.employee_projects Table (Junction table)
CREATE TABLE advanced_dates_cases_and_null_space.employee_projects (
    emp_project_id SERIAL PRIMARY KEY,
    emp_id INT REFERENCES advanced_dates_cases_and_null_space.employees(emp_id) ON DELETE CASCADE,
    project_id INT REFERENCES advanced_dates_cases_and_null_space.projects(project_id) ON DELETE CASCADE,
    assigned_date DATE NOT NULL,
    role VARCHAR(50),
    hours_billed NUMERIC(6, 2) DEFAULT 0.00,
    billing_rate NUMERIC(8, 2),
    completion_date DATE, -- Date employee completed their part
    UNIQUE(emp_id, project_id) -- An employee has one role per project
);

-- advanced_dates_cases_and_null_space.leave_requests Table
CREATE TABLE advanced_dates_cases_and_null_space.leave_requests (
    leave_id SERIAL PRIMARY KEY,
    emp_id INT REFERENCES advanced_dates_cases_and_null_space.employees(emp_id) ON DELETE CASCADE,
    request_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    leave_start_date DATE NOT NULL,
    leave_end_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('Pending', 'Approved', 'Rejected', 'Cancelled')),
    approved_by_manager_id INT REFERENCES advanced_dates_cases_and_null_space.employees(emp_id),
    reason TEXT,
    CONSTRAINT check_leave_dates CHECK (leave_end_date >= leave_start_date)
);

-- Populate advanced_dates_cases_and_null_space.departments
INSERT INTO advanced_dates_cases_and_null_space.departments (dept_name, creation_date, location) VALUES
('Human Resources', '2010-01-15', 'New York'),
('Engineering', '2010-03-01', 'San Francisco'),
('Sales', '2010-02-01', 'Chicago'),
('Marketing', '2011-05-20', 'New York'),
('Finance', '2010-01-20', 'New York');

-- Populate advanced_dates_cases_and_null_space.employees (managers first, then their reports)
INSERT INTO advanced_dates_cases_and_null_space.employees (emp_name, hire_date, salary, dept_id, manager_id, termination_date, email, performance_rating) VALUES
('Alice Wonderland', '2015-06-01', 90000.00, 2, NULL, NULL, 'alice@example.com', 5), -- Eng Manager
('David Copperfield', '2015-03-10', 120000.00, 3, NULL, NULL, 'david@example.com', 4), -- Sales Manager
('Frankenstein Monster', '2019-11-01', 95000.00, 1, NULL, NULL, 'frank@example.com', 3), -- HR Manager
('Ivy Poison', '2022-09-15', 110000.00, 5, NULL, NULL, 'ivy@example.com', 4); -- Finance Head

INSERT INTO advanced_dates_cases_and_null_space.employees (emp_name, hire_date, salary, dept_id, manager_id, termination_date, email, performance_rating) VALUES
('Bob The Builder', '2016-08-15', 75000.00, 2, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), NULL, 'bob@example.com', 4),
('Carol Danvers', '2017-01-20', 80000.00, 2, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), NULL, 'carol@example.com', 5),
('Eve Harrington', '2018-07-01', 65000.00, 3, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='david@example.com'), '2023-12-31', 'eve@example.com', 2),
('Grace Hopper', '2020-02-10', 70000.00, 1, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='frank@example.com'), NULL, 'grace@example.com', NULL),
('Henry Jekyll', '2021-05-01', 50000.00, 4, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='david@example.com'), NULL, 'henry@example.com', 3), -- Marketing, reports to Sales head for now
('Jack Sparrow', '2023-01-20', 60000.00, 5, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='ivy@example.com'), '2023-08-15', 'jack@example.com', 1),
('Kevin McCallister', '2018-09-01', 72000.00, 2, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), NULL, 'kevin@example.com', NULL),
('Laura Croft', '2019-04-15', 85000.00, 4, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='david@example.com'), NULL, 'laura@example.com', 5); -- Marketing, reports to Sales head

-- Populate advanced_dates_cases_and_null_space.projects
INSERT INTO advanced_dates_cases_and_null_space.projects (project_name, start_date, planned_end_date, actual_end_date, budget, lead_emp_id) VALUES
('Project Alpha', '2023-01-01', '2023-06-30', '2023-07-15', 100000.00, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com')),
('Project Beta', '2023-03-01', '2023-09-30', NULL, 150000.00, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='bob@example.com')),
('Project Gamma', '2022-09-01', '2023-03-31', '2023-03-20', 80000.00, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com')),
('Project Delta', '2023-08-01', '2024-02-29', NULL, 200000.00, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='david@example.com')),
('Project Epsilon', '2023-05-01', '2023-08-31', '2023-09-05', 60000.00, NULL),
('Project Zeta', '2024-01-01', '2024-01-30', NULL, 120000.00, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='bob@example.com')), -- Ends Jan 30, 2024
('Project Omega', '2023-10-01', '2023-12-20', '2023-12-20', 50000.00, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='carol@example.com')),
('Critical Eng Proj 1', '2024-01-02', '2024-01-25', NULL, 5000, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com')), -- Critical for report
('Critical Eng Proj 2', '2024-01-05', '2024-02-10', NULL, 5000, (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='bob@example.com')); -- Critical for report

-- Populate advanced_dates_cases_and_null_space.employee_projects
INSERT INTO advanced_dates_cases_and_null_space.employee_projects (emp_id, project_id, assigned_date, role, hours_billed, billing_rate, completion_date) VALUES
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Alpha'), '2023-01-01', 'Project Manager', 200, 150.00, '2023-07-15'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Gamma'), '2022-09-01', 'Project Manager', 180, 150.00, '2023-03-20'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='bob@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Alpha'), '2023-01-05', 'Developer', 300, 120.00, '2023-07-10'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='bob@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Beta'), '2023-03-01', 'Lead Developer', 250, 130.00, NULL),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='bob@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Zeta'), '2024-01-01', 'Lead Developer', 50, 135.00, NULL),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='carol@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Beta'), '2023-03-05', 'Developer', 220, 120.00, NULL),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='carol@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Epsilon'), '2023-05-01', 'Consultant', 100, 200.00, '2023-09-05'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='carol@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Omega'), '2023-10-01', 'Developer', 80, 125.00, '2023-12-20'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='eve@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Delta'), '2023-08-01', 'Sales Rep', 150, 100.00, '2023-12-31'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='grace@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Alpha'), '2023-02-01', 'HR Coordinator', 80, NULL, '2023-07-15'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='kevin@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Beta'), '2023-03-15', 'QA Engineer', 180, 110.00, NULL),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='laura@example.com'), (SELECT project_id from advanced_dates_cases_and_null_space.projects WHERE project_name='Project Delta'), '2023-08-05', 'Marketing Lead', 200, 140.00, NULL);

-- Populate advanced_dates_cases_and_null_space.leave_requests
INSERT INTO advanced_dates_cases_and_null_space.leave_requests (emp_id, request_date, leave_start_date, leave_end_date, status, approved_by_manager_id, reason) VALUES
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='bob@example.com'), '2023-04-01 10:00:00', '2023-04-10', '2023-04-12', 'Approved', (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), 'Vacation'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='carol@example.com'), '2023-05-10 14:30:00', '2023-06-01', '2023-06-05', 'Approved', (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), 'Personal Leave'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='eve@example.com'), '2023-11-01 09:00:00', '2023-11-10', '2023-11-15', 'Pending', (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='david@example.com'), 'Sick Leave'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='grace@example.com'), '2023-06-15 11:00:00', '2023-07-01', '2023-07-03', 'Rejected', (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='frank@example.com'), NULL),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='bob@example.com'), '2023-08-01 16:00:00', '2023-08-20', '2023-08-25', 'Approved', (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), 'Family event'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='kevin@example.com'), '2023-09-01 08:00:00', '2023-09-10', '2023-09-11', 'Pending', (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), ''),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='laura@example.com'), '2024-01-10 10:00:00', '2024-02-01', '2024-02-05', 'Pending', (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='david@example.com'), 'Conference'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), '2023-12-01 09:00:00', '2023-12-20', '2023-12-28', 'Approved', NULL, 'Holiday Season'),
((SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='bob@example.com'), '2024-01-10 10:00:00', '2024-01-14', '2024-01-16', 'Approved', (SELECT emp_id from advanced_dates_cases_and_null_space.employees WHERE email='alice@example.com'), 'Short break');