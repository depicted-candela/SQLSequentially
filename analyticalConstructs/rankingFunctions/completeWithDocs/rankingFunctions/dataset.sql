-- Dataset for PostgreSQL

DROP TABLE IF EXISTS product_sales;
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    hire_date DATE
);

INSERT INTO employees (employee_id, first_name, last_name, department, salary, hire_date) VALUES
(1, 'Alice', 'Smith', 'HR', 60000.00, '2020-01-15'),
(2, 'Bob', 'Johnson', 'HR', 65000.00, '2019-07-01'),
(3, 'Charlie', 'Williams', 'IT', 80000.00, '2021-03-10'),
(4, 'David', 'Brown', 'IT', 90000.00, '2018-05-20'),
(5, 'Eve', 'Jones', 'IT', 80000.00, '2022-01-05'),
(6, 'Frank', 'Garcia', 'Finance', 75000.00, '2020-11-01'),
(7, 'Grace', 'Miller', 'Finance', 75000.00, '2021-06-15'),
(8, 'Henry', 'Davis', 'Marketing', 70000.00, '2019-02-28'),
(9, 'Ivy', 'Rodriguez', 'Marketing', 72000.00, '2023-01-10'),
(10, 'Jack', 'Wilson', 'Marketing', 70000.00, '2020-08-15'),
(11, 'Karen', 'Moore', 'HR', 60000.00, '2021-09-01'),
(12, 'Liam', 'Taylor', 'IT', 95000.00, '2023-03-01');

CREATE TABLE product_sales (
    sale_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    sale_date DATE,
    sale_amount DECIMAL(10, 2),
    quantity_sold INT
);

INSERT INTO product_sales (sale_id, product_name, category, sale_date, sale_amount, quantity_sold) VALUES
(1, 'Laptop Pro', 'Electronics', '2023-01-10', 1200.00, 5),
(2, 'Smartphone X', 'Electronics', '2023-01-12', 800.00, 10),
(3, 'Office Chair', 'Furniture', '2023-01-15', 150.00, 20),
(4, 'Desk Lamp', 'Furniture', '2023-01-18', 40.00, 30),
(5, 'Laptop Pro', 'Electronics', '2023-02-05', 1200.00, 3),
(6, 'Gaming Mouse', 'Electronics', '2023-02-10', 75.00, 50),
(7, 'Smartphone X', 'Electronics', '2023-02-15', 780.00, 8),
(8, 'Bookshelf', 'Furniture', '2023-02-20', 200.00, 10),
(9, 'Laptop Pro', 'Electronics', '2023-03-01', 1150.00, 4),
(10, 'External HDD', 'Electronics', '2023-03-05', 100.00, 25),
(11, 'Office Chair', 'Furniture', '2023-03-10', 140.00, 15),
(12, 'Desk Lamp', 'Furniture', '2023-03-15', 35.00, 40),
(13, 'Smartphone Y', 'Electronics', '2023-03-20', 900.00, 12),
(14, 'Coffee Maker', 'Appliances', '2023-01-20', 60.00, 10),
(15, 'Toaster', 'Appliances', '2023-02-25', 30.00, 15),
(16, 'Blender', 'Appliances', '2023-03-01', 50.00, 8);