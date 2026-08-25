import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq135 — crossskill equivalence(s)

Question: Which date before 2022 had the highest total transaction amount in the Zilliqa blockchain data?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq135

CREATE TABLE TRANSACTIONS («block_height» INT, «block_timestamp» STRING, «block_timestamp_truncated» INT, «txhash» STRING, «transaction_type» STRING, «gas_wanted» INT, «gas_used» INT, «sender» STRING, «fee» STRING, «memo» STRING)

HYPOTHESIS hyp0_1_0 : TRANSACTIONS "CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01'"
HYPOTHESIS hyp0_1_1 : TRANSACTIONS "CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01'"
HYPOTHESIS hyp0_1_2 : TRANSACTIONS "CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) = CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE)"
theorem eq_0_1 (t : TableRel TRANSACTIONS_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) (h2 : hyp0_1_2 t) :
    (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1") t = (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : TRANSACTIONS "CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01'"
HYPOTHESIS hyp0_2_1 : TRANSACTIONS "CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01'"
HYPOTHESIS hyp0_2_2 : TRANSACTIONS "CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) = CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE)"
theorem eq_0_2 (t : TableRel TRANSACTIONS_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) (h2 : hyp0_2_2 t) :
    (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1") t = (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS \"date\" FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) ORDER BY SUM(\"amount\") DESC LIMIT 1") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : TRANSACTIONS "CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01'"
HYPOTHESIS hyp0_3_1 : TRANSACTIONS "TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2022-01-01'"
HYPOTHESIS hyp0_3_2 : TRANSACTIONS "CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) = CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE)"
theorem eq_0_3 (t : TableRel TRANSACTIONS_schema) (h0 : hyp0_3_0 t) (h1 : hyp0_3_1 t) (h2 : hyp0_3_2 t) :
    (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP_NTZ(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1") t = (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1") t := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1" = sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS \"date\" FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) ORDER BY SUM(\"amount\") DESC LIMIT 1" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : TRANSACTIONS "CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01'"
HYPOTHESIS hyp1_3_1 : TRANSACTIONS "TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2022-01-01'"
theorem eq_1_3 (t : TableRel TRANSACTIONS_schema) (h0 : hyp1_3_0 t) (h1 : hyp1_3_1 t) :
    (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1") t = (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : TRANSACTIONS "CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01'"
HYPOTHESIS hyp2_3_1 : TRANSACTIONS "TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2022-01-01'"
theorem eq_2_3 (t : TableRel TRANSACTIONS_schema) (h0 : hyp2_3_0 t) (h1 : hyp2_3_1 t) :
    (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS \"date\" FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) < '2022-01-01' GROUP BY CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) ORDER BY SUM(\"amount\") DESC LIMIT 1") t = (sql%([TRANSACTIONS_schema]) "SELECT CAST(TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS date FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2022-01-01' GROUP BY date ORDER BY SUM(\"amount\") DESC LIMIT 1") t := by
  first | sql_equiv | sorry

end Bench_sf_bq135
