import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_ga003_eq_0_1

CREATE TABLE EVENTS_20180915 («event_date» STRING, «event_timestamp» INT, «event_name» STRING, «event_params» STRING, «event_previous_timestamp» INT, «event_value_in_usd» FLOAT, «event_bundle_sequence_id» INT, «event_server_timestamp_offset» INT, «user_id» STRING, «user_pseudo_id» STRING, «user_properties» STRING, «user_first_touch_timestamp» INT, «user_ltv» STRING, «device» STRING, «geo» STRING, «app_info» STRING, «traffic_source» STRING, «stream_id» STRING, «platform» STRING, «event_dimensions» STRING)

theorem eq (t0 : TableRel EVENTS_20180915_schema) :
    (sql%([EVENTS_20180915_schema]) "SELECT board_type AS BOARD, ROUND(CAST(AVG(score) AS DECIMAL), 6) AS AVERAGE_SCORE FROM (SELECT MAX(CASE WHEN CAST(JSON_EXTRACT_PATH(f.value, 'key') AS TEXT) = 'board' THEN CAST(JSON_EXTRACT_PATH(f.value, 'value', 'string_value') AS TEXT) END) AS board_type, MAX(CASE WHEN CAST(JSON_EXTRACT_PATH(f.value, 'key') AS TEXT) = 'value' THEN CAST(JSON_EXTRACT_PATH(f.value, 'value', 'int_value') AS INT) END) AS score FROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" AS e, LATERAL UNNEST(input => e.\"event_params\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE e.\"event_name\" = 'level_complete_quickplay' GROUP BY e.\"event_timestamp\", e.\"user_pseudo_id\") GROUP BY board_type ORDER BY board_type") t0
  = (sql%([EVENTS_20180915_schema]) "SELECT CAST(JSON_EXTRACT_PATH(f_board.value, 'value', 'string_value') AS TEXT) AS BOARD, ROUND(CAST(AVG(CAST(JSON_EXTRACT_PATH(f_val.value, 'value', 'int_value') AS DECIMAL(38, 0))) AS DECIMAL), 6) AS AVERAGE_SCORE FROM \"FIREBASE\".\"ANALYTICS_153293282\".\"EVENTS_20180915\" AS e, LATERAL UNNEST(input => CAST(e.\"event_params\" AS JSON)) AS f_board(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(input => CAST(e.\"event_params\" AS JSON)) AS f_val(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE e.\"event_name\" = 'level_complete_quickplay' AND CAST(JSON_EXTRACT_PATH(f_board.value, 'key') AS TEXT) = 'board' AND CAST(JSON_EXTRACT_PATH(f_val.value, 'key') AS TEXT) = 'value' GROUP BY BOARD ORDER BY AVERAGE_SCORE DESC") t0
  := by first | sql_equiv | sorry

end N_sf_ga003_eq_0_1
