import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq186_eq_1_2

CREATE TABLE BIKESHARE_TRIPS («trip_id» INT, «duration_sec» INT, «start_date» INT, «start_station_name» STRING, «start_station_id» INT, «end_date» INT, «end_station_name» STRING, «end_station_id» INT, «bike_number» INT, «zip_code» STRING, «subscriber_type» STRING)

theorem eq (t0 : TableRel BIKESHARE_TRIPS_schema) :
    (sql%([BIKESHARE_TRIPS_schema]) "WITH base AS (SELECT TO_CHAR(TO_TIMESTAMP(CAST(\"start_date\" AS DOUBLE PRECISION) / 1000000), 'YYYYMM') AS YEAR_MONTH, \"start_date\", CAST(\"duration_sec\" AS DOUBLE PRECISION) / 60.0 AS duration_minutes FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\"), ranked AS (SELECT YEAR_MONTH, duration_minutes, ROW_NUMBER() OVER (PARTITION BY YEAR_MONTH ORDER BY \"start_date\" ASC, duration_minutes DESC) AS rn_first, ROW_NUMBER() OVER (PARTITION BY YEAR_MONTH ORDER BY \"start_date\" DESC, duration_minutes ASC) AS rn_last FROM base) SELECT MAX(CASE WHEN rn_first = 1 THEN duration_minutes END) AS FIRST_TRIP_DURATION_MINUTES, MAX(CASE WHEN rn_last = 1 THEN duration_minutes END) AS LAST_TRIP_DURATION_MINUTES, MAX(duration_minutes) AS HIGHEST_TRIP_DURATION_MINUTES, MIN(duration_minutes) AS LOWEST_TRIP_DURATION_MINUTES, YEAR_MONTH FROM ranked GROUP BY YEAR_MONTH ORDER BY YEAR_MONTH") t0
  ~= (sql%([BIKESHARE_TRIPS_schema]) "WITH trips AS (SELECT TO_CHAR(TO_TIMESTAMP(CAST(\"start_date\" AS DOUBLE PRECISION) / 1000000), 'YYYYMM') AS YEAR_MONTH, CAST(\"duration_sec\" AS DOUBLE PRECISION) / 60.0 AS duration_minutes, \"start_date\", \"trip_id\", ROW_NUMBER() OVER (PARTITION BY TO_CHAR(TO_TIMESTAMP(CAST(\"start_date\" AS DOUBLE PRECISION) / 1000000), 'YYYYMM') ORDER BY \"start_date\" ASC, \"trip_id\" ASC) AS rn_asc, ROW_NUMBER() OVER (PARTITION BY TO_CHAR(TO_TIMESTAMP(CAST(\"start_date\" AS DOUBLE PRECISION) / 1000000), 'YYYYMM') ORDER BY \"start_date\" DESC, \"trip_id\" DESC) AS rn_desc FROM \"SAN_FRANCISCO\".\"SAN_FRANCISCO\".\"BIKESHARE_TRIPS\"), first_last AS (SELECT YEAR_MONTH, MAX(CASE WHEN rn_asc = 1 THEN duration_minutes END) AS FIRST_TRIP_DURATION_MINUTES, MAX(CASE WHEN rn_desc = 1 THEN duration_minutes END) AS LAST_TRIP_DURATION_MINUTES, MAX(duration_minutes) AS HIGHEST_TRIP_DURATION_MINUTES, MIN(duration_minutes) AS LOWEST_TRIP_DURATION_MINUTES FROM trips GROUP BY YEAR_MONTH) SELECT FIRST_TRIP_DURATION_MINUTES, LAST_TRIP_DURATION_MINUTES, HIGHEST_TRIP_DURATION_MINUTES, LOWEST_TRIP_DURATION_MINUTES, YEAR_MONTH FROM first_last ORDER BY YEAR_MONTH") t0
  := by first | sql_equiv | sorry

end N_sf_bq186_eq_1_2
