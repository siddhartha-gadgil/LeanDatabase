import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local021_eq_0_2

CREATE TABLE BATSMAN_SCORED («match_id» INT, «over_id» INT, «ball_id» INT, «runs_scored» INT, «innings_no» INT)
CREATE TABLE BALL_BY_BALL («match_id» INT, «over_id» INT, «ball_id» INT, «innings_no» INT, «team_batting» INT, «team_bowling» INT, «striker_batting_position» INT, «striker» INT, «non_striker» INT, «bowler» INT)
CREATE TABLE MATCH («match_id» INT, «team_1» INT, «team_2» INT, «match_date» STRING, «season_id» INT, «venue» STRING, «toss_winner» INT, «toss_decision» STRING, «win_type» STRING, «win_margin» INT, «outcome_type» STRING, «match_winner» INT, «man_of_the_match» INT)

theorem eq (t0 : TableRel BATSMAN_SCORED_schema) (t1 : TableRel BALL_BY_BALL_schema) (t2 : TableRel MATCH_schema) :
    (sql%([BATSMAN_SCORED_schema, BALL_BY_BALL_schema, MATCH_schema]) "WITH striker_match_runs AS (/* Calculate total runs per striker per match */ SELECT b.\"striker\", b.\"match_id\", SUM(bs.\"runs_scored\") AS match_runs FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS b JOIN \"IPL\".\"IPL\".\"BATSMAN_SCORED\" AS bs ON b.\"match_id\" = bs.\"match_id\" AND b.\"over_id\" = bs.\"over_id\" AND b.\"ball_id\" = bs.\"ball_id\" AND b.\"innings_no\" = bs.\"innings_no\" GROUP BY b.\"striker\", b.\"match_id\"), qualified_strikers AS (/* Find strikers who scored more than 50 in any single match */ SELECT DISTINCT \"striker\" FROM striker_match_runs WHERE match_runs > 50), striker_career_totals AS (/* Get total (career) runs for each qualified striker */ SELECT smr.\"striker\", SUM(smr.match_runs) AS total_runs FROM striker_match_runs AS smr INNER JOIN qualified_strikers AS qs ON smr.\"striker\" = qs.\"striker\" GROUP BY smr.\"striker\") /* Calculate the average of total runs across all qualified strikers */ SELECT AVG(total_runs) AS OUTPUT FROM striker_career_totals") t0 t1 t2
  ~= (sql%([BATSMAN_SCORED_schema, BALL_BY_BALL_schema, MATCH_schema]) "/* Calculate the average of the total runs scored by all strikers */ /* who have scored more than 50 runs in any single match */ SELECT AVG(\"total_runs\") AS \"OUTPUT\" FROM (/* Total runs per striker across all matches */ SELECT b.\"striker\", SUM(bs.\"runs_scored\") AS \"total_runs\" FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS b JOIN \"IPL\".\"IPL\".\"BATSMAN_SCORED\" AS bs ON b.\"match_id\" = bs.\"match_id\" AND b.\"over_id\" = bs.\"over_id\" AND b.\"ball_id\" = bs.\"ball_id\" AND b.\"innings_no\" = bs.\"innings_no\" WHERE b.\"striker\" IN (/* Strikers who scored more than 50 in any single match */ SELECT b2.\"striker\" FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS b2 JOIN \"IPL\".\"IPL\".\"BATSMAN_SCORED\" AS bs2 ON b2.\"match_id\" = bs2.\"match_id\" AND b2.\"over_id\" = bs2.\"over_id\" AND b2.\"ball_id\" = bs2.\"ball_id\" AND b2.\"innings_no\" = bs2.\"innings_no\" GROUP BY b2.\"striker\", b2.\"match_id\" HAVING SUM(bs2.\"runs_scored\") > 50) GROUP BY b.\"striker\") AS sub") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local021_eq_0_2
