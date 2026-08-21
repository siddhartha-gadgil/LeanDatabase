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
    (sql%([EVENTS_schema]) "SELECT \"browser\",\n  AVG(TIMESTAMPDIFF('SECOND', \n    TO_TIMESTAMP(MIN_ts / 1000000), \n    TO_TIMESTAMP(MAX_ts / 1000000))) AS AVG_USER_DURATION\nFROM (\n  SELECT \"user_id\", \"session_id\", \"browser\",\n    MIN(\"created_at\") AS MIN_ts,\n    MAX(\"created_at\") AS MAX_ts\n  FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n  GROUP BY \"user_id\", \"session_id\", \"browser\"\n) sub\nGROUP BY \"browser\"\nHAVING COUNT(*) > 10\nORDER BY AVG_USER_DURATION ASC\nLIMIT 3;") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (\n  SELECT \n    \"session_id\",\n    \"browser\",\n    (MAX(\"created_at\") - MIN(\"created_at\")) / 1000000.0 AS duration_seconds\n  FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n  GROUP BY \"session_id\", \"browser\"\n)\nSELECT \n  \"browser\",\n  AVG(duration_seconds) AS AVG_USER_DURATION\nFROM session_durations\nGROUP BY \"browser\"\nHAVING COUNT(*) > 10\nORDER BY AVG_USER_DURATION ASC\nLIMIT 3;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([EVENTS_schema]) "SELECT \"browser\",\n  AVG(TIMESTAMPDIFF('SECOND', \n    TO_TIMESTAMP(MIN_ts / 1000000), \n    TO_TIMESTAMP(MAX_ts / 1000000))) AS AVG_USER_DURATION\nFROM (\n  SELECT \"user_id\", \"session_id\", \"browser\",\n    MIN(\"created_at\") AS MIN_ts,\n    MAX(\"created_at\") AS MAX_ts\n  FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n  GROUP BY \"user_id\", \"session_id\", \"browser\"\n) sub\nGROUP BY \"browser\"\nHAVING COUNT(*) > 10\nORDER BY AVG_USER_DURATION ASC\nLIMIT 3;") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (\n    SELECT\n        \"browser\",\n        \"session_id\",\n        (MAX(\"created_at\") - MIN(\"created_at\")) / 1000000 AS session_duration_seconds\n    FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n    GROUP BY \"browser\", \"session_id\"\n)\nSELECT\n    \"browser\",\n    AVG(session_duration_seconds) AS \"AVG_USER_DURATION\"\nFROM session_durations\nGROUP BY \"browser\"\nHAVING COUNT(\"session_id\") > 10\nORDER BY \"AVG_USER_DURATION\" ASC\nLIMIT 3;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_3 : ∀ t,
    (sql%([EVENTS_schema]) "SELECT \"browser\",\n  AVG(TIMESTAMPDIFF('SECOND', \n    TO_TIMESTAMP(MIN_ts / 1000000), \n    TO_TIMESTAMP(MAX_ts / 1000000))) AS AVG_USER_DURATION\nFROM (\n  SELECT \"user_id\", \"session_id\", \"browser\",\n    MIN(\"created_at\") AS MIN_ts,\n    MAX(\"created_at\") AS MAX_ts\n  FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n  GROUP BY \"user_id\", \"session_id\", \"browser\"\n) sub\nGROUP BY \"browser\"\nHAVING COUNT(*) > 10\nORDER BY AVG_USER_DURATION ASC\nLIMIT 3;") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (\n  SELECT \n    \"session_id\",\n    \"browser\",\n    (MAX(\"created_at\") - MIN(\"created_at\")) / 1000000.0 AS duration_seconds\n  FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n  GROUP BY \"session_id\", \"browser\"\n),\nbrowser_stats AS (\n  SELECT\n    \"browser\",\n    AVG(duration_seconds) AS avg_session_duration,\n    COUNT(*) AS total_sessions\n  FROM session_durations\n  GROUP BY \"browser\"\n)\nSELECT \"browser\", avg_session_duration\nFROM browser_stats\nWHERE total_sessions > 10\nORDER BY avg_session_duration ASC\nLIMIT 3;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([EVENTS_schema]) "WITH session_durations AS (\n  SELECT \n    \"session_id\",\n    \"browser\",\n    (MAX(\"created_at\") - MIN(\"created_at\")) / 1000000.0 AS duration_seconds\n  FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n  GROUP BY \"session_id\", \"browser\"\n)\nSELECT \n  \"browser\",\n  AVG(duration_seconds) AS AVG_USER_DURATION\nFROM session_durations\nGROUP BY \"browser\"\nHAVING COUNT(*) > 10\nORDER BY AVG_USER_DURATION ASC\nLIMIT 3;") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (\n    SELECT\n        \"browser\",\n        \"session_id\",\n        (MAX(\"created_at\") - MIN(\"created_at\")) / 1000000 AS session_duration_seconds\n    FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n    GROUP BY \"browser\", \"session_id\"\n)\nSELECT\n    \"browser\",\n    AVG(session_duration_seconds) AS \"AVG_USER_DURATION\"\nFROM session_durations\nGROUP BY \"browser\"\nHAVING COUNT(\"session_id\") > 10\nORDER BY \"AVG_USER_DURATION\" ASC\nLIMIT 3;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([EVENTS_schema]) "WITH session_durations AS (\n  SELECT \n    \"session_id\",\n    \"browser\",\n    (MAX(\"created_at\") - MIN(\"created_at\")) / 1000000.0 AS duration_seconds\n  FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n  GROUP BY \"session_id\", \"browser\"\n)\nSELECT \n  \"browser\",\n  AVG(duration_seconds) AS AVG_USER_DURATION\nFROM session_durations\nGROUP BY \"browser\"\nHAVING COUNT(*) > 10\nORDER BY AVG_USER_DURATION ASC\nLIMIT 3;" = sql%([EVENTS_schema]) "WITH session_durations AS (\n  SELECT \n    \"session_id\",\n    \"browser\",\n    (MAX(\"created_at\") - MIN(\"created_at\")) / 1000000.0 AS duration_seconds\n  FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n  GROUP BY \"session_id\", \"browser\"\n),\nbrowser_stats AS (\n  SELECT\n    \"browser\",\n    AVG(duration_seconds) AS avg_session_duration,\n    COUNT(*) AS total_sessions\n  FROM session_durations\n  GROUP BY \"browser\"\n)\nSELECT \"browser\", avg_session_duration\nFROM browser_stats\nWHERE total_sessions > 10\nORDER BY avg_session_duration ASC\nLIMIT 3;" := by
  first | sql_equiv | sorry

theorem eq_2_3 : ∀ t,
    (sql%([EVENTS_schema]) "WITH session_durations AS (\n    SELECT\n        \"browser\",\n        \"session_id\",\n        (MAX(\"created_at\") - MIN(\"created_at\")) / 1000000 AS session_duration_seconds\n    FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n    GROUP BY \"browser\", \"session_id\"\n)\nSELECT\n    \"browser\",\n    AVG(session_duration_seconds) AS \"AVG_USER_DURATION\"\nFROM session_durations\nGROUP BY \"browser\"\nHAVING COUNT(\"session_id\") > 10\nORDER BY \"AVG_USER_DURATION\" ASC\nLIMIT 3;") t ~= (sql%([EVENTS_schema]) "WITH session_durations AS (\n  SELECT \n    \"session_id\",\n    \"browser\",\n    (MAX(\"created_at\") - MIN(\"created_at\")) / 1000000.0 AS duration_seconds\n  FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"EVENTS\"\n  GROUP BY \"session_id\", \"browser\"\n),\nbrowser_stats AS (\n  SELECT\n    \"browser\",\n    AVG(duration_seconds) AS avg_session_duration,\n    COUNT(*) AS total_sessions\n  FROM session_durations\n  GROUP BY \"browser\"\n)\nSELECT \"browser\", avg_session_duration\nFROM browser_stats\nWHERE total_sessions > 10\nORDER BY avg_session_duration ASC\nLIMIT 3;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq333
