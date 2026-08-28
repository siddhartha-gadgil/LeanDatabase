import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq333 — crossskill equivalence(s)

Question: Which three browsers have the shortest average session duration—calculated by the difference in seconds between the earliest and latest timestamps for each user’s session—while only including browsers that have more than 10 total sessions, and what are their respective average session durations?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq333

CREATE TABLE EVENTS («id» INT, «user_id» INT, «sequence_number» INT, «session_id» STRING, «created_at» INT, «ip_address» STRING, «city» STRING, «state» STRING, «postal_code» STRING, «browser» STRING, «traffic_source» STRING, «uri» STRING, «event_type» STRING)

theorem eq_0_1 : ∀ t,
    (sql%([EVENTS_schema]) "SELECT \"browser\", AVG(CAST(EXTRACT(epoch FROM CAST(TO_TIMESTAMP(CAST(MAX_ts AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP) - CAST(TO_TIMESTAMP(CAST(MIN_ts AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP)) AS BIGINT)) AS AVG_USER_DURATION FROM (SELECT \"user_id\", \"session_id\", \"browser\", MIN(\"created_at\") AS MIN_ts, MAX(\"created_at\") AS MAX_ts FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"user_id\", \"session_id\", \"browser\") AS sub GROUP BY \"browser\" HAVING COUNT(*) > 10 ORDER BY AVG_USER_DURATION ASC LIMIT 3") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"session_id\", \"browser\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000.0 AS duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"session_id\", \"browser\") SELECT \"browser\", AVG(duration_seconds) AS AVG_USER_DURATION FROM session_durations GROUP BY \"browser\" HAVING COUNT(*) > 10 ORDER BY AVG_USER_DURATION ASC LIMIT 3") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([EVENTS_schema]) "SELECT \"browser\", AVG(CAST(EXTRACT(epoch FROM CAST(TO_TIMESTAMP(CAST(MAX_ts AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP) - CAST(TO_TIMESTAMP(CAST(MIN_ts AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP)) AS BIGINT)) AS AVG_USER_DURATION FROM (SELECT \"user_id\", \"session_id\", \"browser\", MIN(\"created_at\") AS MIN_ts, MAX(\"created_at\") AS MAX_ts FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"user_id\", \"session_id\", \"browser\") AS sub GROUP BY \"browser\" HAVING COUNT(*) > 10 ORDER BY AVG_USER_DURATION ASC LIMIT 3") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"browser\", \"session_id\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000 AS session_duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"browser\", \"session_id\") SELECT \"browser\", AVG(session_duration_seconds) AS \"AVG_USER_DURATION\" FROM session_durations GROUP BY \"browser\" HAVING COUNT(\"session_id\") > 10 ORDER BY \"AVG_USER_DURATION\" ASC LIMIT 3") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_3 : ∀ t,
    (sql%([EVENTS_schema]) "SELECT \"browser\", AVG(CAST(EXTRACT(epoch FROM CAST(TO_TIMESTAMP(CAST(MAX_ts AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP) - CAST(TO_TIMESTAMP(CAST(MIN_ts AS DOUBLE PRECISION) / 1000000) AS TIMESTAMP)) AS BIGINT)) AS AVG_USER_DURATION FROM (SELECT \"user_id\", \"session_id\", \"browser\", MIN(\"created_at\") AS MIN_ts, MAX(\"created_at\") AS MAX_ts FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"user_id\", \"session_id\", \"browser\") AS sub GROUP BY \"browser\" HAVING COUNT(*) > 10 ORDER BY AVG_USER_DURATION ASC LIMIT 3") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"session_id\", \"browser\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000.0 AS duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"session_id\", \"browser\"), browser_stats AS (SELECT \"browser\", AVG(duration_seconds) AS avg_session_duration, COUNT(*) AS total_sessions FROM session_durations GROUP BY \"browser\") SELECT \"browser\", avg_session_duration FROM browser_stats WHERE total_sessions > 10 ORDER BY avg_session_duration ASC LIMIT 3") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"session_id\", \"browser\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000.0 AS duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"session_id\", \"browser\") SELECT \"browser\", AVG(duration_seconds) AS AVG_USER_DURATION FROM session_durations GROUP BY \"browser\" HAVING COUNT(*) > 10 ORDER BY AVG_USER_DURATION ASC LIMIT 3") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"browser\", \"session_id\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000 AS session_duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"browser\", \"session_id\") SELECT \"browser\", AVG(session_duration_seconds) AS \"AVG_USER_DURATION\" FROM session_durations GROUP BY \"browser\" HAVING COUNT(\"session_id\") > 10 ORDER BY \"AVG_USER_DURATION\" ASC LIMIT 3") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"session_id\", \"browser\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000.0 AS duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"session_id\", \"browser\") SELECT \"browser\", AVG(duration_seconds) AS AVG_USER_DURATION FROM session_durations GROUP BY \"browser\" HAVING COUNT(*) > 10 ORDER BY AVG_USER_DURATION ASC LIMIT 3" = sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"session_id\", \"browser\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000.0 AS duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"session_id\", \"browser\"), browser_stats AS (SELECT \"browser\", AVG(duration_seconds) AS avg_session_duration, COUNT(*) AS total_sessions FROM session_durations GROUP BY \"browser\") SELECT \"browser\", avg_session_duration FROM browser_stats WHERE total_sessions > 10 ORDER BY avg_session_duration ASC LIMIT 3" := by
  first | sql_equiv | sorry

theorem eq_2_3 : ∀ t,
    (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"browser\", \"session_id\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000 AS session_duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"browser\", \"session_id\") SELECT \"browser\", AVG(session_duration_seconds) AS \"AVG_USER_DURATION\" FROM session_durations GROUP BY \"browser\" HAVING COUNT(\"session_id\") > 10 ORDER BY \"AVG_USER_DURATION\" ASC LIMIT 3") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (SELECT \"session_id\", \"browser\", CAST((MAX(\"created_at\") - MIN(\"created_at\")) AS DOUBLE PRECISION) / 1000000.0 AS duration_seconds FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\" GROUP BY \"session_id\", \"browser\"), browser_stats AS (SELECT \"browser\", AVG(duration_seconds) AS avg_session_duration, COUNT(*) AS total_sessions FROM session_durations GROUP BY \"browser\") SELECT \"browser\", avg_session_duration FROM browser_stats WHERE total_sessions > 10 ORDER BY avg_session_duration ASC LIMIT 3") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq333
