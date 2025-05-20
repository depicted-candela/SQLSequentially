-- Dataset for Exercises
-- Drop tables if they exist to ensure a clean setup
DROP TABLE IF EXISTS data_transformation_and_aggregation.EventCalendar CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.ProjectAssignments CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.Employees CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.SystemLogs CASCADE;
DROP TABLE IF EXISTS data_transformation_and_aggregation.ServiceSubscriptions CASCADE;

-- Create Tables
CREATE TABLE data_transformation_and_aggregation.Employees (
    employeeId INT PRIMARY KEY,
    employeeName VARCHAR(100) NOT NULL,
    hireDate DATE NOT NULL,
    department VARCHAR (50),
    skills TEXT[], -- For unnest, array_append, array_length
    performanceReviews JSONB -- For JSON functions, e.g., '[{"year": 2022, "rating": 4, "note": "Good progress"}, ...]'
);

CREATE TABLE data_transformation_and_aggregation.ProjectAssignments (
    assignmentId SERIAL PRIMARY KEY,
    projectId INT NOT NULL,
    projectName VARCHAR(100),
    employeeId INT REFERENCES data_transformation_and_aggregation.Employees (employeeId),
    role VARCHAR(50),
    assignmentHours INT,
    assignmentData JSONB -- e.g., '{ "milestones": [{"name": "Phase 1", "status": "completed"}, {"name": "Phase 2", "status": "pending"}], "budget": 5000.00 }'
);

CREATE TABLE data_transformation_and_aggregation.SystemLogs (
    logId SERIAL PRIMARY KEY,
    logTimestamp TIMESTAMP NOT NULL,
    serviceName VARCHAR(50),
    logLevel VARCHAR (10), -- e.g., INFO, ERROR, WARN
    logDetails JSONB -- e.g., '{ "clientIp": "192.168.1.10", "requestPath": "/api/data", "statusCode": 200, "userContext": {"userId": 101, "sessionId": "xyz"} }'
);

CREATE TABLE data_transformation_and_aggregation.ServiceSubscriptions (
    subscriptionId SERIAL PRIMARY KEY,
    userId INT,
    customerName VARCHAR(100),
    serviceType VARCHAR (50),
    startDate DATE NOT NULL,
    endDate DATE, -- Can be NULL for ongoing subscriptions
    monthlyFee DECIMAL (10,2),
    features JSONB -- e.g., '{ "storageLimitGB": 50, "prioritySupport": true, "addons": ["backup", "monitoring"] }'
);

CREATE TABLE data_transformation_and_aggregation.EventCalendar (
    eventId SERIAL PRIMARY KEY,
    eventName VARCHAR(100),
    eventCategory VARCHAR(50),
    eventStartDate DATE,
    eventEndDate DATE,
    expectedAttendees INT,
    bookedResources TEXT [] -- e.g., '{"Room A", "Projector X"}'
);

-- Populate Tables
INSERT INTO data_transformation_and_aggregation.Employees (employeeId, employeeName, hireDate, department, skills, performanceReviews) VALUES
(1, 'Alice Wonderland', '2020-01-15', 'Engineering', ARRAY ['SQL', 'Python', 'Data Analysis'], '[{"year": 2022, "rating": 4, "note": "Exceeded expectations in Q3"}, {"year": 2023, "rating": 5, "note": "Top performer"}]'),
(2, 'Bob The Builder', '2019-03-01', 'Engineering', ARRAY['Java', 'Spring', 'Microservices'], '[{"year": 2022, "rating": 3, "notes": "Met expectations"}, {"year": 2023, "rating": 4, "note": "Improved significantly"}]'),
(3, 'Charlie Brown', '2021-07-30', 'Sales', ARRAY['Communication', 'Negotiation', 'CRM'], '[{"year": 2023, "rating": 4, "note": "Good sales figures"}]'),
(4, 'Diana Prince', '2018-05-10', 'HR', ARRAY['Recruitment', 'Employee Relations', 'Legal Knowledge'], NULL),
(5, 'Edward Scissorhands', '2022-11-01', 'Engineering', ARRAY ['Python', 'Machine Learning'], '[{"year": 2023, "rating": 5, "note": "Innovative solutions"}]'),
(6, 'Fiona Gallagher', '2023-02-15', 'Sales', ARRAY['CRM', 'Presentations'], '[]'), -- Empty JSON array
(7, 'George Jetson', '2017-09-01', 'Management', ARRAY ['Leadership', 'Strategy'], '[{"year": 2022, "rating": 5, "notes": "Excellent leadership"}, {"year": 2023, "rating": 4, "note": "Managed team well through transition"}]');

INSERT INTO data_transformation_and_aggregation.ProjectAssignments (projectId, projectName, employeeId, role, assignmentHours, assignmentData) VALUES
(101, 'Data Warehouse Migration', 1, 'Lead Data Engineer', 120, '{ "milestones": [{"name": "Schema Design", "status": "completed"}, {"name": "ETL Development", "status": "in-progress"}], "budget": 20000.00, "critical": true }'),
(101, 'Data Warehouse Migration', 2, 'Backend Developer', 80, '{ "milestones": [{"name": "API Integration", "status": "pending"}], "budget": 15000.00, "critical": true }'),
(102, 'Mobile App Development', 2, 'Lead Mobile Developer', 150, '{ "milestones": [{"name": "UI/UX Design", "status": "completed"}, {"name": "Frontend Dev", "status": "completed"}, {"name": "Backend Dev", "status": "in-progress"}], "budget": 50000.00, "critical": false }'),
(103, 'Sales Platform Upgrade', 3, 'Sales Lead', 100, '{ "milestones": [{"name": "Requirement Gathering", "status": "completed"}], "budget": 10000.00, "critical": false }'),
(101, 'Data Warehouse Migration', 5, 'ML Engineer', 60, '{ "milestones": [{"name": "Model Training", "status": "in-progress"}], "budget": 12000.00, "critical": true }'),
(104, 'HR System Implementation', 4, 'HR Specialist', 90, NULL); -- No JSON data

INSERT INTO data_transformation_and_aggregation.SystemLogs (logTimestamp, serviceName, logLevel, logDetails) VALUES
('2023-10-01 10:00:00', 'AuthService', 'INFO', '{ "message": "User login successful", "userId": 1, "clientIp": "192.168.0.10" }'),
('2023-10-01 10:05:00', 'OrderService', 'ERROR', '{ "message": "Payment processing failed", "orderId": 123, "errorCode": "P5001", "details": { "reason": "Insufficient funds"}}'),
('2023-10-01 10:10:00', 'ProductService', 'WARN', '{ "message": "Low stock warning", "productId": "XYZ123", "currentStock": 5 }'),
('2023-10-02 11:00:00', 'AuthService', 'INFO', '{ "message": "User login successful", "userId": 2, "clientIp": "192.168.0.15" }'),
('2023-10-02 11:15:00', 'OrderService', 'INFO', '{ "message": "Order placed", "orderId": 124, "items": ["itemA", "itemB"], "totalAmount": 75.50 }'),
(NOW() - INTERVAL '1 day', 'Reporting Service', 'DEBUG', '{ "queryId": "q123", "executionTimeMs": 1500, "parameters": {"startDate": "2023-01-01", "endDate": "2023-01-31"}}');

INSERT INTO data_transformation_and_aggregation.ServiceSubscriptions (userId, customerName, serviceType, startDate, endDate, monthlyFee, features) VALUES
(101, 'Customer Alpha', 'Premium Cloud Storage', '2023-01-01', '2023-12-31', 20.00, '{ "storageLimitGB": 100, "prioritySupport": true, "addons": [ "versioning", "encryption" ] }'),
(102, 'Customer Beta', 'Basic VPN Service', '2023-03-15', NULL, 5.00, '{ "dataCapMB": 5000, "prioritySupport": false, "serverLocations": ["US", "EU"] }'),
(103, 'Customer Gamma', 'Standard Streaming', '2023-05-01', '2024-04-30', 10.00, '{ "resolution": "1080p", "profiles": 4, "offlineDownload": true }'),
(101, 'Customer Alpha', 'Analytics Suite', '2023-06-01', NULL, 50.00, '{ "users": 5, "dashboards": 10, "dataSources": ["db1", "s3"] }'),
(104, 'Customer Delta', 'Premium Cloud Storage', '2022-11-01','2023-11-01', 18.00, '{ "storageLimitGB": 100, "prioritySupport": true, "addons": ["backup"] }');

INSERT INTO data_transformation_and_aggregation.EventCalendar (eventName, eventCategory, eventStartDate, eventEndDate, expectedAttendees, bookedResources) VALUES
('Tech Conference 2024', 'Conference', '2024-03-10', '2024-03-12', 500, ARRAY ['Main Hall', 'Audio System', 'Projectors']),
('Product Launch Q1', 'Marketing', '2024-02-15', '2024-02-15', 100, ARRAY ['Meeting Room Alpha', 'Catering Service']),
('Team Building Workshop', 'HR', '2024-04-05', '2024-04-05', 30, ARRAY ['Outdoor Space', 'Activity Kits']),
('Quarterly Review Meeting', 'Management', '2024-01-20', '2024-01-20', 15, ARRAY ['Board Room']),
('Holiday Party 2023', 'Social', '2023-12-15', '2023-12-15', 150, NULL); -- No resources booked