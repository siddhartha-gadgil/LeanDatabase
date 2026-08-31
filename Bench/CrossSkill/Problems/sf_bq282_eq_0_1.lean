import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq282_eq_0_1

CREATE TABLE BIKESHARE_TRIPS («trip_id» STRING, «subscriber_type» STRING, «bike_id» STRING, «bike_type» STRING, «start_time» INT, «start_station_id» INT, «start_station_name» STRING, «end_station_id» STRING, «end_station_name» STRING, «duration_minutes» INT)
CREATE TABLE BIKESHARE_STATIONS («station_id» INT, «name» STRING, «status» STRING, «location» STRING, «address» STRING, «alternate_name» STRING, «city_asset_number» INT, «property_type» STRING, «number_of_docks» INT, «power_type» STRING, «footprint_length» INT, «footprint_width» FLOAT, «notes» STRING, «council_district» INT, «image» STRING, «modified_date» INT)

theorem eq (t0 : TableRel BIKESHARE_TRIPS_schema) (t1 : TableRel BIKESHARE_STATIONS_schema) :
    (sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT s1.\"council_district\" AS output FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" AS t JOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" AS s1 ON CAST(t.\"start_station_id\" AS INT) = s1.\"station_id\" JOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" AS s2 ON CAST(t.\"end_station_id\" AS INT) = s2.\"station_id\" WHERE s1.\"status\" = 'active' AND s2.\"status\" = 'active' AND s1.\"council_district\" = s2.\"council_district\" AND t.\"start_station_id\" <> t.\"end_station_id\" GROUP BY s1.\"council_district\" ORDER BY COUNT(*) DESC LIMIT 1") t0 t1
  = (sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT s1.\"council_district\" AS output FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" AS t JOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" AS s1 ON CAST(t.\"start_station_id\" AS INT) = s1.\"station_id\" JOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" AS s2 ON CAST(t.\"end_station_id\" AS INT) = s2.\"station_id\" WHERE s1.\"council_district\" = s2.\"council_district\" AND t.\"start_station_id\" <> t.\"end_station_id\" AND s1.\"status\" = 'active' AND s2.\"status\" = 'active' GROUP BY s1.\"council_district\" ORDER BY COUNT(*) DESC LIMIT 1") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq282_eq_0_1
