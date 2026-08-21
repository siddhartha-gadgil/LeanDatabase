import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq285 — crossskill equivalence(s)

Question: Could you provide me with the zip code of the location that has the highest number of bank institutions in Florida?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq285

CREATE TABLE LOCATIONS («fdic_certificate_number» STRING, «institution_name» STRING, «branch_name» STRING, «branch_number» STRING, «main_office» BOOL, «branch_address» STRING, «branch_city» STRING, «zip_code» STRING, «branch_county» STRING, «county_fips_code» STRING, «state» STRING, «state_name» STRING, «institution_class» STRING, «cbsa_fips_code» STRING, «cbsa_name» STRING, «cbsa_division_flag» BOOL, «cbsa_division_fips_code» INT, «cbsa_division_name» STRING, «cbsa_metro_flag» BOOL, «cbsa_metro_fips_code» STRING, «cbsa_metro_name» STRING, «cbsa_micro_flag» BOOL, «csa_flag» BOOL, «csa_fips_code» STRING, «csa_name» STRING, «date_established» STRING, «fdic_uninum» STRING, «last_updated» STRING, «service_type» STRING, «branch_fdic_uninum» STRING)

theorem eq_0_1 :
    sql%([LOCATIONS_schema]) "SELECT \"zip_code\" AS OUTPUT\nFROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\"\nWHERE \"state_name\" = 'Florida'\nGROUP BY \"zip_code\"\nORDER BY COUNT(*) DESC\nLIMIT 1;" = sql%([LOCATIONS_schema]) "SELECT \"zip_code\" AS OUTPUT\nFROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\"\nWHERE \"state_name\" = 'Florida'\nGROUP BY \"zip_code\"\nORDER BY COUNT(DISTINCT \"fdic_certificate_number\") DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : LOCATIONS "\"state_name\" = 'Florida'"
HYPOTHESIS hyp0_2_1 : LOCATIONS "\"state\" = 'FL'"
theorem eq_0_2 (t : TableRel LOCATIONS_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([LOCATIONS_schema]) "SELECT \"zip_code\" AS OUTPUT\nFROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\"\nWHERE \"state_name\" = 'Florida'\nGROUP BY \"zip_code\"\nORDER BY COUNT(*) DESC\nLIMIT 1;") t ~= (sql%([LOCATIONS_schema]) "SELECT \"zip_code\"\nFROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\"\nWHERE \"state\" = 'FL'\nGROUP BY \"zip_code\"\nORDER BY COUNT(DISTINCT \"fdic_certificate_number\") DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : LOCATIONS "\"state_name\" = 'Florida'"
HYPOTHESIS hyp1_2_1 : LOCATIONS "\"state\" = 'FL'"
theorem eq_1_2 (t : TableRel LOCATIONS_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) :
    (sql%([LOCATIONS_schema]) "SELECT \"zip_code\" AS OUTPUT\nFROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\"\nWHERE \"state_name\" = 'Florida'\nGROUP BY \"zip_code\"\nORDER BY COUNT(DISTINCT \"fdic_certificate_number\") DESC\nLIMIT 1;") t ~= (sql%([LOCATIONS_schema]) "SELECT \"zip_code\"\nFROM \"FDA\".\"FDIC_BANKS\".\"LOCATIONS\"\nWHERE \"state\" = 'FL'\nGROUP BY \"zip_code\"\nORDER BY COUNT(DISTINCT \"fdic_certificate_number\") DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq285
