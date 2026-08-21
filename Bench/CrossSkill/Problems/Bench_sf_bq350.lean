import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq350 — crossskill equivalence(s)

Question: For the detailed molecule data, Please display the drug id, drug type and withdrawal status for approved drugs with a black box warning and known drug type among 'Keytruda', 'Vioxx', 'Premarin', and 'Humira'

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq350

CREATE TABLE MOLECULE («id» STRING, «canonicalSmiles» STRING, «inchiKey» STRING, «drugType» STRING, «blackBoxWarning» BOOL, «name» STRING, «yearOfFirstApproval» INT, «maximumClinicalTrialPhase» FLOAT, «parentId» STRING, «hasBeenWithdrawn» BOOL, «isApproved» BOOL, «tradeNames» STRING, «synonyms» STRING, «crossReferences» STRING, «childChemblIds» STRING, «linkedDiseases» STRING, «linkedTargets» STRING, «description» STRING)

theorem eq_0_1 :
    sql%([MOLECULE_schema]) "SELECT \n    m.\"id\" AS DRUG_ID,\n    tn.VALUE:\"element\"::STRING AS DRUG_TRADE_NAME,\n    m.\"drugType\" AS DRUG_TYPE,\n    m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\n    LATERAL FLATTEN(input => m.\"tradeNames\":\"list\") tn\nWHERE m.\"isApproved\" = true\n  AND m.\"blackBoxWarning\" = true\n  AND m.\"drugType\" != 'Unknown'\n  AND tn.VALUE:\"element\"::STRING IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira')\nORDER BY DRUG_ID;" = sql%([MOLECULE_schema]) "SELECT\n    m.\"id\" AS DRUG_ID,\n    f.value:\"element\"::STRING AS DRUG_TRADE_NAME,\n    m.\"drugType\" AS DRUG_TYPE,\n    m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\n    LATERAL FLATTEN(input => m.\"tradeNames\":\"list\") f\nWHERE m.\"isApproved\" = true\n  AND m.\"blackBoxWarning\" = true\n  AND m.\"drugType\" != 'Unknown'\n  AND LOWER(f.value:\"element\"::STRING) IN ('keytruda', 'vioxx', 'premarin', 'humira')\nORDER BY DRUG_ID;" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([MOLECULE_schema]) "SELECT \n    m.\"id\" AS DRUG_ID,\n    tn.VALUE:\"element\"::STRING AS DRUG_TRADE_NAME,\n    m.\"drugType\" AS DRUG_TYPE,\n    m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\n    LATERAL FLATTEN(input => m.\"tradeNames\":\"list\") tn\nWHERE m.\"isApproved\" = true\n  AND m.\"blackBoxWarning\" = true\n  AND m.\"drugType\" != 'Unknown'\n  AND tn.VALUE:\"element\"::STRING IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira')\nORDER BY DRUG_ID;" = sql%([MOLECULE_schema]) "SELECT\n    m.\"id\" AS \"DRUG_ID\",\n    f.value:\"element\"::STRING AS \"DRUG_TRADE_NAME\",\n    m.\"drugType\" AS \"DRUG_TYPE\",\n    m.\"hasBeenWithdrawn\" AS \"DRUG_WITHDRAWN\"\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\nLATERAL FLATTEN(input => m.\"tradeNames\":\"list\") f\nWHERE f.value:\"element\"::STRING IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira')\n  AND m.\"isApproved\" = true\n  AND m.\"blackBoxWarning\" = true\n  AND m.\"drugType\" != 'Unknown'\nORDER BY m.\"id\";" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : MOLECULE "\"isApproved\" = true"
HYPOTHESIS hyp0_3_1 : MOLECULE "\"blackBoxWarning\" = true"
HYPOTHESIS hyp0_3_2 : MOLECULE "\"isApproved\" = TRUE"
HYPOTHESIS hyp0_3_3 : MOLECULE "\"blackBoxWarning\" = TRUE"
theorem eq_0_3 (t : TableRel MOLECULE_schema) (h0 : hyp0_3_0 t) (h1 : hyp0_3_1 t) (h2 : hyp0_3_2 t) (h3 : hyp0_3_3 t) :
    (sql%([MOLECULE_schema]) "SELECT \n    m.\"id\" AS DRUG_ID,\n    tn.VALUE:\"element\"::STRING AS DRUG_TRADE_NAME,\n    m.\"drugType\" AS DRUG_TYPE,\n    m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\n    LATERAL FLATTEN(input => m.\"tradeNames\":\"list\") tn\nWHERE m.\"isApproved\" = true\n  AND m.\"blackBoxWarning\" = true\n  AND m.\"drugType\" != 'Unknown'\n  AND tn.VALUE:\"element\"::STRING IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira')\nORDER BY DRUG_ID;") t = (sql%([MOLECULE_schema]) "SELECT\n    m.\"id\" AS DRUG_ID,\n    f.value:\"element\"::STRING AS DRUG_TRADE_NAME,\n    m.\"drugType\" AS DRUG_TYPE,\n    m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\nLATERAL FLATTEN(input => m.\"tradeNames\":\"list\") f\nWHERE f.value:\"element\"::STRING IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira')\n  AND m.\"isApproved\" = TRUE\n  AND m.\"blackBoxWarning\" = TRUE\n  AND m.\"drugType\" != 'Unknown'\nORDER BY DRUG_ID;") t := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([MOLECULE_schema]) "SELECT\n    m.\"id\" AS DRUG_ID,\n    f.value:\"element\"::STRING AS DRUG_TRADE_NAME,\n    m.\"drugType\" AS DRUG_TYPE,\n    m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\n    LATERAL FLATTEN(input => m.\"tradeNames\":\"list\") f\nWHERE m.\"isApproved\" = true\n  AND m.\"blackBoxWarning\" = true\n  AND m.\"drugType\" != 'Unknown'\n  AND LOWER(f.value:\"element\"::STRING) IN ('keytruda', 'vioxx', 'premarin', 'humira')\nORDER BY DRUG_ID;" = sql%([MOLECULE_schema]) "SELECT\n    m.\"id\" AS \"DRUG_ID\",\n    f.value:\"element\"::STRING AS \"DRUG_TRADE_NAME\",\n    m.\"drugType\" AS \"DRUG_TYPE\",\n    m.\"hasBeenWithdrawn\" AS \"DRUG_WITHDRAWN\"\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\nLATERAL FLATTEN(input => m.\"tradeNames\":\"list\") f\nWHERE f.value:\"element\"::STRING IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira')\n  AND m.\"isApproved\" = true\n  AND m.\"blackBoxWarning\" = true\n  AND m.\"drugType\" != 'Unknown'\nORDER BY m.\"id\";" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : MOLECULE "\"isApproved\" = true"
HYPOTHESIS hyp1_3_1 : MOLECULE "\"blackBoxWarning\" = true"
HYPOTHESIS hyp1_3_2 : MOLECULE "\"isApproved\" = TRUE"
HYPOTHESIS hyp1_3_3 : MOLECULE "\"blackBoxWarning\" = TRUE"
theorem eq_1_3 (t : TableRel MOLECULE_schema) (h0 : hyp1_3_0 t) (h1 : hyp1_3_1 t) (h2 : hyp1_3_2 t) (h3 : hyp1_3_3 t) :
    (sql%([MOLECULE_schema]) "SELECT\n    m.\"id\" AS DRUG_ID,\n    f.value:\"element\"::STRING AS DRUG_TRADE_NAME,\n    m.\"drugType\" AS DRUG_TYPE,\n    m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\n    LATERAL FLATTEN(input => m.\"tradeNames\":\"list\") f\nWHERE m.\"isApproved\" = true\n  AND m.\"blackBoxWarning\" = true\n  AND m.\"drugType\" != 'Unknown'\n  AND LOWER(f.value:\"element\"::STRING) IN ('keytruda', 'vioxx', 'premarin', 'humira')\nORDER BY DRUG_ID;") t = (sql%([MOLECULE_schema]) "SELECT\n    m.\"id\" AS DRUG_ID,\n    f.value:\"element\"::STRING AS DRUG_TRADE_NAME,\n    m.\"drugType\" AS DRUG_TYPE,\n    m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\nLATERAL FLATTEN(input => m.\"tradeNames\":\"list\") f\nWHERE f.value:\"element\"::STRING IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira')\n  AND m.\"isApproved\" = TRUE\n  AND m.\"blackBoxWarning\" = TRUE\n  AND m.\"drugType\" != 'Unknown'\nORDER BY DRUG_ID;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : MOLECULE "\"isApproved\" = true"
HYPOTHESIS hyp2_3_1 : MOLECULE "\"blackBoxWarning\" = true"
HYPOTHESIS hyp2_3_2 : MOLECULE "\"isApproved\" = TRUE"
HYPOTHESIS hyp2_3_3 : MOLECULE "\"blackBoxWarning\" = TRUE"
theorem eq_2_3 (t : TableRel MOLECULE_schema) (h0 : hyp2_3_0 t) (h1 : hyp2_3_1 t) (h2 : hyp2_3_2 t) (h3 : hyp2_3_3 t) :
    (sql%([MOLECULE_schema]) "SELECT\n    m.\"id\" AS \"DRUG_ID\",\n    f.value:\"element\"::STRING AS \"DRUG_TRADE_NAME\",\n    m.\"drugType\" AS \"DRUG_TYPE\",\n    m.\"hasBeenWithdrawn\" AS \"DRUG_WITHDRAWN\"\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\nLATERAL FLATTEN(input => m.\"tradeNames\":\"list\") f\nWHERE f.value:\"element\"::STRING IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira')\n  AND m.\"isApproved\" = true\n  AND m.\"blackBoxWarning\" = true\n  AND m.\"drugType\" != 'Unknown'\nORDER BY m.\"id\";") t = (sql%([MOLECULE_schema]) "SELECT\n    m.\"id\" AS DRUG_ID,\n    f.value:\"element\"::STRING AS DRUG_TRADE_NAME,\n    m.\"drugType\" AS DRUG_TYPE,\n    m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN\nFROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" m,\nLATERAL FLATTEN(input => m.\"tradeNames\":\"list\") f\nWHERE f.value:\"element\"::STRING IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira')\n  AND m.\"isApproved\" = TRUE\n  AND m.\"blackBoxWarning\" = TRUE\n  AND m.\"drugType\" != 'Unknown'\nORDER BY DRUG_ID;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq350
