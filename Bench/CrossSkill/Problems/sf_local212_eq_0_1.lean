import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local212_eq_0_1

CREATE TABLE DELIVERIES («delivery_id» INT, «delivery_order_id» INT, «driver_id» FLOAT, «delivery_distance_meters» FLOAT, «delivery_status» STRING)
CREATE TABLE ORDERS («order_id» INT, «store_id» INT, «channel_id» INT, «payment_order_id» INT, «delivery_order_id» INT, «order_status» STRING, «order_amount» FLOAT, «order_delivery_fee» FLOAT, «order_delivery_cost» FLOAT, «order_created_hour» INT, «order_created_minute» INT, «order_created_day» INT, «order_created_month» INT, «order_created_year» INT, «order_moment_created» STRING, «order_moment_accepted» STRING, «order_moment_ready» STRING, «order_moment_collected» STRING, «order_moment_in_expedition» STRING, «order_moment_delivering» STRING, «order_moment_delivered» STRING, «order_moment_finished» STRING, «order_metric_collected_time» FLOAT, «order_metric_paused_time» FLOAT, «order_metric_production_time» FLOAT, «order_metric_walking_time» FLOAT, «order_metric_expediton_speed_time» FLOAT, «order_metric_transit_time» FLOAT, «order_metric_cycle_time» FLOAT)
CREATE TABLE DRIVERS («driver_id» INT, «driver_modal» STRING, «driver_type» STRING)

theorem eq (t0 : TableRel DELIVERIES_schema) (t1 : TableRel ORDERS_schema) (t2 : TableRel DRIVERS_schema) :
    (sql%([DELIVERIES_schema, ORDERS_schema, DRIVERS_schema]) "WITH daily_counts AS (SELECT d.\"driver_id\", o.\"order_created_year\", o.\"order_created_month\", o.\"order_created_day\", COUNT(*) AS daily_deliveries FROM \"DELIVERY_CENTER\".\"DELIVERY_CENTER\".\"DELIVERIES\" AS d JOIN \"DELIVERY_CENTER\".\"DELIVERY_CENTER\".\"ORDERS\" AS o ON d.\"delivery_order_id\" = o.\"delivery_order_id\" WHERE NOT d.\"driver_id\" IS NULL GROUP BY d.\"driver_id\", o.\"order_created_year\", o.\"order_created_month\", o.\"order_created_day\"), avg_daily AS (SELECT \"driver_id\", AVG(daily_deliveries) AS AVG_DAILY_DELIVERIES FROM daily_counts GROUP BY \"driver_id\") SELECT a.\"driver_id\", dr.\"driver_modal\", dr.\"driver_type\", a.AVG_DAILY_DELIVERIES FROM avg_daily AS a JOIN \"DELIVERY_CENTER\".\"DELIVERY_CENTER\".\"DRIVERS\" AS dr ON a.\"driver_id\" = dr.\"driver_id\" ORDER BY a.AVG_DAILY_DELIVERIES DESC LIMIT 5") t0 t1 t2
  = (sql%([DELIVERIES_schema, ORDERS_schema, DRIVERS_schema]) "WITH daily_counts AS (SELECT d.\"driver_id\", o.\"order_created_year\", o.\"order_created_month\", o.\"order_created_day\", COUNT(*) AS daily_deliveries FROM \"DELIVERY_CENTER\".\"DELIVERY_CENTER\".\"DELIVERIES\" AS d JOIN \"DELIVERY_CENTER\".\"DELIVERY_CENTER\".\"ORDERS\" AS o ON d.\"delivery_order_id\" = o.\"order_id\" WHERE NOT d.\"driver_id\" IS NULL GROUP BY d.\"driver_id\", o.\"order_created_year\", o.\"order_created_month\", o.\"order_created_day\"), avg_daily AS (SELECT \"driver_id\", AVG(daily_deliveries) AS AVG_DAILY_DELIVERIES FROM daily_counts GROUP BY \"driver_id\" ORDER BY AVG_DAILY_DELIVERIES DESC LIMIT 5) SELECT a.\"driver_id\", dr.\"driver_modal\", dr.\"driver_type\", ROUND(a.AVG_DAILY_DELIVERIES, 6) AS AVG_DAILY_DELIVERIES FROM avg_daily AS a JOIN \"DELIVERY_CENTER\".\"DELIVERY_CENTER\".\"DRIVERS\" AS dr ON a.\"driver_id\" = dr.\"driver_id\" ORDER BY a.AVG_DAILY_DELIVERIES DESC") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local212_eq_0_1
