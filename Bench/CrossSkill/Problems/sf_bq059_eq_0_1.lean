import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq059_eq_0_1

CREATE TABLE BIKESHARE_STATION_INFO («station_id» STRING, «name» STRING, «short_name» STRING, «lat» FLOAT, «lon» FLOAT, «region_id» INT, «rental_methods» STRING, «capacity» INT, «external_id» STRING, «eightd_has_key_dispenser» BOOL, «has_kiosk» BOOL, «station_geom» STRING)
CREATE TABLE BIKESHARE_TRIPS («trip_id» STRING, «duration_sec» INT, «start_date» INT, «start_station_name» STRING, «start_station_id» INT, «end_date» INT, «end_station_name» STRING, «end_station_id» INT, «bike_number» INT, «zip_code» STRING, «subscriber_type» STRING, «c_subscription_type» STRING, «start_station_latitude» FLOAT, «start_station_longitude» FLOAT, «end_station_latitude» FLOAT, «end_station_longitude» FLOAT, «member_birth_year» INT, «member_gender» STRING, «bike_share_for_all_trip» STRING, «start_station_geom» STRING, «end_station_geom» STRING)

theorem eq (t0 : TableRel BIKESHARE_STATION_INFO_schema) (t1 : TableRel BIKESHARE_TRIPS_schema) :
    (sql%([BIKESHARE_STATION_INFO_schema, BIKESHARE_TRIPS_schema]) "SELECT ROUND(MAX(CAST(HAVERSINE(\"start_station_latitude\", \"start_station_longitude\", \"end_station_latitude\", \"end_station_longitude\") * 1000 AS DOUBLE PRECISION) / \"duration_sec\"), 1) AS \"MAX_VELOCITY\" FROM \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_BIKESHARE\".\"BIKESHARE_TRIPS\" AS t JOIN \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_BIKESHARE\".\"BIKESHARE_STATION_INFO\" AS s ON t.\"start_station_id\" = CAST(s.\"station_id\" AS INT) WHERE s.\"region_id\" = 14 AND HAVERSINE(\"start_station_latitude\", \"start_station_longitude\", \"end_station_latitude\", \"end_station_longitude\") * 1000 > 1000 AND \"duration_sec\" > 0") t0 t1
  ~= (sql%([BIKESHARE_STATION_INFO_schema, BIKESHARE_TRIPS_schema]) "WITH berkeley_trips AS (SELECT t.\"trip_id\", t.\"duration_sec\", t.\"start_station_latitude\" AS lat1, t.\"start_station_longitude\" AS lon1, t.\"end_station_latitude\" AS lat2, t.\"end_station_longitude\" AS lon2 FROM \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_BIKESHARE\".\"BIKESHARE_TRIPS\" AS t JOIN \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_BIKESHARE\".\"BIKESHARE_STATION_INFO\" AS s1 ON t.\"start_station_id\" = s1.\"station_id\" JOIN \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_BIKESHARE\".\"BIKESHARE_STATION_INFO\" AS s2 ON t.\"end_station_id\" = s2.\"station_id\" WHERE s1.\"region_id\" = 14 AND s2.\"region_id\" = 14 AND NOT t.\"start_station_latitude\" IS NULL AND NOT t.\"end_station_latitude\" IS NULL AND t.\"duration_sec\" > 0), with_distance AS (SELECT *, 2 * 6371000 * ASIN(SQRT(POWER(SIN(CAST(RADIANS(lat2 - lat1) AS DOUBLE PRECISION) / 2), 2) + COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * POWER(SIN(CAST(RADIANS(lon2 - lon1) AS DOUBLE PRECISION) / 2), 2))) AS distance_m FROM berkeley_trips) SELECT ROUND(MAX(CAST(distance_m AS DOUBLE PRECISION) / \"duration_sec\"), 1) AS MAX_VELOCITY FROM with_distance WHERE distance_m > 1000") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq059_eq_0_1
