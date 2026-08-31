import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local024_eq_1_2

CREATE TABLE PLAYER_MATCH («match_id» INT, «player_id» INT, «role» STRING, «team_id» INT)
CREATE TABLE PLAYER («player_id» INT, «player_name» STRING, «dob» STRING, «batting_hand» STRING, «bowling_skill» STRING, «country_name» STRING)
CREATE TABLE BATSMAN_SCORED («match_id» INT, «over_id» INT, «ball_id» INT, «runs_scored» INT, «innings_no» INT)
CREATE TABLE BALL_BY_BALL («match_id» INT, «over_id» INT, «ball_id» INT, «innings_no» INT, «team_batting» INT, «team_bowling» INT, «striker_batting_position» INT, «striker» INT, «non_striker» INT, «bowler» INT)
CREATE TABLE MATCH («match_id» INT, «team_1» INT, «team_2» INT, «match_date» STRING, «season_id» INT, «venue» STRING, «toss_winner» INT, «toss_decision» STRING, «win_type» STRING, «win_margin» INT, «outcome_type» STRING, «match_winner» INT, «man_of_the_match» INT)

theorem eq (t0 : TableRel PLAYER_MATCH_schema) (t1 : TableRel PLAYER_schema) (t2 : TableRel BATSMAN_SCORED_schema) (t3 : TableRel BALL_BY_BALL_schema) (t4 : TableRel MATCH_schema) :
    (sql%([PLAYER_MATCH_schema, PLAYER_schema, BATSMAN_SCORED_schema, BALL_BY_BALL_schema, MATCH_schema]) "WITH player_total_runs AS (SELECT bb.\"striker\" AS player_id, SUM(bs.\"runs_scored\") AS total_runs FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS bb JOIN \"IPL\".\"IPL\".\"BATSMAN_SCORED\" AS bs ON bb.\"match_id\" = bs.\"match_id\" AND bb.\"over_id\" = bs.\"over_id\" AND bb.\"ball_id\" = bs.\"ball_id\" AND bb.\"innings_no\" = bs.\"innings_no\" GROUP BY bb.\"striker\"), player_match_count AS (SELECT \"player_id\", COUNT(DISTINCT \"match_id\") AS matches_played FROM \"IPL\".\"IPL\".\"PLAYER_MATCH\" GROUP BY \"player_id\"), player_avg AS (SELECT ptr.player_id, CAST(ptr.total_runs * 1.0 AS DOUBLE PRECISION) / pmc.matches_played AS avg_runs_per_match FROM player_total_runs AS ptr JOIN player_match_count AS pmc ON ptr.player_id = pmc.\"player_id\") SELECT p.\"country_name\", AVG(pa.avg_runs_per_match) AS country_batting_average FROM player_avg AS pa JOIN \"IPL\".\"IPL\".\"PLAYER\" AS p ON pa.player_id = p.\"player_id\" GROUP BY p.\"country_name\" ORDER BY country_batting_average DESC LIMIT 5") t0 t1 t2 t3 t4
  = (sql%([PLAYER_MATCH_schema, PLAYER_schema, BATSMAN_SCORED_schema, BALL_BY_BALL_schema, MATCH_schema]) "WITH player_runs AS (SELECT bb.\"striker\" AS player_id, SUM(bs.\"runs_scored\") AS total_runs FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS bb JOIN \"IPL\".\"IPL\".\"BATSMAN_SCORED\" AS bs ON bb.\"match_id\" = bs.\"match_id\" AND bb.\"over_id\" = bs.\"over_id\" AND bb.\"ball_id\" = bs.\"ball_id\" AND bb.\"innings_no\" = bs.\"innings_no\" GROUP BY bb.\"striker\"), player_matches AS (SELECT pm.\"player_id\" AS player_id, COUNT(DISTINCT pm.\"match_id\") AS matches_played FROM \"IPL\".\"IPL\".\"PLAYER_MATCH\" AS pm GROUP BY pm.\"player_id\"), player_batting_avg AS (SELECT pr.player_id, CAST(pr.total_runs * 1.0 AS DOUBLE PRECISION) / pmx.matches_played AS batting_avg FROM player_runs AS pr JOIN player_matches AS pmx ON pr.player_id = pmx.player_id) SELECT p.\"country_name\" AS \"country_name\", AVG(pba.batting_avg) AS \"country_batting_average\" FROM player_batting_avg AS pba JOIN \"IPL\".\"IPL\".\"PLAYER\" AS p ON pba.player_id = p.\"player_id\" GROUP BY p.\"country_name\" ORDER BY \"country_batting_average\" DESC LIMIT 5") t0 t1 t2 t3 t4
  := by first | sql_equiv | sorry

end N_sf_local024_eq_1_2
