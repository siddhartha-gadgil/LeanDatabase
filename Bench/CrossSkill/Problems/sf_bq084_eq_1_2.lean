import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq084_eq_1_2

CREATE TABLE TRANSACTIONS («block_hash» STRING, «block_timestamp» STRING, «transaction_hash» STRING, «transaction_index» INT, «nonce» INT, «from_address» STRING, «to_address» STRING, «value» STRING, «input» STRING, «gas» INT, «gas_price» STRING, «max_fee_per_gas» INT, «max_priority_fee_per_gas» INT, «transaction_type» INT, «access_list» STRING, «r» STRING, «s» STRING, «v» STRING)

theorem eq (t0 : TableRel TRANSACTIONS_schema) :
    (sql%([TRANSACTIONS_schema]) "SELECT COUNT(*) AS TXN_COUNT_PER_MONTH, ROUND(CAST(CAST(COUNT(*) AS DOUBLE PRECISION) / ((CAST(DATE_TRUNC('MONTH', MIN(\"block_timestamp\")) + INTERVAL '1 MONTH' AS DATE) - CAST(DATE_TRUNC('MONTH', MIN(\"block_timestamp\")) AS DATE)) * 86400) AS DECIMAL), 6) AS TXN_PER_SECOND, EXTRACT(YEAR FROM MIN(\"block_timestamp\")) AS YEAR, EXTRACT(MONTH FROM MIN(\"block_timestamp\")) AS MONTH FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_POLYGON_MAINNET_US\".\"TRANSACTIONS\" WHERE EXTRACT(YEAR FROM \"block_timestamp\") = 2023 GROUP BY EXTRACT(YEAR FROM \"block_timestamp\"), EXTRACT(MONTH FROM \"block_timestamp\") ORDER BY TXN_COUNT_PER_MONTH DESC") t0
  ~= (sql%([TRANSACTIONS_schema]) "SELECT COUNT(*) AS \"TXN_COUNT_PER_MONTH\", CAST(COUNT(*) AS DOUBLE PRECISION) / (CASE EXTRACT(MONTH FROM MIN(\"block_timestamp\")) WHEN 1 THEN 31 WHEN 2 THEN CASE WHEN EXTRACT(YEAR FROM MIN(\"block_timestamp\")) % 4 = 0 AND (EXTRACT(YEAR FROM MIN(\"block_timestamp\")) % 100 <> 0 OR EXTRACT(YEAR FROM MIN(\"block_timestamp\")) % 400 = 0) THEN 29 ELSE 28 END WHEN 3 THEN 31 WHEN 4 THEN 30 WHEN 5 THEN 31 WHEN 6 THEN 30 WHEN 7 THEN 31 WHEN 8 THEN 31 WHEN 9 THEN 30 WHEN 10 THEN 31 WHEN 11 THEN 30 WHEN 12 THEN 31 END * 86400) AS \"TXN_PER_SECOND\", EXTRACT(YEAR FROM \"block_timestamp\") AS \"YEAR\", EXTRACT(MONTH FROM \"block_timestamp\") AS \"MONTH\" FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_POLYGON_MAINNET_US\".\"TRANSACTIONS\" WHERE EXTRACT(YEAR FROM \"block_timestamp\") = 2023 GROUP BY \"YEAR\", \"MONTH\" ORDER BY \"TXN_COUNT_PER_MONTH\" DESC") t0
  := by first | sql_equiv | sorry

end N_sf_bq084_eq_1_2
