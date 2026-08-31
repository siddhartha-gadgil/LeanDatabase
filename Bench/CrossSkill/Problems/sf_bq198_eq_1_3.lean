import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq198_eq_1_3

CREATE TABLE MBB_HISTORICAL_TEAMS_SEASONS («season» INT, «market» STRING, «name» STRING, «team_code» INT, «team_id» STRING, «alias» STRING, «division» INT, «current_division» STRING, «wins» INT, «losses» INT, «ties» INT)

theorem eq (t0 : TableRel MBB_HISTORICAL_TEAMS_SEASONS_schema) :
    (sql%([MBB_HISTORICAL_TEAMS_SEASONS_schema]) "WITH season_max AS (SELECT \"season\", MAX(\"wins\") AS max_wins FROM \"NCAA_BASKETBALL\".\"NCAA_BASKETBALL\".\"MBB_HISTORICAL_TEAMS_SEASONS\" WHERE \"season\" BETWEEN 1900 AND 2000 GROUP BY \"season\"), peak_teams AS (SELECT t.\"market\" AS TEAM_NAME, t.\"season\" FROM \"NCAA_BASKETBALL\".\"NCAA_BASKETBALL\".\"MBB_HISTORICAL_TEAMS_SEASONS\" AS t INNER JOIN season_max AS s ON t.\"season\" = s.\"season\" AND t.\"wins\" = s.max_wins WHERE t.\"season\" BETWEEN 1900 AND 2000 AND NOT t.\"name\" IS NULL) SELECT TEAM_NAME, COUNT(*) AS TOP_PERFORMER_COUNT FROM peak_teams GROUP BY TEAM_NAME ORDER BY TOP_PERFORMER_COUNT DESC, TEAM_NAME ASC LIMIT 5") t0
  = (sql%([MBB_HISTORICAL_TEAMS_SEASONS_schema]) "WITH season_max_wins AS (SELECT \"season\", MAX(\"wins\") AS max_wins FROM \"NCAA_BASKETBALL\".\"NCAA_BASKETBALL\".\"MBB_HISTORICAL_TEAMS_SEASONS\" WHERE \"season\" BETWEEN 1900 AND 2000 GROUP BY \"season\"), peak_teams AS (SELECT t.\"market\" AS TEAM_NAME, t.\"season\" FROM \"NCAA_BASKETBALL\".\"NCAA_BASKETBALL\".\"MBB_HISTORICAL_TEAMS_SEASONS\" AS t INNER JOIN season_max_wins AS s ON t.\"season\" = s.\"season\" AND t.\"wins\" = s.max_wins WHERE t.\"season\" BETWEEN 1900 AND 2000 AND NOT t.\"market\" IS NULL) SELECT TEAM_NAME, COUNT(*) AS TOP_PERFORMER_COUNT FROM peak_teams GROUP BY TEAM_NAME ORDER BY TOP_PERFORMER_COUNT DESC, TEAM_NAME ASC LIMIT 5") t0
  := by first | sql_equiv | sorry

end N_sf_bq198_eq_1_3
