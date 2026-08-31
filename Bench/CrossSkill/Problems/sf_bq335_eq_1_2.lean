import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq335_eq_1_2

CREATE TABLE OUTPUTS («transaction_hash» STRING, «block_hash» STRING, «block_number» INT, «block_timestamp» INT, «index» INT, «script_asm» STRING, «script_hex» STRING, «required_signatures» INT, «type» STRING, «addresses» STRING, «value» INT)
CREATE TABLE INPUTS («transaction_hash» STRING, «block_hash» STRING, «block_number» INT, «block_timestamp» INT, «index» INT, «spent_transaction_hash» STRING, «spent_output_index» INT, «script_asm» STRING, «script_hex» STRING, «sequence» INT, «required_signatures» INT, «type» STRING, «addresses» STRING, «value» INT)

theorem eq (t0 : TableRel OUTPUTS_schema) (t1 : TableRel INPUTS_schema) :
    (sql%([OUTPUTS_schema, INPUTS_schema]) "WITH all_addr AS (SELECT CAST(f.VALUE AS TEXT) AS address, \"block_timestamp\", \"value\" FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"INPUTS\", LATERAL UNNEST(INPUT => \"addresses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE \"block_timestamp\" >= 1506816000000000 AND \"block_timestamp\" < 1509494400000000 UNION ALL SELECT CAST(f.VALUE AS TEXT) AS address, \"block_timestamp\", \"value\" FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"OUTPUTS\", LATERAL UNNEST(INPUT => \"addresses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE \"block_timestamp\" >= 1506816000000000 AND \"block_timestamp\" < 1509494400000000), addr_stats AS (SELECT address, MAX(\"block_timestamp\") AS last_ts, SUM(\"value\") AS total_value FROM all_addr GROUP BY address) SELECT address AS \"OUTPUT\" FROM addr_stats ORDER BY last_ts DESC, total_value DESC LIMIT 1") t0 t1
  ~= (sql%([OUTPUTS_schema, INPUTS_schema]) "WITH all_addresses AS (/* Addresses from OUTPUTS in October 2017 */ SELECT CAST(f.VALUE AS TEXT) AS address, o.\"value\" AS tx_value, TO_TIMESTAMP(CAST(o.\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS block_ts FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"OUTPUTS\" AS o, LATERAL UNNEST(input => o.\"addresses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE TO_TIMESTAMP(CAST(o.\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) >= '2017-10-01' AND TO_TIMESTAMP(CAST(o.\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2017-11-01' UNION ALL /* Addresses from INPUTS in October 2017 */ SELECT CAST(f.VALUE AS TEXT) AS address, i.\"value\" AS tx_value, TO_TIMESTAMP(CAST(i.\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) AS block_ts FROM \"CRYPTO\".\"CRYPTO_BITCOIN\".\"INPUTS\" AS i, LATERAL UNNEST(input => i.\"addresses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE TO_TIMESTAMP(CAST(i.\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) >= '2017-10-01' AND TO_TIMESTAMP(CAST(i.\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2017-11-01'), address_stats AS (SELECT address, MAX(block_ts) AS last_tx_date, SUM(tx_value) AS total_value FROM all_addresses GROUP BY address) SELECT address AS \"OUTPUT\" FROM address_stats ORDER BY last_tx_date DESC, total_value DESC LIMIT 1") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq335_eq_1_2
