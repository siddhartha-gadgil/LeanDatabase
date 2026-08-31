import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq333_eq_0_2

CREATE TABLE EVENTS («id» INT, «user_id» INT, «sequence_number» INT, «session_id» STRING, «created_at» INT, «ip_address» STRING, «city» STRING, «state» STRING, «postal_code» STRING, «browser» STRING, «traffic_source» STRING, «uri» STRING, «event_type» STRING)

theorem eq (t0 : TableRel EVENTS_schema) :
    (sql%([EVENTS_schema]) "SELECT \"browser\", AVG(CAST(EXTRACT(epoch FROM CAST(TO_TIMESTAMP(CAST(MAX_ts AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP) - CAST(TO_TIMESTAMP(CAST(MIN_ts AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP)) AS BIGINT)) AS AVG_USER_DURATION FROM (SELECT \"user_id\", \"session_id\", \"browser\", MIN(\"created_at\") AS MIN_ts, MAX(\"created_at\") AS MAX_ts FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"user_id\", \"session_id\", \"browser\") AS sub GROUP BY \"browser\" HAVING COUNT(*) > 10 ORDER BY AVG_USER_DURATION ASC LIMIT 3") t0
  ~= (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"browser\", \"session_id\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000 AS session_duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"browser\", \"session_id\") SELECT \"browser\", AVG(session_duration_seconds) AS \"AVG_USER_DURATION\" FROM session_durations GROUP BY \"browser\" HAVING COUNT(\"session_id\") > 10 ORDER BY \"AVG_USER_DURATION\" ASC LIMIT 3") t0
  := by first | sql_equiv | sorry

end N_sf_bq333_eq_0_2
