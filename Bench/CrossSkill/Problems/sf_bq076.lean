import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq076 — crossskill equivalence(s)

Question: What is the highest number of motor vehicle theft incidents that occurred in any single month during 2016?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq076

CREATE TABLE CRIME («unique_key» INT, «case_number» STRING, «date» INT, «block» STRING, «iucr» STRING, «primary_type» STRING, «description» STRING, «location_description» STRING, «arrest» BOOL, «domestic» BOOL, «beat» INT, «district» INT, «ward» INT, «community_area» INT, «fbi_code» STRING, «x_coordinate» FLOAT, «y_coordinate» FLOAT, «year» INT, «updated_on» INT, «latitude» FLOAT, «longitude» FLOAT, «location» STRING)

theorem eq_0_1 :
    sql%([CRIME_schema]) "SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / 1000000)) AS MONTH, COUNT(*) AS MOTOR_VEHICLE_THEFT_COUNT FROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\" WHERE \"year\" = 2016 AND \"primary_type\" = 'MOTOR VEHICLE THEFT' GROUP BY MONTH ORDER BY MOTOR_VEHICLE_THEFT_COUNT DESC LIMIT 1" = sql%([CRIME_schema]) "SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / POWER(10, 6))) AS \"MONTH\", COUNT(*) AS \"MOTOR_VEHICLE_THEFT_COUNT\" FROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\" WHERE \"primary_type\" = 'MOTOR VEHICLE THEFT' AND \"year\" = 2016 GROUP BY EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / POWER(10, 6))) ORDER BY \"MOTOR_VEHICLE_THEFT_COUNT\" DESC LIMIT 1" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : CRIME "\"year\" = 2016"
HYPOTHESIS hyp0_2_1 : CRIME "EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / 1000000)) = 2016"
theorem eq_0_2 (t : TableRel CRIME_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([CRIME_schema]) "SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / 1000000)) AS MONTH, COUNT(*) AS MOTOR_VEHICLE_THEFT_COUNT FROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\" WHERE \"year\" = 2016 AND \"primary_type\" = 'MOTOR VEHICLE THEFT' GROUP BY MONTH ORDER BY MOTOR_VEHICLE_THEFT_COUNT DESC LIMIT 1") t = (sql%([CRIME_schema]) "SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / 1000000)) AS month, COUNT(*) AS incident_count FROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\" WHERE \"primary_type\" = 'MOTOR VEHICLE THEFT' AND EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / 1000000)) = 2016 GROUP BY month ORDER BY incident_count DESC LIMIT 1") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : CRIME "\"year\" = 2016"
HYPOTHESIS hyp1_2_1 : CRIME "EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / 1000000)) = 2016"
theorem eq_1_2 (t : TableRel CRIME_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) :
    (sql%([CRIME_schema]) "SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / POWER(10, 6))) AS \"MONTH\", COUNT(*) AS \"MOTOR_VEHICLE_THEFT_COUNT\" FROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\" WHERE \"primary_type\" = 'MOTOR VEHICLE THEFT' AND \"year\" = 2016 GROUP BY EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / POWER(10, 6))) ORDER BY \"MOTOR_VEHICLE_THEFT_COUNT\" DESC LIMIT 1") t = (sql%([CRIME_schema]) "SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / 1000000)) AS month, COUNT(*) AS incident_count FROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\" WHERE \"primary_type\" = 'MOTOR VEHICLE THEFT' AND EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / 1000000)) = 2016 GROUP BY month ORDER BY incident_count DESC LIMIT 1") t := by
  first | sql_equiv | sorry

end Bench_sf_bq076
