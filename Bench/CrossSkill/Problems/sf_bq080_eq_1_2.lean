import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq080_eq_1_2

CREATE TABLE TRACES («transaction_hash» STRING, «transaction_index» INT, «from_address» STRING, «to_address» STRING, «value» INT, «input» STRING, «output» STRING, «trace_type» STRING, «call_type» STRING, «reward_type» STRING, «gas» INT, «gas_used» INT, «subtraces» INT, «trace_address» STRING, «error» STRING, «status» INT, «block_timestamp» INT, «block_number» INT, «block_hash» STRING, «trace_id» STRING)

theorem eq (t0 : TableRel TRACES_schema) :
    (sql%([TRACES_schema]) "WITH date_spine AS (/* Generate all dates from Aug 30 to Sep 30, 2018 (32 days) */ SELECT CAST('2018-08-30' AS DATE) + INTERVAL '1 DAY' * SEQ4() AS \"DATE\" FROM TABLE(GENERATOR(32))), daily_counts AS (/* Count daily contract creations by type */ SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / POWER(10, 6)) AS DATE) AS dt, SUM(CASE WHEN \"trace_address\" IS NULL THEN 1 ELSE 0 END) AS external_daily, SUM(CASE WHEN NOT \"trace_address\" IS NULL THEN 1 ELSE 0 END) AS contract_daily FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TRACES\" WHERE \"trace_type\" = 'create' AND CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / POWER(10, 6)) AS DATE) BETWEEN '2018-08-30' AND '2018-09-30' GROUP BY dt) SELECT ds.\"DATE\", SUM(COALESCE(dc.external_daily, 0)) OVER (ORDER BY ds.\"DATE\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS \"EXTERNAL_USER_CUMULATIVE_CONTRACTS\", SUM(COALESCE(dc.contract_daily, 0)) OVER (ORDER BY ds.\"DATE\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS \"CONTRACT_CREATOR_CUMULATIVE_CONTRACTS\" FROM date_spine AS ds LEFT JOIN daily_counts AS dc ON ds.\"DATE\" = dc.dt ORDER BY ds.\"DATE\"") t0
  = (sql%([TRACES_schema]) "WITH date_range AS (SELECT CAST('2018-08-30' AS DATE) + INTERVAL '1 DAY' * SEQ4() AS \"DATE\" FROM TABLE(GENERATOR(32))), daily_counts AS (SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS dt, COUNT(CASE WHEN \"trace_address\" IS NULL THEN 1 END) AS external_user_count, COUNT(CASE WHEN NOT \"trace_address\" IS NULL THEN 1 END) AS contract_creator_count FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TRACES\" WHERE \"trace_type\" = 'create' AND CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) BETWEEN '2018-08-30' AND '2018-09-30' GROUP BY dt), joined AS (SELECT dr.\"DATE\", COALESCE(dc.external_user_count, 0) AS external_user_count, COALESCE(dc.contract_creator_count, 0) AS contract_creator_count FROM date_range AS dr LEFT JOIN daily_counts AS dc ON dr.\"DATE\" = dc.dt) SELECT \"DATE\", SUM(external_user_count) OVER (ORDER BY \"DATE\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS \"EXTERNAL_USER_CUMULATIVE_CONTRACTS\", SUM(contract_creator_count) OVER (ORDER BY \"DATE\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS \"CONTRACT_CREATOR_CUMULATIVE_CONTRACTS\" FROM joined ORDER BY \"DATE\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq080_eq_1_2
