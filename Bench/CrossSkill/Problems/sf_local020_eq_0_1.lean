import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local020_eq_0_1

CREATE TABLE PLAYER («player_id» INT, «player_name» STRING, «dob» STRING, «batting_hand» STRING, «bowling_skill» STRING, «country_name» STRING)
CREATE TABLE BATSMAN_SCORED («match_id» INT, «over_id» INT, «ball_id» INT, «runs_scored» INT, «innings_no» INT)
CREATE TABLE WICKET_TAKEN («match_id» INT, «over_id» INT, «ball_id» INT, «player_out» INT, «kind_out» STRING, «innings_no» INT)
CREATE TABLE BALL_BY_BALL («match_id» INT, «over_id» INT, «ball_id» INT, «innings_no» INT, «team_batting» INT, «team_bowling» INT, «striker_batting_position» INT, «striker» INT, «non_striker» INT, «bowler» INT)

theorem eq (t0 : TableRel PLAYER_schema) (t1 : TableRel BATSMAN_SCORED_schema) (t2 : TableRel WICKET_TAKEN_schema) (t3 : TableRel BALL_BY_BALL_schema) :
    (sql%([PLAYER_schema, BATSMAN_SCORED_schema, WICKET_TAKEN_schema, BALL_BY_BALL_schema]) "SELECT p.\"player_name\" AS \"OUTPUT\" FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS b JOIN \"IPL\".\"IPL\".\"BATSMAN_SCORED\" AS bs ON b.\"match_id\" = bs.\"match_id\" AND b.\"over_id\" = bs.\"over_id\" AND b.\"ball_id\" = bs.\"ball_id\" AND b.\"innings_no\" = bs.\"innings_no\" LEFT JOIN \"IPL\".\"IPL\".\"WICKET_TAKEN\" AS w ON b.\"match_id\" = w.\"match_id\" AND b.\"over_id\" = w.\"over_id\" AND b.\"ball_id\" = w.\"ball_id\" AND b.\"innings_no\" = w.\"innings_no\" JOIN \"IPL\".\"IPL\".\"PLAYER\" AS p ON b.\"bowler\" = p.\"player_id\" GROUP BY b.\"bowler\", p.\"player_name\" HAVING COUNT(DISTINCT CASE WHEN NOT w.\"match_id\" IS NULL THEN w.\"match_id\" || '-' || w.\"over_id\" || '-' || w.\"ball_id\" || '-' || w.\"innings_no\" END) > 0 ORDER BY CAST(SUM(bs.\"runs_scored\") * 1.0 AS DOUBLE PRECISION) / COUNT(DISTINCT CASE WHEN NOT w.\"match_id\" IS NULL THEN w.\"match_id\" || '-' || w.\"over_id\" || '-' || w.\"ball_id\" || '-' || w.\"innings_no\" END) ASC LIMIT 1") t0 t1 t2 t3
  ~= (sql%([PLAYER_schema, BATSMAN_SCORED_schema, WICKET_TAKEN_schema, BALL_BY_BALL_schema]) "WITH bowler_runs AS (SELECT bb.\"bowler\", SUM(bs.\"runs_scored\") AS total_runs FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS bb JOIN \"IPL\".\"IPL\".\"BATSMAN_SCORED\" AS bs ON bb.\"match_id\" = bs.\"match_id\" AND bb.\"over_id\" = bs.\"over_id\" AND bb.\"ball_id\" = bs.\"ball_id\" AND bb.\"innings_no\" = bs.\"innings_no\" GROUP BY bb.\"bowler\"), bowler_wickets AS (SELECT bb.\"bowler\", COUNT(*) AS total_wickets FROM \"IPL\".\"IPL\".\"BALL_BY_BALL\" AS bb JOIN \"IPL\".\"IPL\".\"WICKET_TAKEN\" AS wt ON bb.\"match_id\" = wt.\"match_id\" AND bb.\"over_id\" = wt.\"over_id\" AND bb.\"ball_id\" = wt.\"ball_id\" AND bb.\"innings_no\" = wt.\"innings_no\" GROUP BY bb.\"bowler\") SELECT p.\"player_name\" AS \"OUTPUT\" FROM bowler_runs AS br JOIN bowler_wickets AS bw ON br.\"bowler\" = bw.\"bowler\" JOIN \"IPL\".\"IPL\".\"PLAYER\" AS p ON br.\"bowler\" = p.\"player_id\" ORDER BY CAST(br.total_runs * 1.0 AS DOUBLE PRECISION) / bw.total_wickets ASC LIMIT 1") t0 t1 t2 t3
  := by first | sql_equiv | sorry

end N_sf_local020_eq_0_1
