import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq095 — crossskill equivalence(s)

Question: Generate a list of drugs from the table containing molecular details that have completed clinical trials for pancreatic endocrine carcinoma, disease ID EFO_0007416. Please include each drug's name, the target approved symbol, and links to the relevant clinical trials.

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq095

CREATE TABLE MOLECULE («id» STRING, «canonicalSmiles» STRING, «inchiKey» STRING, «drugType» STRING, «blackBoxWarning» BOOL, «name» STRING, «yearOfFirstApproval» INT, «maximumClinicalTrialPhase» FLOAT, «parentId» STRING, «hasBeenWithdrawn» BOOL, «isApproved» BOOL, «tradeNames» STRING, «synonyms» STRING, «crossReferences» STRING, «childChemblIds» STRING, «linkedDiseases» STRING, «linkedTargets» STRING, «description» STRING)
CREATE TABLE KNOWNDRUGSAGGREGATED («drugId» STRING, «targetId» STRING, «diseaseId» STRING, «phase» FLOAT, «status» STRING, «urls» STRING, «ancestors» STRING, «label» STRING, «approvedSymbol» STRING, «approvedName» STRING, «targetClass» STRING, «prefName» STRING, «tradeNames» STRING, «synonyms» STRING, «drugType» STRING, «mechanismOfAction» STRING, «targetName» STRING)

theorem eq_0_1 :
    sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT k.\"approvedSymbol\" AS TARGET_SYMBOL, m.\"name\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(f.value, 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" AS k JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m ON k.\"drugId\" = m.\"id\", LATERAL UNNEST(input => JSON_EXTRACT_PATH(k.\"urls\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE k.\"diseaseId\" = 'EFO_0007416' AND k.\"status\" = 'Completed' ORDER BY TARGET_SYMBOL" = sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT k.\"approvedSymbol\" AS TARGET_SYMBOL, m.\"name\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(k.\"urls\", 'list', '0', 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" AS k ON m.\"id\" = k.\"drugId\" WHERE k.\"diseaseId\" = 'EFO_0007416' AND k.\"status\" = 'Completed' ORDER BY TARGET_SYMBOL" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT k.\"approvedSymbol\" AS TARGET_SYMBOL, m.\"name\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(f.value, 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" AS k JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m ON k.\"drugId\" = m.\"id\", LATERAL UNNEST(input => JSON_EXTRACT_PATH(k.\"urls\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE k.\"diseaseId\" = 'EFO_0007416' AND k.\"status\" = 'Completed' ORDER BY TARGET_SYMBOL" = sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT \"approvedSymbol\" AS \"TARGET_SYMBOL\", \"prefName\" AS \"DRUG_NAME\", CAST(JSON_EXTRACT_PATH(f.value, 'element', 'url') AS VARCHAR) AS \"CLINICAL_TRIAL_REFERENCE_URL\" FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\", LATERAL UNNEST(input => JSON_EXTRACT_PATH(\"urls\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE \"diseaseId\" = 'EFO_0007416' AND \"status\" = 'Completed' AND CAST(JSON_EXTRACT_PATH(f.value, 'element', 'niceName') AS VARCHAR) = 'ClinicalTrials' ORDER BY \"approvedSymbol\"" := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT k.\"approvedSymbol\" AS TARGET_SYMBOL, m.\"name\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(f.value, 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" AS k JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m ON k.\"drugId\" = m.\"id\", LATERAL UNNEST(input => JSON_EXTRACT_PATH(k.\"urls\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE k.\"diseaseId\" = 'EFO_0007416' AND k.\"status\" = 'Completed' ORDER BY TARGET_SYMBOL" = sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT \"approvedSymbol\" AS TARGET_SYMBOL, \"prefName\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(\"urls\", 'list', '0', 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" WHERE \"diseaseId\" = 'EFO_0007416' AND \"status\" = 'Completed' ORDER BY TARGET_SYMBOL" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT k.\"approvedSymbol\" AS TARGET_SYMBOL, m.\"name\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(k.\"urls\", 'list', '0', 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" AS k ON m.\"id\" = k.\"drugId\" WHERE k.\"diseaseId\" = 'EFO_0007416' AND k.\"status\" = 'Completed' ORDER BY TARGET_SYMBOL" = sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT \"approvedSymbol\" AS \"TARGET_SYMBOL\", \"prefName\" AS \"DRUG_NAME\", CAST(JSON_EXTRACT_PATH(f.value, 'element', 'url') AS VARCHAR) AS \"CLINICAL_TRIAL_REFERENCE_URL\" FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\", LATERAL UNNEST(input => JSON_EXTRACT_PATH(\"urls\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE \"diseaseId\" = 'EFO_0007416' AND \"status\" = 'Completed' AND CAST(JSON_EXTRACT_PATH(f.value, 'element', 'niceName') AS VARCHAR) = 'ClinicalTrials' ORDER BY \"approvedSymbol\"" := by
  first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT k.\"approvedSymbol\" AS TARGET_SYMBOL, m.\"name\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(k.\"urls\", 'list', '0', 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"MOLECULE\" AS m JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" AS k ON m.\"id\" = k.\"drugId\" WHERE k.\"diseaseId\" = 'EFO_0007416' AND k.\"status\" = 'Completed' ORDER BY TARGET_SYMBOL" = sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT \"approvedSymbol\" AS TARGET_SYMBOL, \"prefName\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(\"urls\", 'list', '0', 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" WHERE \"diseaseId\" = 'EFO_0007416' AND \"status\" = 'Completed' ORDER BY TARGET_SYMBOL" := by
  first | sql_equiv | sorry

theorem eq_2_3 :
    sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT \"approvedSymbol\" AS \"TARGET_SYMBOL\", \"prefName\" AS \"DRUG_NAME\", CAST(JSON_EXTRACT_PATH(f.value, 'element', 'url') AS VARCHAR) AS \"CLINICAL_TRIAL_REFERENCE_URL\" FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\", LATERAL UNNEST(input => JSON_EXTRACT_PATH(\"urls\", 'list')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE \"diseaseId\" = 'EFO_0007416' AND \"status\" = 'Completed' AND CAST(JSON_EXTRACT_PATH(f.value, 'element', 'niceName') AS VARCHAR) = 'ClinicalTrials' ORDER BY \"approvedSymbol\"" = sql%([MOLECULE_schema, KNOWNDRUGSAGGREGATED_schema]) "SELECT \"approvedSymbol\" AS TARGET_SYMBOL, \"prefName\" AS DRUG_NAME, CAST(JSON_EXTRACT_PATH(\"urls\", 'list', '0', 'element', 'url') AS TEXT) AS CLINICAL_TRIAL_REFERENCE_URL FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"KNOWNDRUGSAGGREGATED\" WHERE \"diseaseId\" = 'EFO_0007416' AND \"status\" = 'Completed' ORDER BY TARGET_SYMBOL" := by
  first | sql_equiv | sorry

end Bench_sf_bq095
