import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq281 — crossskill equivalence(s)

Question: What is the highest number of electric bike rides lasting more than 10 minutes taken by subscribers with 'Student Membership' in a single day, excluding rides starting or ending at 'Mobile Station' or 'Repair Shop'?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq281

CREATE TABLE BIKESHARE_TRIPS («trip_id» STRING, «subscriber_type» STRING, «bike_id» STRING, «bike_type» STRING, «start_time» INT, «start_station_id» INT, «start_station_name» STRING, «end_station_id» STRING, «end_station_name» STRING, «duration_minutes» INT)

HYPOTHESIS hyp0_1_0 : BIKESHARE_TRIPS "\"start_station_name\" <> 'Mobile Station'"
HYPOTHESIS hyp0_1_1 : BIKESHARE_TRIPS "\"end_station_name\" <> 'Mobile Station'"
HYPOTHESIS hyp0_1_2 : BIKESHARE_TRIPS "\"start_station_name\" <> 'Repair Shop'"
HYPOTHESIS hyp0_1_3 : BIKESHARE_TRIPS "\"end_station_name\" <> 'Repair Shop'"
HYPOTHESIS hyp0_1_4 : BIKESHARE_TRIPS "NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop')"
HYPOTHESIS hyp0_1_5 : BIKESHARE_TRIPS "NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop')"
theorem eq_0_1 (t : TableRel BIKESHARE_TRIPS_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) (h2 : hyp0_1_2 t) (h3 : hyp0_1_3 t) (h4 : hyp0_1_4 t) (h5 : hyp0_1_5 t) :
    (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS OUTPUT FROM (SELECT CAST(\"start_time\" AS DATE) AS ride_day, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"subscriber_type\" = 'Student Membership' AND \"duration_minutes\" > 10 AND \"start_station_name\" <> 'Mobile Station' AND \"end_station_name\" <> 'Mobile Station' AND \"start_station_name\" <> 'Repair Shop' AND \"end_station_name\" <> 'Repair Shop' GROUP BY ride_day)") t = (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(ride_count) AS OUTPUT FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS ride_date, COUNT(*) AS ride_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"subscriber_type\" = 'Student Membership' AND \"duration_minutes\" > 10 AND NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop') AND NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop') GROUP BY ride_date) AS daily_counts") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : BIKESHARE_TRIPS "\"start_station_name\" <> 'Mobile Station'"
HYPOTHESIS hyp0_2_1 : BIKESHARE_TRIPS "\"end_station_name\" <> 'Mobile Station'"
HYPOTHESIS hyp0_2_2 : BIKESHARE_TRIPS "\"start_station_name\" <> 'Repair Shop'"
HYPOTHESIS hyp0_2_3 : BIKESHARE_TRIPS "\"end_station_name\" <> 'Repair Shop'"
HYPOTHESIS hyp0_2_4 : BIKESHARE_TRIPS "NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop')"
HYPOTHESIS hyp0_2_5 : BIKESHARE_TRIPS "NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop')"
theorem eq_0_2 (t : TableRel BIKESHARE_TRIPS_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) (h2 : hyp0_2_2 t) (h3 : hyp0_2_3 t) (h4 : hyp0_2_4 t) (h5 : hyp0_2_5 t) :
    (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS OUTPUT FROM (SELECT CAST(\"start_time\" AS DATE) AS ride_day, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"subscriber_type\" = 'Student Membership' AND \"duration_minutes\" > 10 AND \"start_station_name\" <> 'Mobile Station' AND \"end_station_name\" <> 'Mobile Station' AND \"start_station_name\" <> 'Repair Shop' AND \"end_station_name\" <> 'Repair Shop' GROUP BY ride_day)") t = (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS \"OUTPUT\" FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS ride_date, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"subscriber_type\" = 'Student Membership' AND \"bike_type\" = 'electric' AND \"duration_minutes\" > 10 AND NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop') AND NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop') GROUP BY ride_date) AS daily_rides") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : BIKESHARE_TRIPS "\"start_station_name\" <> 'Mobile Station'"
HYPOTHESIS hyp0_3_1 : BIKESHARE_TRIPS "\"end_station_name\" <> 'Mobile Station'"
HYPOTHESIS hyp0_3_2 : BIKESHARE_TRIPS "\"start_station_name\" <> 'Repair Shop'"
HYPOTHESIS hyp0_3_3 : BIKESHARE_TRIPS "\"end_station_name\" <> 'Repair Shop'"
HYPOTHESIS hyp0_3_4 : BIKESHARE_TRIPS "NOT \"start_station_name\" ILIKE '%Mobile Station%'"
HYPOTHESIS hyp0_3_5 : BIKESHARE_TRIPS "NOT \"start_station_name\" ILIKE '%Repair Shop%'"
HYPOTHESIS hyp0_3_6 : BIKESHARE_TRIPS "NOT \"end_station_name\" ILIKE '%Mobile Station%'"
HYPOTHESIS hyp0_3_7 : BIKESHARE_TRIPS "NOT \"end_station_name\" ILIKE '%Repair Shop%'"
theorem eq_0_3 (t : TableRel BIKESHARE_TRIPS_schema) (h0 : hyp0_3_0 t) (h1 : hyp0_3_1 t) (h2 : hyp0_3_2 t) (h3 : hyp0_3_3 t) (h4 : hyp0_3_4 t) (h5 : hyp0_3_5 t) (h6 : hyp0_3_6 t) (h7 : hyp0_3_7 t) :
    (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS OUTPUT FROM (SELECT CAST(\"start_time\" AS DATE) AS ride_day, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"subscriber_type\" = 'Student Membership' AND \"duration_minutes\" > 10 AND \"start_station_name\" <> 'Mobile Station' AND \"end_station_name\" <> 'Mobile Station' AND \"start_station_name\" <> 'Repair Shop' AND \"end_station_name\" <> 'Repair Shop' GROUP BY ride_day)") t = (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS OUTPUT FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS trip_date, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"duration_minutes\" > 10 AND \"subscriber_type\" = 'Student Membership' AND NOT \"start_station_name\" ILIKE '%Mobile Station%' AND NOT \"start_station_name\" ILIKE '%Repair Shop%' AND NOT \"end_station_name\" ILIKE '%Mobile Station%' AND NOT \"end_station_name\" ILIKE '%Repair Shop%' GROUP BY trip_date) AS sub") t := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(ride_count) AS OUTPUT FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS ride_date, COUNT(*) AS ride_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"subscriber_type\" = 'Student Membership' AND \"duration_minutes\" > 10 AND NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop') AND NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop') GROUP BY ride_date) AS daily_counts" = sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS \"OUTPUT\" FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS ride_date, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"subscriber_type\" = 'Student Membership' AND \"bike_type\" = 'electric' AND \"duration_minutes\" > 10 AND NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop') AND NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop') GROUP BY ride_date) AS daily_rides" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : BIKESHARE_TRIPS "NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop')"
HYPOTHESIS hyp1_3_1 : BIKESHARE_TRIPS "NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop')"
HYPOTHESIS hyp1_3_2 : BIKESHARE_TRIPS "NOT \"start_station_name\" ILIKE '%Mobile Station%'"
HYPOTHESIS hyp1_3_3 : BIKESHARE_TRIPS "NOT \"start_station_name\" ILIKE '%Repair Shop%'"
HYPOTHESIS hyp1_3_4 : BIKESHARE_TRIPS "NOT \"end_station_name\" ILIKE '%Mobile Station%'"
HYPOTHESIS hyp1_3_5 : BIKESHARE_TRIPS "NOT \"end_station_name\" ILIKE '%Repair Shop%'"
theorem eq_1_3 (t : TableRel BIKESHARE_TRIPS_schema) (h0 : hyp1_3_0 t) (h1 : hyp1_3_1 t) (h2 : hyp1_3_2 t) (h3 : hyp1_3_3 t) (h4 : hyp1_3_4 t) (h5 : hyp1_3_5 t) :
    (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(ride_count) AS OUTPUT FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS ride_date, COUNT(*) AS ride_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"subscriber_type\" = 'Student Membership' AND \"duration_minutes\" > 10 AND NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop') AND NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop') GROUP BY ride_date) AS daily_counts") t = (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS OUTPUT FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS trip_date, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"duration_minutes\" > 10 AND \"subscriber_type\" = 'Student Membership' AND NOT \"start_station_name\" ILIKE '%Mobile Station%' AND NOT \"start_station_name\" ILIKE '%Repair Shop%' AND NOT \"end_station_name\" ILIKE '%Mobile Station%' AND NOT \"end_station_name\" ILIKE '%Repair Shop%' GROUP BY trip_date) AS sub") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : BIKESHARE_TRIPS "NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop')"
HYPOTHESIS hyp2_3_1 : BIKESHARE_TRIPS "NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop')"
HYPOTHESIS hyp2_3_2 : BIKESHARE_TRIPS "NOT \"start_station_name\" ILIKE '%Mobile Station%'"
HYPOTHESIS hyp2_3_3 : BIKESHARE_TRIPS "NOT \"start_station_name\" ILIKE '%Repair Shop%'"
HYPOTHESIS hyp2_3_4 : BIKESHARE_TRIPS "NOT \"end_station_name\" ILIKE '%Mobile Station%'"
HYPOTHESIS hyp2_3_5 : BIKESHARE_TRIPS "NOT \"end_station_name\" ILIKE '%Repair Shop%'"
theorem eq_2_3 (t : TableRel BIKESHARE_TRIPS_schema) (h0 : hyp2_3_0 t) (h1 : hyp2_3_1 t) (h2 : hyp2_3_2 t) (h3 : hyp2_3_3 t) (h4 : hyp2_3_4 t) (h5 : hyp2_3_5 t) :
    (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS \"OUTPUT\" FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS ride_date, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"subscriber_type\" = 'Student Membership' AND \"bike_type\" = 'electric' AND \"duration_minutes\" > 10 AND NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop') AND NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop') GROUP BY ride_date) AS daily_rides") t = (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS OUTPUT FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS trip_date, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"duration_minutes\" > 10 AND \"subscriber_type\" = 'Student Membership' AND NOT \"start_station_name\" ILIKE '%Mobile Station%' AND NOT \"start_station_name\" ILIKE '%Repair Shop%' AND NOT \"end_station_name\" ILIKE '%Mobile Station%' AND NOT \"end_station_name\" ILIKE '%Repair Shop%' GROUP BY trip_date) AS sub") t := by
  first | sql_equiv | sorry

end Bench_sf_bq281
