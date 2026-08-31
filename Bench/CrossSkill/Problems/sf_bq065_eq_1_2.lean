import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq065_eq_1_2

CREATE TABLE ORACLE_REQUESTS («block_height» INT, «block_timestamp» STRING, «block_timestamp_truncated» INT, «oracle_request_id» INT, «request» STRING, «reports» STRING, «result» STRING, «decoded_result» STRING, «oracle_script» STRING)

theorem eq (t0 : TableRel ORACLE_REQUESTS_schema) :
    (sql%([ORACLE_REQUESTS_schema]) "WITH top_requests AS (SELECT \"block_timestamp\", \"oracle_request_id\", \"decoded_result\" FROM \"CRYPTO\".\"CRYPTO_BAND\".\"ORACLE_REQUESTS\" WHERE CAST(JSON_EXTRACT_PATH(\"request\", 'oracle_script_id') AS INT) = 3 ORDER BY \"block_timestamp\" DESC, \"oracle_request_id\" DESC LIMIT 10) SELECT \"block_timestamp\" AS BLOCK_TIMESTAMP, \"oracle_request_id\" AS ORACLE_REQUEST_ID, CAST(s.VALUE AS TEXT) AS SYMBOL, CAST(r.VALUE AS DOUBLE PRECISION) / CAST(JSON_EXTRACT_PATH(CAST(JSON_EXTRACT_PATH(\"decoded_result\", 'calldata') AS JSON), 'multiplier') AS DOUBLE PRECISION) AS ADJUSTED_RATE FROM top_requests, LATERAL UNNEST(input => JSON_EXTRACT_PATH(CAST(JSON_EXTRACT_PATH(\"decoded_result\", 'calldata') AS JSON), 'symbols')) AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(input => JSON_EXTRACT_PATH(CAST(JSON_EXTRACT_PATH(\"decoded_result\", 'result') AS JSON), 'rates')) AS r(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE s.INDEX = r.INDEX ORDER BY \"block_timestamp\" DESC, \"oracle_request_id\" DESC, s.INDEX") t0
  ~= (sql%([ORACLE_REQUESTS_schema]) "WITH top10 AS (SELECT \"block_timestamp\", \"oracle_request_id\", CAST(JSON_EXTRACT_PATH(\"decoded_result\", 'calldata') AS JSON) AS calldata, CAST(JSON_EXTRACT_PATH(\"decoded_result\", 'result') AS JSON) AS result_obj FROM \"CRYPTO\".\"CRYPTO_BAND\".\"ORACLE_REQUESTS\" WHERE CAST(JSON_EXTRACT_PATH(\"request\", 'oracle_script_id') AS INT) = 3 ORDER BY \"block_timestamp\" DESC, \"oracle_request_id\" DESC LIMIT 10) SELECT t.\"block_timestamp\" AS \"BLOCK_TIMESTAMP\", t.\"oracle_request_id\" AS \"ORACLE_REQUEST_ID\", CAST(sym.VALUE AS TEXT) AS \"SYMBOL\", CAST(rates.VALUE AS DOUBLE PRECISION) / CAST(JSON_EXTRACT_PATH(calldata, 'multiplier') AS DOUBLE PRECISION) AS \"ADJUSTED_RATE\" FROM top10 AS t, LATERAL UNNEST(input => JSON_EXTRACT_PATH(t.calldata, 'symbols')) AS sym(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(input => JSON_EXTRACT_PATH(t.result_obj, 'rates')) AS rates(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE sym.INDEX = rates.INDEX ORDER BY t.\"block_timestamp\" DESC, t.\"oracle_request_id\" DESC") t0
  := by first | sql_equiv | sorry

end N_sf_bq065_eq_1_2
