import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq415 — crossskill equivalence(s)

Question: List the top 10 samples in the genome data that have the highest number of positions where there is exactly one alternate allele and the sample's genotype is homozygous for the reference allele (both alleles are 0). Order the results in descending order of these counts.

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq415

CREATE TABLE _1000_GENOMES_PHASE_3_VARIANTS_20150220 («reference_name» STRING, «start_position» INT, «end_position» INT, «reference_bases» STRING, «alternate_bases» STRING, «names» STRING, «quality» FLOAT, «filter» STRING, «call» STRING, «CIEND» STRING, «CIPOS» STRING, «CS» STRING, «IMPRECISE» BOOL, «MC» STRING, «MEINFO» STRING, «MEND» INT, «MLEN» INT, «MSTART» INT, «SVLEN» STRING, «SVTYPE» STRING, «TSD» STRING, «NS» INT, «AN» INT, «DP» INT, «AA» STRING, «VT» STRING, «EX_TARGET» BOOL, «MULTI_ALLELIC» BOOL, «OLD_VARIANT» STRING, «partition_date_please_ignore» STRING)

theorem eq_0_1 : ∀ t,
    (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT\n  c.value:name::STRING AS CALL_SET_NAME,\n  COUNT(*) AS HOM_RR_COUNT\nFROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" v,\nLATERAL FLATTEN(input => v.\"call\") c\nWHERE ARRAY_SIZE(v.\"alternate_bases\") = 1\n  AND c.value:genotype[0]::INT = 0\n  AND c.value:genotype[1]::INT = 0\nGROUP BY c.value:name::STRING\nORDER BY HOM_RR_COUNT DESC, CALL_SET_NAME ASC\nLIMIT 10;") t ~= (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "WITH one_alt_positions AS (\n  SELECT v.\"reference_name\", v.\"start_position\", v.\"call\"\n  FROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" v\n  WHERE ARRAY_SIZE(v.\"alternate_bases\") = 1\n    AND v.\"alternate_bases\"[0]:\"alt\"::STRING != '<*>'\n)\nSELECT \n  c.value:\"name\"::STRING AS CALL_SET_NAME,\n  COUNT(*) AS HOM_RR_COUNT\nFROM one_alt_positions p,\nLATERAL FLATTEN(input => p.\"call\") c\nWHERE c.value:\"genotype\"[0]::INT = 0\n  AND c.value:\"genotype\"[1]::INT = 0\nGROUP BY CALL_SET_NAME\nORDER BY HOM_RR_COUNT DESC\nLIMIT 10;") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : _1000_GENOMES_PHASE_3_VARIANTS_20150220 "ARRAY_SIZE(\"alternate_bases\") = 1"
theorem eq_0_2 (t : TableRel _1000_GENOMES_PHASE_3_VARIANTS_20150220_schema) (h0 : hyp0_2_0 t) :
    (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT\n  c.value:name::STRING AS CALL_SET_NAME,\n  COUNT(*) AS HOM_RR_COUNT\nFROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" v,\nLATERAL FLATTEN(input => v.\"call\") c\nWHERE ARRAY_SIZE(v.\"alternate_bases\") = 1\n  AND c.value:genotype[0]::INT = 0\n  AND c.value:genotype[1]::INT = 0\nGROUP BY c.value:name::STRING\nORDER BY HOM_RR_COUNT DESC, CALL_SET_NAME ASC\nLIMIT 10;") t = (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT\n  c.value:name::STRING AS \"CALL_SET_NAME\",\n  COUNT(*) AS \"HOM_RR_COUNT\"\nFROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" t,\nLATERAL FLATTEN(input => t.\"call\") c\nWHERE ARRAY_SIZE(t.\"alternate_bases\") = 1\n  AND c.value:genotype[0]::INT = 0\n  AND c.value:genotype[1]::INT = 0\nGROUP BY c.value:name::STRING\nORDER BY \"HOM_RR_COUNT\" DESC, \"CALL_SET_NAME\" ASC\nLIMIT 10;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : _1000_GENOMES_PHASE_3_VARIANTS_20150220 "ARRAY_SIZE(\"alternate_bases\") = 1"
theorem eq_0_3 (t : TableRel _1000_GENOMES_PHASE_3_VARIANTS_20150220_schema) (h0 : hyp0_3_0 t) :
    (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT\n  c.value:name::STRING AS CALL_SET_NAME,\n  COUNT(*) AS HOM_RR_COUNT\nFROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" v,\nLATERAL FLATTEN(input => v.\"call\") c\nWHERE ARRAY_SIZE(v.\"alternate_bases\") = 1\n  AND c.value:genotype[0]::INT = 0\n  AND c.value:genotype[1]::INT = 0\nGROUP BY c.value:name::STRING\nORDER BY HOM_RR_COUNT DESC, CALL_SET_NAME ASC\nLIMIT 10;") t = (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT\n  c.value:name::STRING AS CALL_SET_NAME,\n  COUNT(*) AS HOM_RR_COUNT\nFROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\",\n  LATERAL FLATTEN(input => \"call\") c\nWHERE ARRAY_SIZE(\"alternate_bases\") = 1\n  AND c.value:genotype[0]::INT = 0\n  AND c.value:genotype[1]::INT = 0\nGROUP BY CALL_SET_NAME\nORDER BY HOM_RR_COUNT DESC\nLIMIT 10;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : _1000_GENOMES_PHASE_3_VARIANTS_20150220 "ARRAY_SIZE(\"alternate_bases\") = 1"
theorem eq_1_2 (t : TableRel _1000_GENOMES_PHASE_3_VARIANTS_20150220_schema) (h0 : hyp1_2_0 t) :
    (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "WITH one_alt_positions AS (\n  SELECT v.\"reference_name\", v.\"start_position\", v.\"call\"\n  FROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" v\n  WHERE ARRAY_SIZE(v.\"alternate_bases\") = 1\n    AND v.\"alternate_bases\"[0]:\"alt\"::STRING != '<*>'\n)\nSELECT \n  c.value:\"name\"::STRING AS CALL_SET_NAME,\n  COUNT(*) AS HOM_RR_COUNT\nFROM one_alt_positions p,\nLATERAL FLATTEN(input => p.\"call\") c\nWHERE c.value:\"genotype\"[0]::INT = 0\n  AND c.value:\"genotype\"[1]::INT = 0\nGROUP BY CALL_SET_NAME\nORDER BY HOM_RR_COUNT DESC\nLIMIT 10;") t ~= (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT\n  c.value:name::STRING AS \"CALL_SET_NAME\",\n  COUNT(*) AS \"HOM_RR_COUNT\"\nFROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" t,\nLATERAL FLATTEN(input => t.\"call\") c\nWHERE ARRAY_SIZE(t.\"alternate_bases\") = 1\n  AND c.value:genotype[0]::INT = 0\n  AND c.value:genotype[1]::INT = 0\nGROUP BY c.value:name::STRING\nORDER BY \"HOM_RR_COUNT\" DESC, \"CALL_SET_NAME\" ASC\nLIMIT 10;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : _1000_GENOMES_PHASE_3_VARIANTS_20150220 "ARRAY_SIZE(\"alternate_bases\") = 1"
theorem eq_1_3 (t : TableRel _1000_GENOMES_PHASE_3_VARIANTS_20150220_schema) (h0 : hyp1_3_0 t) :
    (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "WITH one_alt_positions AS (\n  SELECT v.\"reference_name\", v.\"start_position\", v.\"call\"\n  FROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" v\n  WHERE ARRAY_SIZE(v.\"alternate_bases\") = 1\n    AND v.\"alternate_bases\"[0]:\"alt\"::STRING != '<*>'\n)\nSELECT \n  c.value:\"name\"::STRING AS CALL_SET_NAME,\n  COUNT(*) AS HOM_RR_COUNT\nFROM one_alt_positions p,\nLATERAL FLATTEN(input => p.\"call\") c\nWHERE c.value:\"genotype\"[0]::INT = 0\n  AND c.value:\"genotype\"[1]::INT = 0\nGROUP BY CALL_SET_NAME\nORDER BY HOM_RR_COUNT DESC\nLIMIT 10;") t ~= (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT\n  c.value:name::STRING AS CALL_SET_NAME,\n  COUNT(*) AS HOM_RR_COUNT\nFROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\",\n  LATERAL FLATTEN(input => \"call\") c\nWHERE ARRAY_SIZE(\"alternate_bases\") = 1\n  AND c.value:genotype[0]::INT = 0\n  AND c.value:genotype[1]::INT = 0\nGROUP BY CALL_SET_NAME\nORDER BY HOM_RR_COUNT DESC\nLIMIT 10;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : _1000_GENOMES_PHASE_3_VARIANTS_20150220 "ARRAY_SIZE(\"alternate_bases\") = 1"
theorem eq_2_3 (t : TableRel _1000_GENOMES_PHASE_3_VARIANTS_20150220_schema) (h0 : hyp2_3_0 t) :
    (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT\n  c.value:name::STRING AS \"CALL_SET_NAME\",\n  COUNT(*) AS \"HOM_RR_COUNT\"\nFROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" t,\nLATERAL FLATTEN(input => t.\"call\") c\nWHERE ARRAY_SIZE(t.\"alternate_bases\") = 1\n  AND c.value:genotype[0]::INT = 0\n  AND c.value:genotype[1]::INT = 0\nGROUP BY c.value:name::STRING\nORDER BY \"HOM_RR_COUNT\" DESC, \"CALL_SET_NAME\" ASC\nLIMIT 10;") t = (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT\n  c.value:name::STRING AS CALL_SET_NAME,\n  COUNT(*) AS HOM_RR_COUNT\nFROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\",\n  LATERAL FLATTEN(input => \"call\") c\nWHERE ARRAY_SIZE(\"alternate_bases\") = 1\n  AND c.value:genotype[0]::INT = 0\n  AND c.value:genotype[1]::INT = 0\nGROUP BY CALL_SET_NAME\nORDER BY HOM_RR_COUNT DESC\nLIMIT 10;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq415
