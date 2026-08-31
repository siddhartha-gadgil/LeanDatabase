import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local029_eq_1_2

CREATE TABLE OLIST_ORDERS («order_id» STRING, «customer_id» STRING, «order_status» STRING, «order_purchase_timestamp» STRING, «order_approved_at» STRING, «order_delivered_carrier_date» STRING, «order_delivered_customer_date» STRING, «order_estimated_delivery_date» STRING)
CREATE TABLE OLIST_ORDER_PAYMENTS («order_id» STRING, «payment_sequential» INT, «payment_type» STRING, «payment_installments» INT, «payment_value» FLOAT)
CREATE TABLE OLIST_CUSTOMERS («customer_id» STRING, «customer_unique_id» STRING, «customer_zip_code_prefix» INT, «customer_city» STRING, «customer_state» STRING)

theorem eq (t0 : TableRel OLIST_ORDERS_schema) (t1 : TableRel OLIST_ORDER_PAYMENTS_schema) (t2 : TableRel OLIST_CUSTOMERS_schema) :
    (sql%([OLIST_ORDERS_schema, OLIST_ORDER_PAYMENTS_schema, OLIST_CUSTOMERS_schema]) "WITH order_payments AS (SELECT p.\"order_id\", SUM(p.\"payment_value\") AS order_total_payment FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDER_PAYMENTS\" AS p GROUP BY p.\"order_id\"), customer_delivered AS (SELECT c.\"customer_unique_id\", o.\"order_id\", c.\"customer_city\", c.\"customer_state\", op.order_total_payment FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDERS\" AS o JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_CUSTOMERS\" AS c ON o.\"customer_id\" = c.\"customer_id\" JOIN order_payments AS op ON o.\"order_id\" = op.\"order_id\" WHERE o.\"order_status\" = 'delivered') SELECT \"customer_unique_id\", COUNT(DISTINCT \"order_id\") AS DELIVERED_ORDERS, AVG(order_total_payment) AS AVG_PAYMENT_VALUE, MAX(\"customer_city\") AS CUSTOMER_CITY, MAX(\"customer_state\") AS CUSTOMER_STATE FROM customer_delivered GROUP BY \"customer_unique_id\" ORDER BY DELIVERED_ORDERS DESC, \"customer_unique_id\" ASC LIMIT 3") t0 t1 t2
  ~= (sql%([OLIST_ORDERS_schema, OLIST_ORDER_PAYMENTS_schema, OLIST_CUSTOMERS_schema]) "SELECT c.\"customer_unique_id\" AS \"customer_unique_id\", COUNT(DISTINCT o.\"order_id\") AS \"DELIVERED_ORDERS\", ROUND(CAST(AVG(p.\"payment_value\") AS DECIMAL), 2) AS \"AVG_PAYMENT_VALUE\", MAX(c.\"customer_city\") AS \"CUSTOMER_CITY\", MAX(c.\"customer_state\") AS \"CUSTOMER_STATE\" FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_CUSTOMERS\" AS c JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDERS\" AS o ON c.\"customer_id\" = o.\"customer_id\" JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDER_PAYMENTS\" AS p ON o.\"order_id\" = p.\"order_id\" WHERE o.\"order_status\" = 'delivered' GROUP BY c.\"customer_unique_id\" ORDER BY \"DELIVERED_ORDERS\" DESC, c.\"customer_unique_id\" LIMIT 3") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local029_eq_1_2
