import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq398 — crossskill equivalence(s)

Question: What are the top three debt indicators for Russia based on the highest debt values?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq398

CREATE TABLE INTERNATIONAL_DEBT («country_name» STRING, «country_code» STRING, «indicator_name» STRING, «indicator_code» STRING, «value» FLOAT, «year» INT)

theorem eq_0_1 :
    sql%([INTERNATIONAL_DEBT_schema]) "SELECT \"indicator_name\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\"\nWHERE \"country_name\" = 'Russian Federation'\n  AND \"value\" IS NOT NULL\nGROUP BY \"indicator_name\"\nORDER BY MAX(\"value\") DESC\nLIMIT 3;" = sql%([INTERNATIONAL_DEBT_schema]) "SELECT \"indicator_name\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\"\nWHERE \"country_name\" = 'Russian Federation'\n  AND \"value\" IS NOT NULL\nGROUP BY \"indicator_name\"\nORDER BY SUM(\"value\") DESC\nLIMIT 3;" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : INTERNATIONAL_DEBT "\"value\" IS NOT NULL"
theorem eq_0_2 (t : TableRel INTERNATIONAL_DEBT_schema) (h0 : hyp0_2_0 t) :
    (sql%([INTERNATIONAL_DEBT_schema]) "SELECT \"indicator_name\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\"\nWHERE \"country_name\" = 'Russian Federation'\n  AND \"value\" IS NOT NULL\nGROUP BY \"indicator_name\"\nORDER BY MAX(\"value\") DESC\nLIMIT 3;") t = (sql%([INTERNATIONAL_DEBT_schema]) "SELECT \"indicator_name\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\"\nWHERE \"country_name\" = 'Russian Federation'\nGROUP BY \"indicator_name\"\nORDER BY SUM(\"value\") DESC NULLS LAST\nLIMIT 3;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : INTERNATIONAL_DEBT "\"value\" IS NOT NULL"
theorem eq_1_2 (t : TableRel INTERNATIONAL_DEBT_schema) (h0 : hyp1_2_0 t) :
    (sql%([INTERNATIONAL_DEBT_schema]) "SELECT \"indicator_name\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\"\nWHERE \"country_name\" = 'Russian Federation'\n  AND \"value\" IS NOT NULL\nGROUP BY \"indicator_name\"\nORDER BY SUM(\"value\") DESC\nLIMIT 3;") t = (sql%([INTERNATIONAL_DEBT_schema]) "SELECT \"indicator_name\"\nFROM \"WORLD_BANK\".\"WORLD_BANK_INTL_DEBT\".\"INTERNATIONAL_DEBT\"\nWHERE \"country_name\" = 'Russian Federation'\nGROUP BY \"indicator_name\"\nORDER BY SUM(\"value\") DESC NULLS LAST\nLIMIT 3;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq398
