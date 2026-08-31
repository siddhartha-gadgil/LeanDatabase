import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq281_eq_1_2

CREATE TABLE BIKESHARE_TRIPS («trip_id» STRING, «subscriber_type» STRING, «bike_id» STRING, «bike_type» STRING, «start_time» INT, «start_station_id» INT, «start_station_name» STRING, «end_station_id» STRING, «end_station_name» STRING, «duration_minutes» INT)

theorem eq (t0 : TableRel BIKESHARE_TRIPS_schema) :
    (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(ride_count) AS OUTPUT FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS ride_date, COUNT(*) AS ride_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"bike_type\" = 'electric' AND \"subscriber_type\" = 'Student Membership' AND \"duration_minutes\" > 10 AND NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop') AND NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop') GROUP BY ride_date) AS daily_counts") t0
  = (sql%([BIKESHARE_TRIPS_schema]) "SELECT MAX(daily_count) AS \"OUTPUT\" FROM (SELECT CAST(TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000) AS DATE) AS ride_date, COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE \"subscriber_type\" = 'Student Membership' AND \"bike_type\" = 'electric' AND \"duration_minutes\" > 10 AND NOT \"start_station_name\" IN ('Mobile Station', 'Repair Shop') AND NOT \"end_station_name\" IN ('Mobile Station', 'Repair Shop') GROUP BY ride_date) AS daily_rides") t0
  := by first | sql_equiv | sorry

end N_sf_bq281_eq_1_2
