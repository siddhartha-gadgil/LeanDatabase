import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq333_eq_1_3

CREATE TABLE EVENTS («id» INT, «user_id» INT, «sequence_number» INT, «session_id» STRING, «created_at» INT, «ip_address» STRING, «city» STRING, «state» STRING, «postal_code» STRING, «browser» STRING, «traffic_source» STRING, «uri» STRING, «event_type» STRING)

theorem eq (t0 : TableRel EVENTS_schema) :
    (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"session_id\", \"browser\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000.0 AS duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"session_id\", \"browser\") SELECT \"browser\", AVG(duration_seconds) AS AVG_USER_DURATION FROM session_durations GROUP BY \"browser\" HAVING COUNT(*) > 10 ORDER BY AVG_USER_DURATION ASC LIMIT 3") t0
  = (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"session_id\", \"browser\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000.0 AS duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"session_id\", \"browser\"), browser_stats AS (SELECT \"browser\", AVG(duration_seconds) AS avg_session_duration, COUNT(*) AS total_sessions FROM session_durations GROUP BY \"browser\") SELECT \"browser\", avg_session_duration FROM browser_stats WHERE total_sessions > 10 ORDER BY avg_session_duration ASC LIMIT 3") t0
  := by first | sql_equiv | sorry

end N_sf_bq333_eq_1_3
