import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq035 — crossskill equivalence(s)

Question: What is the total distance traveled by each bike in the San Francisco Bikeshare program, measured in meters? Use data from bikeshare trips and stations to calculate this.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq035

CREATE TABLE BIKESHARE_STATIONS («station_id» INT, «name» STRING, «latitude» FLOAT, «longitude» FLOAT, «dockcount» INT, «landmark» STRING, «installation_date» STRING)
CREATE TABLE BIKESHARE_TRIPS («trip_id» INT, «duration_sec» INT, «start_date» INT, «start_station_name» STRING, «start_station_id» INT, «end_date» INT, «end_station_name» STRING, «end_station_id» INT, «bike_number» INT, «zip_code» STRING, «subscriber_type» STRING)

theorem eq_0_1 : ∀ t,
    (sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "SELECT t.\"bike_number\" AS BIKE_NUMBER, ROUND(CAST(AVG(ST_DISTANCE(ST_POINT(s1.\"longitude\", s1.\"latitude\"), ST_POINT(s2.\"longitude\", s2.\"latitude\"))) AS DECIMAL), 2) AS AVG_DIST_M, ROUND(SUM(ST_DISTANCE(ST_POINT(s1.\"longitude\", s1.\"latitude\"), ST_POINT(s2.\"longitude\", s2.\"latitude\"))), 2) AS TOTAL_DIST_M FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" AS t JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s1 ON t.\"start_station_id\" = s1.\"station_id\" JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s2 ON t.\"end_station_id\" = s2.\"station_id\" GROUP BY t.\"bike_number\" ORDER BY TOTAL_DIST_M DESC") t ~= (sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "WITH trip_distances AS (SELECT t.\"bike_number\", ST_DISTANCE(ST_POINT(s_start.\"longitude\", s_start.\"latitude\"), ST_POINT(s_end.\"longitude\", s_end.\"latitude\")) AS dist_m FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" AS t JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s_start ON t.\"start_station_id\" = s_start.\"station_id\" JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s_end ON t.\"end_station_id\" = s_end.\"station_id\") SELECT \"bike_number\" AS \"BIKE_NUMBER\", AVG(dist_m) AS \"AVG_DIST_M\", SUM(dist_m) AS \"TOTAL_DIST_M\" FROM trip_distances GROUP BY \"bike_number\" ORDER BY \"TOTAL_DIST_M\" DESC") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "SELECT t.\"bike_number\" AS BIKE_NUMBER, ROUND(CAST(AVG(ST_DISTANCE(ST_POINT(s1.\"longitude\", s1.\"latitude\"), ST_POINT(s2.\"longitude\", s2.\"latitude\"))) AS DECIMAL), 2) AS AVG_DIST_M, ROUND(SUM(ST_DISTANCE(ST_POINT(s1.\"longitude\", s1.\"latitude\"), ST_POINT(s2.\"longitude\", s2.\"latitude\"))), 2) AS TOTAL_DIST_M FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" AS t JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s1 ON t.\"start_station_id\" = s1.\"station_id\" JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s2 ON t.\"end_station_id\" = s2.\"station_id\" GROUP BY t.\"bike_number\" ORDER BY TOTAL_DIST_M DESC") t ~= (sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "WITH trip_distances AS (SELECT t.\"bike_number\" AS BIKE_NUMBER, ST_DISTANCE(ST_POINT(s1.\"longitude\", s1.\"latitude\"), ST_POINT(s2.\"longitude\", s2.\"latitude\")) AS dist_m FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" AS t JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s1 ON t.\"start_station_id\" = s1.\"station_id\" JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s2 ON t.\"end_station_id\" = s2.\"station_id\") SELECT BIKE_NUMBER, ROUND(CAST(AVG(dist_m) AS DECIMAL), 2) AS AVG_DIST_M, ROUND(SUM(dist_m), 2) AS TOTAL_DIST_M FROM trip_distances GROUP BY BIKE_NUMBER ORDER BY TOTAL_DIST_M DESC") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "WITH trip_distances AS (SELECT t.\"bike_number\", ST_DISTANCE(ST_POINT(s_start.\"longitude\", s_start.\"latitude\"), ST_POINT(s_end.\"longitude\", s_end.\"latitude\")) AS dist_m FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" AS t JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s_start ON t.\"start_station_id\" = s_start.\"station_id\" JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s_end ON t.\"end_station_id\" = s_end.\"station_id\") SELECT \"bike_number\" AS \"BIKE_NUMBER\", AVG(dist_m) AS \"AVG_DIST_M\", SUM(dist_m) AS \"TOTAL_DIST_M\" FROM trip_distances GROUP BY \"bike_number\" ORDER BY \"TOTAL_DIST_M\" DESC" = sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "WITH trip_distances AS (SELECT t.\"bike_number\" AS BIKE_NUMBER, ST_DISTANCE(ST_POINT(s1.\"longitude\", s1.\"latitude\"), ST_POINT(s2.\"longitude\", s2.\"latitude\")) AS dist_m FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" AS t JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s1 ON t.\"start_station_id\" = s1.\"station_id\" JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" AS s2 ON t.\"end_station_id\" = s2.\"station_id\") SELECT BIKE_NUMBER, ROUND(CAST(AVG(dist_m) AS DECIMAL), 2) AS AVG_DIST_M, ROUND(SUM(dist_m), 2) AS TOTAL_DIST_M FROM trip_distances GROUP BY BIKE_NUMBER ORDER BY TOTAL_DIST_M DESC" := by
  first | sql_equiv | sorry

end Bench_sf_bq035
