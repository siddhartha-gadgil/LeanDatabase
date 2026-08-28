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
    sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(tn.VALUE, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS tn(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' AND CAST(JSON_EXTRACT_PATH(tn.VALUE, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') ORDER BY DRUG_ID" = sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' AND LOWER(CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT)) IN ('keytruda', 'vioxx', 'premarin', 'humira') ORDER BY DRUG_ID" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(tn.VALUE, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS tn(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' AND CAST(JSON_EXTRACT_PATH(tn.VALUE, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') ORDER BY DRUG_ID" = sql%([MOLECULE_schema]) "SELECT m.\"id\" AS \"DRUG_ID\", CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS \"DRUG_TRADE_NAME\", m.\"drugType\" AS \"DRUG_TYPE\", m.\"hasBeenWithdrawn\" AS \"DRUG_WITHDRAWN\" FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') AND m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' ORDER BY m.\"id\"" := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(tn.VALUE, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS tn(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' AND CAST(JSON_EXTRACT_PATH(tn.VALUE, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') ORDER BY DRUG_ID" = sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') AND m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' ORDER BY DRUG_ID" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' AND LOWER(CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT)) IN ('keytruda', 'vioxx', 'premarin', 'humira') ORDER BY DRUG_ID" = sql%([MOLECULE_schema]) "SELECT m.\"id\" AS \"DRUG_ID\", CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS \"DRUG_TRADE_NAME\", m.\"drugType\" AS \"DRUG_TYPE\", m.\"hasBeenWithdrawn\" AS \"DRUG_WITHDRAWN\" FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') AND m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' ORDER BY m.\"id\"" := by
  first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' AND LOWER(CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT)) IN ('keytruda', 'vioxx', 'premarin', 'humira') ORDER BY DRUG_ID" = sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') AND m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' ORDER BY DRUG_ID" := by
  first | sql_equiv | sorry

theorem eq_2_3 :
    sql%([MOLECULE_schema]) "SELECT m.\"id\" AS \"DRUG_ID\", CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS \"DRUG_TRADE_NAME\", m.\"drugType\" AS \"DRUG_TYPE\", m.\"hasBeenWithdrawn\" AS \"DRUG_WITHDRAWN\" FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') AND m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' ORDER BY m.\"id\"" = sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') AND m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' ORDER BY DRUG_ID" := by
  first | sql_equiv | sorry

end Bench_sf_bq350
