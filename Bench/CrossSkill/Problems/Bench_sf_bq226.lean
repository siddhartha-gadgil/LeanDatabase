import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq226 — crossskill equivalence(s)

Question: Which sender address, represented as a complete URL on https://cronoscan.com, has been used most frequently on the Cronos blockchain in transactions to non-null 'to_address' fields, within blocks larger than 4096 bytes, since January 1, 2023?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq226

CREATE TABLE BLOCKS («block_hash» STRING, «block_number» INT, «block_timestamp» STRING, «parent_hash» STRING, «size» INT, «extra_data» STRING, «gas_limit» INT, «gas_used» INT, «base_fee_per_gas» INT, «mix_hash» STRING, «nonce» INT, «difficulty» STRING, «total_difficulty» STRING, «miner» STRING, «uncles_sha3» STRING, «uncles» STRING, «transactions_root» STRING, «receipts_root» STRING, «state_root» STRING, «logs_bloom» STRING)
CREATE TABLE TRANSACTIONS («block_hash» STRING, «block_timestamp» STRING, «transaction_hash» STRING, «transaction_index» INT, «nonce» INT, «from_address» STRING, «to_address» STRING, «value» STRING, «input» STRING, «gas» INT, «gas_price» STRING, «max_fee_per_gas» INT, «max_priority_fee_per_gas» INT, «transaction_type» INT, «access_list» STRING, «r» STRING, «s» STRING, «v» STRING)

theorem eq_0_1 :
    sql%([BLOCKS_schema, TRANSACTIONS_schema]) "SELECT 'https://cronoscan.com/address/' || t.\"from_address\" AS OUTPUT FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"TRANSACTIONS\" AS t JOIN \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"BLOCKS\" AS b ON t.\"block_hash\" = b.\"block_hash\" WHERE b.\"size\" > 4096 AND t.\"block_timestamp\" >= '2023-01-01' AND NOT t.\"to_address\" IS NULL GROUP BY t.\"from_address\" ORDER BY COUNT(*) DESC LIMIT 1" = sql%([BLOCKS_schema, TRANSACTIONS_schema]) "SELECT 'https://cronoscan.com/address/' || t.\"from_address\" AS OUTPUT FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"TRANSACTIONS\" AS t JOIN \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"BLOCKS\" AS b ON t.\"block_hash\" = b.\"block_hash\" WHERE NOT t.\"to_address\" IS NULL AND b.\"size\" > 4096 AND t.\"block_timestamp\" >= '2023-01-01' GROUP BY t.\"from_address\" ORDER BY COUNT(*) DESC LIMIT 1" := by
  first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 :
    sql%([BLOCKS_schema, TRANSACTIONS_schema]) "SELECT 'https://cronoscan.com/address/' || t.\"from_address\" AS OUTPUT FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"TRANSACTIONS\" AS t JOIN \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"BLOCKS\" AS b ON t.\"block_hash\" = b.\"block_hash\" WHERE b.\"size\" > 4096 AND t.\"block_timestamp\" >= '2023-01-01' AND NOT t.\"to_address\" IS NULL GROUP BY t.\"from_address\" ORDER BY COUNT(*) DESC LIMIT 1" = sql%([BLOCKS_schema, TRANSACTIONS_schema]) "SELECT 'https://cronoscan.com/address/' || t.\"from_address\" AS \"OUTPUT\" FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"TRANSACTIONS\" AS t JOIN \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"BLOCKS\" AS b ON t.\"block_hash\" = b.\"block_hash\" WHERE NOT t.\"to_address\" IS NULL AND b.\"size\" > 4096 AND b.\"block_timestamp\" >= '2023-01-01' GROUP BY t.\"from_address\" ORDER BY COUNT(*) DESC LIMIT 1" := by
  first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 :
    sql%([BLOCKS_schema, TRANSACTIONS_schema]) "SELECT 'https://cronoscan.com/address/' || t.\"from_address\" AS OUTPUT FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"TRANSACTIONS\" AS t JOIN \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"BLOCKS\" AS b ON t.\"block_hash\" = b.\"block_hash\" WHERE NOT t.\"to_address\" IS NULL AND b.\"size\" > 4096 AND t.\"block_timestamp\" >= '2023-01-01' GROUP BY t.\"from_address\" ORDER BY COUNT(*) DESC LIMIT 1" = sql%([BLOCKS_schema, TRANSACTIONS_schema]) "SELECT 'https://cronoscan.com/address/' || t.\"from_address\" AS \"OUTPUT\" FROM \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"TRANSACTIONS\" AS t JOIN \"GOOG_BLOCKCHAIN\".\"GOOG_BLOCKCHAIN_CRONOS_MAINNET_US\".\"BLOCKS\" AS b ON t.\"block_hash\" = b.\"block_hash\" WHERE NOT t.\"to_address\" IS NULL AND b.\"size\" > 4096 AND b.\"block_timestamp\" >= '2023-01-01' GROUP BY t.\"from_address\" ORDER BY COUNT(*) DESC LIMIT 1" := by
  first | sql_equiv | sorry

end Bench_sf_bq226
