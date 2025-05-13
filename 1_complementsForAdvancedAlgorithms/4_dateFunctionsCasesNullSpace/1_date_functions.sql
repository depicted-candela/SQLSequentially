		-- Concepts: Date arithmetic, OVERLAPS operator.

-- (i) Meaning, values, relations, advantages of unique usage

-- 		Exercise 1.1: Project Timeline Extension and Next Month Check
-- Problem: For all projects, calculate their planned end date if extended by 2 months
-- and 15 days. Also, determine if the original planned end date falls within February
-- 2024. Display project name, original planned end date, extended planned end date, and
-- a boolean indicating if it’s planned for Feb 2024.
SELECT
	project_name,
	planned_end_date original_planned_end_date,
	planned_end_date + INTERVAL '2 months' + INTERVAL '15 days' adjusted_end_date
FROM advanced_dates_cases_and_null_space.projects
WHERE EXTRACT(MONTH FROM planned_end_date) = 2 AND EXTRACT(YEAR FROM planned_end_date) = 2024;

-- 		Exercise 1.2: Identifying Concurrent Project Assignments for Employees
-- Problem: Identify employees who are assigned to multiple projects whose active pe-
-- riods on those projects overlap. An employee’s active period on a project is from
-- assigned date to COALESCE(completion date, ’infinity’) (for ongoing assignments).
-- List the employee’s name and the names of the two overlapping projects along with their
-- assignment and completion dates.
SELECT
	e.emp_id, e.emp_name,
	p1.project_id, ep1.assigned_date, ep1.completion_date,
	p2.project_id, ep2.assigned_date, ep2.completion_date
FROM advanced_dates_cases_and_null_space.employees e
NATURAL JOIN advanced_dates_cases_and_null_space.employee_projects ep1
JOIN advanced_dates_cases_and_null_space.employee_projects ep2
	ON ep1.project_id > ep2.project_id
	AND (ep1.assigned_date, COALESCE(ep1.completion_date, 'infinity'::TIMESTAMP))
		OVERLAPS(ep2.assigned_date, COALESCE(ep2.completion_date, 'infinity'::TIMESTAMP))
JOIN advanced_dates_cases_and_null_space.projects p1
	ON p1.project_id = ep1.project_id
JOIN advanced_dates_cases_and_null_space.projects p2
	ON p2.project_id = ep1.project_id
ORDER BY ep1.project_id, e.emp_name;
SELECT
	e.emp_id, e.emp_name,
	p1.project_name, ep1.assigned_date, ep1.completion_date,
	p2.project_name, ep2.assigned_date, ep2.completion_date
FROM advanced_dates_cases_and_null_space.employees e
NATURAL JOIN advanced_dates_cases_and_null_space.employee_projects ep1
JOIN advanced_dates_cases_and_null_space.employee_projects ep2
	ON ep1.project_id <> ep2.project_id
	AND (ep1.assigned_date, COALESCE(ep1.completion_date, 'infinity'::TIMESTAMP))
		OVERLAPS(ep2.assigned_date, COALESCE(ep2.completion_date, 'infinity'::TIMESTAMP))
JOIN advanced_dates_cases_and_null_space.projects p1
	ON p1.project_id = ep1.project_id
JOIN advanced_dates_cases_and_null_space.projects p2
	ON p2.project_id = ep2.project_id
ORDER BY ep1.project_id, e.emp_name;

-- (ii) Disadvantages of all its technical concepts

-- 		Exercise 1.3: OVERLAPS with identical start/end points
-- Problem: The OVERLAPS operator checks if two time periods overlap. The standard defi-
-- nition is (S1, E1) OVERLAPS (S2, E2) is true if S1 < E2 AND S2 < E1. What happens
-- if E1 is the same as S1 (a zero-duration interval)? Consider checking if a project’s start
-- day (start date, start date) overlaps with an approved leave period. Explain the be-
-- havior and potential misinterpretation in PostgreSQL. Show a query that demonstrates
-- this behavior and contrast it with a correct way to check if a single date point falls within
-- a range.

-- Nothing can overlap period of zero, then the comparison gives FALSE and thus skipped when not
-- necessarily should be in that way.
-- Example: Project starts on a day an employee is on approved leave.
-- Incorrectly using (start_date, start_date) for OVERLAPS
SELECT
    p.project_name,
    p.start_date,
    e.emp_name,
    lr.leave_start_date,
    lr.leave_end_date,
	-- Incorrect 
    (p.start_date, p.start_date) OVERLAPS (lr.leave_start_date, lr.leave_end_date) AS overlaps_test_empty_interval,
	-- Correct: explicit, verbose and less efficient way expanding equivalently bounds for the desired effect
	(p.start_date,
	CASE
		WHEN p.start_date = p.start_date THEN p.start_date + INTERVAL '1 day'
		ELSE p.start_date
	END
	) OVERLAPS (
		lr.leave_start_date,
		CASE
			WHEN lr.leave_start_date = lr.leave_end_date THEN lr.leave_start_date + INTERVAL '1 day'
			ELSE lr.leave_end_date
		END
	) AS overlaps_test_empty_interval,
	-- Correct: implicit and efficient way expanding equivalently bounds for the desired effect
	(p.start_date, p.start_date + INTERVAL '1 day') 
		OVERLAPS
	(lr.leave_start_date, lr.leave_end_date + INTERVAL '1 day') AS overlaps_corrected_interval
FROM advanced_dates_cases_and_null_space.projects p
JOIN advanced_dates_cases_and_null_space.employee_projects ep ON p.project_id = ep.project_id
JOIN advanced_dates_cases_and_null_space.employees e ON ep.emp_id = e.emp_id
JOIN advanced_dates_cases_and_null_space.leave_requests lr ON e.emp_id = lr.emp_id
WHERE lr.status = 'Approved' 
  AND p.project_name = 'Project Alpha' 
  AND e.emp_name = 'Alice Wonderland' 
LIMIT 1;

-- 		Exercise 1.4: Time Zone Issues in Date Arithmetic without Explicit Time
-- Zone Handling
-- Problem: If CURRENT TIMESTAMP is used in date arithmetic (e.g., CURRENT TIMESTAMP +
-- INTERVAL ’1 day’) in a system with users or data from different time zones, and with-
-- out explicit time zone conversion (e.g., AT TIME ZONE), discuss the potential disadvan-
-- tages or inconsistencies. Provide conceptual SQL examples to illustrate potential issues
-- with both TIMESTAMP WITHOUT TIME ZONE and TIMESTAMP WITH TIME ZONE across DST
-- transitions or in global applications.

-- If a TIMESTAMP does not have TIME ZONE means that adding a day and then extract the next time
-- measurement (MONTH) expected to change to its next value could not be the case because a day
-- in different time zones vary. Is incorrect to add 4 hours comparing date times from China and Colombia.
WITH example_times AS (
  SELECT 
    '2024-01-31 22:00:00'::TIMESTAMP WITHOUT TIME ZONE AS china_time,  -- China (UTC+8)
    '2024-01-31 10:00:00'::TIMESTAMP WITHOUT TIME ZONE AS colombia_time  -- Colombia (UTC-5)
)
SELECT
  china_time AS original_china_time,
  colombia_time AS original_colombia_time,
  
  -- Adding 4 hours to both timestamps
  china_time + INTERVAL '4 hours' AS china_plus_4h,
  colombia_time + INTERVAL '4 hours' AS colombia_plus_4h,
  
  -- Extracting month after addition (shows the problem)
  EXTRACT(MONTH FROM (china_time + INTERVAL '4 hours')) AS china_new_month,
  EXTRACT(MONTH FROM (colombia_time + INTERVAL '4 hours')) AS colombia_new_month,
  
  -- The dangerous comparison (appears correct but is actually wrong)
  (china_time + INTERVAL '4 hours') = (colombia_time + INTERVAL '4 hours') AS naive_comparison
FROM example_times;


SELECT -- Example (behavior depends on session time zone for display)
    TIMESTAMP WITH TIME ZONE '2024-03-10 01:00:00 America/Bogota' AS ts_before_col,
    TIMESTAMP WITH TIME ZONE '2024-03-10 01:00:00 America/Bogota' + INTERVAL '24 hours' AS ts_plus_24h;
-- Colombia does not observe DST (UTC-5 all year)
-- 1:00 AM -05 + 24 hours = 1:00 AM -05 the next day (exactly 24 hours later)

SELECT -- For TIMESTAMP WITHOUT TIME ZONE (assuming server time is local and not UTC)
    '2024-01-15 10:00:00'::TIMESTAMP WITHOUT TIME ZONE AS current_ts_no_tz,
    ('2024-01-15 10:00:00'::TIMESTAMP WITHOUT TIME ZONE) + INTERVAL '1 day' AS next_day_no_tz;
Result: 2024-01-16 10:00:00. Meaning is relative to unspecified time zone.


-- (iii) Practice entirely cases where people in general does not use
-- these approaches losing their advantages, relations and values
-- because of the easier, basic, common or easily understandable
-- but highly inefficient solutions

-- 		Exercise 1.5: Inefficiently Finding Projects Active During a Specific Period
-- Problem: Find all projects that were active (i.e., their period from start date to
-- COALESCE(actual end date, planned end date)) at any point during Q1 2023 (Jan
-- 1, 2023 to Mar 31, 2023). An inefficient way involves multiple OR conditions checking if
-- project start is in Q1, end is in Q1, or project spans Q1. Show this inefficient method,
-- then provide the efficient OVERLAPS solution.

SELECT 					-- High complexities with verbosities prone to errors
    project_name, 
    start_date, 
    COALESCE(actual_end_date, planned_end_date) AS relevant_end_date
FROM advanced_dates_cases_and_null_space.projects
WHERE
    (start_date BETWEEN '2023-01-01' AND '2023-03-31') OR
    (COALESCE(actual_end_date, planned_end_date) BETWEEN '2023-01-01' AND '2023-03-31') OR
    (start_date < '2023-01-01' AND COALESCE(actual_end_date, planned_end_date) > '2023-03-31');

SELECT 					-- How overlapping solves verbosity and unreadable complexity
    project_name, 
    start_date, 
    COALESCE(actual_end_date, planned_end_date) AS relevant_end_date
FROM advanced_dates_cases_and_null_space.projects
WHERE
	(start_date, COALESCE(actual_end_date, planned_end_date))
		OVERLAPS 
	(TO_DATE('2023-01-01', 'YYYY-MM-DD'), TO_DATE('2023-03-31', 'YYYY-MM-DD'));
