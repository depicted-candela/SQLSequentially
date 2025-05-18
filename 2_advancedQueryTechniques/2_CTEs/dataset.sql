-- Common Table Expressions - CTEs
-- Advanced Query Techniques: Exercises
-- May 17, 2025

-- Global Dataset for PostgreSQL

-- Dataset for Category (i)
CREATE TABLE advanced_query_techniques.DepartmentsI (
    departmentId INTEGER PRIMARY KEY,
    departmentName VARCHAR(100) NOT NULL,
    locationCity VARCHAR(50)
);

CREATE TABLE advanced_query_techniques.EmployeesI (
    employeeId INTEGER PRIMARY KEY,
    employeeName VARCHAR(100) NOT NULL,
    departmentId INTEGER REFERENCES advanced_query_techniques.DepartmentsI(departmentId),
    managerId INTEGER REFERENCES advanced_query_techniques.EmployeesI(employeeId), -- Self-reference for hierarchy
    salary DECIMAL(10, 2) NOT NULL,
    hireDate DATE NOT NULL
);

INSERT INTO advanced_query_techniques.DepartmentsI (departmentId, departmentName, locationCity) VALUES
(1, 'Technology', 'New York'),
(2, 'Human Resources', 'London'),
(3, 'Sales', 'Tokyo'),
(4, 'Marketing', 'Paris');

INSERT INTO advanced_query_techniques.EmployeesI (employeeId, employeeName, departmentId, managerId, salary, hireDate) VALUES
(101, 'Alice Wonderland', 1, NULL, 120000.00, '2018-03-15'),
(102, 'Bob The Builder', 1, 101, 90000.00, '2019-07-01'),
(103, 'Charlie Brown', 1, 102, 80000.00, '2020-01-10'),
(104, 'Diana Prince', 2, NULL, 110000.00, '2017-05-20'),
(105, 'Eve Harrington', 2, 104, 75000.00, '2021-02-28'),
(106, 'Frankenstein Monster', 3, NULL, 130000.00, '2018-11-01'),
(107, 'Grace Malley', 3, 106, 85000.00, '2019-05-15'),
(108, 'Henry Jekyll', 3, 106, 82000.00, '2022-08-20'),
(109, 'Ivy Pepper', 1, 101, 95000.00, '2020-06-01'),
(110, 'John Doe', NULL, 101, 60000.00, '2023-01-15');

-- Dataset for Category (ii)
CREATE TABLE advanced_query_techniques.ProductCategoriesII (
    categoryId SERIAL PRIMARY KEY,
    categoryName VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE advanced_query_techniques.ProductsII (
    productId SERIAL PRIMARY KEY,
    productName VARCHAR(100) NOT NULL,
    categoryId INTEGER REFERENCES advanced_query_techniques.ProductCategoriesII(categoryId),
    basePrice DECIMAL(10,2)
);

CREATE TABLE advanced_query_techniques.SalesTransactionsII (
    transactionId SERIAL PRIMARY KEY,
    productId INTEGER REFERENCES advanced_query_techniques.ProductsII(productId),
    saleDate TIMESTAMP NOT NULL,
    quantitySold INTEGER NOT NULL,
    discount DECIMAL(3,2) DEFAULT 0.00
);

INSERT INTO advanced_query_techniques.ProductCategoriesII (categoryName) VALUES ('Electronics'), ('Books'), ('Home Goods');

INSERT INTO advanced_query_techniques.ProductsII (productName, categoryId, basePrice) VALUES
('Laptop Pro', 1, 1200.00), ('Quantum Physics Primer', 2, 25.00), ('Smart LED Bulb', 3, 15.00),
('Desktop Gamer', 1, 1800.00), ('History of Time', 2, 20.00), ('Robotic Vacuum', 3, 300.00);

DO $$
DECLARE
    i INT;
    pId INT;
    sDate TIMESTAMP;
    qty INT;
BEGIN
    FOR i IN 1..10000 LOOP
        pId := (MOD(i, 6)) + 1;
        sDate := CURRENT_TIMESTAMP - (MOD(i,365) || ' days')::INTERVAL - (MOD(i,24) || ' hours')::INTERVAL;
        qty := (MOD(i, 5)) + 1;
        INSERT INTO advanced_query_techniques.SalesTransactionsII (productId, saleDate, quantitySold, discount)
        VALUES (pId, sDate, qty, CASE WHEN MOD(i,10) = 0 THEN 0.05 ELSE 0.00 END);
    END LOOP;
END $$;

UPDATE advanced_query_techniques.SalesTransactionsII
SET saleDate = CURRENT_DATE - INTERVAL '1 month' + (MOD(transactionId, 30) || ' days')::INTERVAL
WHERE MOD(productId, 2) = 0; -- Update some products to have recent sales

-- Dataset for Category (iii)
CREATE TABLE advanced_query_techniques.CustomersIII (
    customerId SERIAL PRIMARY KEY,
    customerName VARCHAR(100) NOT NULL,
    registrationDate DATE,
    city VARCHAR(50)
);

CREATE TABLE advanced_query_techniques.ProductsMasterIII (
    productId SERIAL PRIMARY KEY,
    productName VARCHAR(100),
    category VARCHAR(50)
);

CREATE TABLE advanced_query_techniques.OrdersIII (
    orderId SERIAL PRIMARY KEY,
    customerId INTEGER REFERENCES advanced_query_techniques.CustomersIII(customerId),
    orderDate DATE,
    shipmentRegion VARCHAR(50)
);

CREATE TABLE advanced_query_techniques.OrderItemsIII (
    orderItemId SERIAL PRIMARY KEY,
    orderId INTEGER REFERENCES advanced_query_techniques.OrdersIII(orderId),
    productId INTEGER REFERENCES advanced_query_techniques.ProductsMasterIII(productId),
    quantity INTEGER,
    pricePerUnit DECIMAL(10,2)
);

INSERT INTO advanced_query_techniques.CustomersIII (customerName, registrationDate, city) VALUES
('Global Corp', '2020-01-15', 'New York'), ('Local Biz', '2021-06-01', 'London'),
('Alpha Inc', '2019-11-20', 'Tokyo'), ('Beta LLC', '2022-03-10', 'New York');

INSERT INTO advanced_query_techniques.ProductsMasterIII (productName, category) VALUES
('Widget A', 'Gadgets'), ('Widget B', 'Gizmos'), ('Service C', 'Services'), ('Tool D', 'Tools');

INSERT INTO advanced_query_techniques.OrdersIII (customerId, orderDate, shipmentRegion) VALUES
(1, '2022-02-10', 'North America'), (2, '2022-03-15', 'Europe'),
(1, '2023-04-20', 'North America'), (3, '2023-05-05', 'Asia'),
(2, '2023-06-10', 'Europe'), (4, '2022-07-01', 'North America');

INSERT INTO advanced_query_techniques.OrderItemsIII (orderId, productId, quantity, pricePerUnit) VALUES
(1, 1, 10, 50.00), (1, 2, 5, 100.00), (2, 3, 1, 200.00),
(3, 1, 20, 45.00), (3, 4, 2, 150.00), (4, 2, 8, 95.00),
(5, 3, 2, 190.00), (6, 4, 3, 140.00);

-- Dataset for Category (iv)
CREATE TABLE advanced_query_techniques.DepartmentsIV (
    departmentId SERIAL PRIMARY KEY,
    departmentName VARCHAR(100) NOT NULL,
    headEmployeeId INTEGER -- Nullable, to be cross-referenced with advanced_query_techniques.EmployeesIV
);

CREATE TABLE advanced_query_techniques.EmployeesIV (
    employeeId SERIAL PRIMARY KEY,
    employeeName VARCHAR(100) NOT NULL,
    departmentId INTEGER REFERENCES advanced_query_techniques.DepartmentsIV(departmentId),
    managerId INTEGER REFERENCES advanced_query_techniques.EmployeesIV(employeeId), -- For hierarchy
    salary DECIMAL(10, 2) NOT NULL,
    hireDate DATE NOT NULL
);

ALTER TABLE advanced_query_techniques.DepartmentsIV ADD CONSTRAINT fkHeadEmployee FOREIGN KEY (headEmployeeId)
REFERENCES advanced_query_techniques.EmployeesIV(employeeId) DEFERRABLE INITIALLY DEFERRED;

INSERT INTO advanced_query_techniques.DepartmentsIV (departmentId, departmentName) VALUES
(1, 'Engineering'), (2, 'Product Management'), (3, 'Research & Development'), (4, 'Operations');

INSERT INTO advanced_query_techniques.EmployeesIV (employeeId, employeeName, departmentId, managerId, salary, hireDate) VALUES
(1, 'Ava CEO', 1, NULL, 250000, '2015-01-01'),
(2, 'Brian Lead', 1, 1, 150000, '2018-06-01'),
(3, 'Chloe SeniorDev', 1, 2, 110000, '2020-03-15'),
(4, 'David JuniorDev', 1, 3, 75000, '2022-07-01'),
(5, 'Eli PMHead', 2, 1, 160000, '2017-09-01'),
(6, 'Fiona SeniorPM', 2, 5, 120000, '2020-11-01'),
(7, 'George PM', 2, 6, 85000, '2021-05-10'),
(8, 'Hannah RDHead', 3, 1, 170000, '2016-04-12'),
(9, 'Ian SeniorScientist', 3, 8, 130000, '2021-01-20'),
(10, 'Julia Scientist', 3, 9, 90000, '2022-08-01'),
(11, 'Kevin OpsLead', 4, 1, 140000, '2019-02-10'),
(12, 'Liam OpsSpecialist', 4, 11, 95000, '2021-10-05'),
(13, 'Mike AnotherDev', 1, 2, 105000, '2021-02-01');

UPDATE advanced_query_techniques.DepartmentsIV SET headEmployeeId = 2 WHERE departmentName = 'Engineering';
UPDATE advanced_query_techniques.DepartmentsIV SET headEmployeeId = 5 WHERE departmentName = 'Product Management';
UPDATE advanced_query_techniques.DepartmentsIV SET headEmployeeId = 8 WHERE departmentName = 'Research & Development';
UPDATE advanced_query_techniques.DepartmentsIV SET headEmployeeId = 11 WHERE departmentName = 'Operations';

CREATE TABLE advanced_query_techniques.ProjectsIV (
    projectId SERIAL PRIMARY KEY,
    projectName VARCHAR(150) NOT NULL,
    startDate DATE,
    endDate DATE,
    budget DECIMAL(12, 2)
);

CREATE TABLE advanced_query_techniques.TasksIV (
    taskId SERIAL PRIMARY KEY,
    projectId INTEGER REFERENCES advanced_query_techniques.ProjectsIV(projectId),
    taskName VARCHAR(200),
    assignedToEmployeeId INTEGER REFERENCES advanced_query_techniques.EmployeesIV(employeeId),
    estimatedHours INTEGER,
    actualHours INTEGER,
    status VARCHAR(20)
);

CREATE TABLE advanced_query_techniques.TimeLogsIV (
    logId SERIAL PRIMARY KEY,
    taskId INTEGER REFERENCES advanced_query_techniques.TasksIV(taskId),
    employeeId INTEGER REFERENCES advanced_query_techniques.EmployeesIV(employeeId),
    logDate DATE NOT NULL,
    hoursWorked DECIMAL(5,2) NOT NULL,
    notes TEXT
);

INSERT INTO advanced_query_techniques.ProjectsIV (projectName, startDate, endDate, budget) VALUES
('Alpha Core System', '2022-01-01', '2023-12-31', 200000.00),
('Beta Mobile App', '2023-03-01', '2024-02-28', 80000.00),
('Gamma Research Initiative', '2021-06-15', '2023-05-30', 160000.00),
('Delta Operations Upgrade', '2023-07-01', NULL, 120000.00);

INSERT INTO advanced_query_techniques.TasksIV (projectId, taskName, assignedToEmployeeId, estimatedHours, actualHours, status) VALUES
(1, 'Design Alpha Architecture', 3, 100, 90, 'Completed'),
(1, 'Develop Alpha Module 1', 3, 150, 160, 'In Progress'),
(2, 'Beta UI/UX Design', 6, 80, 70, 'Completed'),
(2, 'Beta Backend Dev', 7, 120, 50, 'In Progress'),
(3, 'Gamma Initial Research', 9, 200, 180, 'Completed'),
(3, 'Gamma Experiment Setup', 9, 100, 110, 'Overdue'),
(4, 'Delta Process Analysis', 12, 60, 40, 'In Progress'),
(1, 'Alpha Documentation', 13, 80, 0, 'Pending');

-- The next task inserted will have taskId = 9 (due to SERIAL on previous 8 inserts)
INSERT INTO advanced_query_techniques.TasksIV (projectId, taskName, assignedToEmployeeId, estimatedHours, actualHours, status) VALUES
(2, 'Cross-project review for Alpha', 3, 20, 0, 'Pending');

INSERT INTO advanced_query_techniques.TimeLogsIV (logId, taskId, employeeId, logDate, hoursWorked, notes) VALUES
(DEFAULT, 1, 3, '2022-03-01', 8.0, 'Initial design'), (DEFAULT, 1, 3, '2022-03-02', 8.0, 'Refinement'),
(DEFAULT, 2, 3, '2022-04-01', 8.0, 'Dev start'), (DEFAULT, 2, 3, '2022-04-02', 8.0, 'Core logic'),
(DEFAULT, 3, 6, '2023-03-10', 7.0, 'UX flows'),
(DEFAULT, 5, 9, '2021-07-01', 6.0, 'Literature review'), (DEFAULT, 5, 9, '2021-07-02', 8.0, 'Planning'),
(DEFAULT, 6, 9, '2021-09-01', 8.0, 'Setup phase 1'), (DEFAULT, 6, 9, '2021-09-02', 5.0, 'Troubleshooting setup'),
(DEFAULT, 7, 12, '2023-07-15', 8.0, 'Mapping current state'),
(DEFAULT, 8, 13, '2022-05-01', 4.0, 'Doc outline');
-- logId values will be 1 to 11 after these inserts

INSERT INTO advanced_query_techniques.TimeLogsIV (logId, taskId, employeeId, logDate, hoursWorked, notes) VALUES
(DEFAULT, 2, 3, '2022-04-03', 8.0, 'Task 2 for emp 3'), -- emp 3 (Chloe) on task 2 (project 1), logId 12
(DEFAULT, 4, 7, '2023-08-01', 5.0, 'Task 4 for emp 7'), -- emp 7 (George) on task 4 (project 2), logId 13
(DEFAULT, 9, 3, '2023-09-01', 3.0, 'Time for task 9, project 2'); -- emp 3 works on task 9 (project 2), logId 14