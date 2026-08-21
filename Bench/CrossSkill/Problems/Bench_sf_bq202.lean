import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq202 — crossskill equivalence(s)

Question: For the station that had the highest number of Citibike trips starting there in 2018, which numeric day of the week and which hour of the day had the greatest number of trips based on the start time of those trips?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq202

CREATE TABLE CITIBIKE_TRIPS («tripduration» INT, «starttime» INT, «stoptime» INT, «start_station_id» INT, «start_station_name» STRING, «start_station_latitude» FLOAT, «start_station_longitude» FLOAT, «end_station_id» INT, «end_station_name» STRING, «end_station_latitude» FLOAT, «end_station_longitude» FLOAT, «bikeid» INT, «usertype» STRING, «birth_year» INT, «gender» STRING, «customer_plan» STRING)
CREATE TABLE TRIPS («route_id» STRING, «service_id» STRING, «trip_id» STRING, «trip_headsign» STRING, «direction_id» STRING, «block_id» STRING, «shape_id» STRING)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 : ∀ t,
    (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "WITH trips_2018 AS (\n    SELECT \n        \"start_station_id\",\n        TO_TIMESTAMP(\"starttime\" / 1000000) AS start_ts\n    FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\n    WHERE \"starttime\" IS NOT NULL\n      AND EXTRACT(YEAR FROM TO_TIMESTAMP(\"starttime\" / 1000000)) = 2018\n),\ntop_station AS (\n    SELECT \"start_station_id\"\n    FROM trips_2018\n    GROUP BY \"start_station_id\"\n    ORDER BY COUNT(*) DESC\n    LIMIT 1\n),\nstation_trips AS (\n    SELECT \n        DAYOFWEEK(t.start_ts) AS DAY_OF_WEEK,\n        EXTRACT(HOUR FROM t.start_ts) AS HOUR_OF_DAY,\n        COUNT(*) AS TRIP_COUNT\n    FROM trips_2018 t\n    JOIN top_station ts ON t.\"start_station_id\" = ts.\"start_station_id\"\n    GROUP BY DAY_OF_WEEK, HOUR_OF_DAY\n)\nSELECT DAY_OF_WEEK, HOUR_OF_DAY, TRIP_COUNT\nFROM station_trips\nORDER BY TRIP_COUNT DESC\nLIMIT 1;") t ~= (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "WITH top_station AS (\n  SELECT \"start_station_name\"\n  FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\n  WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(\"starttime\"/1000000)) = 2018\n    AND \"start_station_name\" IS NOT NULL\n  GROUP BY \"start_station_name\"\n  ORDER BY COUNT(*) DESC\n  LIMIT 1\n)\nSELECT DAYOFWEEK(TO_TIMESTAMP(\"starttime\"/1000000)) AS DAY_OF_WEEK,\n       EXTRACT(HOUR FROM TO_TIMESTAMP(\"starttime\"/1000000)) AS HOUR_OF_DAY,\n       COUNT(*) AS TRIP_COUNT\nFROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\nWHERE \"start_station_name\" = (SELECT \"start_station_name\" FROM top_station)\n  AND EXTRACT(YEAR FROM TO_TIMESTAMP(\"starttime\"/1000000)) = 2018\nGROUP BY DAY_OF_WEEK, HOUR_OF_DAY\nORDER BY TRIP_COUNT DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 : ∀ t,
    (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "WITH trips_2018 AS (\n    SELECT \n        \"start_station_id\",\n        TO_TIMESTAMP(\"starttime\" / 1000000) AS start_ts\n    FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\n    WHERE \"starttime\" IS NOT NULL\n      AND EXTRACT(YEAR FROM TO_TIMESTAMP(\"starttime\" / 1000000)) = 2018\n),\ntop_station AS (\n    SELECT \"start_station_id\"\n    FROM trips_2018\n    GROUP BY \"start_station_id\"\n    ORDER BY COUNT(*) DESC\n    LIMIT 1\n),\nstation_trips AS (\n    SELECT \n        DAYOFWEEK(t.start_ts) AS DAY_OF_WEEK,\n        EXTRACT(HOUR FROM t.start_ts) AS HOUR_OF_DAY,\n        COUNT(*) AS TRIP_COUNT\n    FROM trips_2018 t\n    JOIN top_station ts ON t.\"start_station_id\" = ts.\"start_station_id\"\n    GROUP BY DAY_OF_WEEK, HOUR_OF_DAY\n)\nSELECT DAY_OF_WEEK, HOUR_OF_DAY, TRIP_COUNT\nFROM station_trips\nORDER BY TRIP_COUNT DESC\nLIMIT 1;") t ~= (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "-- Find the station with the most trips starting in 2018,\n-- then for that station find the day of week and hour of day with the most trips.\n-- Day of week uses BigQuery convention: 1=Sunday, 2=Monday, ..., 7=Saturday\nWITH top_station AS (\n  SELECT \"start_station_id\"\n  FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\n  WHERE YEAR(TO_TIMESTAMP(\"starttime\" / 1000000)) = 2018\n  GROUP BY \"start_station_id\"\n  ORDER BY COUNT(*) DESC\n  LIMIT 1\n)\nSELECT\n  DAYOFWEEK(TO_TIMESTAMP(\"starttime\" / 1000000)) AS \"DAY_OF_WEEK\",\n  HOUR(TO_TIMESTAMP(\"starttime\" / 1000000)) AS \"HOUR_OF_DAY\",\n  COUNT(*) AS \"TRIP_COUNT\"\nFROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\nWHERE YEAR(TO_TIMESTAMP(\"starttime\" / 1000000)) = 2018\n  AND \"start_station_id\" = (SELECT \"start_station_id\" FROM top_station)\nGROUP BY \"DAY_OF_WEEK\", \"HOUR_OF_DAY\"\nORDER BY \"TRIP_COUNT\" DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 : ∀ t,
    (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "WITH top_station AS (\n  SELECT \"start_station_name\"\n  FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\n  WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(\"starttime\"/1000000)) = 2018\n    AND \"start_station_name\" IS NOT NULL\n  GROUP BY \"start_station_name\"\n  ORDER BY COUNT(*) DESC\n  LIMIT 1\n)\nSELECT DAYOFWEEK(TO_TIMESTAMP(\"starttime\"/1000000)) AS DAY_OF_WEEK,\n       EXTRACT(HOUR FROM TO_TIMESTAMP(\"starttime\"/1000000)) AS HOUR_OF_DAY,\n       COUNT(*) AS TRIP_COUNT\nFROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\nWHERE \"start_station_name\" = (SELECT \"start_station_name\" FROM top_station)\n  AND EXTRACT(YEAR FROM TO_TIMESTAMP(\"starttime\"/1000000)) = 2018\nGROUP BY DAY_OF_WEEK, HOUR_OF_DAY\nORDER BY TRIP_COUNT DESC\nLIMIT 1;") t ~= (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "-- Find the station with the most trips starting in 2018,\n-- then for that station find the day of week and hour of day with the most trips.\n-- Day of week uses BigQuery convention: 1=Sunday, 2=Monday, ..., 7=Saturday\nWITH top_station AS (\n  SELECT \"start_station_id\"\n  FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\n  WHERE YEAR(TO_TIMESTAMP(\"starttime\" / 1000000)) = 2018\n  GROUP BY \"start_station_id\"\n  ORDER BY COUNT(*) DESC\n  LIMIT 1\n)\nSELECT\n  DAYOFWEEK(TO_TIMESTAMP(\"starttime\" / 1000000)) AS \"DAY_OF_WEEK\",\n  HOUR(TO_TIMESTAMP(\"starttime\" / 1000000)) AS \"HOUR_OF_DAY\",\n  COUNT(*) AS \"TRIP_COUNT\"\nFROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\"\nWHERE YEAR(TO_TIMESTAMP(\"starttime\" / 1000000)) = 2018\n  AND \"start_station_id\" = (SELECT \"start_station_id\" FROM top_station)\nGROUP BY \"DAY_OF_WEEK\", \"HOUR_OF_DAY\"\nORDER BY \"TRIP_COUNT\" DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq202
