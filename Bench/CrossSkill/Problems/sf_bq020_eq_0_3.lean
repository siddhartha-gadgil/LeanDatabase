import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq020_eq_0_3

CREATE TABLE MNPR01_REFERENCE_201703 («name» STRING, «length» INT)
CREATE TABLE MNPR01_201703 («reference_name» STRING, «start» INT, «end» INT, «reference_bases» STRING, «alternate_bases» STRING, «variant_id» STRING, «quality» FLOAT, «filter» STRING, «names» STRING, «call» STRING, «AB» STRING, «ABP» STRING, «AC» STRING, «AF» STRING, «AN» INT, «AO» STRING, «CIGAR» STRING, «DP» INT, «DPB» FLOAT, «DPRA» STRING, «EPP» STRING, «EPPR» FLOAT, «GTI» INT, «LEN» STRING, «MEANALT» STRING, «MQM» STRING, «MQMR» FLOAT, «NS» INT, «NUMALT» INT, «ODDS» FLOAT, «PAIRED» STRING, «PAIREDR» FLOAT, «PAO» STRING, «PQA» STRING, «PQR» FLOAT, «PRO» FLOAT, «QA» STRING, «QR» INT, «RO» INT, «RPL» STRING, «RPP» STRING, «RPPR» FLOAT, «RPR» STRING, «RUN» STRING, «SAF» STRING, «SAP» STRING, «SAR» STRING, «SRF» INT, «SRP» FLOAT, «SRR» INT, «TYPE» STRING)

theorem eq (t0 : TableRel MNPR01_REFERENCE_201703_schema) (t1 : TableRel MNPR01_201703_schema) :
    (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT v.\"reference_name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY v.\"reference_name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / CAST(r.\"length\" AS DOUBLE PRECISION) DESC LIMIT 1") t0 t1
  ~= (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS reference_name FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / r.\"length\" DESC LIMIT 1") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq020_eq_0_3
