import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq084_eq_0_3

CREATE TABLE TRANSACTIONS («block_hash» STRING, «block_timestamp» STRING, «transaction_hash» STRING, «transaction_index» INT, «nonce» INT, «from_address» STRING, «to_address» STRING, «value» STRING, «input» STRING, «gas» INT, «gas_price» STRING, «max_fee_per_gas» INT, «max_priority_fee_per_gas» INT, «transaction_type» INT, «access_list» STRING, «r» STRING, «s» STRING, «v» STRING)

theorem eq (t0 : TableRel TRANSACTIONS_schema) :
    (sql%([TRANSACTIONS_schema]) "SELECT COUNT(*) AS TXN_COUNT_PER_MONTH, ROUND(CAST(CAST(COUNT(*) AS DOUBLE PRECISION) / CASE WHEN EXTRACT(MONTH FROM \"block_timestamp\") IN (1, 3, 5, 7, 8, 10, 12) THEN 31 * 24 * 3600 WHEN EXTRACT(MONTH FROM \"block_timestamp\") IN (4, 6, 9, 11) THEN 30 * 24 * 3600 WHEN EXTRACT(MONTH FROM \"block_timestamp\") = 2 THEN CASE WHEN EXTRACT(YEAR FROM \"block_timestamp\") % 4 = 0 AND (EXTRACT(YEAR FROM \"block_timestamp\") % 100 <> 0 OR EXTRACT(YEAR FROM \"block_timestamp\") % 400 = 0) THEN 29 * 24 * 3600 ELSE 28 * 24 * 3600 END END AS DECIMAL), 6) AS TXN_PER_SECOND, EXTRACT(YEAR FROM \"block_timestamp\") AS YEAR, EXTRACT(MONTH FROM \"block_timestamp\") AS MONTH FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_POLYGON_MAINNET_US\".\"TRANSACTIONS\" WHERE EXTRACT(YEAR FROM \"block_timestamp\") = 2023 GROUP BY EXTRACT(YEAR FROM \"block_timestamp\"), EXTRACT(MONTH FROM \"block_timestamp\") ORDER BY TXN_COUNT_PER_MONTH DESC") t0
  ~= (sql%([TRANSACTIONS_schema]) "WITH monthly_txn AS (SELECT EXTRACT(YEAR FROM \"block_timestamp\") AS YEAR, EXTRACT(MONTH FROM \"block_timestamp\") AS MONTH, COUNT(*) AS TXN_COUNT_PER_MONTH FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_POLYGON_MAINNET_US\".\"TRANSACTIONS\" WHERE EXTRACT(YEAR FROM \"block_timestamp\") = 2023 GROUP BY YEAR, MONTH), seconds_per_month AS (SELECT YEAR, MONTH, TXN_COUNT_PER_MONTH, CASE MONTH WHEN 1 THEN 31 WHEN 2 THEN CASE WHEN (YEAR % 4 = 0 AND YEAR % 100 <> 0) OR (YEAR % 400 = 0) THEN 29 ELSE 28 END WHEN 3 THEN 31 WHEN 4 THEN 30 WHEN 5 THEN 31 WHEN 6 THEN 30 WHEN 7 THEN 31 WHEN 8 THEN 31 WHEN 9 THEN 30 WHEN 10 THEN 31 WHEN 11 THEN 30 WHEN 12 THEN 31 END * 24 * 3600 AS seconds_in_month FROM monthly_txn) SELECT TXN_COUNT_PER_MONTH, ROUND(CAST(TXN_COUNT_PER_MONTH AS DOUBLE PRECISION) / seconds_in_month, 6) AS TXN_PER_SECOND, YEAR, MONTH FROM seconds_per_month ORDER BY TXN_COUNT_PER_MONTH DESC") t0
  := by first | sql_equiv | sorry

end N_sf_bq084_eq_0_3
