import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq076_eq_0_1

CREATE TABLE CRIME («unique_key» INT, «case_number» STRING, «date» INT, «block» STRING, «iucr» STRING, «primary_type» STRING, «description» STRING, «location_description» STRING, «arrest» BOOL, «domestic» BOOL, «beat» INT, «district» INT, «ward» INT, «community_area» INT, «fbi_code» STRING, «x_coordinate» FLOAT, «y_coordinate» FLOAT, «year» INT, «updated_on» INT, «latitude» FLOAT, «longitude» FLOAT, «location» STRING)

theorem eq (t0 : TableRel CRIME_schema) :
    (sql%([CRIME_schema]) "SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / 1000000)) AS MONTH, COUNT(*) AS MOTOR_VEHICLE_THEFT_COUNT FROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\" WHERE \"year\" = 2016 AND \"primary_type\" = 'MOTOR VEHICLE THEFT' GROUP BY MONTH ORDER BY MOTOR_VEHICLE_THEFT_COUNT DESC LIMIT 1") t0
  = (sql%([CRIME_schema]) "SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / POWER(10, 6))) AS \"MONTH\", COUNT(*) AS \"MOTOR_VEHICLE_THEFT_COUNT\" FROM \"CHICAGO\".\"CHICAGO_CRIME\".\"CRIME\" WHERE \"primary_type\" = 'MOTOR VEHICLE THEFT' AND \"year\" = 2016 GROUP BY EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"date\" AS DOUBLE PRECISION) / POWER(10, 6))) ORDER BY \"MOTOR_VEHICLE_THEFT_COUNT\" DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_bq076_eq_0_1
