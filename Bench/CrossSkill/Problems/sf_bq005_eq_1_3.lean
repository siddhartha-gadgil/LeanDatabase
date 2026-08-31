import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq005_eq_1_3

CREATE TABLE BLOCKS («block_height» INT, «block_timestamp» STRING, «block_timestamp_truncated» INT, «block_hash» STRING, «proposer_address» STRING, «last_commit_hash» STRING, «data_hash» STRING, «validators_hash» STRING, «next_validators_hash» STRING, «consensus_hash» STRING, «app_hash» STRING, «last_results_hash» STRING, «evidence_hash» STRING, «signatures» STRING)

theorem eq (t0 : TableRel BLOCKS_schema) :
    (sql%([BLOCKS_schema]) "WITH numbered AS (SELECT \"number\", \"timestamp\", CAST(TO_TIMESTAMP(CAST(\"timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS block_date, ROW_NUMBER() OVER (ORDER BY \"number\") AS rn FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"BLOCKS\" WHERE \"number\" > 0 /* exclude genesis block */) SELECT b.block_date AS \"DATE\", AVG(CAST((b.\"timestamp\" - a.\"timestamp\") AS DOUBLE PRECISION) / 1000000) AS \"MEAN_BLOCK_INTERVAL\" FROM numbered AS a JOIN numbered AS b ON b.rn = a.rn + 1 WHERE EXTRACT(YEAR FROM b.block_date) = 2023 GROUP BY b.block_date ORDER BY b.block_date LIMIT 10") t0
  ~= (sql%([BLOCKS_schema]) "WITH numbered_blocks AS (SELECT \"number\", \"timestamp\", ROW_NUMBER() OVER (ORDER BY \"number\") AS rn FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"BLOCKS\" WHERE \"number\" > 0), block_intervals AS (SELECT CAST(TO_TIMESTAMP(CAST(b.\"timestamp\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS \"DATE\", CAST((b.\"timestamp\" - a.\"timestamp\") AS DOUBLE PRECISION) / 1000000.0 AS interval_seconds FROM numbered_blocks AS b JOIN numbered_blocks AS a ON b.rn = a.rn + 1) SELECT \"DATE\", AVG(interval_seconds) AS \"MEAN_BLOCK_INTERVAL\" FROM block_intervals WHERE \"DATE\" >= '2023-01-01' AND \"DATE\" < '2024-01-01' GROUP BY \"DATE\" ORDER BY \"DATE\" LIMIT 10") t0
  := by first | sql_equiv | sorry

end N_sf_bq005_eq_1_3
