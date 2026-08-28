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
    sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT d.\"targetId\" AS TARGET_ID, d.\"datasourceId\" AS \"datasourceId\", t.\"approvedSymbol\" AS APPROVED_SYMBOL, o.\"score\" AS OVERALL_SCORE FROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" AS d JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" AS o ON d.\"targetId\" = o.\"targetId\" AND d.\"diseaseId\" = o.\"diseaseId\" JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" AS t ON d.\"targetId\" = t.\"id\" WHERE d.\"diseaseId\" = 'EFO_0000676' AND d.\"datasourceId\" = 'impc' ORDER BY o.\"score\" DESC LIMIT 1" = sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT ds.\"targetId\" AS TARGET_ID, ds.\"datasourceId\" AS \"datasourceId\", t.\"approvedSymbol\" AS APPROVED_SYMBOL, ov.\"score\" AS OVERALL_SCORE FROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" AS ds JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" AS ov ON ds.\"targetId\" = ov.\"targetId\" AND ds.\"diseaseId\" = ov.\"diseaseId\" JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" AS t ON ds.\"targetId\" = t.\"id\" WHERE ds.\"diseaseId\" = 'EFO_0000676' AND ds.\"datasourceId\" = 'impc' ORDER BY ov.\"score\" DESC LIMIT 1" := by
  first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 :
    sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT d.\"targetId\" AS TARGET_ID, d.\"datasourceId\" AS \"datasourceId\", t.\"approvedSymbol\" AS APPROVED_SYMBOL, o.\"score\" AS OVERALL_SCORE FROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" AS d JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" AS o ON d.\"targetId\" = o.\"targetId\" AND d.\"diseaseId\" = o.\"diseaseId\" JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" AS t ON d.\"targetId\" = t.\"id\" WHERE d.\"diseaseId\" = 'EFO_0000676' AND d.\"datasourceId\" = 'impc' ORDER BY o.\"score\" DESC LIMIT 1" = sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT a.\"targetId\" AS TARGET_ID, a.\"datasourceId\", t.\"approvedSymbol\" AS APPROVED_SYMBOL, o.\"score\" AS OVERALL_SCORE FROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" AS a JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" AS o ON a.\"targetId\" = o.\"targetId\" AND a.\"diseaseId\" = o.\"diseaseId\" JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" AS t ON a.\"targetId\" = t.\"id\" WHERE a.\"diseaseId\" = 'EFO_0000676' AND a.\"datasourceId\" = 'impc' ORDER BY o.\"score\" DESC LIMIT 1" := by
  first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 :
    sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT ds.\"targetId\" AS TARGET_ID, ds.\"datasourceId\" AS \"datasourceId\", t.\"approvedSymbol\" AS APPROVED_SYMBOL, ov.\"score\" AS OVERALL_SCORE FROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" AS ds JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" AS ov ON ds.\"targetId\" = ov.\"targetId\" AND ds.\"diseaseId\" = ov.\"diseaseId\" JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" AS t ON ds.\"targetId\" = t.\"id\" WHERE ds.\"diseaseId\" = 'EFO_0000676' AND ds.\"datasourceId\" = 'impc' ORDER BY ov.\"score\" DESC LIMIT 1" = sql%([ASSOCIATIONBYOVERALLDIRECT_schema, TARGETS_schema, ASSOCIATIONBYDATASOURCEDIRECT_schema]) "SELECT a.\"targetId\" AS TARGET_ID, a.\"datasourceId\", t.\"approvedSymbol\" AS APPROVED_SYMBOL, o.\"score\" AS OVERALL_SCORE FROM \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYDATASOURCEDIRECT\" AS a JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" AS o ON a.\"targetId\" = o.\"targetId\" AND a.\"diseaseId\" = o.\"diseaseId\" JOIN \"OPEN_TARGETS_PLATFORM_2\".\"OPEN_TARGETS_PLATFORM\".\"TARGETS\" AS t ON a.\"targetId\" = t.\"id\" WHERE a.\"diseaseId\" = 'EFO_0000676' AND a.\"datasourceId\" = 'impc' ORDER BY o.\"score\" DESC LIMIT 1" := by
  first | sql_equiv | sorry

end Bench_sf_bq078
