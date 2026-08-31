import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq095_eq_0_2

CREATE TABLE MOLECULE («id» STRING, «canonicalSmiles» STRING, «inchiKey» STRING, «drugType» STRING, «blackBoxWarning» BOOL, «name» STRING, «yearOfFirstApproval» INT, «maximumClinicalTrialPhase» FLOAT, «parentId» STRING, «hasBeenWithdrawn» BOOL, «isApproved» BOOL, «tradeNames» STRING, «synonyms» STRING, «crossReferences» STRING, «childChemblIds» STRING, «linkedDiseases» STRING, «linkedTargets» STRING, «description» STRING)
CREATE TABLE KNOWNDRUGSAGGREGATED («drugId» STRING, «targetId» STRING, «diseaseId» STRING, «phase» FLOAT, «status» STRING, «urls» STRING, «ancestors» STRING, «label» STRING, «approvedSymbol» STRING, «approvedName» STRING, «targetClass» STRING, «prefName» STRING, «tradeNames» STRING, «synonyms» STRING, «drugType» STRING, «mechanismOfAction» STRING, «targetName» STRING)

theorem eq (t0 : TableRel MOLECULE_schema) (t1 : TableRel KNOWNDRUGSAGGREGATED_schema) :
    (sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT k.\"approvedSymbol\" AS TARGET_SYMBOL, m.\"name\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(f.value, 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" AS k JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m ON k.\"drugId\" = m.\"id\", LATERAL UNNEST(input => JSON_EXTRACT_PATH(k.\"urls\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE k.\"diseaseId\" = 'EFO_0007416' AND k.\"status\" = 'Completed' ORDER BY TARGET_SYMBOL") t0 t1
  = (sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT \"approvedSymbol\" AS \"TARGET_SYMBOL\", \"prefName\" AS \"DRUG_NAME\", CAST(JSON_EXTRACT_PATH(f.value, 'element', 'url') AS VARCHAR) AS \"CLINICAL_TRIAL_REFERENCE_URL\" FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\", LATERAL UNNEST(input => JSON_EXTRACT_PATH(\"urls\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE \"diseaseId\" = 'EFO_0007416' AND \"status\" = 'Completed' AND CAST(JSON_EXTRACT_PATH(f.value, 'element', 'niceName') AS VARCHAR) = 'ClinicalTrials' ORDER BY \"approvedSymbol\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq095_eq_0_2
