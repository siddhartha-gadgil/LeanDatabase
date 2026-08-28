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
    (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "WITH trips_2018 AS (SELECT \"start_station_id\", TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000) AS start_ts FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE NOT \"starttime\" IS NULL AND EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018), top_station AS (SELECT \"start_station_id\" FROM trips_2018 GROUP BY \"start_station_id\" ORDER BY COUNT(*) DESC LIMIT 1), station_trips AS (SELECT DAY_OF_WEEK(t.start_ts) AS DAY_OF_WEEK, EXTRACT(HOUR FROM t.start_ts) AS HOUR_OF_DAY, COUNT(*) AS TRIP_COUNT FROM trips_2018 AS t JOIN top_station AS ts ON t.\"start_station_id\" = ts.\"start_station_id\" GROUP BY DAY_OF_WEEK, HOUR_OF_DAY) SELECT DAY_OF_WEEK, HOUR_OF_DAY, TRIP_COUNT FROM station_trips ORDER BY TRIP_COUNT DESC LIMIT 1") t ~= (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "WITH top_station AS (SELECT \"start_station_name\" FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018 AND NOT \"start_station_name\" IS NULL GROUP BY \"start_station_name\" ORDER BY COUNT(*) DESC LIMIT 1) SELECT DAY_OF_WEEK(TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) AS DAY_OF_WEEK, EXTRACT(HOUR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) AS HOUR_OF_DAY, COUNT(*) AS TRIP_COUNT FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE \"start_station_name\" = (SELECT \"start_station_name\" FROM top_station) AND EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018 GROUP BY DAY_OF_WEEK, HOUR_OF_DAY ORDER BY TRIP_COUNT DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 : ∀ t,
    (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "WITH trips_2018 AS (SELECT \"start_station_id\", TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000) AS start_ts FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE NOT \"starttime\" IS NULL AND EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018), top_station AS (SELECT \"start_station_id\" FROM trips_2018 GROUP BY \"start_station_id\" ORDER BY COUNT(*) DESC LIMIT 1), station_trips AS (SELECT DAY_OF_WEEK(t.start_ts) AS DAY_OF_WEEK, EXTRACT(HOUR FROM t.start_ts) AS HOUR_OF_DAY, COUNT(*) AS TRIP_COUNT FROM trips_2018 AS t JOIN top_station AS ts ON t.\"start_station_id\" = ts.\"start_station_id\" GROUP BY DAY_OF_WEEK, HOUR_OF_DAY) SELECT DAY_OF_WEEK, HOUR_OF_DAY, TRIP_COUNT FROM station_trips ORDER BY TRIP_COUNT DESC LIMIT 1") t ~= (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "/* Find the station with the most trips starting in 2018, */ /* then for that station find the day of week and hour of day with the most trips. */ /* Day of week uses BigQuery convention: 1=Sunday, 2=Monday, ..., 7=Saturday */ WITH top_station AS (SELECT \"start_station_id\" FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018 GROUP BY \"start_station_id\" ORDER BY COUNT(*) DESC LIMIT 1) SELECT DAY_OF_WEEK(TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) AS \"DAY_OF_WEEK\", HOUR(TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) AS \"HOUR_OF_DAY\", COUNT(*) AS \"TRIP_COUNT\" FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018 AND \"start_station_id\" = (SELECT \"start_station_id\" FROM top_station) GROUP BY \"DAY_OF_WEEK\", \"HOUR_OF_DAY\" ORDER BY \"TRIP_COUNT\" DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 : ∀ t,
    (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "WITH top_station AS (SELECT \"start_station_name\" FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018 AND NOT \"start_station_name\" IS NULL GROUP BY \"start_station_name\" ORDER BY COUNT(*) DESC LIMIT 1) SELECT DAY_OF_WEEK(TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) AS DAY_OF_WEEK, EXTRACT(HOUR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) AS HOUR_OF_DAY, COUNT(*) AS TRIP_COUNT FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE \"start_station_name\" = (SELECT \"start_station_name\" FROM top_station) AND EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018 GROUP BY DAY_OF_WEEK, HOUR_OF_DAY ORDER BY TRIP_COUNT DESC LIMIT 1") t ~= (sql%([CITIBIKE_TRIPS_schema, TRIPS_schema]) "/* Find the station with the most trips starting in 2018, */ /* then for that station find the day of week and hour of day with the most trips. */ /* Day of week uses BigQuery convention: 1=Sunday, 2=Monday, ..., 7=Saturday */ WITH top_station AS (SELECT \"start_station_id\" FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018 GROUP BY \"start_station_id\" ORDER BY COUNT(*) DESC LIMIT 1) SELECT DAY_OF_WEEK(TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) AS \"DAY_OF_WEEK\", HOUR(TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) AS \"HOUR_OF_DAY\", COUNT(*) AS \"TRIP_COUNT\" FROM \"NEW_YORK_PLUS\".\"NEW_YORK_CITIBIKE\".\"CITIBIKE_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"starttime\" AS DOUBLE PRECISION) / 1000000)) = 2018 AND \"start_station_id\" = (SELECT \"start_station_id\" FROM top_station) GROUP BY \"DAY_OF_WEEK\", \"HOUR_OF_DAY\" ORDER BY \"TRIP_COUNT\" DESC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq202
