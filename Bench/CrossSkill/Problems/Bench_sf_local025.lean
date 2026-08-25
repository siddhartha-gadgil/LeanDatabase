import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local025 — crossskill equivalence(s)

Question: For each match, considering every innings, please combine runs from both batsman scored and extra runs for each over, then identify the single over with the highest total runs, retrieve the bowler for that over from the ball by ball table, and calculate the average of these highest over totals across all matches, ensuring that all runs and bowler details are accurately reflected.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local025

CREATE TABLE PLAYER («player_id» INT, «player_name» STRING, «dob» STRING, «batting_hand» STRING, «bowling_skill» STRING, «country_name» STRING)
CREATE TABLE BATSMAN_SCORED («match_id» INT, «over_id» INT, «ball_id» INT, «runs_scored» INT, «innings_no» INT)
CREATE TABLE BALL_BY_BALL («match_id» INT, «over_id» INT, «ball_id» INT, «innings_no» INT, «team_batting» INT, «team_bowling» INT, «striker_batting_position» INT, «striker» INT, «non_striker» INT, «bowler» INT)
CREATE TABLE EXTRA_RUNS («match_id» INT, «over_id» INT, «ball_id» INT, «extra_type» STRING, «extra_runs» INT, «innings_no» INT)
CREATE TABLE MATCH («match_id» INT, «team_1» INT, «team_2» INT, «match_date» STRING, «season_id» INT, «venue» STRING, «toss_winner» INT, «toss_decision» STRING, «win_type» STRING, «win_margin» INT, «outcome_type» STRING, «match_winner» INT, «man_of_the_match» INT)

theorem eq_0_1 : ∀ t,
    (sql%([PLAYER_schema, BATSMAN_SCORED_schema, BALL_BY_BALL_schema, EXTRA_RUNS_schema, MATCH_schema]) "WITH over_runs AS (SELECT b.\"match_id\", b.\"over_id\", b.\"innings_no\", SUM(COALESCE(bs.\"runs_scored\", 0)) + SUM(COALESCE(er.\"extra_runs\", 0)) AS total_runs FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS b LEFT JOIN \"IPL\".\"IPL\".\"BATSMAN_SCORED\" AS bs ON b.\"match_id\" = bs.\"match_id\" AND b.\"over_id\" = bs.\"over_id\" AND b.\"ball_id\" = bs.\"ball_id\" AND b.\"innings_no\" = bs.\"innings_no\" LEFT JOIN \"IPL\".\"IPL\".\"EXTRA_RUNS\" AS er ON b.\"match_id\" = er.\"match_id\" AND b.\"over_id\" = er.\"over_id\" AND b.\"ball_id\" = er.\"ball_id\" AND b.\"innings_no\" = er.\"innings_no\" GROUP BY b.\"match_id\", b.\"over_id\", b.\"innings_no\"), ranked_overs AS (SELECT \"match_id\", \"over_id\", \"innings_no\", total_runs, ROW_NUMBER() OVER (PARTITION BY \"match_id\" ORDER BY total_runs DESC, \"innings_no\" ASC, \"over_id\" ASC) AS rn FROM over_runs), best_over AS (SELECT \"match_id\", \"over_id\", \"innings_no\", total_runs FROM ranked_overs WHERE rn = 1), bowler_per_over AS (SELECT \"match_id\", \"over_id\", \"innings_no\", \"bowler\", ROW_NUMBER() OVER (PARTITION BY \"match_id\", \"over_id\", \"innings_no\" ORDER BY MIN(\"ball_id\") ASC) AS rn FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" GROUP BY \"match_id\", \"over_id\", \"innings_no\", \"bowler\") SELECT bo.\"match_id\", bo.\"innings_no\", bo.\"over_id\", bp.\"bowler\" AS BOWLER_ID, p.\"player_name\" AS BOWLER_NAME, bo.total_runs AS HIGHEST_OVER_RUNS, ROUND(CAST(AVG(bo.total_runs) OVER () AS DECIMAL), 3) AS AVG_HIGHEST_OVER_RUNS_ACROSS_MATCHES FROM best_over AS bo JOIN bowler_per_over AS bp ON bo.\"match_id\" = bp.\"match_id\" AND bo.\"over_id\" = bp.\"over_id\" AND bo.\"innings_no\" = bp.\"innings_no\" AND bp.rn = 1 LEFT JOIN \"IPL\".\"IPL\".\"PLAYER\" AS p ON bp.\"bowler\" = p.\"player_id\" ORDER BY bo.\"match_id\" ASC") t ~= (sql%([PLAYER_schema, BATSMAN_SCORED_schema, BALL_BY_BALL_schema, EXTRA_RUNS_schema, MATCH_schema]) "WITH over_bowler AS (/* Get the bowler who bowled the first ball of each over */ SELECT \"match_id\", \"innings_no\", \"over_id\", \"bowler\" FROM (SELECT \"match_id\", \"innings_no\", \"over_id\", \"bowler\", ROW_NUMBER() OVER (PARTITION BY \"match_id\", \"innings_no\", \"over_id\" ORDER BY \"ball_id\" ASC) AS rn FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\") AS t WHERE rn = 1), over_runs AS (/* Calculate total runs per (match_id, innings_no, over_id) */ SELECT b.\"match_id\", b.\"innings_no\", b.\"over_id\", ob.\"bowler\" AS \"BOWLER_ID\", SUM(COALESCE(bs.\"runs_scored\", 0)) + SUM(COALESCE(er.\"extra_runs\", 0)) AS \"HIGHEST_OVER_RUNS\" FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS b LEFT JOIN \"IPL\".\"IPL\".\"BATSMAN_SCORED\" AS bs ON b.\"match_id\" = bs.\"match_id\" AND b.\"over_id\" = bs.\"over_id\" AND b.\"ball_id\" = bs.\"ball_id\" AND b.\"innings_no\" = bs.\"innings_no\" LEFT JOIN \"IPL\".\"IPL\".\"EXTRA_RUNS\" AS er ON b.\"match_id\" = er.\"match_id\" AND b.\"over_id\" = er.\"over_id\" AND b.\"ball_id\" = er.\"ball_id\" AND b.\"innings_no\" = er.\"innings_no\" JOIN over_bowler AS ob ON b.\"match_id\" = ob.\"match_id\" AND b.\"innings_no\" = ob.\"innings_no\" AND b.\"over_id\" = ob.\"over_id\" GROUP BY b.\"match_id\", b.\"innings_no\", b.\"over_id\", ob.\"bowler\"), ranked AS (/* For each match, rank overs by total runs DESC, tie-break innings ASC, over ASC */ SELECT \"match_id\", \"innings_no\", \"over_id\", \"BOWLER_ID\", \"HIGHEST_OVER_RUNS\", ROW_NUMBER() OVER (PARTITION BY \"match_id\" ORDER BY \"HIGHEST_OVER_RUNS\" DESC, \"innings_no\" ASC, \"over_id\" ASC) AS rn FROM over_runs) SELECT r.\"match_id\", r.\"innings_no\", r.\"over_id\", r.\"BOWLER_ID\", p.\"player_name\" AS \"BOWLER_NAME\", r.\"HIGHEST_OVER_RUNS\", ROUND(CAST(AVG(r.\"HIGHEST_OVER_RUNS\") OVER () AS DECIMAL), 3) AS \"AVG_HIGHEST_OVER_RUNS_ACROSS_MATCHES\" FROM ranked AS r LEFT JOIN \"IPL\".\"IPL\".\"PLAYER\" AS p ON r.\"BOWLER_ID\" = p.\"player_id\" WHERE r.rn = 1 ORDER BY r.\"match_id\" ASC") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_local025
