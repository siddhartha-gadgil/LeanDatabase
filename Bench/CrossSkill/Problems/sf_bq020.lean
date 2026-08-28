import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq020 — crossskill equivalence(s)

Question: What is the name of the reference sequence with the highest variant density in the given cannabis genome dataset?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq020

CREATE TABLE MNPR01_REFERENCE_201703 («name» STRING, «length» INT)
CREATE TABLE MNPR01_201703 («reference_name» STRING, «start» INT, «end» INT, «reference_bases» STRING, «alternate_bases» STRING, «variant_id» STRING, «quality» FLOAT, «filter» STRING, «names» STRING, «call» STRING, «AB» STRING, «ABP» STRING, «AC» STRING, «AF» STRING, «AN» INT, «AO» STRING, «CIGAR» STRING, «DP» INT, «DPB» FLOAT, «DPRA» STRING, «EPP» STRING, «EPPR» FLOAT, «GTI» INT, «LEN» STRING, «MEANALT» STRING, «MQM» STRING, «MQMR» FLOAT, «NS» INT, «NUMALT» INT, «ODDS» FLOAT, «PAIRED» STRING, «PAIREDR» FLOAT, «PAO» STRING, «PQA» STRING, «PQR» FLOAT, «PRO» FLOAT, «QA» STRING, «QR» INT, «RO» INT, «RPL» STRING, «RPP» STRING, «RPPR» FLOAT, «RPR» STRING, «RUN» STRING, «SAF» STRING, «SAP» STRING, «SAR» STRING, «SRF» INT, «SRP» FLOAT, «SRR» INT, «TYPE» STRING)

theorem eq_0_1 :
    sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT v.\"reference_name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY v.\"reference_name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / CAST(r.\"length\" AS DOUBLE PRECISION) DESC LIMIT 1" = sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / CAST(r.\"length\" AS DOUBLE PRECISION) DESC LIMIT 1" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT v.\"reference_name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY v.\"reference_name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / CAST(r.\"length\" AS DOUBLE PRECISION) DESC LIMIT 1" = sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / r.\"length\" DESC LIMIT 1" := by
  first | sql_equiv | sorry

theorem eq_0_3 : ∀ t,
    (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT v.\"reference_name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY v.\"reference_name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / CAST(r.\"length\" AS DOUBLE PRECISION) DESC LIMIT 1") t ~= (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS reference_name FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / r.\"length\" DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / CAST(r.\"length\" AS DOUBLE PRECISION) DESC LIMIT 1" = sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / r.\"length\" DESC LIMIT 1" := by
  first | sql_equiv | sorry

theorem eq_1_3 : ∀ t,
    (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / CAST(r.\"length\" AS DOUBLE PRECISION) DESC LIMIT 1") t ~= (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS reference_name FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / r.\"length\" DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

theorem eq_2_3 : ∀ t,
    (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS \"OUTPUT\" FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / r.\"length\" DESC LIMIT 1") t ~= (sql%([MNPR01_REFERENCE_201703_schema, MNPR01_201703_schema]) "SELECT r.\"name\" AS reference_name FROM \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_201703\" AS v JOIN \"GENOMICS_CANNABIS\".\"GENOMICS_CANNABIS\".\"MNPR01_REFERENCE_201703\" AS r ON v.\"reference_name\" = r.\"name\" GROUP BY r.\"name\", r.\"length\" ORDER BY CAST(COUNT(*) AS DOUBLE PRECISION) / r.\"length\" DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq020
