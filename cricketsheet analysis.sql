CREATE DATABASE cricsheet CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cricsheet;
SHOW TABLES;

SELECT batter, SUM(runs_batter) AS runs
FROM odi_matches
GROUP BY batter
ORDER BY runs DESC
LIMIT 10;

SELECT bowler, COUNT(*) AS wickets
FROM t20_matches
WHERE wicket_kind IS NOT NULL
  AND wicket_kind NOT IN ('run out', 'retired hurt', 'obstructing the field')  -- bowler not credited
GROUP BY bowler
ORDER BY wickets DESC
LIMIT 10;
SET SESSION sql_mode = (SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''));

SELECT match_id, team1, team2, winner, by_wickets
FROM odi_matches
GROUP BY match_id
HAVING MAX(by_wickets) IS NOT NULL
ORDER BY MAX(by_wickets) ASC
LIMIT 10;

WITH base AS (
  SELECT match_id, winner, team1, team2
  FROM test_matches
  GROUP BY match_id
)
SELECT team, 
       SUM(CASE WHEN winner = team THEN 1 ELSE 0 END) * 1.0 / COUNT(*) * 100 AS win_pct
FROM (
  SELECT match_id, team1 AS team, winner FROM base
  UNION ALL
  SELECT match_id, team2 AS team, winner FROM base
) t
GROUP BY team
ORDER BY win_pct DESC;

SELECT match_id, team1, team2, winner, by_runs
FROM odi_matches
GROUP BY match_id
HAVING MAX(by_runs) IS NOT NULL
ORDER BY MAX(by_runs) ASC
LIMIT 10;

SELECT match_id, team1, team2, winner, by_wickets
FROM odi_matches
GROUP BY match_id
HAVING MAX(by_wickets) IS NOT NULL
ORDER BY MAX(by_wickets) ASC
LIMIT 10;

WITH balls AS (
  SELECT match_id, batter, COUNT(*) AS balls, SUM(runs_batter) AS runs
  FROM t20_matches
  GROUP BY match_id, batter
)
SELECT match_id, batter, runs, balls
FROM balls
WHERE runs >= 50
ORDER BY balls ASC, runs DESC
LIMIT 15;

SELECT bowler, COUNT(*) AS fours_conceded
FROM odi_matches
WHERE runs_batter = 4
GROUP BY bowler
ORDER BY fours_conceded DESC
LIMIT 10;

SELECT batter, COUNT(*) AS sixes
FROM odi_matches
WHERE runs_batter = 6
GROUP BY batter
ORDER BY sixes DESC
LIMIT 10;

WITH sums AS (
  SELECT bowler,
         SUM(CASE WHEN runs_total = 0 THEN 1 ELSE 0 END) AS dots,
         COUNT(*) AS balls
  FROM t20_matches
  GROUP BY bowler
)
SELECT bowler, dots*1.0/balls*100 AS dot_pct, balls
FROM sums
WHERE balls >= 60
ORDER BY dot_pct DESC;

WITH b AS (
  SELECT bowler, SUM(runs_total) AS runs, COUNT(*) AS balls
  FROM odi_matches
  GROUP BY bowler
)
SELECT bowler, runs*6.0/balls AS economy, balls
FROM b
WHERE balls >= 120
ORDER BY economy ASC
LIMIT 20;

WITH outs AS (
  SELECT match_id, batter,
         SUM(CASE WHEN wicket_player_out = batter THEN 1 ELSE 0 END) AS dismissals,
         SUM(runs_batter) AS runs
  FROM odi_matches
  GROUP BY match_id, batter
),
agg AS (
  SELECT batter, SUM(runs) AS runs, SUM(dismissals) AS dismissals
  FROM outs
  GROUP BY batter
)
SELECT batter,
       runs*1.0/NULLIF(dismissals,0) AS batting_average,
       runs, dismissals
FROM agg
WHERE runs >= 200
ORDER BY batting_average DESC;

SELECT match_id, inning_team AS team, SUM(runs_total) AS total
FROM odi_matches
GROUP BY match_id, inning_team
ORDER BY match_id;

SELECT wicket_kind, COUNT(*) AS n
FROM t20_matches
WHERE wicket_kind IS NOT NULL
GROUP BY wicket_kind
ORDER BY n DESC;

WITH m AS (
  SELECT match_id, player_of_match
  FROM (
    SELECT match_id, player_of_match FROM test_matches
    UNION ALL SELECT match_id, player_of_match FROM odi_matches
    UNION ALL SELECT match_id, player_of_match FROM t20_matches
  ) x
  GROUP BY match_id, player_of_match
)
SELECT TRIM(player_of_match) AS player, COUNT(*) AS awards
FROM m
WHERE player_of_match <> ''
GROUP BY TRIM(player_of_match)
ORDER BY awards DESC
LIMIT 20;

WITH totals AS (
  SELECT match_id, venue, inning_team, SUM(runs_total) AS total
  FROM odi_matches
  GROUP BY match_id, venue, inning_team
)
SELECT venue, AVG(total) AS avg_total, COUNT(*) AS innings
FROM totals
GROUP BY venue
HAVING innings >= 10
ORDER BY avg_total DESC
LIMIT 15;

WITH sums AS (
  SELECT season, match_id, SUM(runs_total) AS runs, COUNT(*) AS balls
  FROM t20_matches
  GROUP BY season, match_id
)
SELECT season, AVG(runs*6.0/balls) AS avg_rr
FROM sums
GROUP BY season
ORDER BY season;

WITH d AS (
  SELECT match_id, bowler,
         SUM(CASE WHEN wicket_kind IS NOT NULL
                  AND wicket_kind NOT IN ('run out','retired hurt','obstructing the field')
                  THEN 1 ELSE 0 END) AS wkts,
         COUNT(*) AS balls
  FROM t20_matches
  GROUP BY match_id, bowler
),
agg AS (
  SELECT bowler, SUM(wkts) AS wkts, SUM(balls) AS balls
  FROM d
  GROUP BY bowler
)
SELECT bowler, balls*1.0/NULLIF(wkts,0) AS strike_rate, balls, wkts
FROM agg
WHERE wkts >= 20
ORDER BY strike_rate ASC
LIMIT 20;







