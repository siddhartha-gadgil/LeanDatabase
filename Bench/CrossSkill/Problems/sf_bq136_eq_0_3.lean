import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq136_eq_0_3

CREATE TABLE TRANSACTIONS («block_height» INT, «block_timestamp» STRING, «block_timestamp_truncated» INT, «txhash» STRING, «transaction_type» STRING, «gas_wanted» INT, «gas_used» INT, «sender» STRING, «fee» STRING, «memo» STRING)
CREATE TABLE TRANSITIONS («block_number» INT, «block_timestamp» INT, «transaction_id» STRING, «index» INT, «accepted» BOOL, «addr» STRING, «depth» INT, «amount» INT, «recipient» STRING, «tag» STRING, «params» STRING)

theorem eq (t0 : TableRel TRANSACTIONS_schema) (t1 : TableRel TRANSITIONS_schema) :
    (sql%([TRANSACTIONS_schema, TRANSITIONS_schema]) "WITH all_txns AS (/* Regular transactions */ SELECT \"id\" AS tx_id, \"sender\" AS from_addr, \"to_addr\" AS to_addr, \"block_timestamp\" AS ts FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE \"success\" = TRUE UNION ALL /* Contract transitions */ SELECT \"transaction_id\" AS tx_id, \"addr\" AS from_addr, \"recipient\" AS to_addr, \"block_timestamp\" AS ts FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSITIONS\" WHERE \"accepted\" = TRUE), outgoing_counts /* Count outgoing transactions per address (to filter out exchanges/mixers) */ AS (SELECT from_addr, COUNT(*) AS outgoing_cnt FROM all_txns GROUP BY from_addr), two_hop_paths /* Find 2-hop paths: source -> intermediate -> destination */ AS (SELECT hop1.from_addr AS source, hop1.to_addr AS intermediate, hop2.to_addr AS destination, hop1.tx_id AS tx1_id, hop2.tx_id AS tx2_id, hop1.ts AS ts1, hop2.ts AS ts2 FROM all_txns AS hop1 JOIN all_txns AS hop2 ON hop1.to_addr = hop2.from_addr WHERE hop1.from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz' AND hop2.to_addr = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e' AND hop2.ts > hop1.ts) SELECT p.source || ' --(tx ' || LEFT(p.tx1_id, 5) || '..)--> ' || p.intermediate || ' --(tx ' || LEFT(p.tx2_id, 5) || '..)--> ' || p.destination AS PATH FROM two_hop_paths AS p JOIN outgoing_counts AS oc ON p.intermediate = oc.from_addr WHERE oc.outgoing_cnt <= 50 ORDER BY PATH") t0 t1
  ~= (sql%([TRANSACTIONS_schema, TRANSITIONS_schema]) "SELECT t1.\"sender\" || ' --(tx ' || LEFT(t1.\"id\", 5) || '..)--> ' || t1.\"to_addr\" || ' --(tx ' || LEFT(t2.\"id\", 5) || '..)--> ' || t2.\"to_addr\" AS \"PATH\" FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" AS t1 JOIN \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" AS t2 ON t1.\"to_addr\" = t2.\"sender\" WHERE t1.\"sender\" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz' AND t2.\"to_addr\" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e' AND t1.\"block_timestamp\" < t2.\"block_timestamp\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq136_eq_0_3
