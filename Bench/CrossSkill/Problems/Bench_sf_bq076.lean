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
    sql%([CRIME_schema]) "SELECT\n    EXTRACT(MONTH FROM TO_TIMESTAMP(\"date\" / 1000000)) AS MONTH,\n    COUNT(*) AS MOTOR_VEHICLE_THEFT_COUNT\nFROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\"\nWHERE \"year\" = 2016\n  AND \"primary_type\" = 'MOTOR VEHICLE THEFT'\nGROUP BY MONTH\nORDER BY MOTOR_VEHICLE_THEFT_COUNT DESC\nLIMIT 1;" = sql%([CRIME_schema]) "SELECT\n    EXTRACT(MONTH FROM TO_TIMESTAMP(\"date\", 6)) AS \"MONTH\",\n    COUNT(*) AS \"MOTOR_VEHICLE_THEFT_COUNT\"\nFROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\"\nWHERE \"primary_type\" = 'MOTOR VEHICLE THEFT'\n  AND \"year\" = 2016\nGROUP BY EXTRACT(MONTH FROM TO_TIMESTAMP(\"date\", 6))\nORDER BY \"MOTOR_VEHICLE_THEFT_COUNT\" DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : CRIME "\"year\" = 2016"
HYPOTHESIS hyp0_2_1 : CRIME "EXTRACT(YEAR FROM TO_TIMESTAMP(\"date\" / 1000000)) = 2016"
theorem eq_0_2 (t : TableRel CRIME_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([CRIME_schema]) "SELECT\n    EXTRACT(MONTH FROM TO_TIMESTAMP(\"date\" / 1000000)) AS MONTH,\n    COUNT(*) AS MOTOR_VEHICLE_THEFT_COUNT\nFROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\"\nWHERE \"year\" = 2016\n  AND \"primary_type\" = 'MOTOR VEHICLE THEFT'\nGROUP BY MONTH\nORDER BY MOTOR_VEHICLE_THEFT_COUNT DESC\nLIMIT 1;") t = (sql%([CRIME_schema]) "SELECT\n    EXTRACT(MONTH FROM TO_TIMESTAMP(\"date\" / 1000000)) AS month,\n    COUNT(*) AS incident_count\nFROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\"\nWHERE \"primary_type\" = 'MOTOR VEHICLE THEFT'\n  AND EXTRACT(YEAR FROM TO_TIMESTAMP(\"date\" / 1000000)) = 2016\nGROUP BY month\nORDER BY incident_count DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : CRIME "\"year\" = 2016"
HYPOTHESIS hyp1_2_1 : CRIME "EXTRACT(YEAR FROM TO_TIMESTAMP(\"date\" / 1000000)) = 2016"
theorem eq_1_2 (t : TableRel CRIME_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) :
    (sql%([CRIME_schema]) "SELECT\n    EXTRACT(MONTH FROM TO_TIMESTAMP(\"date\", 6)) AS \"MONTH\",\n    COUNT(*) AS \"MOTOR_VEHICLE_THEFT_COUNT\"\nFROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\"\nWHERE \"primary_type\" = 'MOTOR VEHICLE THEFT'\n  AND \"year\" = 2016\nGROUP BY EXTRACT(MONTH FROM TO_TIMESTAMP(\"date\", 6))\nORDER BY \"MOTOR_VEHICLE_THEFT_COUNT\" DESC\nLIMIT 1;") t = (sql%([CRIME_schema]) "SELECT\n    EXTRACT(MONTH FROM TO_TIMESTAMP(\"date\" / 1000000)) AS month,\n    COUNT(*) AS incident_count\nFROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\"\nWHERE \"primary_type\" = 'MOTOR VEHICLE THEFT'\n  AND EXTRACT(YEAR FROM TO_TIMESTAMP(\"date\" / 1000000)) = 2016\nGROUP BY month\nORDER BY incident_count DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq076
