import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_ga003 — crossskill equivalence(s)

Question: I'm trying to evaluate which board types were most effective on September 15, 2018. Can you find out the average scores for each board type from the quick play mode completions on that day?

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_ga003

CREATE TABLE EVENTS_20180915 («event_date» STRING, «event_timestamp» INT, «event_name» STRING, «event_params» STRING, «event_previous_timestamp» INT, «event_value_in_usd» FLOAT, «event_bundle_sequence_id» INT, «event_server_timestamp_offset» INT, «user_id» STRING, «user_pseudo_id» STRING, «user_properties» STRING, «user_first_touch_timestamp» INT, «user_ltv» STRING, «device» STRING, «geo» STRING, «app_info» STRING, «traffic_source» STRING, «stream_id» STRING, «platform» STRING, «event_dimensions» STRING)

theorem eq_0_1 :
    sql%([EVENTS_20180915_schema]) "SELECT\n  board_type AS BOARD,\n  ROUND(AVG(score), 6) AS AVERAGE_SCORE\nFROM (\n  SELECT\n    MAX(CASE WHEN f.value:key::STRING = 'board' THEN f.value:value:string_value::STRING END) AS board_type,\n    MAX(CASE WHEN f.value:key::STRING = 'value' THEN f.value:value:int_value::INT END) AS score\n  FROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" e,\n  LATERAL FLATTEN(input => e.\"event_params\") f\n  WHERE e.\"event_name\" = 'level_complete_quickplay'\n  GROUP BY e.\"event_timestamp\", e.\"user_pseudo_id\"\n)\nGROUP BY board_type\nORDER BY board_type;" = sql%([EVENTS_20180915_schema]) "SELECT \n  f_board.value:value:string_value::STRING AS BOARD,\n  ROUND(AVG(f_val.value:value:int_value::NUMBER), 6) AS AVERAGE_SCORE\nFROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" e,\n  LATERAL FLATTEN(input => PARSE_JSON(e.\"event_params\")) f_board,\n  LATERAL FLATTEN(input => PARSE_JSON(e.\"event_params\")) f_val\nWHERE e.\"event_name\" = 'level_complete_quickplay'\n  AND f_board.value:key::STRING = 'board'\n  AND f_val.value:key::STRING = 'value'\nGROUP BY BOARD\nORDER BY AVERAGE_SCORE DESC;" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([EVENTS_20180915_schema]) "SELECT\n  board_type AS BOARD,\n  ROUND(AVG(score), 6) AS AVERAGE_SCORE\nFROM (\n  SELECT\n    MAX(CASE WHEN f.value:key::STRING = 'board' THEN f.value:value:string_value::STRING END) AS board_type,\n    MAX(CASE WHEN f.value:key::STRING = 'value' THEN f.value:value:int_value::INT END) AS score\n  FROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" e,\n  LATERAL FLATTEN(input => e.\"event_params\") f\n  WHERE e.\"event_name\" = 'level_complete_quickplay'\n  GROUP BY e.\"event_timestamp\", e.\"user_pseudo_id\"\n)\nGROUP BY board_type\nORDER BY board_type;" = sql%([EVENTS_20180915_schema]) "SELECT\n  bp.value:value:string_value::STRING AS \"BOARD\",\n  AVG(sp.value:value:int_value::INT) AS \"AVERAGE_SCORE\"\nFROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" e,\n     LATERAL FLATTEN(input => e.\"event_params\") bp,\n     LATERAL FLATTEN(input => e.\"event_params\") sp\nWHERE e.\"event_name\" = 'level_complete_quickplay'\n  AND bp.value:key::STRING = 'board'\n  AND sp.value:key::STRING = 'value'\nGROUP BY bp.value:value:string_value::STRING\nORDER BY bp.value:value:string_value::STRING;" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : EVENTS_20180915 "\"event_name\" = 'level_complete_quickplay'"
theorem eq_0_3 (t : TableRel EVENTS_20180915_schema) (h0 : hyp0_3_0 t) :
    (sql%([EVENTS_20180915_schema]) "SELECT\n  board_type AS BOARD,\n  ROUND(AVG(score), 6) AS AVERAGE_SCORE\nFROM (\n  SELECT\n    MAX(CASE WHEN f.value:key::STRING = 'board' THEN f.value:value:string_value::STRING END) AS board_type,\n    MAX(CASE WHEN f.value:key::STRING = 'value' THEN f.value:value:int_value::INT END) AS score\n  FROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" e,\n  LATERAL FLATTEN(input => e.\"event_params\") f\n  WHERE e.\"event_name\" = 'level_complete_quickplay'\n  GROUP BY e.\"event_timestamp\", e.\"user_pseudo_id\"\n)\nGROUP BY board_type\nORDER BY board_type;") t ~= (sql%([EVENTS_20180915_schema]) "SELECT \n  f1.value:\"value\":\"string_value\"::VARCHAR AS board_type,\n  AVG(f2.value:\"value\":\"int_value\"::INT) AS average_score\nFROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\",\n  LATERAL FLATTEN(input => \"event_params\") f1,\n  LATERAL FLATTEN(input => \"event_params\") f2\nWHERE \"event_name\" = 'level_complete_quickplay'\n  AND f1.value:\"key\"::VARCHAR = 'board'\n  AND f2.value:\"key\"::VARCHAR = 'value'\nGROUP BY board_type\nORDER BY average_score DESC;") t := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([EVENTS_20180915_schema]) "SELECT \n  f_board.value:value:string_value::STRING AS BOARD,\n  ROUND(AVG(f_val.value:value:int_value::NUMBER), 6) AS AVERAGE_SCORE\nFROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" e,\n  LATERAL FLATTEN(input => PARSE_JSON(e.\"event_params\")) f_board,\n  LATERAL FLATTEN(input => PARSE_JSON(e.\"event_params\")) f_val\nWHERE e.\"event_name\" = 'level_complete_quickplay'\n  AND f_board.value:key::STRING = 'board'\n  AND f_val.value:key::STRING = 'value'\nGROUP BY BOARD\nORDER BY AVERAGE_SCORE DESC;" = sql%([EVENTS_20180915_schema]) "SELECT\n  bp.value:value:string_value::STRING AS \"BOARD\",\n  AVG(sp.value:value:int_value::INT) AS \"AVERAGE_SCORE\"\nFROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" e,\n     LATERAL FLATTEN(input => e.\"event_params\") bp,\n     LATERAL FLATTEN(input => e.\"event_params\") sp\nWHERE e.\"event_name\" = 'level_complete_quickplay'\n  AND bp.value:key::STRING = 'board'\n  AND sp.value:key::STRING = 'value'\nGROUP BY bp.value:value:string_value::STRING\nORDER BY bp.value:value:string_value::STRING;" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : EVENTS_20180915 "\"event_name\" = 'level_complete_quickplay'"
theorem eq_1_3 (t : TableRel EVENTS_20180915_schema) (h0 : hyp1_3_0 t) :
    (sql%([EVENTS_20180915_schema]) "SELECT \n  f_board.value:value:string_value::STRING AS BOARD,\n  ROUND(AVG(f_val.value:value:int_value::NUMBER), 6) AS AVERAGE_SCORE\nFROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" e,\n  LATERAL FLATTEN(input => PARSE_JSON(e.\"event_params\")) f_board,\n  LATERAL FLATTEN(input => PARSE_JSON(e.\"event_params\")) f_val\nWHERE e.\"event_name\" = 'level_complete_quickplay'\n  AND f_board.value:key::STRING = 'board'\n  AND f_val.value:key::STRING = 'value'\nGROUP BY BOARD\nORDER BY AVERAGE_SCORE DESC;") t ~= (sql%([EVENTS_20180915_schema]) "SELECT \n  f1.value:\"value\":\"string_value\"::VARCHAR AS board_type,\n  AVG(f2.value:\"value\":\"int_value\"::INT) AS average_score\nFROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\",\n  LATERAL FLATTEN(input => \"event_params\") f1,\n  LATERAL FLATTEN(input => \"event_params\") f2\nWHERE \"event_name\" = 'level_complete_quickplay'\n  AND f1.value:\"key\"::VARCHAR = 'board'\n  AND f2.value:\"key\"::VARCHAR = 'value'\nGROUP BY board_type\nORDER BY average_score DESC;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : EVENTS_20180915 "\"event_name\" = 'level_complete_quickplay'"
theorem eq_2_3 (t : TableRel EVENTS_20180915_schema) (h0 : hyp2_3_0 t) :
    (sql%([EVENTS_20180915_schema]) "SELECT\n  bp.value:value:string_value::STRING AS \"BOARD\",\n  AVG(sp.value:value:int_value::INT) AS \"AVERAGE_SCORE\"\nFROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" e,\n     LATERAL FLATTEN(input => e.\"event_params\") bp,\n     LATERAL FLATTEN(input => e.\"event_params\") sp\nWHERE e.\"event_name\" = 'level_complete_quickplay'\n  AND bp.value:key::STRING = 'board'\n  AND sp.value:key::STRING = 'value'\nGROUP BY bp.value:value:string_value::STRING\nORDER BY bp.value:value:string_value::STRING;") t ~= (sql%([EVENTS_20180915_schema]) "SELECT \n  f1.value:\"value\":\"string_value\"::VARCHAR AS board_type,\n  AVG(f2.value:\"value\":\"int_value\"::INT) AS average_score\nFROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\",\n  LATERAL FLATTEN(input => \"event_params\") f1,\n  LATERAL FLATTEN(input => \"event_params\") f2\nWHERE \"event_name\" = 'level_complete_quickplay'\n  AND f1.value:\"key\"::VARCHAR = 'board'\n  AND f2.value:\"key\"::VARCHAR = 'value'\nGROUP BY board_type\nORDER BY average_score DESC;") t := by
  first | sql_equiv | sorry

end Bench_sf_ga003
