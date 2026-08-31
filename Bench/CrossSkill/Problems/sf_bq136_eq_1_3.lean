import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq136_eq_1_3

CREATE TABLE TRANSACTIONS («block_height» INT, «block_timestamp» STRING, «block_timestamp_truncated» INT, «txhash» STRING, «transaction_type» STRING, «gas_wanted» INT, «gas_used» INT, «sender» STRING, «fee» STRING, «memo» STRING)
CREATE TABLE TRANSITIONS («block_number» INT, «block_timestamp» INT, «transaction_id» STRING, «index» INT, «accepted» BOOL, «addr» STRING, «depth» INT, «amount» INT, «recipient» STRING, «tag» STRING, «params» STRING)

theorem eq (t0 : TableRel TRANSACTIONS_schema) (t1 : TableRel TRANSITIONS_schema) :
    (sql%([TRANSACTIONS_schema, TRANSITIONS_schema]) "WITH all_edges AS (/* Regular transactions */ SELECT \"id\" AS tx_id, \"sender\" AS from_addr, \"to_addr\" AS to_addr, \"block_timestamp\" AS ts FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" WHERE \"success\" = TRUE UNION ALL /* Contract transitions */ SELECT \"transaction_id\" AS tx_id, \"addr\" AS from_addr, \"recipient\" AS to_addr, \"block_timestamp\" AS ts FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSITIONS\" WHERE \"accepted\" = TRUE), outgoing_counts AS (SELECT FROM_ADDR, COUNT(*) AS OUTGOING_CNT FROM all_edges GROUP BY FROM_ADDR), two_hop AS (SELECT e1.FROM_ADDR AS SOURCE, e1.TX_ID AS TX1_ID, e1.TO_ADDR AS INTERMEDIATE, e2.TX_ID AS TX2_ID, e2.TO_ADDR AS DESTINATION, e1.TS AS TS1, e2.TS AS TS2 FROM all_edges AS e1 JOIN all_edges AS e2 ON e1.TO_ADDR = e2.FROM_ADDR JOIN outgoing_counts AS oc ON oc.FROM_ADDR = e1.TO_ADDR WHERE e1.FROM_ADDR = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz' AND e2.TO_ADDR = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e' AND e1.TS < e2.TS AND oc.OUTGOING_CNT <= 50) SELECT SOURCE || ' --(tx ' || LEFT(TX1_ID, 5) || '..)--> ' || INTERMEDIATE || ' --(tx ' || LEFT(TX2_ID, 5) || '..)--> ' || DESTINATION AS \"PATH\" FROM two_hop ORDER BY TS1, TS2") t0 t1
  ~= (sql%([TRANSACTIONS_schema, TRANSITIONS_schema]) "SELECT t1.\"sender\" || ' --(tx ' || LEFT(t1.\"id\", 5) || '..)--> ' || t1.\"to_addr\" || ' --(tx ' || LEFT(t2.\"id\", 5) || '..)--> ' || t2.\"to_addr\" AS \"PATH\" FROM \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" AS t1 JOIN \"CRYPTO\".\"CRYPTO_ZILLIQA\".\"TRANSACTIONS\" AS t2 ON t1.\"to_addr\" = t2.\"sender\" WHERE t1.\"sender\" = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz' AND t2.\"to_addr\" = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e' AND t1.\"block_timestamp\" < t2.\"block_timestamp\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq136_eq_1_3
