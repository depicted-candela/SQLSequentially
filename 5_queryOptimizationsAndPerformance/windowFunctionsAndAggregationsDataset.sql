-- Drop tables if they exist
DROP TABLE IF EXISTS query_optimizations_and_performance.SalesTransactions CASCADE;
DROP TABLE IF EXISTS query_optimizations_and_performance.Products CASCADE;
DROP TABLE IF EXISTS query_optimizations_and_performance.Customers CASCADE;
DROP TABLE IF EXISTS query_optimizations_and_performance.Regions CASCADE;

-- Create query_optimizations_and_performance.Regions Table
CREATE TABLE query_optimizations_and_performance.Regions (
    regionId SERIAL PRIMARY KEY,
    regionName VARCHAR(50) NOT NULL UNIQUE
);

-- Create query_optimizations_and_performance.Customers Table
CREATE TABLE query_optimizations_and_performance.Customers (
    customerId SERIAL PRIMARY KEY,
    customerName VARCHAR(150) NOT NULL,
    regionId INT,
    joinDate DATE,
    CONSTRAINT fk_Region FOREIGN KEY (regionId) REFERENCES query_optimizations_and_performance.Regions(regionId)
);

-- Create query_optimizations_and_performance.Products Table
CREATE TABLE query_optimizations_and_performance.Products (
    productId SERIAL PRIMARY KEY,
    productName VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    launchDate DATE
);

-- Create query_optimizations_and_performance.SalesTransactions Table
CREATE TABLE query_optimizations_and_performance.SalesTransactions (
    transactionId BIGSERIAL PRIMARY KEY,
    productId INT NOT NULL,
    customerId INT NOT NULL,
    transactionDate TIMESTAMP NOT NULL,
    quantitySold INT NOT NULL,
    unitPrice NUMERIC(10, 2) NOT NULL,
    totalAmount NUMERIC(12, 2) NOT NULL,
    CONSTRAINT fk_Product FOREIGN KEY (productId) REFERENCES query_optimizations_and_performance.Products(productId),
    CONSTRAINT fk_Customer FOREIGN KEY (customerId) REFERENCES query_optimizations_and_performance.Customers(customerId)
);

-- Populate query_optimizations_and_performance.Regions
INSERT INTO query_optimizations_and_performance.Regions (regionName) VALUES
('North'), ('South'), ('East'), ('West'), ('Central');

-- Populate query_optimizations_and_performance.Customers (2,000 query_optimizations_and_performance.Customers)
INSERT INTO query_optimizations_and_performance.Customers (customerName, regionId, joinDate)
SELECT
    'Customer ' || i,
    (i % 5) + 1,
    CURRENT_DATE - (RANDOM() * 1000)::INT
FROM generate_series(1, 2000) s(i);

-- Populate query_optimizations_and_performance.Products (200 query_optimizations_and_performance.Products, 10 categories)
INSERT INTO query_optimizations_and_performance.Products (productName, category, launchDate)
SELECT
    'Product ' || i,
    'Category ' || ((i % 10) + 1),
    CURRENT_DATE - (RANDOM() * 700)::INT
FROM generate_series(1, 200) s(i);

-- Populate query_optimizations_and_performance.SalesTransactions (e.g., 1,500,000 rows for significant window function workload)
INSERT INTO query_optimizations_and_performance.SalesTransactions (productId, customerId, transactionDate, quantitySold, unitPrice, totalAmount)
SELECT
    (RANDOM() * 199)::INT + 1 AS prodId,        -- Generates productId from 1 to 199. Product 200 won't be included.
    (RANDOM() * 1999)::INT + 1 AS custId,       -- Generates customerId from 1 to 1999. Customer 2000 won't be included.
    TIMESTAMP '2021-01-01 00:00:00' +
        make_interval(days => (RANDOM() * 365 * 2.5)::INT, hours => (RANDOM() * 23)::INT, mins => (RANDOM() * 59)::INT),
    (RANDOM() * 5)::INT + 1 AS qty,
    ROUND((RANDOM() * 150 + 10)::NUMERIC, 2) AS price,
    0 -- totalAmount will be updated in the next step
FROM generate_series(1, 1500000) s(i);

-- Update totalAmount in query_optimizations_and_performance.SalesTransactions
UPDATE query_optimizations_and_performance.SalesTransactions SET totalAmount = quantitySold * unitPrice;

-- Indexes for optimization examples
CREATE INDEX IF NOT EXISTS idx_SalesTransactions_Date ON query_optimizations_and_performance.SalesTransactions (transactionDate);
CREATE INDEX IF NOT EXISTS idx_SalesTransactions_ProdCustDate ON query_optimizations_and_performance.SalesTransactions (productId, customerId, transactionDate);
CREATE INDEX IF NOT EXISTS idx_SalesTransactions_CustDate ON query_optimizations_and_performance.SalesTransactions (customerId, transactionDate);
CREATE INDEX IF NOT EXISTS idx_Products_Category ON query_optimizations_and_performance.Products (category);
CREATE INDEX IF NOT EXISTS idx_Customers_RegionId ON query_optimizations_and_performance.Customers (regionId);