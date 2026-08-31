import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq184_eq_0_3

CREATE TABLE TRACES («transaction_hash» STRING, «transaction_index» INT, «from_address» STRING, «to_address» STRING, «value» INT, «input» STRING, «output» STRING, «trace_type» STRING, «call_type» STRING, «reward_type» STRING, «gas» INT, «gas_used» INT, «subtraces» INT, «trace_address» STRING, «error» STRING, «status» INT, «block_timestamp» INT, «block_number» INT, «block_hash» STRING, «trace_id» STRING)

theorem eq (t0 : TableRel TRACES_schema) :
    (sql%([TRACES_schema]) "WITH date_spine AS (SELECT CAST('2017-01-01' AS DATE) + INTERVAL '1 DAY' * (ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1) AS \"DATE\" FROM TABLE(GENERATOR(1826))), daily_counts AS (SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS dt, SUM(CASE WHEN \"trace_address\" IS NULL THEN 1 ELSE 0 END) AS external_daily, SUM(CASE WHEN NOT \"trace_address\" IS NULL THEN 1 ELSE 0 END) AS contract_daily FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TRACES\" WHERE \"trace_type\" = 'create' AND CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) BETWEEN '2017-01-01' AND '2021-12-31' GROUP BY dt) SELECT d.\"DATE\", COALESCE(dc.external_daily, 0) AS \"EXTERNAL_DAILY\", COALESCE(dc.contract_daily, 0) AS \"CONTRACT_DAILY\", SUM(COALESCE(dc.external_daily, 0)) OVER (ORDER BY d.\"DATE\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS \"EXTERNAL_CUMULATIVE\", SUM(COALESCE(dc.contract_daily, 0)) OVER (ORDER BY d.\"DATE\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS \"CONTRACT_CUMULATIVE\" FROM date_spine AS d LEFT JOIN daily_counts AS dc ON d.\"DATE\" = dc.dt ORDER BY d.\"DATE\"") t0
  = (sql%([TRACES_schema]) "WITH date_spine AS (SELECT CAST('2017-01-01' AS DATE) + INTERVAL '1 DAY' * SEQ4() AS \"date\" FROM TABLE(GENERATOR(1827))), daily_counts AS (SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS create_date, COUNT(CASE WHEN \"trace_address\" IS NULL THEN 1 END) AS external_daily, COUNT(CASE WHEN NOT \"trace_address\" IS NULL THEN 1 END) AS contract_daily FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TRACES\" WHERE \"trace_type\" = 'create' AND CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) BETWEEN '2017-01-01' AND '2021-12-31' GROUP BY create_date) SELECT ds.\"date\" AS \"date\", COALESCE(dc.external_daily, 0) AS \"external_daily\", COALESCE(dc.contract_daily, 0) AS \"contract_daily\", SUM(COALESCE(dc.external_daily, 0)) OVER (ORDER BY ds.\"date\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS \"external_cumulative\", SUM(COALESCE(dc.contract_daily, 0)) OVER (ORDER BY ds.\"date\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS \"contract_cumulative\" FROM date_spine AS ds LEFT JOIN daily_counts AS dc ON ds.\"date\" = dc.create_date WHERE ds.\"date\" BETWEEN '2017-01-01' AND '2021-12-31' ORDER BY ds.\"date\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq184_eq_0_3
