import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq279_eq_0_3

CREATE TABLE BIKESHARE_TRIPS («trip_id» STRING, «subscriber_type» STRING, «bike_id» STRING, «bike_type» STRING, «start_time» INT, «start_station_id» INT, «start_station_name» STRING, «end_station_id» STRING, «end_station_name» STRING, «duration_minutes» INT)
CREATE TABLE BIKESHARE_STATIONS («station_id» INT, «name» STRING, «status» STRING, «location» STRING, «address» STRING, «alternate_name» STRING, «city_asset_number» INT, «property_type» STRING, «number_of_docks» INT, «power_type» STRING, «footprint_length» INT, «footprint_width» FLOAT, «notes» STRING, «council_district» INT, «image» STRING, «modified_date» INT)

theorem eq (t0 : TableRel BIKESHARE_TRIPS_schema) (t1 : TableRel BIKESHARE_STATIONS_schema) :
    (sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(t.\"start_time\" AS DOUBLE PRECISION) / 1000000)) AS year, COUNT(DISTINCT CASE WHEN s.\"status\" = 'active' THEN t.\"start_station_id\" END) AS number_status_active, COUNT(DISTINCT CASE WHEN s.\"status\" = 'closed' THEN t.\"start_station_id\" END) AS number_status_closed FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" AS t JOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" AS s ON t.\"start_station_id\" = s.\"station_id\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(t.\"start_time\" AS DOUBLE PRECISION) / 1000000)) IN (2013, 2014) GROUP BY year ORDER BY year") t0 t1
  = (sql%([BIKESHARE_TRIPS_schema, BIKESHARE_STATIONS_schema]) "SELECT EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000)) AS year, COUNT(DISTINCT CASE WHEN s.\"status\" = 'active' THEN t.\"start_station_id\" END) AS number_status_active, COUNT(DISTINCT CASE WHEN s.\"status\" = 'closed' THEN t.\"start_station_id\" END) AS number_status_closed FROM \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_TRIPS\" AS t JOIN \"AUSTIN\".\"AUSTIN_BIKESHARE\".\"BIKESHARE_STATIONS\" AS s ON t.\"start_station_id\" = s.\"station_id\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"start_time\" AS DOUBLE PRECISION) / 1000000)) IN (2013, 2014) GROUP BY year ORDER BY year") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq279_eq_0_3
