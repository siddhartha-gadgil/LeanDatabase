import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq135_eq_1_2

CREATE TABLE TRANSACTIONS («block_height» INT, «block_timestamp» STRING, «block_timestamp_truncated» INT, «txhash» STRING, «transaction_type» STRING, «gas_wanted» INT, «gas_used» INT, «sender» STRING, «fee» STRING, «memo» STRING)

theorem eq (t0 : TableRel TRANSACTIONS_schema) :
    (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1") t0
  = (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS \"date\" FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) ORDER BY SUM(\"amount\") DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_bq135_eq_1_2
