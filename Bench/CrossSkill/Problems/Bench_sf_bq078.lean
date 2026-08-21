import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq078 — crossskill equivalence(s)

Question: Retrieve the approved symbol of target genes with the highest overall score that are associated with the disease 'EFO_0000676' from the data source 'IMPC'.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq078

CREATE TABLE ASSOCIATIONBYOVERALLDIRECT («diseaseId» STRING, «targetId» STRING, «score» FLOAT, «evidenceCount» INT)
CREATE TABLE TARGETS («id» STRING, «approvedSymbol» STRING, «biotype» STRING, «transcriptIds» STRING, «canonicalTranscript» STRING, «canonicalExons» STRING, «genomicLocation» STRING, «alternativeGenes» STRING, «approvedName» STRING, «go» STRING, «hallmarks» STRING, «synonyms» STRING, «symbolSynonyms» STRING, «nameSynonyms» STRING, «functionDescriptions» STRING, «subcellularLocations» STRING, «targetClass» STRING, «obsoleteSymbols» STRING, «obsoleteNames» STRING, «constraint» STRING, «tep» STRING, «proteinIds» STRING, «dbXrefs» STRING, «chemicalProbes» STRING, «homologues» STRING, «tractability» STRING, «safetyLiabilities» STRING, «pathways» STRING)
CREATE TABLE ASSOCIATIONBYDATASOURCEDIRECT («datatypeId» STRING, «datasourceId» STRING, «diseaseId» STRING, «targetId» STRING, «score» FLOAT, «evidenceCount» INT)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 :
    sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT \n    d.\"targetId\" AS TARGET_ID,\n    d.\"datasourceId\" AS \"datasourceId\",\n    t.\"approvedSymbol\" AS APPROVED_SYMBOL,\n    o.\"score\" AS OVERALL_SCORE\nFROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" d\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" o\n    ON d.\"targetId\" = o.\"targetId\" AND d.\"diseaseId\" = o.\"diseaseId\"\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" t\n    ON d.\"targetId\" = t.\"id\"\nWHERE d.\"diseaseId\" = 'EFO_0000676'\n  AND d.\"datasourceId\" = 'impc'\nORDER BY o.\"score\" DESC\nLIMIT 1;" = sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT\n    ds.\"targetId\" AS TARGET_ID,\n    ds.\"datasourceId\" AS \"datasourceId\",\n    t.\"approvedSymbol\" AS APPROVED_SYMBOL,\n    ov.\"score\" AS OVERALL_SCORE\nFROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" ds\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" ov\n    ON ds.\"targetId\" = ov.\"targetId\"\n    AND ds.\"diseaseId\" = ov.\"diseaseId\"\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" t\n    ON ds.\"targetId\" = t.\"id\"\nWHERE ds.\"diseaseId\" = 'EFO_0000676'\n    AND ds.\"datasourceId\" = 'impc'\nORDER BY ov.\"score\" DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 :
    sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT \n    d.\"targetId\" AS TARGET_ID,\n    d.\"datasourceId\" AS \"datasourceId\",\n    t.\"approvedSymbol\" AS APPROVED_SYMBOL,\n    o.\"score\" AS OVERALL_SCORE\nFROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" d\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" o\n    ON d.\"targetId\" = o.\"targetId\" AND d.\"diseaseId\" = o.\"diseaseId\"\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" t\n    ON d.\"targetId\" = t.\"id\"\nWHERE d.\"diseaseId\" = 'EFO_0000676'\n  AND d.\"datasourceId\" = 'impc'\nORDER BY o.\"score\" DESC\nLIMIT 1;" = sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT a.\"targetId\" AS TARGET_ID,\n       a.\"datasourceId\",\n       t.\"approvedSymbol\" AS APPROVED_SYMBOL,\n       o.\"score\" AS OVERALL_SCORE\nFROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" a\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" o \n  ON a.\"targetId\" = o.\"targetId\" AND a.\"diseaseId\" = o.\"diseaseId\"\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" t \n  ON a.\"targetId\" = t.\"id\"\nWHERE a.\"diseaseId\" = 'EFO_0000676' \n  AND a.\"datasourceId\" = 'impc'\nORDER BY o.\"score\" DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 :
    sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT\n    ds.\"targetId\" AS TARGET_ID,\n    ds.\"datasourceId\" AS \"datasourceId\",\n    t.\"approvedSymbol\" AS APPROVED_SYMBOL,\n    ov.\"score\" AS OVERALL_SCORE\nFROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" ds\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" ov\n    ON ds.\"targetId\" = ov.\"targetId\"\n    AND ds.\"diseaseId\" = ov.\"diseaseId\"\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" t\n    ON ds.\"targetId\" = t.\"id\"\nWHERE ds.\"diseaseId\" = 'EFO_0000676'\n    AND ds.\"datasourceId\" = 'impc'\nORDER BY ov.\"score\" DESC\nLIMIT 1;" = sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT a.\"targetId\" AS TARGET_ID,\n       a.\"datasourceId\",\n       t.\"approvedSymbol\" AS APPROVED_SYMBOL,\n       o.\"score\" AS OVERALL_SCORE\nFROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" a\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" o \n  ON a.\"targetId\" = o.\"targetId\" AND a.\"diseaseId\" = o.\"diseaseId\"\nJOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" t \n  ON a.\"targetId\" = t.\"id\"\nWHERE a.\"diseaseId\" = 'EFO_0000676' \n  AND a.\"datasourceId\" = 'impc'\nORDER BY o.\"score\" DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

end Bench_sf_bq078
