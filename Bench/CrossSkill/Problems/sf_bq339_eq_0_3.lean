import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq339_eq_0_3

CREATE TABLE BIKESHARE_TRIPS («trip_id» STRING, «duration_sec» INT, «start_date» INT, «start_station_name» STRING, «start_station_id» INT, «end_date» INT, «end_station_name» STRING, «end_station_id» INT, «bike_number» INT, «zip_code» STRING, «subscriber_type» STRING, «c_subscription_type» STRING, «start_station_latitude» FLOAT, «start_station_longitude» FLOAT, «end_station_latitude» FLOAT, «end_station_longitude» FLOAT, «member_birth_year» INT, «member_gender» STRING, «bike_share_for_all_trip» STRING, «start_station_geom» STRING, «end_station_geom» STRING)

theorem eq (t0 : TableRel BIKESHARE_TRIPS_schema) :
    (sql%([BIKESHARE_TRIPS_schema]) "WITH monthly AS (SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"end_date\" AS DOUBLE PRECISION) / 1000000)) AS end_month, CAST(CAST(SUM(CASE WHEN \"subscriber_type\" = 'Customer' THEN \"duration_sec\" ELSE 0 END) AS DOUBLE PRECISION) / 60.0 AS DOUBLE PRECISION) / 1000.0 AS customer_minutes_k, CAST(CAST(SUM(CASE WHEN \"subscriber_type\" = 'Subscriber' THEN \"duration_sec\" ELSE 0 END) AS DOUBLE PRECISION) / 60.0 AS DOUBLE PRECISION) / 1000.0 AS subscriber_minutes_k FROM \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"end_date\" AS DOUBLE PRECISION) / 1000000)) = 2017 AND \"subscriber_type\" IN ('Customer', 'Subscriber') GROUP BY 1), cumulative AS (SELECT end_month, SUM(customer_minutes_k) OVER (ORDER BY end_month) AS cum_customer, SUM(subscriber_minutes_k) OVER (ORDER BY end_month) AS cum_subscriber FROM monthly) SELECT end_month AS END_MONTH FROM cumulative ORDER BY ABS(cum_customer - cum_subscriber) DESC LIMIT 1") t0
  = (sql%([BIKESHARE_TRIPS_schema]) "WITH monthly_usage AS (SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"end_date\" AS DOUBLE PRECISION) / 1000000)) AS end_month, \"subscriber_type\", CAST(SUM(\"duration_sec\") AS DOUBLE PRECISION) / 60.0 AS total_minutes FROM \"SAN_FRANCISCO_PLUS\".\"SAN_FRANCISCO_BIKESHARE\".\"BIKESHARE_TRIPS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"end_date\" AS DOUBLE PRECISION) / 1000000)) = 2017 AND \"subscriber_type\" IN ('Customer', 'Subscriber') GROUP BY end_month, \"subscriber_type\"), cumulative AS (SELECT end_month, \"subscriber_type\", SUM(total_minutes) OVER (PARTITION BY \"subscriber_type\" ORDER BY end_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_minutes FROM monthly_usage), pivoted AS (SELECT end_month, MAX(CASE WHEN \"subscriber_type\" = 'Customer' THEN cumulative_minutes ELSE 0 END) AS customer_cumulative, MAX(CASE WHEN \"subscriber_type\" = 'Subscriber' THEN cumulative_minutes ELSE 0 END) AS subscriber_cumulative FROM cumulative GROUP BY end_month) SELECT end_month AS END_MONTH FROM pivoted ORDER BY ABS(customer_cumulative - subscriber_cumulative) DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_bq339_eq_0_3
