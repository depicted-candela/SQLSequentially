-- Drop tables if they exist to ensure a clean setup
DROP TABLE IF EXISTS data_transformation_and_aggregation.EmployeeProjects CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.Sales CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.Employees CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.Departments CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.Projects CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.Products CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.Regions CASCADE;

-- Table: data_transformation_and_aggregation.Departments
CREATE TABLE data_transformation_and_aggregation.Departments (
    departmentId INT PRIMARY KEY,
    departmentName VARCHAR(100) NOT NULL,
    locationCity VARCHAR(50)
);

-- Table: data_transformation_and_aggregation.Employees
CREATE TABLE data_transformation_and_aggregation.Employees (
    employeeId INT PRIMARY KEY,
    firstName VARCHAR(50) NOT NULL,
    lastName VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    hireDate DATE NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    departmentId INT,
    managerId INT,
    performanceScore NUMERIC(3,2), -- Score from 0.00 to 5.00
    skills TEXT[], -- Array of skills
    FOREIGN KEY (departmentId) REFERENCES data_transformation_and_aggregation.Departments(departmentId),
    FOREIGN KEY (managerId) REFERENCES data_transformation_and_aggregation.Employees(employeeId)
);

-- Table: data_transformation_and_aggregation.Projects
CREATE TABLE data_transformation_and_aggregation.Projects (
    projectId INT PRIMARY KEY,
    projectName VARCHAR(100) NOT NULL,
    startDate DATE,
    deadlineDate DATE,
    budget DECIMAL(12,2)
);

-- Table: data_transformation_and_aggregation.EmployeeProjects
CREATE TABLE data_transformation_and_aggregation.EmployeeProjects (
    assignmentId SERIAL PRIMARY KEY,
    employeeId INT,
    projectId INT,
    hoursWorked INT,
    taskNotes TEXT,
    FOREIGN KEY (employeeId) REFERENCES data_transformation_and_aggregation.Employees(employeeId),
    FOREIGN KEY (projectId) REFERENCES data_transformation_and_aggregation.Projects(projectId)
);

-- Table: data_transformation_and_aggregation.Regions
CREATE TABLE data_transformation_and_aggregation.Regions (
    regionId INT PRIMARY KEY,
    regionName VARCHAR(50) NOT NULL UNIQUE
);

-- Table: data_transformation_and_aggregation.Products
CREATE TABLE data_transformation_and_aggregation.Products (
    productId INT PRIMARY KEY,
    productName VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    standardCost DECIMAL(10, 2),
    listPrice DECIMAL(10, 2)
);

-- Table: data_transformation_and_aggregation.Sales
CREATE TABLE data_transformation_and_aggregation.Sales (
    saleId INT PRIMARY KEY,
    productId INT,
    employeeId INT,
    saleDate DATE NOT NULL,
    quantity INT NOT NULL,
    regionId INT,
    notes JSONB, -- e.g., {"customerSatisfaction": 5, "followUpRequired": true}
    FOREIGN KEY (productId) REFERENCES data_transformation_and_aggregation.Products(productId),
    FOREIGN KEY (employeeId) REFERENCES data_transformation_and_aggregation.Employees(employeeId),
    FOREIGN KEY (regionId) REFERENCES data_transformation_and_aggregation.Regions(regionId)
);

-- Insert data into data_transformation_and_aggregation.Departments
INSERT INTO data_transformation_and_aggregation.Departments (departmentId, departmentName, locationCity) VALUES
(1, 'Human Resources', 'New York'),
(2, 'Engineering', 'San Francisco'),
(3, 'Sales', 'Chicago'),
(4, 'Marketing', 'New York'),
(5, 'Research', 'San Francisco');

-- Insert data into data_transformation_and_aggregation.Employees
INSERT INTO data_transformation_and_aggregation.Employees (employeeId, firstName, lastName, email, hireDate, salary, departmentId, managerId, performanceScore, skills) VALUES
(101, 'Alice', 'Smith', 'alice.smith@example.com', '2020-01-15', 70000, 2, NULL, 4.50, ARRAY['Java', 'Python', 'SQL']),
(102, 'Bob', 'Johnson', 'bob.johnson@example.com', '2019-03-01', 80000, 2, 101, 4.20, ARRAY['Python', 'Machine Learning']),
(103, 'Carol', 'Williams', 'carol.williams@example.com', '2021-07-30', 60000, 1, NULL, 3.90, ARRAY['HR Policies', 'Recruitment']),
(104, 'David', 'Brown', 'david.brown@example.com', '2018-06-11', 95000, 2, 101, 4.80, ARRAY['Java', 'Spring Boot', 'Microservices']),
(105, 'Eve', 'Davis', 'eve.davis@example.com', '2022-01-10', 75000, 3, NULL, 4.10, ARRAY['Salesforce', 'Negotiation']),
(106, 'Frank', 'Miller', 'frank.miller@example.com', '2019-11-05', 120000, 3, 105, 4.60, ARRAY['Key Account Management', 'CRM']),
(107, 'Grace', 'Wilson', 'grace.wilson@example.com', '2020-08-20', 65000, 4, NULL, 3.70, ARRAY['SEO', 'Content Creation']),
(108, 'Henry', 'Moore', 'henry.moore@example.com', '2023-02-18', 55000, 1, 103, 4.00, ARRAY['Onboarding', 'Employee Relations']),
(109, 'Ivy', 'Taylor', 'ivy.taylor@example.com', '2017-05-25', 110000, 5, NULL, 4.90, ARRAY['Research Methodologies', 'Statistical Analysis', 'Python']),
(110, 'Jack', 'Anderson', 'jack.anderson@example.com', '2021-10-01', 72000, 5, 109, 4.30, ARRAY['Lab Techniques', 'Data Analysis']),
(111, 'Kevin', 'Spacey', 'kevin.spacey@example.com', '2020-05-15', 65000, 4, 107, 4.1, ARRAY['Digital Marketing', 'Analytics']),
(112, 'Laura', 'Palmer', 'laura.palmer@example.com', '2021-08-01', 90000, 5, 109, 4.7, ARRAY['Quantum Physics', 'Research']),
(113, 'Dale', 'Cooper', 'dale.cooper@example.com', '2019-09-10', 130000, 3, 105, 4.8, ARRAY['Strategic data_transformation_and_aggregation.Sales', 'Leadership']),
(114, 'Audrey', 'Horne', 'audrey.horne@example.com', '2022-03-20', 60000, 1, 103, NULL, ARRAY['Payroll', 'Conflict Resolution']);


-- Insert data into data_transformation_and_aggregation.Projects
INSERT INTO data_transformation_and_aggregation.Projects (projectId, projectName, startDate, deadlineDate, budget) VALUES
(1, 'Alpha Platform', '2023-01-01', '2023-12-31', 500000),
(2, 'Beta Feature', '2023-03-15', '2023-09-30', 150000),
(3, 'Gamma Initiative', '2023-06-01', '2024-05-31', 750000),
(4, 'Delta Rollout', '2022-11-01', '2023-07-30', 300000);

-- Insert data into data_transformation_and_aggregation.EmployeeProjects
INSERT INTO data_transformation_and_aggregation.EmployeeProjects (employeeId, projectId, hoursWorked, taskNotes) VALUES
(101, 1, 120, 'Developed core APIs'),
(102, 1, 100, 'Machine learning model integration'),
(104, 1, 150, 'Backend services for Alpha'),
(101, 2, 80, 'API refinement for Beta feature'),
(105, 3, 200, 'Sales strategy for Gamma'),
(106, 3, 180, 'Client acquisition for Gamma'),
(107, 4, 90, 'Marketing campaign for Delta'),
(109, 2, 110, 'Research for Beta feature improvements'),
(110, 2, 70, 'Data analysis for Beta feature testing'),
(102, 3, 50, 'Consulting on ML aspects for Gamma');

-- Insert data into data_transformation_and_aggregation.Regions
INSERT INTO data_transformation_and_aggregation.Regions (regionId, regionName) VALUES
(1, 'North'), (2, 'South'), (3, 'East'), (4, 'West'), (5, 'Central');

-- Insert data into data_transformation_and_aggregation.Products
INSERT INTO data_transformation_and_aggregation.Products (productId, productName, category, standardCost, listPrice) VALUES
(1, 'Laptop Pro', 'Electronics', 800, 1200),
(2, 'Smartphone X', 'Electronics', 400, 700),
(3, 'Office Chair', 'Furniture', 100, 250),
(4, 'Desk Lamp', 'Furniture', 20, 45),
(5, 'Software Suite', 'Software', 50, 150),
(6, 'Advanced CPU', 'Components', 250, 400),
(7, 'Graphics Card', 'Components', 300, 550);

-- Insert data into data_transformation_and_aggregation.Sales
INSERT INTO data_transformation_and_aggregation.Sales (saleId, productId, employeeId, saleDate, quantity, regionId, notes) VALUES
(1, 1, 105, '2022-01-20', 2, 1, '{"customerSatisfaction": 5, "followUpRequired": false}'),
(2, 2, 106, '2022-02-10', 5, 2, '{"customerSatisfaction": 4, "discountApplied": "10%"}'),
(3, 1, 105, '2022-02-15', 1, 1, '{"customerSatisfaction": 4, "followUpRequired": true, "feedback": "Needs faster shipping options"}'),
(4, 3, 106, '2022-03-05', 10, 3, NULL),
(5, 4, 105, '2023-03-22', 20, 4, '{"customerSatisfaction": 3}'),
(6, 5, 106, '2023-04-10', 50, 1, '{"customerSatisfaction": 5, "bulkOrder": true}'),
(7, 2, 105, '2023-04-18', 3, 2, '{"customerSatisfaction": 5}'),
(8, 1, 106, '2022-05-01', 2, 3, '{"notes": "Repeat customer"}'),
(9, 3, 105, '2022-05-25', 8, 4, NULL),
(10, 5, 106, '2023-06-11', 30, 5, '{"customerSatisfaction": 4, "followUpRequired": true}'),
(11, 6, 102, '2023-07-01', 5, 1, '{"source": "Tech Expo"}'),
(12, 7, 104, '2023-07-05', 3, 2, '{"source": "Internal Purchase"}'),
(13, 1, 105, '2022-01-25', 3, 1, '{"customerSatisfaction": 5}'),
(14, 2, 105, '2023-02-12', 2, 2, '{"customerSatisfaction": 3, "feedback": "Item was backordered"}'),
(15, 1, 106, '2023-01-30', 1, 1, NULL),
(16, 3, 113, '2022-08-15', 12, 2, '{"customerSatisfaction": 5}'),
(17, 4, 105, '2022-09-01', 25, 3, '{"customerSatisfaction": 4, "notes": "Urgent delivery"}'),
(18, 5, 106, '2023-08-20', 60, 4, '{"bulkOrder": true}'),
(19, 6, 113, '2023-09-05', 8, 5, NULL),
(20, 7, 105, '2023-10-10', 4, 1, '{"customerSatisfaction": 5, "followUpRequired": true}');

-- Update data for NULL examples
UPDATE data_transformation_and_aggregation.Employees SET departmentId = NULL WHERE employeeId = 108; -- Henry Moore has no department
UPDATE data_transformation_and_aggregation.Sales SET regionId = NULL WHERE saleId = 4; -- Sale 4 has no region
UPDATE data_transformation_and_aggregation.Products SET category = NULL WHERE productId = 4; -- Desk Lamp has no category