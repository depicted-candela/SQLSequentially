-- Dataset for PostgreSQL

-- Drop tables if they exist (for easy re-running of the script)
DROP TABLE IF EXISTS advanced_joins_aggregators.sales_data CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.project_assignments CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.projects CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.employees CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.departments CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.locations CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.job_grades CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.product_inventory CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.products CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.categories CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.product_info_natural CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.product_sales_natural CASCADE;
DROP TABLE IF EXISTS advanced_joins_aggregators.shift_schedules CASCADE;

-- Table Creation and Data Population

-- advanced_joins_aggregators.locations Table
CREATE TABLE advanced_joins_aggregators.locations (
    location_id SERIAL PRIMARY KEY,
    address VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(50)
);

INSERT INTO advanced_joins_aggregators.locations (address, city, country) VALUES
('123 Main St', 'New York', 'USA'),
('456 Oak Ave', 'London', 'UK'),
('789 Pine Ln', 'Tokyo', 'Japan'),
('101 Maple Dr', 'Berlin', 'Germany');

-- advanced_joins_aggregators.departments Table
CREATE TABLE advanced_joins_aggregators.departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    location_id INT,
    creation_date DATE DEFAULT CURRENT_DATE,
    department_budget NUMERIC(15,2),
    CONSTRAINT fk_location FOREIGN KEY (location_id) REFERENCES advanced_joins_aggregators.locations(location_id)
);

INSERT INTO advanced_joins_aggregators.departments (department_name, location_id, department_budget, creation_date) VALUES
('Human Resources', 1, 500000.00, '2020-01-15'),
('Engineering', 2, 2500000.00, '2019-03-10'),
('Sales', 1, 1200000.00, '2019-06-01'),
('Marketing', 2, 800000.00, '2020-05-20'),
('Research', 3, 1500000.00, '2021-02-01'),
('Support', NULL, 300000.00, '2021-07-10'); -- Department with no location

-- advanced_joins_aggregators.employees Table
CREATE TABLE advanced_joins_aggregators.employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone_number VARCHAR(20),
    hire_date DATE NOT NULL,
    job_title VARCHAR(50),
    salary NUMERIC(10, 2) CHECK (salary > 0),
    manager_id INT,
    department_id INT,
    performance_rating INT CHECK (performance_rating BETWEEN 1 AND 5) NULL, -- 1 (Low) to 5 (High)
    CONSTRAINT fk_manager FOREIGN KEY (manager_id) REFERENCES advanced_joins_aggregators.employees(employee_id),
    CONSTRAINT fk_department FOREIGN KEY (department_id) REFERENCES advanced_joins_aggregators.departments(department_id)
);

INSERT INTO advanced_joins_aggregators.employees (first_name, last_name, email, phone_number, hire_date, job_title, salary, manager_id, department_id, performance_rating) VALUES
('Alice', 'Smith', 'alice.smith@example.com', '555-0101', '2019-03-01', 'CEO', 150000.00, NULL, NULL, 5), -- CEO, no manager, initially no dept
('Bob', 'Johnson', 'bob.johnson@example.com', '555-0102', '2019-06-15', 'CTO', 120000.00, 1, 2, 5),
('Charlie', 'Williams', 'charlie.williams@example.com', '555-0103', '2019-07-01', 'Lead Engineer', 90000.00, 2, 2, 4),
('Diana', 'Brown', 'diana.brown@example.com', '555-0104', '2020-01-10', 'Software Engineer', 75000.00, 3, 2, 3),
('Edward', 'Jones', 'edward.jones@example.com', '555-0105', '2020-02-20', 'Software Engineer', 72000.00, 3, 2, 4),
('Fiona', 'Garcia', 'fiona.garcia@example.com', '555-0106', '2019-09-01', 'HR Manager', 85000.00, 1, 1, 5),
('George', 'Miller', 'george.miller@example.com', '555-0107', '2021-04-15', 'HR Specialist', 60000.00, 6, 1, 3),
('Hannah', 'Davis', 'hannah.davis@example.com', '555-0108', '2019-11-01', 'Sales Director', 110000.00, 1, 3, 4),
('Ian', 'Rodriguez', 'ian.rodriguez@example.com', '555-0109', '2022-01-05', 'Sales Associate', 65000.00, 8, 3, 3),
('Julia', 'Martinez', 'julia.martinez@example.com', '555-0110', '2022-03-10', 'Sales Associate', 62000.00, 8, 3, 2),
('Kevin', 'Hernandez', 'kevin.hernandez@example.com', '555-0111', '2020-07-01', 'Marketing Head', 95000.00, 1, 4, 4),
('Laura', 'Lopez', 'laura.lopez@example.com', '555-0112', '2022-05-01', 'Marketing Specialist', 58000.00, 11, 4, 3),
('Mike', 'Gonzalez', 'mike.gonzalez@example.com', '555-0113', '2021-08-01', 'Research Scientist', 88000.00, 1, 5, 5), -- Reports to CEO
('Nina', 'Wilson', 'nina.wilson@example.com', '555-0114', '2023-01-10', 'Junior Engineer', 60000.00, 3, 2, NULL), -- New hire, no rating yet
('Oscar', 'Anderson', 'oscar.anderson@example.com', '555-0115', '2020-11-01', 'Support Lead', 70000.00, 1, 6, 4);

UPDATE advanced_joins_aggregators.employees SET department_id = 1 WHERE first_name = 'Alice'; -- Assign CEO to HR for example

-- Job Grades (for CROSS JOIN)
CREATE TABLE advanced_joins_aggregators.job_grades (
    grade_level CHAR(1) PRIMARY KEY,
    description VARCHAR(50),
    min_salary NUMERIC(10,2),
    max_salary NUMERIC(10,2)
);

INSERT INTO advanced_joins_aggregators.job_grades (grade_level, description, min_salary, max_salary) VALUES
('A', 'Entry Level', 30000, 50000),
('B', 'Junior', 45000, 70000),
('C', 'Mid-Level', 65000, 90000),
('D', 'Senior', 85000, 120000),
('E', 'Executive', 110000, 200000);

-- Shift Schedules (for CROSS JOIN)
CREATE TABLE advanced_joins_aggregators.shift_schedules (
    schedule_id SERIAL PRIMARY KEY,
    shift_name VARCHAR(50) NOT NULL,
    start_time TIME,
    end_time TIME
);
INSERT INTO advanced_joins_aggregators.shift_schedules (shift_name, start_time, end_time) VALUES
('Morning Shift', '08:00:00', '16:00:00'),
('Evening Shift', '16:00:00', '00:00:00'),
('Night Shift', '00:00:00', '08:00:00');


--  advanced_joins_aggregators.projects Table
CREATE TABLE  advanced_joins_aggregators.projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    start_date DATE,
    end_date DATE,
    budget NUMERIC(12,2),
    department_id INT, -- Renamed from department_id_assign to department_id for NATURAL JOIN demo
    CONSTRAINT fk_proj_dept FOREIGN KEY (department_id) REFERENCES advanced_joins_aggregators.departments(department_id)
);

INSERT INTO  advanced_joins_aggregators.projects (project_name, start_date, end_date, budget, department_id) VALUES
('Project Alpha', '2023-01-15', '2023-12-31', 500000.00, 2),
('Project Beta', '2023-03-01', '2024-06-30', 1200000.00, 2),
('Project Gamma', '2023-05-10', '2023-11-30', 300000.00, 4),
('Project Delta', '2024-01-01', NULL, 750000.00, 5),
('Project Epsilon', '2023-02-01', '2023-08-31', 250000.00, 1);


-- Project Assignments Table
CREATE TABLE advanced_joins_aggregators.project_assignments (
    assignment_id SERIAL PRIMARY KEY,
    project_id INT,
    employee_id INT,
    role_in_project VARCHAR(50),
    assigned_date DATE,
    hours_allocated INT,
    CONSTRAINT fk_pa_project FOREIGN KEY (project_id) REFERENCES  advanced_joins_aggregators.projects(project_id),
    CONSTRAINT fk_pa_employee FOREIGN KEY (employee_id) REFERENCES advanced_joins_aggregators.employees(employee_id)
);

INSERT INTO advanced_joins_aggregators.project_assignments (project_id, employee_id, role_in_project, assigned_date, hours_allocated) VALUES
(1, 3, 'Lead Developer', '2023-01-10', 40),
(1, 4, 'Developer', '2023-01-12', 30),
(1, 5, 'Developer', '2023-01-12', 30),
(2, 2, 'Project Manager', '2023-02-25', 20),
(2, 3, 'Senior Developer', '2023-03-01', 40),
(3, 11, 'Marketing Lead', '2023-05-05', 35),
(3, 12, 'Marketing Assistant', '2023-05-08', 25),
(4, 13, 'Lead Researcher', '2023-12-20', 40),
(5, 7, 'HR Coordinator', '2023-01-30', 15);


-- advanced_joins_aggregators.categories Table
CREATE TABLE advanced_joins_aggregators.categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

INSERT INTO advanced_joins_aggregators.categories (category_name, description) VALUES
('Electronics', 'Devices and gadgets powered by electricity.'),
('Books', 'Printed and digital books across various genres.'),
('Clothing', 'Apparel for men, women, and children.'),
('Home Goods', 'Items for household use and decoration.'),
('Software', 'Applications and programs for computers and mobile devices.');

-- advanced_joins_aggregators.products Table
CREATE TABLE advanced_joins_aggregators.products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INT,
    supplier_id INT, -- Assuming a suppliers table exists, but not creating for brevity
    unit_price NUMERIC(10,2) CHECK (unit_price >= 0),
    common_code VARCHAR(10), -- For NATURAL JOIN example
    status VARCHAR(20) DEFAULT 'Active', -- For NATURAL JOIN example
    CONSTRAINT fk_prod_category FOREIGN KEY (category_id) REFERENCES advanced_joins_aggregators.categories(category_id)
);

INSERT INTO advanced_joins_aggregators.products (product_name, category_id, supplier_id, unit_price, common_code, status) VALUES
('Laptop Pro 15"', 1, 101, 1200.00, 'LP15', 'Active'),
('Smartphone X', 1, 102, 800.00, 'SPX', 'Active'),
('The SQL Mystery', 2, 201, 25.00, 'SQLM', 'Active'),
('Data Structures Algo', 2, 201, 45.00, 'DSA', 'Discontinued'),
('Men T-Shirt', 3, 301, 15.00, 'MTS', 'Active'),
('Women Jeans', 3, 302, 50.00, 'WJN', 'Active'),
('Coffee Maker', 4, 401, 75.00, 'CMK', 'Active'),
('Office Chair', 4, 402, 150.00, 'OCH', 'Backorder'),
('Antivirus Pro', 5, 501, 49.99, 'AVP', 'Active'),
('Photo Editor Plus', 5, 501, 89.99, 'PEP', 'Active'),
('Wireless Mouse', 1, 103, 22.50, 'WMS', 'Active'),
('History of Time', 2, 202, 18.00, 'HOT', 'Active');


-- Product Info (For NATURAL JOIN - intentional common columns)
CREATE TABLE advanced_joins_aggregators.product_info_natural (
    product_id INT PRIMARY KEY, -- Common column name 1
    common_code VARCHAR(10),    -- Common column name 2
    supplier_id INT,
    description TEXT,
    launch_date DATE
);
INSERT INTO advanced_joins_aggregators.product_info_natural (product_id, common_code, supplier_id, description, launch_date) VALUES
(1, 'LP15', 101, 'High-performance laptop', '2022-08-15'),
(2, 'SPX', 102, 'Latest generation smartphone', '2023-01-20'),
(3, 'SQLM', 201, 'A thrilling database mystery novel', '2021-05-10'),
(9, 'AVP', 501, 'Comprehensive antivirus solution', '2022-01-01');

-- Product Sales (For NATURAL JOIN - intentional common columns)
CREATE TABLE advanced_joins_aggregators.product_sales_natural (
    sale_id SERIAL PRIMARY KEY,
    product_id INT,          -- Common column name 1
    common_code VARCHAR(10), -- Common column name 2
    sale_date DATE,
    quantity_sold INT,
    customer_id_text VARCHAR(10) -- Using different name to avoid auto-join if it existed elsewhere
);
INSERT INTO advanced_joins_aggregators.product_sales_natural (product_id, common_code, sale_date, quantity_sold, customer_id_text) VALUES
(1, 'LP15', '2023-10-01', 5, 'CUST001'),
(2, 'SPX', '2023-10-05', 10, 'CUST002'),
(1, 'LP15', '2023-10-10', 3, 'CUST003'),
(9, 'AVP', '2023-11-01', 20, 'CUST004');


-- Sales Data Table (For Aggregators)
CREATE TABLE advanced_joins_aggregators.sales_data (
    sale_id SERIAL PRIMARY KEY,
    product_id INT,
    employee_id INT, -- Salesperson
    customer_id_text VARCHAR(10), -- Simulating a customer identifier
    sale_date TIMESTAMP,
    quantity_sold INT CHECK (quantity_sold > 0),
    unit_price_at_sale NUMERIC(10,2) CHECK (unit_price_at_sale >= 0),
    discount_percentage NUMERIC(4,2) DEFAULT 0 CHECK (discount_percentage BETWEEN 0 AND 1),
    region VARCHAR(50), -- e.g., 'North America', 'Europe', 'Asia'
    payment_method VARCHAR(20), -- e.g., 'Credit Card', 'PayPal', 'Cash'
    CONSTRAINT fk_sd_product FOREIGN KEY (product_id) REFERENCES advanced_joins_aggregators.products(product_id),
    CONSTRAINT fk_sd_employee FOREIGN KEY (employee_id) REFERENCES advanced_joins_aggregators.employees(employee_id)
);

INSERT INTO advanced_joins_aggregators.sales_data (product_id, employee_id, customer_id_text, sale_date, quantity_sold, unit_price_at_sale, discount_percentage, region, payment_method) VALUES
(1, 9, 'CUST001', '2023-01-15 10:30:00', 1, 1200.00, 0.05, 'North America', 'Credit Card'),
(2, 10, 'CUST002', '2023-01-20 14:00:00', 2, 800.00, 0.0, 'Europe', 'PayPal'),
(3, 9, 'CUST003', '2023-02-01 09:15:00', 5, 25.00, 0.1, 'Asia', 'Credit Card'),
(5, 10, 'CUST001', '2023-02-10 11:00:00', 3, 15.00, 0.0, 'North America', 'Cash'),
(7, 9, 'CUST004', '2023-03-05 16:45:00', 1, 75.00, 0.0, 'Europe', 'Credit Card'),
(9, 10, 'CUST002', '2023-03-12 10:00:00', 2, 49.99, 0.02, 'North America', 'PayPal'),
(10, 9, 'CUST005', '2023-04-01 13:20:00', 1, 89.99, 0.0, 'Asia', 'Credit Card'),
(1, 8, 'CUST006', '2023-04-10 09:00:00', 1, 1200.00, 0.1, 'Europe', 'Credit Card'), -- High perf employee (Hannah)
(4, 10, 'CUST001', '2023-05-01 17:00:00', 10, 45.00, 0.15, 'North America', 'Cash'), -- Large sale value
(6, 9, 'CUST007', '2023-05-15 11:30:00', 2, 50.00, 0.0, 'Europe', 'PayPal'),
(8, 10, 'CUST003', '2023-06-01 10:10:00', 1, 150.00, 0.05, 'Asia', 'Credit Card'),
(11, 8, 'CUST008', '2023-06-10 14:30:00', 4, 22.50, 0.0, 'North America', 'Credit Card'), -- High perf employee (Hannah)
(12, 9, 'CUST004', '2023-06-20 15:00:00', 3, 18.00, 0.0, 'Europe', 'Cash'),
(1, 10, 'CUST005', '2023-07-01 09:45:00', 1, 1150.00, 0.0, 'North America', 'PayPal'), -- Slightly lower price
(2, 8, 'CUST001', '2023-07-05 12:00:00', 1, 790.00, 0.0, 'Europe', 'Credit Card'), -- High perf employee (Hannah), high value
(3, 9, 'CUST002', '2023-01-17 10:30:00', 1, 25.00, 0.0, 'North America', 'Credit Card'), -- Same customer, different product
(5, 10, 'CUST003', '2023-02-15 11:00:00', 2, 15.00, 0.0, 'Asia', 'Cash'), -- Same customer
(7, 9, 'CUST001', '2023-03-08 16:45:00', 3, 70.00, 0.0, 'North America', 'Credit Card'), -- Same customer, high value sale > 200
(11, 13, 'CUST009', '2023-08-15 11:00:00', 2, 22.50, 0.0, 'Asia', 'PayPal');