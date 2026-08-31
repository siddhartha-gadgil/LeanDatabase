import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq272_eq_0_1

CREATE TABLE PRODUCTS («id» INT, «cost» FLOAT, «category» STRING, «name» STRING, «brand» STRING, «retail_price» FLOAT, «department» STRING, «sku» STRING, «distribution_center_id» INT)
CREATE TABLE ORDER_ITEMS («id» INT, «order_id» INT, «user_id» INT, «product_id» INT, «inventory_item_id» INT, «status» STRING, «created_at» INT, «shipped_at» INT, «delivered_at» INT, «returned_at» INT, «sale_price» FLOAT)

theorem eq (t0 : TableRel PRODUCTS_schema) (t1 : TableRel ORDER_ITEMS_schema) :
    (sql%([PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_product_profit AS (SELECT CAST(DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000)) AS DATE) AS \"MONTH\", p.\"name\" AS \"PRODUCT_NAME\", SUM(oi.\"sale_price\") - SUM(p.\"cost\") AS \"PROFIT\" FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE NOT oi.\"status\" IN ('Cancelled', 'Returned') AND TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000) >= '2019-01-01' AND TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000) < '2022-09-01' GROUP BY \"MONTH\", p.\"name\"), ranked AS (SELECT \"MONTH\", \"PRODUCT_NAME\", \"PROFIT\", ROW_NUMBER() OVER (PARTITION BY \"MONTH\" ORDER BY \"PROFIT\" DESC) AS \"RANK\" FROM monthly_product_profit) SELECT \"MONTH\", \"PRODUCT_NAME\", \"PROFIT\", \"RANK\" FROM ranked WHERE \"RANK\" <= 3 ORDER BY \"MONTH\", \"RANK\"") t0 t1
  = (sql%([PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH product_monthly_profit AS (SELECT CAST(DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000)) AS DATE) AS \"MONTH\", p.\"name\" AS \"PRODUCT_NAME\", SUM(oi.\"sale_price\") - SUM(p.\"cost\") AS \"PROFIT\" FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE NOT oi.\"status\" IN ('Cancelled', 'Returned') AND TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000) >= '2019-01-01' AND TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000) < '2022-09-01' GROUP BY 1, 2), ranked AS (SELECT \"MONTH\", \"PRODUCT_NAME\", \"PROFIT\", ROW_NUMBER() OVER (PARTITION BY \"MONTH\" ORDER BY \"PROFIT\" DESC) AS \"RANK\" FROM product_monthly_profit) SELECT \"MONTH\", \"PRODUCT_NAME\", \"PROFIT\", \"RANK\" FROM ranked WHERE \"RANK\" <= 3 ORDER BY \"MONTH\", \"RANK\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq272_eq_0_1
