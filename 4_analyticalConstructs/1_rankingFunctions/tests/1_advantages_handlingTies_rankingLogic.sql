-- Example 1: Advantages (Handling Ties, Ranking Logic)
-- Scenario: Rank sales teams by performance within regions, showing ties and ranking behavior.

-- DDL
--CREATE TABLE ranking_functions.sales_teams (
--  team_id SERIAL PRIMARY KEY,
--  region VARCHAR(20),
--  sales NUMERIC(10,2)
--);

-- DML (6 rows with deliberate ties)
--INSERT INTO ranking_functions.sales_teams (region, sales) VALUES
--('East', 150000),
--('East', 150000),
--('East', 90000),
--('West', 200000),
--('West', 180000),
--('West', 180000);

CREATE VIEW ranking_functions.advantages_handlingties_ranking_logic AS (
	SELECT
		*,
		RANK() OVER(PARTITION BY region ORDER BY sales),
		DENSE_RANK() OVER(PARTITION BY region ORDER BY sales),
		ROW_NUMBER() OVER(PARTITION BY region ORDER BY sales)
	FROM ranking_functions.sales_teams
		ORDER BY region, rank
);