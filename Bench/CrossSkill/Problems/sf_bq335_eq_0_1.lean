import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq335_eq_0_1

CREATE TABLE OUTPUTS («transaction_hash» STRING, «block_hash» STRING, «block_number» INT, «block_timestamp» INT, «index» INT, «script_asm» STRING, «script_hex» STRING, «required_signatures» INT, «type» STRING, «addresses» STRING, «value» INT)
CREATE TABLE INPUTS («transaction_hash» STRING, «block_hash» STRING, «block_number» INT, «block_timestamp» INT, «index» INT, «spent_transaction_hash» STRING, «spent_output_index» INT, «script_asm» STRING, «script_hex» STRING, «sequence» INT, «required_signatures» INT, «type» STRING, «addresses» STRING, «value» INT)

theorem eq (t0 : TableRel OUTPUTS_schema) (t1 : TableRel INPUTS_schema) :
    (sql%([OUTPUTS_schema, INPUTS_schema]) "WITH all_txns AS (/* Combine inputs and outputs with flattened addresses */ SELECT CAST(f.VALUE AS TEXT) AS address, TO_TIMESTAMP(CAST(i.\"block_timestamp\" AS DOUBLE PRECISION) / POWER(10, 6)) AS ts, i.\"value\" FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"INPUTS\" AS i, LATERAL UNNEST(INPUT => i.\"addresses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE TO_TIMESTAMP(CAST(i.\"block_timestamp\" AS DOUBLE PRECISION) / POWER(10, 6)) >= '2017-10-01' AND TO_TIMESTAMP(CAST(i.\"block_timestamp\" AS DOUBLE PRECISION) / POWER(10, 6)) < '2017-11-01' UNION ALL SELECT CAST(f.VALUE AS TEXT) AS address, TO_TIMESTAMP(CAST(o.\"block_timestamp\" AS DOUBLE PRECISION) / POWER(10, 6)) AS ts, o.\"value\" FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"OUTPUTS\" AS o, LATERAL UNNEST(INPUT => o.\"addresses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE TO_TIMESTAMP(CAST(o.\"block_timestamp\" AS DOUBLE PRECISION) / POWER(10, 6)) >= '2017-10-01' AND TO_TIMESTAMP(CAST(o.\"block_timestamp\" AS DOUBLE PRECISION) / POWER(10, 6)) < '2017-11-01'), per_address AS (/* For each address: find their last transaction timestamp and total value */ SELECT address, MAX(ts) AS last_txn_ts, SUM(\"value\") AS total_value FROM all_txns GROUP BY address) /* Find the address with the latest final transaction, breaking ties by highest total value */ SELECT address AS OUTPUT FROM per_address ORDER BY last_txn_ts DESC, total_value DESC LIMIT 1") t0 t1
  ~= (sql%([OUTPUTS_schema, INPUTS_schema]) "WITH all_addr AS (SELECT CAST(f.VALUE AS TEXT) AS address, \"block_timestamp\", \"value\" FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"INPUTS\", LATERAL UNNEST(INPUT => \"addresses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE \"block_timestamp\" >= 1506816000000000 AND \"block_timestamp\" < 1509494400000000 UNION ALL SELECT CAST(f.VALUE AS TEXT) AS address, \"block_timestamp\", \"value\" FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"OUTPUTS\", LATERAL UNNEST(INPUT => \"addresses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE \"block_timestamp\" >= 1506816000000000 AND \"block_timestamp\" < 1509494400000000), addr_stats AS (SELECT address, MAX(\"block_timestamp\") AS last_ts, SUM(\"value\") AS total_value FROM all_addr GROUP BY address) SELECT address AS \"OUTPUT\" FROM addr_stats ORDER BY last_ts DESC, total_value DESC LIMIT 1") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq335_eq_0_1
