-- Dataset for Navigation Functions Exercises
-- This dataset will be used for all exercises below.
-- It represents fictional employee performance metrics over time.

CREATE TABLE navigate_functions.employee_performance (
    perf_id SERIAL PRIMARY KEY,
    employee_id INT,
    employee_name VARCHAR(50),
    department VARCHAR(50),
    metric_date DATE,
    sales_amount DECIMAL(10, 2),
    tasks_completed INT
);

INSERT INTO navigate_functions.employee_performance (employee_id, employee_name, department, metric_date, sales_amount, tasks_completed) VALUES
-- Alice Smith (Sales)
(101, 'Alice Smith', 'Sales', '2023-01-05', 1500.00, 5),
(101, 'Alice Smith', 'Sales', '2023-01-12', 1700.00, 7),
(101, 'Alice Smith', 'Sales', '2023-01-19', 1600.00, 6),
(101, 'Alice Smith', 'Sales', '2023-02-03', 1800.00, 8),
(101, 'Alice Smith', 'Sales', '2023-02-10', 1750.00, 5),
(101, 'Alice Smith', 'Sales', '2023-03-05', 2000.00, 9),

-- Bob Johnson (Sales)
(102, 'Bob Johnson', 'Sales', '2023-01-08', 1200.00, 4),
(102, 'Bob Johnson', 'Sales', '2023-01-15', 1300.00, 6),
(102, 'Bob Johnson', 'Sales', '2023-02-05', 1100.00, 3),
(102, 'Bob Johnson', 'Sales', '2023-02-12', 1400.00, 7),
(102, 'Bob Johnson', 'Sales', '2023-03-10', 1500.00, 5),

-- Carol Davis (Engineering)
(201, 'Carol Davis', 'Engineering', '2023-01-10', 50.00, 10), -- Assuming minor sales for cross-functional tasks or internal transfers
(201, 'Carol Davis', 'Engineering', '2023-01-17', 70.00, 12),
(201, 'Carol Davis', 'Engineering', '2023-01-24', 60.00, 8),
(201, 'Carol Davis', 'Engineering', '2023-02-07', 80.00, 11),
(201, 'Carol Davis', 'Engineering', '2023-02-14', 75.00, 13),
(201, 'Carol Davis', 'Engineering', '2023-03-08', 90.00, 9),

-- David Wilson (Engineering)
(202, 'David Wilson', 'Engineering', '2023-01-05', 40.00, 7),
(202, 'David Wilson', 'Engineering', '2023-01-12', 60.00, 9),
(202, 'David Wilson', 'Engineering', '2023-02-03', 30.00, 6),
(202, 'David Wilson', 'Engineering', '2023-02-10', 65.00, 10),
(202, 'David Wilson', 'Engineering', '2023-03-05', 55.00, 8),

-- Eva Brown (Marketing)
(301, 'Eva Brown', 'Marketing', '2023-01-15', 500.00, 3),
(301, 'Eva Brown', 'Marketing', '2023-02-20', 600.00, 4),
(301, 'Eva Brown', 'Marketing', '2023-03-25', 550.00, 2);
