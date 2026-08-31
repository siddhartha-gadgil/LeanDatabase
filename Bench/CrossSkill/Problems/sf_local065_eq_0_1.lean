import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local065_eq_0_1

CREATE TABLE PIZZA_CLEAN_RUNNER_ORDERS («order_id» INT, «runner_id» INT, «pickup_time» STRING, «distance» FLOAT, «duration» FLOAT, «cancellation» STRING)
CREATE TABLE PIZZA_CLEAN_CUSTOMER_ORDERS («order_id» INT, «customer_id» INT, «pizza_id» INT, «exclusions» STRING, «extras» STRING, «order_time» STRING)
CREATE TABLE PIZZA_GET_EXTRAS («row_id» INT, «order_id» INT, «extras» INT, «extras_count» INT)

theorem eq (t0 : TableRel PIZZA_CLEAN_RUNNER_ORDERS_schema) (t1 : TableRel PIZZA_CLEAN_CUSTOMER_ORDERS_schema) (t2 : TableRel PIZZA_GET_EXTRAS_schema) :
    (sql%([PIZZA_CLEAN_RUNNER_ORDERS_schema, PIZZA_CLEAN_CUSTOMER_ORDERS_schema, PIZZA_GET_EXTRAS_schema]) "WITH non_canceled_orders AS (SELECT c.\"order_id\", c.\"pizza_id\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_CLEAN_CUSTOMER_ORDERS\" AS c INNER JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_CLEAN_RUNNER_ORDERS\" AS r ON c.\"order_id\" = r.\"order_id\" WHERE r.\"cancellation\" IS NULL OR r.\"cancellation\" = ''), pizza_income AS (SELECT SUM(CASE WHEN \"pizza_id\" = 1 THEN 12 WHEN \"pizza_id\" = 2 THEN 10 ELSE 0 END) AS total_pizza_income FROM non_canceled_orders), extras_income AS (SELECT COUNT(*) AS total_extras_income FROM \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_GET_EXTRAS\" AS e INNER JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_CLEAN_RUNNER_ORDERS\" AS r ON e.\"order_id\" = r.\"order_id\" WHERE r.\"cancellation\" IS NULL OR r.\"cancellation\" = '') SELECT p.total_pizza_income + x.total_extras_income AS output FROM pizza_income AS p CROSS JOIN extras_income AS x") t0 t1 t2
  ~= (sql%([PIZZA_CLEAN_RUNNER_ORDERS_schema, PIZZA_CLEAN_CUSTOMER_ORDERS_schema, PIZZA_GET_EXTRAS_schema]) "SELECT SUM(CASE WHEN c.\"pizza_id\" = 1 THEN 12 WHEN c.\"pizza_id\" = 2 THEN 10 ELSE 0 END + CASE WHEN c.\"extras\" IS NULL OR c.\"extras\" = '' THEN 0 ELSE ARRAY_LENGTH(SPLIT(c.\"extras\", ','), 1) END) AS \"output\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_CLEAN_CUSTOMER_ORDERS\" AS c JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"PIZZA_CLEAN_RUNNER_ORDERS\" AS r ON c.\"order_id\" = r.\"order_id\" WHERE r.\"cancellation\" IS NULL OR r.\"cancellation\" = ''") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local065_eq_0_1
