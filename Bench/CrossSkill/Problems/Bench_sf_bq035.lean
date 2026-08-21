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
    (sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "SELECT\n  t.\"bike_number\" AS BIKE_NUMBER,\n  ROUND(AVG(ST_DISTANCE(\n    ST_MAKEPOINT(s1.\"longitude\", s1.\"latitude\"),\n    ST_MAKEPOINT(s2.\"longitude\", s2.\"latitude\")\n  )), 2) AS AVG_DIST_M,\n  ROUND(SUM(ST_DISTANCE(\n    ST_MAKEPOINT(s1.\"longitude\", s1.\"latitude\"),\n    ST_MAKEPOINT(s2.\"longitude\", s2.\"latitude\")\n  )), 2) AS TOTAL_DIST_M\nFROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" t\nJOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s1\n  ON t.\"start_station_id\" = s1.\"station_id\"\nJOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s2\n  ON t.\"end_station_id\" = s2.\"station_id\"\nGROUP BY t.\"bike_number\"\nORDER BY TOTAL_DIST_M DESC;") t ~= (sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "WITH trip_distances AS (\n  SELECT\n    t.\"bike_number\",\n    ST_DISTANCE(\n      ST_MAKEPOINT(s_start.\"longitude\", s_start.\"latitude\"),\n      ST_MAKEPOINT(s_end.\"longitude\", s_end.\"latitude\")\n    ) AS dist_m\n  FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" t\n  JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s_start\n    ON t.\"start_station_id\" = s_start.\"station_id\"\n  JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s_end\n    ON t.\"end_station_id\" = s_end.\"station_id\"\n)\nSELECT\n  \"bike_number\" AS \"BIKE_NUMBER\",\n  AVG(dist_m) AS \"AVG_DIST_M\",\n  SUM(dist_m) AS \"TOTAL_DIST_M\"\nFROM trip_distances\nGROUP BY \"bike_number\"\nORDER BY \"TOTAL_DIST_M\" DESC;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "SELECT\n  t.\"bike_number\" AS BIKE_NUMBER,\n  ROUND(AVG(ST_DISTANCE(\n    ST_MAKEPOINT(s1.\"longitude\", s1.\"latitude\"),\n    ST_MAKEPOINT(s2.\"longitude\", s2.\"latitude\")\n  )), 2) AS AVG_DIST_M,\n  ROUND(SUM(ST_DISTANCE(\n    ST_MAKEPOINT(s1.\"longitude\", s1.\"latitude\"),\n    ST_MAKEPOINT(s2.\"longitude\", s2.\"latitude\")\n  )), 2) AS TOTAL_DIST_M\nFROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" t\nJOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s1\n  ON t.\"start_station_id\" = s1.\"station_id\"\nJOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s2\n  ON t.\"end_station_id\" = s2.\"station_id\"\nGROUP BY t.\"bike_number\"\nORDER BY TOTAL_DIST_M DESC;") t ~= (sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "WITH trip_distances AS (\n    SELECT\n        t.\"bike_number\" AS BIKE_NUMBER,\n        ST_DISTANCE(\n            ST_MAKEPOINT(s1.\"longitude\", s1.\"latitude\"),\n            ST_MAKEPOINT(s2.\"longitude\", s2.\"latitude\")\n        ) AS dist_m\n    FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" t\n    JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s1\n        ON t.\"start_station_id\" = s1.\"station_id\"\n    JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s2\n        ON t.\"end_station_id\" = s2.\"station_id\"\n)\nSELECT\n    BIKE_NUMBER,\n    ROUND(AVG(dist_m), 2) AS AVG_DIST_M,\n    ROUND(SUM(dist_m), 2) AS TOTAL_DIST_M\nFROM trip_distances\nGROUP BY BIKE_NUMBER\nORDER BY TOTAL_DIST_M DESC;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "WITH trip_distances AS (\n  SELECT\n    t.\"bike_number\",\n    ST_DISTANCE(\n      ST_MAKEPOINT(s_start.\"longitude\", s_start.\"latitude\"),\n      ST_MAKEPOINT(s_end.\"longitude\", s_end.\"latitude\")\n    ) AS dist_m\n  FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" t\n  JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s_start\n    ON t.\"start_station_id\" = s_start.\"station_id\"\n  JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s_end\n    ON t.\"end_station_id\" = s_end.\"station_id\"\n)\nSELECT\n  \"bike_number\" AS \"BIKE_NUMBER\",\n  AVG(dist_m) AS \"AVG_DIST_M\",\n  SUM(dist_m) AS \"TOTAL_DIST_M\"\nFROM trip_distances\nGROUP BY \"bike_number\"\nORDER BY \"TOTAL_DIST_M\" DESC;" = sql%([BIKESHARE_STATIONS_schema, BIKESHARE_TRIPS_schema]) "WITH trip_distances AS (\n    SELECT\n        t.\"bike_number\" AS BIKE_NUMBER,\n        ST_DISTANCE(\n            ST_MAKEPOINT(s1.\"longitude\", s1.\"latitude\"),\n            ST_MAKEPOINT(s2.\"longitude\", s2.\"latitude\")\n        ) AS dist_m\n    FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\" t\n    JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s1\n        ON t.\"start_station_id\" = s1.\"station_id\"\n    JOIN \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_STATIONS\" s2\n        ON t.\"end_station_id\" = s2.\"station_id\"\n)\nSELECT\n    BIKE_NUMBER,\n    ROUND(AVG(dist_m), 2) AS AVG_DIST_M,\n    ROUND(SUM(dist_m), 2) AS TOTAL_DIST_M\nFROM trip_distances\nGROUP BY BIKE_NUMBER\nORDER BY TOTAL_DIST_M DESC;" := by
  first | sql_equiv | sorry

end Bench_sf_bq035
