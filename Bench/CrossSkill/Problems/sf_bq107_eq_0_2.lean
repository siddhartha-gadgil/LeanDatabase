import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq107_eq_0_2

CREATE TABLE MNPR01_REFERENCE_201703 («name» STRING, «length» INT)
CREATE TABLE MNPR01_201703 («reference_name» STRING, «start» INT, «end» INT, «reference_bases» STRING, «alternate_bases» STRING, «variant_id» STRING, «quality» FLOAT, «filter» STRING, «names» STRING, «call» STRING, «AB» STRING, «ABP» STRING, «AC» STRING, «AF» STRING, «AN» INT, «AO» STRING, «CIGAR» STRING, «DP» INT, «DPB» FLOAT, «DPRA» STRING, «EPP» STRING, «EPPR» FLOAT, «GTI» INT, «LEN» STRING, «MEANALT» STRING, «MQM» STRING, «MQMR» FLOAT, «NS» INT, «NUMALT» INT, «ODDS» FLOAT, «PAIRED» STRING, «PAIREDR» FLOAT, «PAO» STRING, «PQA» STRING, «PQR» FLOAT, «PRO» FLOAT, «QA» STRING, «QR» INT, «RO» INT, «RPL» STRING, «RPP» STRING, «RPPR» FLOAT, «RPR» STRING, «RUN» STRING, «SAF» STRING, «SAP» STRING, «SAR» STRING, «SRF» INT, «SRP» FLOAT, «SRR» INT, «TYPE» STRING)

theorem eq (t0 : TableRel MNPR01_REFERENCE_201703_schema) (t1 : TableRel MNPR01_201703_schema) :
    (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "WITH longest_ref AS (SELECT \"name\" AS REFERENCE_NAME, \"length\" AS REFERENCE_LENGTH FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" ORDER BY \"length\" DESC LIMIT 1), variant_with_gt AS (SELECT v.\"reference_name\", v.\"start\", v.\"end\", MAX(CAST(g.VALUE AS INT)) AS max_genotype FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v, LATERAL UNNEST(input => v.\"call\") AS c(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(input => JSON_EXTRACT_PATH(c.VALUE, 'genotype')) AS g(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE v.\"reference_name\" = (SELECT REFERENCE_NAME FROM longest_ref) GROUP BY v.\"reference_name\", v.\"start\", v.\"end\"), variant_count AS (SELECT \"reference_name\", COUNT(*) AS VARIANT_COUNT FROM variant_with_gt WHERE max_genotype > 0 GROUP BY \"reference_name\") SELECT lr.REFERENCE_NAME, ROUND(CAST(vc.VARIANT_COUNT AS DOUBLE PRECISION) / lr.REFERENCE_LENGTH, 6) AS VARIANT_DENSITY, vc.VARIANT_COUNT, lr.REFERENCE_LENGTH FROM longest_ref AS lr JOIN variant_count AS vc ON lr.REFERENCE_NAME = vc.\"reference_name\"") t0 t1
  ~= (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "WITH variants_with_call AS (SELECT DISTINCT v.\"reference_name\", v.\"start\", v.\"end\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v, LATERAL UNNEST(input => v.\"call\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(input => JSON_EXTRACT_PATH(f.value, 'genotype')) AS g(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(g.value AS INT) > 0), variant_counts AS (SELECT \"reference_name\", COUNT(*) AS VARIANT_COUNT FROM variants_with_call GROUP BY \"reference_name\"), joined AS (SELECT vc.\"reference_name\" AS REFERENCE_NAME, vc.VARIANT_COUNT, r.\"length\" AS REFERENCE_LENGTH, CAST(vc.VARIANT_COUNT AS DOUBLE PRECISION) / r.\"length\" AS VARIANT_DENSITY FROM variant_counts AS vc JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON vc.\"reference_name\" = r.\"name\") SELECT REFERENCE_NAME, VARIANT_DENSITY, VARIANT_COUNT, REFERENCE_LENGTH FROM joined ORDER BY REFERENCE_LENGTH DESC LIMIT 1") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq107_eq_0_2
