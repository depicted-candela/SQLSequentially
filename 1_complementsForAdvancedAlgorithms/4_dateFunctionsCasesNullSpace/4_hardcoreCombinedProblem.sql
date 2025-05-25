	-- 4. Date Functions, Cases, NULL Space 
		-- 4 Hardcore Problem
		
-- 		Exercise 4.1: Comprehensive Departmental Project Health and Employee Engagement Report
-- Problem: Generate a report as of ’2024-01-15’ (’current report date’) that assesses project
-- health and employee engagement for each department. The report should include for each
-- department:
-- 	• dept name.
-- 	• total active employees: Count of employees in the department not terminated
-- 	as of current report date.
-- 	• avg employee tenure years: Average tenure (in years, rounded to 2 decimal places)
-- 	of active employees in the department as of current report date. Tenure is
-- 	(current report date - hire date) / 365.25. If a department has no active
-- 	employees, this should be NULL.
-- 	• projects info: A string categorizing department’s project involvement:
-- 		– ’High Overlap Risk’: If any two distinct active projects led by *active managers
-- 		from this department* have overlapping timeframes (start date to planned end date).
-- 		An active project is one with no actual end date or actual end date > current report date
-- 		An active manager is one not terminated and is either a manager id for someone
-- 		or has no manager id themselves (top-level).
-- 		– ’Multiple Critical Deadlines’: (If not ’High Overlap Risk’) If the department has
-- 		more than one active project (led by its active managers) with planned end date
-- 		within 30 days from current report date (inclusive of current report date,
-- 		up to current report date + 30 days).
-- 		– ’Normal Load’: Otherwise.
-- • avg rating adjusted: Average performance rating of active employees. If
-- performance rating is NULL, it’s treated as ’2’ for this calculation. Round to 2
-- decimal places. If no rated employees (even after COALESCE), show NULL (or 0 if
-- preferred for display).
-- • employees on leave percentage: Percentage of active employees in the depart-
-- ment currently on ’Approved’ leave on current report date. Calculate as
-- (distinct employees on leave / total active employees) * 100.0. Handle di-
-- vision by zero with NULLIF, resulting in NULL. Round to 2 decimal places.

-- The final report should be ordered by:
-- • projects info (’High Overlap Risk’ first, then ’Multiple Critical Deadlines’, then
-- ’Normal Load’).
-- • Within these categories, by dept name alphabetically.
-- • Limit the result to the top 5 departments based on this combined order.

-- Never try hardcore problems without partitions if the problem is kicking your mind
WITH context AS (SELECT DATE '2024-01-15' AS report_date),
active_workers AS (
	SELECT * 
	FROM advanced_dates_cases_and_null_space.employees e1, context c
	WHERE e1.termination_date IS NULL OR e1.termination_date > c.report_date),
active_workers_on_leave AS (
	SELECT DISTINCT emp_id, dept_id
	FROM active_workers aw
	JOIN advanced_dates_cases_and_null_space.leave_requests lr USING(emp_id)
	WHERE lr.status = 'Approved'),
active_managers AS (
	SELECT * 
	FROM active_workers aw
	WHERE
		(aw.manager_id IS NULL OR EXISTS(
			SELECT 1
			FROM advanced_dates_cases_and_null_space.employees e2
			WHERE e2.manager_id = aw.emp_id
		))),
active_projects AS (
	SELECT p.*
	FROM advanced_dates_cases_and_null_space.projects p, context c
	WHERE actual_end_date IS NULL OR actual_end_date > c.report_date),
actively_managed_active_projects AS (
	SELECT *
	FROM active_projects ap
	JOIN advanced_dates_cases_and_null_space.employee_projects ep USING(project_id)
	JOIN active_managers am USING(emp_id)),
departmental_actively_managed_active_projects AS (
	SELECT *
	FROM advanced_dates_cases_and_null_space.departments d
	JOIN actively_managed_active_projects a1 USING(dept_id)),
overlapped_departmental_actively_managed_active_projects AS (
	SELECT ap1.dept_id, ap1.project_id, ap2.project_id
	FROM departmental_actively_managed_active_projects ap1
	JOIN departmental_actively_managed_active_projects ap2 
		ON ap1.project_id > ap2.project_id
		AND ap1.dept_id = ap1.dept_id
		AND 
			(ap1.start_date, COALESCE(ap1.actual_end_date, 'infinity'::date)) 
				OVERLAPS 
			(ap2.start_date, COALESCE(ap1.actual_end_date, 'infinity'::date))
)

SELECT * FROM (
	SELECT
		d.dept_id, d.dept_name,
		COUNT(DISTINCT aw.emp_id) total_active,
		ROUND(AVG((c.report_date - e.hire_date) / 365.25), 2) avg_tenure,
		CASE
			WHEN d.dept_id IN (SELECT odamap.dept_id FROM overlapped_departmental_actively_managed_active_projects odamap) 
				THEN 'High Overlap Risk'
			WHEN 0 < (
				SELECT COUNT(*)
				FROM departmental_actively_managed_active_projects damap, context c
				WHERE damap.dept_id = dept_id AND damap.planned_end_date BETWEEN c.report_date AND INTERVAL '30 days' + c.report_date
			) THEN 'Multiple Critical Deadlines'
			ELSE 'Normal Loads'
		END project_info,
		NULLIF(ROUND(AVG(COALESCE(e.performance_rating, 2)), 2), 0) avg_performance_rating,
		ROUND(COUNT(DISTINCT awl.emp_id)::numeric / COUNT(DISTINCT aw.emp_id), 2) * 100 actives_leaving_percentage
	FROM advanced_dates_cases_and_null_space.employees e
	NATURAL JOIN advanced_dates_cases_and_null_space.departments d
	JOIN active_workers aw ON aw.dept_id = e.dept_id
	LEFT JOIN active_workers_on_leave awl ON awl.dept_id = d.dept_id
	CROSS JOIN context c
	WHERE e.termination_date IS NULL OR e.termination_date > c.report_date
	GROUP BY d.dept_id, d.dept_name
) AS mainSubQuery ORDER BY 
	CASE
		WHEN project_info = 'High Overlap Risk' THEN 1
		WHEN project_info = 'Multiple Critical Deadlines' THEN 2
		ELSE 3
	END ASC,
	dept_name ASC
LIMIT 5;
