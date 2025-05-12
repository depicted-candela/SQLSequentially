-- Drop tables if they exist to ensure a clean setup
DROP TABLE IF EXISTS advanced_orders.employee_projects CASCADE;
DROP TABLE IF EXISTS advanced_orders.employees CASCADE;
DROP TABLE IF EXISTS advanced_orders.departments CASCADE;

-- Create advanced_orders.departments table
CREATE TABLE advanced_orders.departments (
    department_name VARCHAR(50) PRIMARY KEY,
    location VARCHAR(50),
    budget_allocation NUMERIC(12,2)
);

-- Populate advanced_orders.departments table
INSERT INTO advanced_orders.departments (department_name, location, budget_allocation) VALUES
('Engineering', 'New York', 500000.00),
('Marketing', 'San Francisco', 300000.00),
('Sales', 'Chicago', 400000.00),
('Human Resources', 'New York', 250000.00),
('Product', 'San Francisco', 350000.00),
('Support', 'Remote', 150000.00);

-- Create advanced_orders.employees table
CREATE TABLE advanced_orders.employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50) REFERENCES advanced_orders.departments(department_name),
    salary NUMERIC(10, 2),
    hire_date DATE,
    bonus_percentage NUMERIC(3, 2), -- Nullable
    manager_id INTEGER REFERENCES advanced_orders.employees(id) -- Nullable
);

-- Populate advanced_orders.employees table
INSERT INTO advanced_orders.employees (first_name, last_name, department, salary, hire_date, bonus_percentage, manager_id) VALUES
('Alice', 'Smith', 'Engineering', 90000.00, '2020-03-15', 0.10, NULL),
('Bob', 'Johnson', 'Engineering', 95000.00, '2019-07-01', 0.12, 1),
('Charlie', 'Williams', 'Marketing', 70000.00, '2021-01-10', 0.08, NULL),
('David', 'Brown', 'Sales', 80000.00, '2020-11-05', NULL, NULL), -- Null bonus
('Eve', 'Jones', 'Engineering', 90000.00, '2021-05-20', 0.10, 1),
('Frank', 'Garcia', 'Marketing', 72000.00, '2022-02-01', NULL, 3), -- Null bonus
('Grace', 'Miller', 'Sales', 82000.00, '2019-05-20', 0.09, 4),
('Heidi', 'Davis', 'Human Resources', 65000.00, '2023-01-15', 0.05, NULL),
('Ivan', 'Rodriguez', 'Product', 110000.00, '2020-08-24', 0.15, NULL),
('Judy', 'Martinez', 'Product', 105000.00, '2021-06-10', NULL, 9), -- Null bonus
('Kevin', 'Hernandez', 'Engineering', 88000.00, '2023-03-01', 0.07, 2),
('Linda', 'Lopez', 'Marketing', 68000.00, '2023-04-10', 0.06, 3),
('Mike', 'Gonzalez', 'Sales', 78000.00, '2022-07-18', 0.11, 4),
('Nancy', 'Wilson', 'Human Resources', 67000.00, '2022-09-01', NULL, 8), -- Null bonus
('Olivia', 'Anderson', 'Engineering', 90000.00, '2020-03-15', NULL, 1), -- Null bonus, same salary/hire_date as Alice
('Peter', 'Lee', 'Product', 100000.00, '2021-08-15', 0.12, 9),
('Zoe', 'King', 'Engineering', 92000.00, '2022-05-01', 0.11, 1),
('Yasmin', 'Scott', 'Marketing', 75000.00, '2021-11-20', NULL, 3),
('Eva', 'Taylor', 'Engineering', 90000.00, '2021-05-20', NULL, 1); -- Same salary/hire_date as Eve, but NULL bonus

-- Create advanced_orders.employee_projects table
CREATE TABLE advanced_orders.employee_projects (
    employee_id INTEGER REFERENCES advanced_orders.employees(id),
    project_name VARCHAR(100),
    project_role VARCHAR(50),
    hours_assigned INTEGER,
    PRIMARY KEY (employee_id, project_name)
);

-- Populate advanced_orders.employee_projects table
INSERT INTO advanced_orders.employee_projects (employee_id, project_name, project_role, hours_assigned) VALUES
(1, 'Alpha Platform', 'Developer', 120),
(1, 'Beta Feature', 'Lead Developer', 80),
(2, 'Alpha Platform', 'Senior Developer', 150),
(3, 'Campaign X', 'Coordinator', 100),
(5, 'Gamma Initiative', 'Developer', 90),
(5, 'Alpha Platform', 'Tester', 40),
(6, 'Campaign Y', 'Analyst', 110),
(7, 'Client Outreach', 'Manager', 60),
(9, 'Omega Product', 'Product Owner', 180),
(10, 'Omega Product', 'UX Designer', 70),
(11, 'Gamma Initiative', 'Junior Developer', 100),
(13, 'Client Retention', 'Specialist', 50);

INSERT INTO advanced_orders.employees (id, first_name, last_name, department, salary, hire_date, last_bonus, manager_id) VALUES
(20, 'Ken', 'Adams', 'Engineering', 92000.00, '2022-06-01', 0.10, 1),     -- Qualifies. Same salary as Zoe, Zoe has higher bonus (0.11 vs 0.10)
(21, 'Laura', 'White', 'Engineering', 90000.00, '2021-07-01', 0.11, 2),   -- Qualifies. Same salary as Eve/Eva. Laura higher bonus % than Eve. Eve > Eva. Laura(0.11) > Eve(0.10) > Eva(NULL)
(22, 'Tom', 'Baker', 'Engineering', 88000.00, '2023-03-01', 0.07, 2),    -- Qualifies. Same salary & bonus as Kevin. Tom hired same day. No project.
(23, 'Sara', 'Connor', 'Engineering', 95000.00, '2021-02-01', 0.12, NULL), -- Qualifies. Highest salary in Eng for post-2021 hires.
(24, 'Sam', 'Blue', 'Marketing', 72000.00, '2022-03-01', 0.07, 3),       -- Qualifies. Same salary as Frank. Sam has bonus, Frank doesn't.
(25, 'Diana', 'Prince', 'Marketing', 70000.00, '2021-01-01', NULL, 3),   -- Qualifies. Same salary as Charlie. Charlie has bonus, Diana doesn't. No project.
(26, 'Bruce', 'Banner', 'Marketing', 75000.00, '2021-11-20', 0.09, 3), -- Qualifies. Same salary/hire_date as Yasmin. Bruce has bonus, Yasmin doesn't.
(27, 'Victor', 'Stone', 'Human Resources', 67000.00, '2022-08-01', 0.06, 8), -- Qualifies. Same salary as Nancy. Victor has bonus, Nancy doesn't.
(28, 'Rachel', 'Green', 'Human Resources', 65000.00, '2023-01-15', NULL, 8), -- Qualifies. Same salary/hire_date as Heidi. Heidi has bonus, Rachel doesn't. No project.
(29, 'Clark', 'Kent', 'Product', 105000.00, '2021-07-01', 0.14, 9),    -- Qualifies. Same salary as Judy. Clark has bonus, Judy doesn't.
(30, 'Lois', 'Lane', 'Product', 100000.00, '2021-08-15', 0.10, 9);     -- Qualifies. Same salary/hire_date as Peter. Peter has higher bonus. No project.


INSERT INTO advanced_orders.employee_projects (employee_id, project_name, project_role, hours_assigned) VALUES
(8, 'HR Portal Upgrade', 'Manager', 150),   -- Heidi Davis (Human Resources)
(14, 'Onboarding Revamp', 'Coordinator', 100), -- Nancy Wilson (Human Resources)
(16, 'UX Overhaul', 'Designer', 110),     -- Peter Lee (Product)
(17, 'Zeta Project', 'Architect', 120), -- Zoe King (Engineering)
(18, 'Social Blitz', 'Strategist', 60), -- Yasmin Scott (Marketing)
(20, 'Infra Upgrade', 'Engineer', 70),  -- Ken Adams (Engineering)
(21, 'Core Refactor', 'Senior Dev', 90), -- Laura White (Engineering)
(23, 'New System Design', 'Lead Architect', 150), -- Sara Connor (Engineering)
(24, 'Market Research Alpha', 'Researcher', 80), -- Sam Blue (Marketing)
(26, 'Rebranding Initiative', 'Lead', 100), -- Bruce Banner (Marketing)
(27, 'Benefits Review', 'Analyst', 80),    -- Victor Stone (Human Resources)
(29, 'Feature X', 'Product Manager', 130); -- Clark Kent (Product)