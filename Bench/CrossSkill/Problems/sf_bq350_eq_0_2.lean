import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq350_eq_0_2

CREATE TABLE MOLECULE («id» STRING, «canonicalSmiles» STRING, «inchiKey» STRING, «drugType» STRING, «blackBoxWarning» BOOL, «name» STRING, «yearOfFirstApproval» INT, «maximumClinicalTrialPhase» FLOAT, «parentId» STRING, «hasBeenWithdrawn» BOOL, «isApproved» BOOL, «tradeNames» STRING, «synonyms» STRING, «crossReferences» STRING, «childChemblIds» STRING, «linkedDiseases» STRING, «linkedTargets» STRING, «description» STRING)

theorem eq (t0 : TableRel MOLECULE_schema) :
    (sql%([MOLECULE_schema]) "SELECT m.\"id\" AS DRUG_ID, CAST(JSON_EXTRACT_PATH(tn.VALUE, 'element') AS TEXT) AS DRUG_TRADE_NAME, m.\"drugType\" AS DRUG_TYPE, m.\"hasBeenWithdrawn\" AS DRUG_WITHDRAWN FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS tn(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' AND CAST(JSON_EXTRACT_PATH(tn.VALUE, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') ORDER BY DRUG_ID") t0
  = (sql%([MOLECULE_schema]) "SELECT m.\"id\" AS \"DRUG_ID\", CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) AS \"DRUG_TRADE_NAME\", m.\"drugType\" AS \"DRUG_TYPE\", m.\"hasBeenWithdrawn\" AS \"DRUG_WITHDRAWN\" FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m, LATERAL UNNEST(input => JSON_EXTRACT_PATH(m.\"tradeNames\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'element') AS TEXT) IN ('Keytruda', 'Vioxx', 'Premarin', 'Humira') AND m.\"isApproved\" = TRUE AND m.\"blackBoxWarning\" = TRUE AND m.\"drugType\" <> 'Unknown' ORDER BY m.\"id\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq350_eq_0_2
