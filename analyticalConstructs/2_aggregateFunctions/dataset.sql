-- Dataset for Aggregate Functions Exercises (PostgreSQL)

-- Drop tables if they exist to ensure a clean setup
DROP TABLE IF EXISTS aggregate_functions.employee_tasks CASCADE;
DROP TABLE IF EXISTS aggregate_functions.projects CASCADE;
DROP TABLE IF EXISTS aggregate_functions.employees CASCADE;
DROP TABLE IF EXISTS aggregate_functions.departments CASCADE;

-- aggregate_functions.departments table
CREATE TABLE aggregate_functions.departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100)
);

-- aggregate_functions.employees table
CREATE TABLE aggregate_functions.employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    salary DECIMAL(10, 2) CHECK (salary > 0),
    hire_date DATE,
    department_id INT REFERENCES aggregate_functions.departments(department_id),
    manager_id INT REFERENCES aggregate_functions.employees(employee_id),
    bonus_percentage NUMERIC(4, 2) CHECK (bonus_percentage >= 0 AND bonus_percentage <= 100.00),
    performance_rating INT CHECK (performance_rating >= 1 AND performance_rating <= 5)
);

-- aggregate_functions.projects table
CREATE TABLE aggregate_functions.projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(150) NOT NULL UNIQUE,
    start_date DATE,
    end_date DATE,
    budget DECIMAL(12, 2) CHECK (budget > 0),
    lead_employee_id INT REFERENCES aggregate_functions.employees(employee_id)
);

-- aggregate_functions.employee_tasks table
CREATE TABLE aggregate_functions.employee_tasks (
    task_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES aggregate_functions.employees(employee_id),
    project_id INT NOT NULL REFERENCES aggregate_functions.projects(project_id),
    task_description TEXT,
    hours_spent DECIMAL(5, 2) CHECK (hours_spent >= 0),
    task_date DATE,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled'))
);

-- Populate aggregate_functions.departments
INSERT INTO aggregate_functions.departments (department_name, location) VALUES
('Human Resources', 'New York'),
('Engineering', 'San Francisco'),
('Marketing', 'Chicago'),
('Sales', 'Boston'),
('Research', 'Austin');

-- Populate aggregate_functions.employees
INSERT INTO aggregate_functions.employees (first_name, last_name, email, salary, hire_date, department_id, manager_id, bonus_percentage, performance_rating) VALUES
('Alice', 'Smith', 'alice.smith@example.com', 70000.00, '2020-01-15', 2, NULL, 10.00, 4), -- Manager for Eng
('Bob', 'Johnson', 'bob.johnson@example.com', 120000.00, '2019-03-01', 2, 1, 15.00, 5),
('Charlie', 'Brown', 'charlie.brown@example.com', 95000.00, '2021-07-20', 2, 1, 12.50, 4),
('Diana', 'Lee', 'diana.lee@example.com', 80000.00, '2022-06-10', 2, 1, NULL, 3),
('Eve', 'Davis', 'eve.davis@example.com', 60000.00, '2020-05-01', 1, NULL, 5.00, 4), -- Manager for HR
('Frank', 'Miller', 'frank.miller@example.com', 55000.00, '2021-08-25', 1, 5, 7.50, 3),
('Grace', 'Wilson', 'grace.wilson@example.com', 58000.00, '2022-01-10', 1, 5, NULL, 4),
('Henry', 'Moore', 'henry.moore@example.com', 90000.00, '2019-11-05', 3, NULL, 10.00, 5), -- Manager for Marketing
('Ivy', 'Taylor', 'ivy.taylor@example.com', 75000.00, '2020-02-17', 3, 8, 8.00, 4),
('Jack', 'Anderson', 'jack.anderson@example.com', 72000.00, '2021-09-30', 3, 8, 9.50, 3),
('Karen', 'Thomas', 'karen.thomas@example.com', 65000.00, '2023-01-20', 3, 8, NULL, 4),
('Leo', 'Jackson', 'leo.jackson@example.com', 110000.00, '2018-07-14', 4, NULL, 20.00, 5), -- Manager for Sales
('Mia', 'White', 'mia.white@example.com', 85000.00, '2019-04-01', 4, 12, 18.00, 4),
('Noah', 'Harris', 'noah.harris@example.com', 82000.00, '2020-10-15', 4, 12, 17.50, 4),
('Olivia', 'Martin', 'olivia.martin@example.com', 78000.00, '2021-12-01', 4, 12, NULL, 3),
('Paul', 'Garcia', 'paul.garcia@example.com', 130000.00, '2017-05-22', 5, NULL, 22.00, 5), -- Manager for Research
('Quinn', 'Martinez', 'quinn.martinez@example.com', 100000.00, '2018-09-10', 5, 16, 15.00, 5),
('Ruby', 'Robinson', 'ruby.robinson@example.com', 92000.00, '2019-06-05', 5, 16, 14.00, 4),
('Sam', 'Clark', 'sam.clark@example.com', 88000.00, '2020-11-11', 5, 16, NULL, 3),
('Tina', 'Rodriguez', 'tina.rodriguez@example.com', 105000.00, '2022-03-15', 2, 1, 10.00, 5),
('Uma', 'Lewis', 'uma.lewis@example.com', 62000.00, '2021-05-10', 1, 5, 6.00, 4),
('Victor', 'Walker', 'victor.walker@example.com', 77000.00, '2022-08-01', 3, 8, 7.00, 3),
('Wendy', 'Hall', 'wendy.hall@example.com', 90000.00, '2020-01-20', 4, 12, 19.00, 5),
('Xavier', 'Allen', 'xavier.allen@example.com', 115000.00, '2021-02-18', 5, 16, 16.00, 4),
('Yara', 'Young', 'yara.young@example.com', 71000.00, '2023-04-01', 2, 1, 5.00, 3);

-- Update manager_id for Alice, Eve, Henry, Leo, Paul (they were NULL, now they are their own managers for simplicity or a designated top manager if exists)
-- For this dataset, let's assume they are top-level or report to someone outside this scope.
-- Or, let's make Alice the overall CEO reporting to no one.
UPDATE aggregate_functions.employees SET manager_id = 1 WHERE employee_id IN (5, 8, 12, 16); -- Other managers report to Alice
UPDATE aggregate_functions.employees SET manager_id = NULL WHERE employee_id = 1;


-- Populate aggregate_functions.projects
INSERT INTO aggregate_functions.projects (project_name, start_date, end_date, budget, lead_employee_id) VALUES
('Project Alpha', '2023-01-15', '2023-06-30', 150000.00, 2), -- Bob (Eng)
('Project Beta', '2023-03-01', '2023-09-30', 250000.00, 17), -- Quinn (Research)
('Project Gamma', '2023-05-10', '2023-12-31', 100000.00, 9), -- Ivy (Marketing)
('Project Delta', '2023-07-01', '2024-01-31', 300000.00, 13), -- Mia (Sales)
('Project Epsilon', '2023-09-01', '2024-03-31', 75000.00, 3),  -- Charlie (Eng)
('Project Zeta', '2024-01-01', '2024-06-30', 220000.00, 18);  -- Ruby (Research)

-- Populate aggregate_functions.employee_tasks
INSERT INTO aggregate_functions.employee_tasks (employee_id, project_id, task_description, hours_spent, task_date, status) VALUES
(2, 1, 'Initial design phase', 40.5, '2023-01-20', 'Completed'),
(3, 1, 'Frontend development', 120.0, '2023-03-15', 'Completed'),
(4, 1, 'Backend development', 150.75, '2023-04-10', 'In Progress'),
(20, 1, 'API integration', 80.0, '2023-05-01', 'In Progress'),
(17, 2, 'Literature review', 60.0, '2023-03-10', 'Completed'),
(18, 2, 'Experiment setup', 90.5, '2023-05-01', 'In Progress'),
(19, 2, 'Data collection', 70.0, '2023-06-15', 'Pending'),
(24, 2, 'Preliminary analysis', 30.25, '2023-07-01', 'Pending'),
(9, 3, 'Market research', 50.0, '2023-05-15', 'Completed'),
(10, 3, 'Campaign strategy', 75.25, '2023-06-20', 'In Progress'),
(11, 3, 'Content creation', 100.0, '2023-08-01', 'In Progress'),
(22, 3, 'Social media outreach', 40.0, '2023-07-10', 'Pending'),
(13, 4, 'Lead generation plan', 45.0, '2023-07-05', 'Completed'),
(14, 4, 'Client outreach', 110.0, '2023-08-15', 'In Progress'),
(15, 4, 'Sales calls', 95.5, '2023-09-01', 'In Progress'),
(23, 4, 'Contract negotiation', 60.75, '2023-09-20', 'Pending'),
(3, 5, 'Requirements gathering', 30.0, '2023-09-05', 'Completed'),
(4, 5, 'Prototyping', 80.0, '2023-10-10', 'In Progress'),
(20, 5, 'User testing setup', 40.5, '2023-11-01', 'Pending'),
(25, 5, 'Documentation', 25.0, '2023-11-15', 'Pending'),
(18, 6, 'Advanced algorithm design', 120.0, '2024-01-10', 'In Progress'),
(19, 6, 'Simulation runs', 100.0, '2024-02-15', 'Pending'),
(24, 6, 'Results validation', 70.25, '2024-03-01', 'Pending'),
(6, 1, 'HR support for Alpha team', 10.0, '2023-02-01', 'Completed'),
(7, 3, 'HR support for Gamma team', 12.0, '2023-06-01', 'Completed'),
(2, 1, 'Additional design review', 15.0, '2023-02-20', 'Completed'),
(3, 1, 'Bug fixing phase 1', 25.0, '2023-04-01', 'Completed'),
(17, 2, 'Grant proposal writing', 35.0, '2023-04-05', 'Completed'),
(9, 3, 'Ad copy review', 18.0, '2023-07-01', 'Completed'),
(13, 4, 'Sales deck preparation', 22.0, '2023-07-20', 'Completed'),
(2, 5, 'Technical specification', 33.0, '2023-09-20', 'In Progress'),
(4, 1, 'Final testing', 50.0, '2023-05-15', 'Cancelled'), -- Cancelled task
(10, 3, 'Competitor analysis', 30.0, '2023-06-01', 'Completed'),
(14, 4, 'Follow-up emails', 20.0, '2023-09-05', 'In Progress'),
(18, 2, 'Refine experiment design', 25.0, '2023-05-20', 'In Progress'),
(20, 1, 'Security audit', 40.0, '2023-05-20', 'Pending'),
(25, 5, 'Deployment planning', 15.0, '2023-12-01', 'Pending'),
(2, 1, 'Documentation for design', 20.0, '2023-02-25', 'Completed'),
(3, 5, 'Frontend module for Epsilon', 60.0, '2023-10-25', 'In Progress'),
(9, 3, 'Press release draft', 25.0, '2023-08-10', 'In Progress'),
(13, 4, 'CRM data update', 10.0, '2023-09-10', 'Completed'),
(17, 6, 'Research paper outline', 40.0, '2024-01-20', 'Pending'),
(4, 1, 'Performance optimization', 0.0, '2023-05-01', 'Pending'), -- Task with 0 hours
(6, 2, 'Recruitment for Project Beta', 15.0, '2023-03-15', 'Completed'),
(7, 4, 'Onboarding new sales members', 18.0, '2023-07-10', 'In Progress'),
(11, 3, 'Video ad script', 30.0, '2023-08-15', 'Pending'),
(15, 4, 'Quarterly sales report', 12.0, '2023-09-25', 'Pending'),
(19, 6, 'Lab maintenance', 8.0, '2024-02-20', 'Pending'),
(22, 3, 'Influencer outreach', 22.0, '2023-07-25', 'In Progress'),
(23, 4, 'Legal review of contracts', 16.0, '2023-09-28', 'Pending');