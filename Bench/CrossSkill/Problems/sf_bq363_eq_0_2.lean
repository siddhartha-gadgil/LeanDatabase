import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq363_eq_0_2

CREATE TABLE TAXI_TRIPS («unique_key» STRING, «taxi_id» STRING, «trip_start_timestamp» INT, «trip_end_timestamp» INT, «trip_seconds» INT, «trip_miles» FLOAT, «pickup_census_tract» INT, «dropoff_census_tract» INT, «pickup_community_area» INT, «dropoff_community_area» INT, «fare» FLOAT, «tips» FLOAT, «tolls» FLOAT, «extras» FLOAT, «trip_total» FLOAT, «payment_type» STRING, «company» STRING, «pickup_latitude» FLOAT, «pickup_longitude» FLOAT, «pickup_location» STRING, «dropoff_latitude» FLOAT, «dropoff_longitude» FLOAT, «dropoff_location» STRING)

theorem eq (t0 : TableRel TAXI_TRIPS_schema) :
    (sql%([TAXI_TRIPS_schema]) "WITH duration_minutes AS (SELECT DISTINCT FLOOR(CAST(\"trip_seconds\" AS DOUBLE PRECISION) / 60.0) AS trip_min FROM \"CHICAGO\".\"CHICAGO_TAXI_TRIPS\".\"TAXI_TRIPS\" WHERE FLOOR(CAST(\"trip_seconds\" AS DOUBLE PRECISION) / 60.0) BETWEEN 1 AND 50), ntiled AS (SELECT trip_min, NTILE(10) OVER (ORDER BY trip_min) AS quantile_group FROM duration_minutes), groups AS (SELECT quantile_group, MIN(trip_min) AS min_min, MAX(trip_min) AS max_min FROM ntiled GROUP BY quantile_group) SELECT LPAD(CAST(CAST(g.min_min AS INT) AS VARCHAR), 2, '0') || 'm to ' || LPAD(CAST(CAST(g.max_min AS INT) AS VARCHAR), 2, '0') || 'm' AS TIME_RANGE, COUNT(*) AS TOTAL_TRIPS, ROUND(CAST(AVG(t.\"fare\") AS DECIMAL), 2) AS AVERAGE_FARE FROM \"CHICAGO\".\"CHICAGO_TAXI_TRIPS\".\"TAXI_TRIPS\" AS t JOIN groups AS g ON FLOOR(CAST(t.\"trip_seconds\" AS DOUBLE PRECISION) / 60.0) BETWEEN g.min_min AND g.max_min WHERE FLOOR(CAST(t.\"trip_seconds\" AS DOUBLE PRECISION) / 60.0) BETWEEN 1 AND 50 GROUP BY g.quantile_group, g.min_min, g.max_min ORDER BY TIME_RANGE") t0
  ~= (sql%([TAXI_TRIPS_schema]) "SELECT LPAD(CAST(MIN(trip_minutes) AS VARCHAR), 2, '0') || 'm to ' || LPAD(CAST(MAX(trip_minutes) AS VARCHAR), 2, '0') || 'm' AS \"TIME_RANGE\", COUNT(*) AS \"TOTAL_TRIPS\", ROUND(CAST(AVG(fare) AS DECIMAL), 2) AS \"AVERAGE_FARE\" FROM (SELECT FLOOR(CAST(\"trip_seconds\" AS DOUBLE PRECISION) / 60) AS trip_minutes, \"fare\" AS fare, CEIL(CAST(FLOOR(CAST(\"trip_seconds\" AS DOUBLE PRECISION) / 60) AS DOUBLE PRECISION) / 5) AS quantile FROM \"CHICAGO\".\"CHICAGO_TAXI_TRIPS\".\"TAXI_TRIPS\" WHERE FLOOR(CAST(\"trip_seconds\" AS DOUBLE PRECISION) / 60) BETWEEN 1 AND 50) GROUP BY quantile ORDER BY \"TIME_RANGE\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq363_eq_0_2
