import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq415_eq_0_1

CREATE TABLE _1000_GENOMES_PHASE_3_VARIANTS_20150220 («reference_name» STRING, «start_position» INT, «end_position» INT, «reference_bases» STRING, «alternate_bases» STRING, «names» STRING, «quality» FLOAT, «filter» STRING, «call» STRING, «CIEND» STRING, «CIPOS» STRING, «CS» STRING, «IMPRECISE» BOOL, «MC» STRING, «MEINFO» STRING, «MEND» INT, «MLEN» INT, «MSTART» INT, «SVLEN» STRING, «SVTYPE» STRING, «TSD» STRING, «NS» INT, «AN» INT, «DP» INT, «AA» STRING, «VT» STRING, «EX_TARGET» BOOL, «MULTI_ALLELIC» BOOL, «OLD_VARIANT» STRING, «partition_date_please_ignore» STRING)

theorem eq (t0 : TableRel _1000_GENOMES_PHASE_3_VARIANTS_20150220_schema) :
    (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "SELECT CAST(JSON_EXTRACT_PATH(c.value, 'name') AS TEXT) AS CALL_SET_NAME, COUNT(*) AS HOM_RR_COUNT FROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" AS v, LATERAL UNNEST(input => v.\"call\") AS c(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE ARRAY_LENGTH(v.\"alternate_bases\", 1) = 1 AND CAST(JSON_EXTRACT_PATH(c.value, 'genotype', '0') AS INT) = 0 AND CAST(JSON_EXTRACT_PATH(c.value, 'genotype', '1') AS INT) = 0 GROUP BY CAST(JSON_EXTRACT_PATH(c.value, 'name') AS TEXT) ORDER BY HOM_RR_COUNT DESC, CALL_SET_NAME ASC LIMIT 10") t0
  ~= (sql%([_1000_GENOMES_PHASE_3_VARIANTS_20150220_schema]) "WITH one_alt_positions AS (SELECT v.\"reference_name\", v.\"start_position\", v.\"call\" FROM \"HUMAN_GENOME_VARIANTS\".\"HUMAN_GENOME_VARIANTS\".\"_1000_GENOMES_PHASE_3_VARIANTS_20150220\" AS v WHERE ARRAY_LENGTH(v.\"alternate_bases\", 1) = 1 AND CAST(JSON_EXTRACT_PATH(v.\"alternate_bases\"[1], 'alt') AS TEXT) <> '<*>') SELECT CAST(JSON_EXTRACT_PATH(c.value, 'name') AS TEXT) AS CALL_SET_NAME, COUNT(*) AS HOM_RR_COUNT FROM one_alt_positions AS p, LATERAL UNNEST(input => p.\"call\") AS c(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(c.value, 'genotype', '0') AS INT) = 0 AND CAST(JSON_EXTRACT_PATH(c.value, 'genotype', '1') AS INT) = 0 GROUP BY CALL_SET_NAME ORDER BY HOM_RR_COUNT DESC LIMIT 10") t0
  := by first | sql_equiv | sorry

end N_sf_bq415_eq_0_1
