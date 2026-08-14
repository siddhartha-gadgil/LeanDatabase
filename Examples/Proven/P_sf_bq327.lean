import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq327 — proven cross-skill equivalence(s)

Question: How many debt indicators for Russia have a value of 0, excluding NULL values?

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` fact, that data assumption is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_bq327

CREATE TABLE INTERNATIONAL_DEBT («country_name» STRING, «country_code» STRING, «indicator_name» STRING, «indicator_code» STRING, «value» FLOAT, «year» INT)

HYPOTHESIS bij0_1_0 : INTERNATIONAL_DEBT BIJECTION «indicator_name» «indicator_code»

theorem eq_0_1 (t : TableRel INTERNATIONAL_DEBT_schema) (h0 : bij0_1_0 t) :
    (sql%([INTERNATIONAL_DEBT_schema]) "SELECT COUNT(DISTINCT \"indicator_name\") AS number_of_indicators_with_zero\nFROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\"\nWHERE \"country_name\" = 'Russian Federation'\n  AND \"value\" = 0;") t = (sql%([INTERNATIONAL_DEBT_schema]) "SELECT\n  COUNT(DISTINCT \"indicator_code\") AS \"number_of_indicators_with_zero\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\"\nWHERE \"country_name\" = 'Russian Federation'\n  AND \"value\" = 0;") t := by sql_equiv

end P_sf_bq327
