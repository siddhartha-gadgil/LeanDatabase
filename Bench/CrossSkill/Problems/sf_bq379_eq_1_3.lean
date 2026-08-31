import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq379_eq_1_3

CREATE TABLE TARGETS («id» STRING, «approvedSymbol» STRING, «biotype» STRING, «transcriptIds» STRING, «canonicalTranscript» STRING, «canonicalExons» STRING, «genomicLocation» STRING, «alternativeGenes» STRING, «approvedName» STRING, «go» STRING, «hallmarks» STRING, «synonyms» STRING, «symbolSynonyms» STRING, «nameSynonyms» STRING, «functionDescriptions» STRING, «subcellularLocations» STRING, «targetClass» STRING, «obsoleteSymbols» STRING, «obsoleteNames» STRING, «constraint» STRING, «tep» STRING, «proteinIds» STRING, «dbXrefs» STRING, «chemicalProbes» STRING, «homologues» STRING, «tractability» STRING, «safetyLiabilities» STRING, «pathways» STRING)
CREATE TABLE ASSOCIATIONBYOVERALLDIRECT («diseaseId» STRING, «targetId» STRING, «score» FLOAT, «evidenceCount» INT)
CREATE TABLE DISEASES («id» STRING, «code» STRING, «dbXRefs» STRING, «description» STRING, «name» STRING, «directLocationIds» STRING, «obsoleteTerms» STRING, «parents» STRING, «synonyms» STRING, «ancestors» STRING, «descendants» STRING, «children» STRING, «therapeuticAreas» STRING, «indirectLocationIds» STRING, «ontology» STRING)

theorem eq (t0 : TableRel TARGETS_schema) (t1 : TableRel ASSOCIATIONBYOVERALLDIRECT_schema) (t2 : TableRel DISEASES_schema) :
    (sql%([TARGETS_schema, ASSOCIATIONBYOVERALLDIRECT_schema, DISEASES_schema]) "WITH mean_cte AS (SELECT AVG(a.\"score\") AS avg_score FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" AS a JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"DISEASES\" AS d ON a.\"diseaseId\" = d.\"id\" WHERE LOWER(d.\"name\") = 'psoriasis') SELECT t.\"approvedSymbol\" AS OUTPUT FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" AS a JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"TARGETS\" AS t ON a.\"targetId\" = t.\"id\" JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"DISEASES\" AS d ON a.\"diseaseId\" = d.\"id\" CROSS JOIN mean_cte AS m WHERE LOWER(d.\"name\") = 'psoriasis' ORDER BY ABS(a.\"score\" - m.avg_score) ASC LIMIT 1") t0 t1 t2
  ~= (sql%([TARGETS_schema, ASSOCIATIONBYOVERALLDIRECT_schema, DISEASES_schema]) "WITH psoriasis_scores AS (SELECT a.\"targetId\", a.\"score\" FROM \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"ASSOCIATIONBYOVERALLDIRECT\" AS a WHERE a.\"diseaseId\" = 'EFO_0000676'), mean_score AS (SELECT AVG(\"score\") AS avg_score FROM psoriasis_scores) SELECT t.\"approvedSymbol\" FROM psoriasis_scores AS ps JOIN \"OPEN_TARGETS_PLATFORM_1\".\"PLATFORM\".\"TARGETS\" AS t ON t.\"id\" = ps.\"targetId\" CROSS JOIN mean_score AS m ORDER BY ABS(ps.\"score\" - m.avg_score) ASC LIMIT 1") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_bq379_eq_1_3
