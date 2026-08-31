import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local029_eq_0_2

CREATE TABLE OLIST_ORDERS («order_id» STRING, «customer_id» STRING, «order_status» STRING, «order_purchase_timestamp» STRING, «order_approved_at» STRING, «order_delivered_carrier_date» STRING, «order_delivered_customer_date» STRING, «order_estimated_delivery_date» STRING)
CREATE TABLE OLIST_ORDER_PAYMENTS («order_id» STRING, «payment_sequential» INT, «payment_type» STRING, «payment_installments» INT, «payment_value» FLOAT)
CREATE TABLE OLIST_CUSTOMERS («customer_id» STRING, «customer_unique_id» STRING, «customer_zip_code_prefix» INT, «customer_city» STRING, «customer_state» STRING)

theorem eq (t0 : TableRel OLIST_ORDERS_schema) (t1 : TableRel OLIST_ORDER_PAYMENTS_schema) (t2 : TableRel OLIST_CUSTOMERS_schema) :
    (sql%([OLIST_ORDERS_schema, OLIST_ORDER_PAYMENTS_schema, OLIST_CUSTOMERS_schema]) "WITH delivered_orders AS (SELECT c.\"customer_unique_id\", o.\"order_id\" FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDERS\" AS o JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_CUSTOMERS\" AS c ON o.\"customer_id\" = c.\"customer_id\" WHERE o.\"order_status\" = 'delivered'), order_payments AS (SELECT d.\"customer_unique_id\", d.\"order_id\", SUM(p.\"payment_value\") AS order_payment_total FROM delivered_orders AS d JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDER_PAYMENTS\" AS p ON d.\"order_id\" = p.\"order_id\" GROUP BY d.\"customer_unique_id\", d.\"order_id\"), customer_stats AS (SELECT \"customer_unique_id\", COUNT(\"order_id\") AS \"DELIVERED_ORDERS\", AVG(order_payment_total) AS \"AVG_PAYMENT_VALUE\" FROM order_payments GROUP BY \"customer_unique_id\" ORDER BY \"DELIVERED_ORDERS\" DESC, \"customer_unique_id\" ASC LIMIT 3), customer_location AS (SELECT DISTINCT c.\"customer_unique_id\", c.\"customer_city\", c.\"customer_state\" FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_CUSTOMERS\" AS c WHERE c.\"customer_unique_id\" IN (SELECT \"customer_unique_id\" FROM customer_stats)) SELECT cs.\"customer_unique_id\", cs.\"DELIVERED_ORDERS\", cs.\"AVG_PAYMENT_VALUE\", cl.\"customer_city\" AS \"CUSTOMER_CITY\", cl.\"customer_state\" AS \"CUSTOMER_STATE\" FROM customer_stats AS cs JOIN customer_location AS cl ON cs.\"customer_unique_id\" = cl.\"customer_unique_id\" ORDER BY cs.\"DELIVERED_ORDERS\" DESC, cs.\"customer_unique_id\" ASC") t0 t1 t2
  ~= (sql%([OLIST_ORDERS_schema, OLIST_ORDER_PAYMENTS_schema, OLIST_CUSTOMERS_schema]) "SELECT c.\"customer_unique_id\" AS \"customer_unique_id\", COUNT(DISTINCT o.\"order_id\") AS \"DELIVERED_ORDERS\", ROUND(CAST(AVG(p.\"payment_value\") AS DECIMAL), 2) AS \"AVG_PAYMENT_VALUE\", MAX(c.\"customer_city\") AS \"CUSTOMER_CITY\", MAX(c.\"customer_state\") AS \"CUSTOMER_STATE\" FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_CUSTOMERS\" AS c JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDERS\" AS o ON c.\"customer_id\" = o.\"customer_id\" JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDER_PAYMENTS\" AS p ON o.\"order_id\" = p.\"order_id\" WHERE o.\"order_status\" = 'delivered' GROUP BY c.\"customer_unique_id\" ORDER BY \"DELIVERED_ORDERS\" DESC, c.\"customer_unique_id\" LIMIT 3") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local029_eq_0_2
