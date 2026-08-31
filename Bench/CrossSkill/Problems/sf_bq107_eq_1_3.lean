import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq107_eq_1_3

CREATE TABLE MNPR01_REFERENCE_201703 («name» STRING, «length» INT)
CREATE TABLE MNPR01_201703 («reference_name» STRING, «start» INT, «end» INT, «reference_bases» STRING, «alternate_bases» STRING, «variant_id» STRING, «quality» FLOAT, «filter» STRING, «names» STRING, «call» STRING, «AB» STRING, «ABP» STRING, «AC» STRING, «AF» STRING, «AN» INT, «AO» STRING, «CIGAR» STRING, «DP» INT, «DPB» FLOAT, «DPRA» STRING, «EPP» STRING, «EPPR» FLOAT, «GTI» INT, «LEN» STRING, «MEANALT» STRING, «MQM» STRING, «MQMR» FLOAT, «NS» INT, «NUMALT» INT, «ODDS» FLOAT, «PAIRED» STRING, «PAIREDR» FLOAT, «PAO» STRING, «PQA» STRING, «PQR» FLOAT, «PRO» FLOAT, «QA» STRING, «QR» INT, «RO» INT, «RPL» STRING, «RPP» STRING, «RPPR» FLOAT, «RPR» STRING, «RUN» STRING, «SAF» STRING, «SAP» STRING, «SAR» STRING, «SRF» INT, «SRP» FLOAT, «SRR» INT, «TYPE» STRING)

theorem eq (t0 : TableRel MNPR01_REFERENCE_201703_schema) (t1 : TableRel MNPR01_201703_schema) :
    (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "/* Variant density for the longest reference in MNPR01 */ /* Variant density = number of variants / reference length */ /* A variant is present if at least one call has genotype > 0 */ WITH longest_ref AS (SELECT \"name\", \"length\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" ORDER BY \"length\" DESC LIMIT 1), variant_positions AS (SELECT DISTINCT v.\"reference_name\", v.\"start\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v INNER JOIN longest_ref AS r ON v.\"reference_name\" = r.\"name\", LATERAL UNNEST(input => v.\"call\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'genotype', '0') AS INT) > 0 OR CAST(JSON_EXTRACT_PATH(f.value, 'genotype', '1') AS INT) > 0) SELECT r.\"name\" AS REFERENCE_NAME, ROUND(CAST(COUNT(vp.\"start\") * 1.0 AS DOUBLE PRECISION) / r.\"length\", 6) AS VARIANT_DENSITY, COUNT(vp.\"start\") AS VARIANT_COUNT, r.\"length\" AS REFERENCE_LENGTH FROM longest_ref AS r LEFT JOIN variant_positions AS vp ON vp.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\"") t0 t1
  = (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "WITH longest_ref AS (SELECT \"name\", \"length\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" ORDER BY \"length\" DESC LIMIT 1), variants_on_longest AS (SELECT DISTINCT v.\"reference_name\", v.\"start\", v.\"reference_bases\", v.\"alternate_bases\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v, LATERAL UNNEST(INPUT => v.\"call\") AS c(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(INPUT => JSON_EXTRACT_PATH(c.VALUE, 'genotype')) AS g(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE v.\"reference_name\" = (SELECT \"name\" FROM longest_ref) AND CAST(g.VALUE AS INT) > 0) SELECT lr.\"name\" AS REFERENCE_NAME, ROUND(CAST(CAST(COUNT(*) AS DOUBLE PRECISION) / CAST(lr.\"length\" AS DOUBLE PRECISION) AS DECIMAL), 6) AS VARIANT_DENSITY, COUNT(*) AS VARIANT_COUNT, lr.\"length\" AS REFERENCE_LENGTH FROM longest_ref AS lr LEFT JOIN variants_on_longest AS vol ON lr.\"name\" = vol.\"reference_name\" GROUP BY lr.\"name\", lr.\"length\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq107_eq_1_3
