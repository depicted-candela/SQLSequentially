-- SQL Dataset for PostgreSQL

-- Drop tables if they exist to ensure a clean slate
DROP TABLE IF EXISTS advanced_query_techniques.EmployeeProjects CASCADE;
DROP TABLE IF EXISTS advanced_query_techniques.ProductSales CASCADE;
DROP TABLE IF EXISTS advanced_query_techniques.Employees CASCADE;
DROP TABLE IF EXISTS advanced_query_techniques.Departments CASCADE;

-- advanced_query_techniques.Departments Table
CREATE TABLE advanced_query_techniques.Departments (
    departmentId SERIAL PRIMARY KEY,
    departmentName VARCHAR(100) UNIQUE NOT NULL,
    locationCity VARCHAR(50)
);

-- advanced_query_techniques.Employees Table
CREATE TABLE advanced_query_techniques.Employees (
    employeeId SERIAL PRIMARY KEY,
    firstName VARCHAR(50) NOT NULL,
    lastName VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hireDate DATE NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    departmentId INTEGER REFERENCES advanced_query_techniques.Departments(departmentId),
    managerId INTEGER -- Will add FK constraint later
);

-- advanced_query_techniques.ProductSales Table
CREATE TABLE advanced_query_techniques.ProductSales (
    saleId SERIAL PRIMARY KEY,
    productName VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    saleDate TIMESTAMP NOT NULL,
    quantitySold INTEGER NOT NULL,
    unitPrice DECIMAL(10, 2) NOT NULL,
    region VARCHAR(50)
);

-- advanced_query_techniques.EmployeeProjects Table
CREATE TABLE advanced_query_techniques.EmployeeProjects (
    assignmentId SERIAL PRIMARY KEY,
    employeeId INTEGER NOT NULL, -- Will add FK constraint later
    projectName VARCHAR(100) NOT NULL,
    hoursWorked INTEGER,
    assignmentDate DATE
);

-- Populate advanced_query_techniques.Departments
INSERT INTO advanced_query_techniques.Departments (departmentName, locationCity) VALUES
('Human Resources', 'New York'),    -- departmentId 1
('Engineering', 'San Francisco'), -- departmentId 2
('Marketing', 'Chicago'),         -- departmentId 3
('Sales', 'Boston'),              -- departmentId 4
('Research', 'Austin');           -- departmentId 5

-- Populate advanced_query_techniques.Employees
-- Manually assigning employeeId for clarity in problem setup, SERIAL will handle it.
-- For inserts, rely on SERIAL. For managerId, use the IDs that will be generated.
-- Managers (NULL managerId or managerId referencing an already inserted employee)
INSERT INTO advanced_query_techniques.Employees (firstName, lastName, email, hireDate, salary, departmentId, managerId) VALUES
('Alice', 'Smith', 'alice.smith@example.com', '2020-01-15', 70000.00, 2, NULL),       -- employeeId 1
('Diana', 'Prince', 'diana.prince@example.com', '2018-05-10', 150000.00, 1, NULL),    -- employeeId 2
('Frank', 'Castle', 'frank.castle@example.com', '2017-11-05', 110000.00, 3, NULL),    -- employeeId 3
('Henry', 'Jekyll', 'henry.jekyll@example.com', '2021-06-30', 88000.00, 4, NULL),      -- employeeId 4
('Kara', 'Stark', 'kara.stark@example.com', '2018-07-15', 130000.00, 5, NULL);       -- employeeId 5

-- Subordinate employees (managerId refers to employeeId generated above)
INSERT INTO advanced_query_techniques.Employees (firstName, lastName, email, hireDate, salary, departmentId, managerId) VALUES
('Bob', 'Johnson', 'bob.johnson@example.com', '2019-03-01', 120000.00, 2, 1),        -- employeeId 6
('Charlie', 'Brown', 'charlie.brown@example.com', '2021-07-22', 65000.00, 2, 1),    -- employeeId 7
('Eve', 'Adams', 'eve.adams@example.com', '2022-02-11', 50000.00, 1, 2),          -- employeeId 8
('Grace', 'Hopper', 'grace.hopper@example.com', '2020-08-19', 95000.00, 3, 3),       -- employeeId 9
('Ivy', 'Poison', 'ivy.poison@example.com', '2019-09-14', 72000.00, 4, 4),         -- employeeId 10
('Jack', 'Ripper', 'jack.ripper@example.com', '2022-01-01', 60000.00, 4, 4),        -- employeeId 11
('Leo', 'Martin', 'leo.martin@example.com', '2023-01-20', 55000.00, 5, 5),         -- employeeId 12
('Mia', 'Wallace', 'mia.wallace@example.com', '2020-04-05', 90000.00, 2, 1),        -- employeeId 13
('Noah', 'Chen', 'noah.chen@example.com', '2021-11-12', 75000.00, 3, 3),         -- employeeId 14
('Olivia', 'Davis', 'olivia.davis@example.com', '2022-05-25', 62000.00, 1, 2);     -- employeeId 15

-- Add self-referencing foreign key for advanced_query_techniques.Employees.managerId
ALTER TABLE advanced_query_techniques.Employees ADD CONSTRAINT fkManager FOREIGN KEY (managerId) REFERENCES advanced_query_techniques.Employees(employeeId);

-- Add foreign key for advanced_query_techniques.EmployeeProjects.employeeId
ALTER TABLE advanced_query_techniques.EmployeeProjects ADD CONSTRAINT fkEmployeeProjectsEmployee FOREIGN KEY (employeeId) REFERENCES advanced_query_techniques.Employees(employeeId);


-- Populate advanced_query_techniques.ProductSales (20 rows)
INSERT INTO advanced_query_techniques.ProductSales (productName, category, saleDate, quantitySold, unitPrice, region) VALUES
('Laptop Pro', 'Electronics', '2023-01-10 10:00:00', 5, 1200.00, 'North'),
('Smartphone X', 'Electronics', '2023-01-12 11:30:00', 10, 800.00, 'North'),
('Office Chair', 'Furniture', '2023-01-15 14:20:00', 2, 150.00, 'West'),
('Desk Lamp', 'Furniture', '2023-01-18 09:00:00', 3, 40.00, 'West'),
('Laptop Pro', 'Electronics', '2023-02-05 16:00:00', 3, 1200.00, 'South'),
('Smartphone X', 'Electronics', '2023-02-08 10:10:00', 8, 810.00, 'East'),
('Coffee Maker', 'Appliances', '2023-02-12 13:00:00', 1, 70.00, 'North'),
('Blender', 'Appliances', '2023-02-15 15:45:00', 2, 50.00, 'South'),
('Laptop Pro', 'Electronics', '2023-03-01 12:00:00', 4, 1180.00, 'West'),
('Smartphone X', 'Electronics', '2023-03-04 17:00:00', 12, 790.00, 'North'),
('Office Chair', 'Furniture', '2023-03-07 11:00:00', 1, 155.00, 'East'),
('Desk Lamp', 'Furniture', '2023-03-10 09:30:00', 5, 38.00, 'South'),
('Toaster', 'Appliances', '2023-03-13 14:50:00', 2, 30.00, 'West'),
('Vacuum Cleaner', 'Appliances', '2023-03-16 18:00:00', 1, 200.00, 'North'),
('Gaming Mouse', 'Electronics', '2023-04-01 10:00:00', 20, 50.00, 'East'),
('Keyboard', 'Electronics', '2023-04-02 11:00:00', 15, 75.00, 'West'),
('Monitor', 'Electronics', '2023-04-03 12:00:00', 7, 300.00, 'South'),
('External HDD', 'Electronics', '2023-04-04 13:00:00', 10, 80.00, 'North'),
('Webcam', 'Electronics', '2023-04-05 14:00:00', 12, 60.00, 'East'),
('Printer', 'Electronics', '2023-04-06 15:00:00', 4, 150.00, 'West');

-- Populate advanced_query_techniques.EmployeeProjects (10 rows)
-- employeeId values correspond to the SERIAL generated IDs:
-- Alice=1, Bob=6, Charlie=7, Eve=8, Grace=9, Ivy=10, Leo=12, Mia=13.
INSERT INTO advanced_query_techniques.EmployeeProjects (employeeId, projectName, hoursWorked, assignmentDate) VALUES
(1, 'Alpha Platform', 120, '2023-01-01'),
(6, 'Alpha Platform', 150, '2023-01-01'),
(7, 'Beta Feature', 80, '2023-02-15'),
(1, 'Beta Feature', 60, '2023-02-15'),
(8, 'HR Portal Update', 100, '2023-03-01'),
(9, 'Marketing Campaign Q1', 160, '2023-01-10'),
(10, 'Sales Dashboard', 130, '2023-02-01'),
(6, 'Gamma Initiative', 200, '2023-04-01'),
(13, 'Gamma Initiative', 180, '2023-04-01'),
(12, 'Research Paper X', 90, '2023-03-20');