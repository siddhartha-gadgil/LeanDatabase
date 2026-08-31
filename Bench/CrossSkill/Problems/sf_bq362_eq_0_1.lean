import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq362_eq_0_1

CREATE TABLE TAXI_TRIPS («unique_key» STRING, «taxi_id» STRING, «trip_start_timestamp» INT, «trip_end_timestamp» INT, «trip_seconds» INT, «trip_miles» FLOAT, «pickup_census_tract» INT, «dropoff_census_tract» INT, «pickup_community_area» INT, «dropoff_community_area» INT, «fare» FLOAT, «tips» FLOAT, «tolls» FLOAT, «extras» FLOAT, «trip_total» FLOAT, «payment_type» STRING, «company» STRING, «pickup_latitude» FLOAT, «pickup_longitude» FLOAT, «pickup_location» STRING, «dropoff_latitude» FLOAT, «dropoff_longitude» FLOAT, «dropoff_location» STRING)

theorem eq (t0 : TableRel TAXI_TRIPS_schema) :
    (sql%([TAXI_TRIPS_schema]) "WITH monthly_counts AS (SELECT \"company\", EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"trip_start_timestamp\" AS DOUBLE PRECISION) / 1000000)) AS trip_month, COUNT(*) AS trip_count FROM \"CHICAGO\".\"CHICAGO_TAXI_TRIPS\".\"TAXI_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"trip_start_timestamp\" AS DOUBLE PRECISION) / 1000000)) = 2018 GROUP BY \"company\", trip_month), month_over_month AS (SELECT curr.\"company\", curr.trip_count - prev.trip_count AS trip_increase FROM monthly_counts AS curr JOIN monthly_counts AS prev ON curr.\"company\" = prev.\"company\" AND curr.trip_month = prev.trip_month + 1), company_max_increase AS (SELECT \"company\", MAX(trip_increase) AS max_increase FROM month_over_month GROUP BY \"company\") SELECT \"company\" AS \"COMPANY\" FROM company_max_increase ORDER BY max_increase DESC LIMIT 3") t0
  = (sql%([TAXI_TRIPS_schema]) "WITH monthly_trips AS (SELECT \"company\", EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"trip_start_timestamp\" AS DOUBLE PRECISION) / 1000000)) AS month, COUNT(*) AS trip_count FROM \"CHICAGO\".\"CHICAGO_TAXI_TRIPS\".\"TAXI_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"trip_start_timestamp\" AS DOUBLE PRECISION) / 1000000)) = 2018 GROUP BY \"company\", month), increases AS (SELECT cur.\"company\", cur.trip_count - prev.trip_count AS increase FROM monthly_trips AS cur JOIN monthly_trips AS prev ON cur.\"company\" = prev.\"company\" AND cur.month = prev.month + 1) SELECT \"company\" AS COMPANY FROM increases GROUP BY \"company\" ORDER BY MAX(increase) DESC LIMIT 3") t0
  := by first | sql_equiv | sorry

end N_sf_bq362_eq_0_1
