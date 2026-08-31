import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local031_eq_1_2

CREATE TABLE OLIST_ORDERS («order_id» STRING, «customer_id» STRING, «order_status» STRING, «order_purchase_timestamp» STRING, «order_approved_at» STRING, «order_delivered_carrier_date» STRING, «order_delivered_customer_date» STRING, «order_estimated_delivery_date» STRING)

theorem eq (t0 : TableRel OLIST_ORDERS_schema) :
    (sql%([OLIST_ORDERS_schema]) "WITH delivered AS (SELECT EXTRACT(YEAR FROM TO_TIMESTAMP(\"order_delivered_customer_date\")) AS yr, EXTRACT(MONTH FROM TO_TIMESTAMP(\"order_delivered_customer_date\")) AS mo FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDERS\" WHERE \"order_status\" = 'delivered' AND NOT \"order_delivered_customer_date\" IS NULL AND \"order_delivered_customer_date\" <> '' AND EXTRACT(YEAR FROM TO_TIMESTAMP(\"order_delivered_customer_date\")) IN (2016, 2017, 2018)), annual_volume AS (SELECT yr, COUNT(*) AS annual_cnt FROM delivered GROUP BY yr), lowest_year AS (SELECT yr FROM annual_volume ORDER BY annual_cnt ASC LIMIT 1), monthly_volume AS (SELECT mo, COUNT(*) AS monthly_cnt FROM delivered WHERE yr = (SELECT yr FROM lowest_year) GROUP BY mo) SELECT MAX(monthly_cnt) AS OUTPUT FROM monthly_volume") t0
  ~= (sql%([OLIST_ORDERS_schema]) "WITH delivered_orders AS (SELECT \"order_id\", EXTRACT(YEAR FROM TO_TIMESTAMP(\"order_delivered_customer_date\")) AS yr, EXTRACT(MONTH FROM TO_TIMESTAMP(\"order_delivered_customer_date\")) AS mo FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDERS\" WHERE \"order_status\" = 'delivered' AND NOT \"order_delivered_customer_date\" IS NULL AND \"order_delivered_customer_date\" <> '' AND EXTRACT(YEAR FROM TO_TIMESTAMP(\"order_delivered_customer_date\")) IN (2016, 2017, 2018)), annual_volume AS (SELECT yr, COUNT(*) AS annual_cnt FROM delivered_orders GROUP BY yr), lowest_year AS (SELECT yr FROM annual_volume ORDER BY annual_cnt ASC LIMIT 1), monthly_volume AS (SELECT mo, COUNT(*) AS monthly_cnt FROM delivered_orders WHERE yr = (SELECT yr FROM lowest_year) GROUP BY mo) SELECT MAX(monthly_cnt) AS \"OUTPUT\" FROM monthly_volume") t0
  := by first | sql_equiv | sorry

end N_sf_local031_eq_1_2
