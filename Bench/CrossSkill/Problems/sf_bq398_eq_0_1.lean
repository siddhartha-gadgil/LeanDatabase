import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq398_eq_0_1

CREATE TABLE INTERNATIONAL_DEBT («country_name» STRING, «country_code» STRING, «indicator_name» STRING, «indicator_code» STRING, «value» FLOAT, «year» INT)

theorem eq (t0 : TableRel INTERNATIONAL_DEBT_schema) :
    (sql%([INTERNATIONAL_DEBT_schema]) "SELECT \"indicator_name\" FROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\" WHERE \"country_name\" = 'Russian Federation' AND NOT \"value\" IS NULL GROUP BY \"indicator_name\" ORDER BY MAX(\"value\") DESC LIMIT 3") t0
  = (sql%([INTERNATIONAL_DEBT_schema]) "SELECT \"indicator_name\" FROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\" WHERE \"country_name\" = 'Russian Federation' AND NOT \"value\" IS NULL GROUP BY \"indicator_name\" ORDER BY SUM(\"value\") DESC LIMIT 3") t0
  := by first | sql_equiv | sorry

end N_sf_bq398_eq_0_1
