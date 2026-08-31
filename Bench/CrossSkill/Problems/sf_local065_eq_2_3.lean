import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local065_eq_2_3

CREATE TABLE PIZZA_CLEAN_RUNNER_ORDERS («order_id» INT, «runner_id» INT, «pickup_time» STRING, «distance» FLOAT, «duration» FLOAT, «cancellation» STRING)
CREATE TABLE PIZZA_CLEAN_CUSTOMER_ORDERS («order_id» INT, «customer_id» INT, «pizza_id» INT, «exclusions» STRING, «extras» STRING, «order_time» STRING)
CREATE TABLE PIZZA_GET_EXTRAS («row_id» INT, «order_id» INT, «extras» INT, «extras_count» INT)

theorem eq (t0 : TableRel PIZZA_CLEAN_RUNNER_ORDERS_schema) (t1 : TableRel PIZZA_CLEAN_CUSTOMER_ORDERS_schema) (t2 : TableRel PIZZA_GET_EXTRAS_schema) :
    (sql%([PIZZA_CLEAN_RUNNER_ORDERS_schema, PIZZA_CLEAN_CUSTOMER_ORDERS_schema, PIZZA_GET_EXTRAS_schema]) "WITH delivered_orders AS (SELECT c.\"order_id\", c.\"pizza_id\", c.\"extras\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_CLEAN_CUSTOMER_ORDERS\" AS c JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_CLEAN_RUNNER_ORDERS\" AS r ON c.\"order_id\" = r.\"order_id\" WHERE r.\"cancellation\" IS NULL OR r.\"cancellation\" = '') SELECT SUM(CASE WHEN \"pizza_id\" = 1 THEN 12 ELSE 10 END + CASE WHEN \"extras\" IS NULL OR \"extras\" = '' THEN 0 ELSE ARRAY_LENGTH(SPLIT(\"extras\", ','), 1) END) AS \"output\" FROM delivered_orders") t0 t1 t2
  = (sql%([PIZZA_CLEAN_RUNNER_ORDERS_schema, PIZZA_CLEAN_CUSTOMER_ORDERS_schema, PIZZA_GET_EXTRAS_schema]) "WITH non_cancelled AS (SELECT c.\"order_id\", c.\"pizza_id\", c.\"extras\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_CLEAN_CUSTOMER_ORDERS\" AS c JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_CLEAN_RUNNER_ORDERS\" AS r ON c.\"order_id\" = r.\"order_id\" WHERE r.\"cancellation\" IS NULL OR r.\"cancellation\" = '') SELECT SUM(CASE WHEN \"pizza_id\" = 1 THEN 12 ELSE 10 END + CASE WHEN \"extras\" IS NULL OR TRIM(\"extras\") = '' THEN 0 ELSE ARRAY_LENGTH(SPLIT(\"extras\", ','), 1) END) AS output FROM non_cancelled") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local065_eq_2_3
