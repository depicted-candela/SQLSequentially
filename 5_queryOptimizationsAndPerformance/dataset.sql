-- Drop tables if they exist to ensure a clean setup
DROP TABLE IF EXISTS query_optimizations_and_performance.EmployeeProjects CASCADE;
DROP TABLE IF EXISTS query_optimizations_and_performance.Employees CASCADE;
DROP TABLE IF EXISTS query_optimizations_and_performance.Projects CASCADE;
DROP TABLE IF EXISTS query_optimizations_and_performance.Departments CASCADE;

-- Create query_optimizations_and_performance.Departments Table
CREATE TABLE query_optimizations_and_performance.Departments (
    departmentId SERIAL PRIMARY KEY,
    departmentName VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100)
);

-- Create query_optimizations_and_performance.Projects Table
CREATE TABLE query_optimizations_and_performance.Projects (
    projectId SERIAL PRIMARY KEY,
    projectName VARCHAR(150) NOT NULL UNIQUE,
    startDate DATE,
    endDate DATE,
    projectDescription TEXT -- For GIN/GiST index example
);

-- Create query_optimizations_and_performance.Employees Table
CREATE TABLE query_optimizations_and_performance.Employees (
    employeeId SERIAL PRIMARY KEY,
    firstName VARCHAR(50) NOT NULL,
    lastName VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE, -- Automatically indexed due to UNIQUE constraint
    departmentId INT,
    salary NUMERIC(10, 2),
    hireDate DATE,
    jobTitle VARCHAR(100),
    performanceScore REAL,
    status VARCHAR(20) DEFAULT 'Active', -- Low cardinality column example
    CONSTRAINT fkDepartment FOREIGN KEY (departmentId) REFERENCES query_optimizations_and_performance.Departments(departmentId)
);

-- Create query_optimizations_and_performance.EmployeeProjects Table (Junction Table)
CREATE TABLE query_optimizations_and_performance.EmployeeProjects (
    employeeProjectId SERIAL PRIMARY KEY,
    employeeId INT,
    projectId INT,
    roleInProject VARCHAR(100),
    CONSTRAINT fkEmployee FOREIGN KEY (employeeId) REFERENCES query_optimizations_and_performance.Employees(employeeId) ON DELETE CASCADE,
    CONSTRAINT fkProject FOREIGN KEY (projectId) REFERENCES query_optimizations_and_performance.Projects(projectId) ON DELETE CASCADE,
    UNIQUE (employeeId, projectId)
);

-- Populate query_optimizations_and_performance.Departments
INSERT INTO query_optimizations_and_performance.Departments (departmentName, location) VALUES
('Human Resources', 'Building A, Floor 1'), ('Engineering', 'Building B, Floor 2'),
('Marketing', 'Building A, Floor 2'), ('Sales', 'Building C, Floor 1'),
('Research and Development', 'Building D, Floor 3'), ('Customer Support', 'Building B, Floor 1'),
('Finance', 'Building A, Floor 3'), ('IT Operations', 'Building D, Floor 1'),
('Legal', 'Building A, Floor 4'), ('Product Management', 'Building B, Floor 3');

-- Populate query_optimizations_and_performance.Projects
INSERT INTO query_optimizations_and_performance.Projects (projectName, startDate, endDate, projectDescription)
SELECT
    'Project Alpha ' || i,
    CURRENT_DATE - (RANDOM() * 365)::INT,
    CURRENT_DATE + (RANDOM() * 730)::INT,
    'Detailed description for Project Alpha ' || i || '. Focuses on innovation and market disruption. Keywords: agile, development, beta, release.'
FROM generate_series(1, 25) s(i);
INSERT INTO query_optimizations_and_performance.Projects (projectName, startDate, endDate, projectDescription)
SELECT
    'Project Omega ' || i,
    CURRENT_DATE - (RANDOM() * 100)::INT,
    CURRENT_DATE + (RANDOM() * 200)::INT,
    'Strategic initiative for Project Omega ' || i || '. Aims to optimize core business processes. Keywords: optimization, strategy, core, efficiency.'
FROM generate_series(1, 25) s(i);
UPDATE query_optimizations_and_performance.Projects SET projectDescription = projectDescription || ' Contains sensitive data about future plans.' WHERE projectId % 7 = 0;
UPDATE query_optimizations_and_performance.Projects SET projectDescription = projectDescription || ' This project is critical for Q3 targets.' WHERE projectId % 5 = 0;


-- Populate query_optimizations_and_performance.Employees (e.g., 30,000 query_optimizations_and_performance.Employees for noticeable performance differences)
INSERT INTO query_optimizations_and_performance.Employees (firstName, lastName, email, departmentId, salary, hireDate, jobTitle, performanceScore, status)
SELECT
    'FirstName' || i,
    'LastName' || (i % 2000), -- Creates some duplicate last names
    'user' || i || '@example.com',
    (i % 10) + 1,
    30000 + (RANDOM() * 90000)::INT,
    CURRENT_DATE - (RANDOM() * 365 * 15)::INT, -- Hired in the last 15 years
    CASE (i % 6)
        WHEN 0 THEN 'Software Engineer' WHEN 1 THEN 'Product Manager' WHEN 2 THEN 'Sales Representative'
        WHEN 3 THEN 'HR Specialist' WHEN 4 THEN 'Data Analyst' ELSE 'Support Technician'
    END,
    ROUND((1 + RANDOM() * 4)::NUMERIC, 1),
    CASE WHEN RANDOM() < 0.1 THEN 'Terminated' ELSE 'Active' END -- ~10% Terminated
FROM generate_series(1, 30000) s(i);

-- Populate query_optimizations_and_performance.EmployeeProjects
INSERT INTO query_optimizations_and_performance.EmployeeProjects (employeeId, projectId, roleInProject)
SELECT
    e.employeeId,
    p.projectId,
    CASE (p.projectId % 4)
        WHEN 0 THEN 'Developer' WHEN 1 THEN 'Team Lead'
        WHEN 2 THEN 'QA Engineer' ELSE 'Consultant'
    END
FROM query_optimizations_and_performance.Employees e
CROSS JOIN LATERAL (
    SELECT projectId FROM query_optimizations_and_performance.Projects ORDER BY RANDOM() LIMIT (1 + (RANDOM() * 3)::INT) -- 1 to 4 query_optimizations_and_performance.Projects
) p
ON CONFLICT (employeeId, projectId) DO NOTHING;

-- Initial recommended indexes for exercises (some intentionally omitted for specific questions)
CREATE INDEX IF NOT EXISTS idxEmployeesLastName ON query_optimizations_and_performance.Employees (lastName);
CREATE INDEX IF NOT EXISTS idxEmployeesDepartmentId ON query_optimizations_and_performance.Employees (departmentId);
CREATE INDEX IF NOT EXISTS idxEmployeesHireDate ON query_optimizations_and_performance.Employees (hireDate);
-- No index on salary, jobTitle, or status initially by default for exercise flexibility


-- SQL code to add necessary and sufficient rows to the Projects table
-- This is intended to make the need for GIN/GiST indexes evident
-- when performing full-text searches on the projectDescription column.
-- Assumes the Projects table already exists as defined in the main dataset.
INSERT INTO Projects (projectName, startDate, endDate, projectDescription)
SELECT
    'Project Gamma ' || i AS projectName,
    CURRENT_DATE - (RANDOM() * 730)::INT AS startDate,
    CURRENT_DATE + (RANDOM() * 365 + 30)::INT AS endDate, -- Ensure endDate is after startDate on average
    CASE (i % 20) -- Control distribution of keywords for "innovation" and "strategy"
        WHEN 0 THEN -- Contains both "innovation" AND "strategy" (approx. 5% of new rows)
            'Project Scope: A detailed plan for a new market strategy incorporating significant product innovation. ' ||
            'This initiative focuses on agile development methodologies and targets a beta release within six months. ' ||
            'The strategic importance of this innovation venture is paramount for future growth. We are exploring new frontiers ' ||
            'to combine effective strategy with groundbreaking innovation. This is a critical path project.'
        WHEN 1 THEN -- Contains "innovation" (approx. 5% of new rows)
            'Project Scope: Centered on pure innovation, this project aims to deliver a breakthrough technological solution. ' ||
            'Our research and development team is pioneering new techniques to achieve transformative outcomes. ' ||
            'The core philosophy is rapid iteration and embracing innovation at every stage. This innovation will redefine industry standards.'
        WHEN 2 THEN -- Contains "strategy" (approx. 5% of new rows)
            'Project Scope: This is a key strategic initiative designed to optimize current operations and consolidate market leadership. ' ||
            'The project involves meticulous planning, efficient resource allocation, and a clear execution roadmap. ' ||
            'Our primary strategy focuses on sustainable growth and enhancing competitive advantage. This forms the core of our annual strategy.'
        WHEN 3 THEN -- Contains "innovation" and other business keywords (approx. 5% of new rows)
            'Project Scope: An innovative approach to enhancing customer engagement through data analytics. ' ||
            'This project includes the development of a next-generation platform utilizing agile principles. ' ||
            'Key objectives include improved scalability, enhanced user experience, and fostering product innovation. A beta version is anticipated next quarter.'
        WHEN 4 THEN -- Contains "strategy" and other business keywords (approx. 5% of new rows)
            'Project Scope: The core strategy for this project is to expand into new geographical markets while optimizing existing supply chains. ' ||
            'This requires a robust strategic framework and a focus on efficient, scalable operations. A critical component of our long-term market strategy.'
        ELSE -- More generic descriptions, may or may not contain the keywords incidentally (approx. 75% of new rows)
            'Project Scope: This general project involves standard operational improvements and feature enhancements. Keywords: ' ||
            CASE (RANDOM() * 5)::INT -- This generates 0, 1, 2, 3, 4. If you have 5 options, use (RANDOM()*4)::INT
                WHEN 0 THEN 'optimization, efficiency, core process improvement, system upgrade'
                WHEN 1 THEN 'scalability, performance tuning, new feature integration, user acceptance testing'
                WHEN 2 THEN 'market analysis, competitive research, user feedback incorporation, product lifecycle management'
                WHEN 3 THEN 'agile methodology, scrum framework, development sprint cycle, beta testing phase'
                ELSE 'technical documentation, customer support protocols, system maintenance, software lifecycle'
            END || '. The project aims to deliver tangible value by ' ||
            (ARRAY['improving current backend systems',
                   'developing new user-facing tools',
                   'enhancing overall customer satisfaction levels',
                   'streamlining internal operational workflows',
                   'exploring potential ancillary markets and revenue streams'])[(RANDOM()*4)::INT + 1] || -- Corrected Line: Parentheses around ARRAY and +1 for 1-based indexing
            '. Further details include a rigorous focus on resource allocation and adherence to project timelines. This is a standard project with typical objectives and deliverables.'
    END ||
    -- Common long suffix to increase text volume and variability, making LIKE scans more expensive
    ' Common Project Addendum: Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ' ||
    'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ' ||
    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ' ||
    'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. ' ||
    'This project description was auto-generated for testing purposes for record number ' || i || '. ' ||
    'Report generated on ' || CURRENT_TIMESTAMP || '. This document may contain placeholder text and outline sensitive information about project goals, future plans, potential risks, and mitigation strategies. ' ||
    'We also consider the impact on various stakeholders and overall business objectives. The project typically has several distinct phases: initial planning, design, development, rigorous testing, and final deployment. ' ||
    'Each phase has specific milestones, deliverables, and quality assurance checks. This project description is intended for internal demonstration and performance testing use only and should not be distributed or used for production decisions without prior authorization. ' ||
    'The successful completion of this simulated project is critical for understanding query performance characteristics on large text fields and achieving our quarterly targets for database optimization exercises and long-term vision for data handling capabilities.'
FROM generate_series(51, 10050) s(i); -- Adds 10,000 new projects, starting IDs after typical initial data.
