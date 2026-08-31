import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq261_eq_0_2

CREATE TABLE PRODUCTS («id» INT, «cost» FLOAT, «category» STRING, «name» STRING, «brand» STRING, «retail_price» FLOAT, «department» STRING, «sku» STRING, «distribution_center_id» INT)
CREATE TABLE ORDER_ITEMS («id» INT, «order_id» INT, «user_id» INT, «product_id» INT, «inventory_item_id» INT, «status» STRING, «created_at» INT, «shipped_at» INT, «delivered_at» INT, «returned_at» INT, «sale_price» FLOAT)

theorem eq (t0 : TableRel PRODUCTS_schema) (t1 : TableRel ORDER_ITEMS_schema) :
    (sql%([PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_product_profit AS (SELECT TO_CHAR(DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ(oi.\"created_at\" / 1000000.0)), 'YYYY-MM') AS \"month_year\", oi.\"product_id\" AS \"product_id\", p.\"name\" AS \"product_name\", SUM(oi.\"sale_price\") AS \"sales\", SUM(p.\"cost\") AS \"cost\", SUM(oi.\"sale_price\" - p.\"cost\") AS \"profit\" FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE TO_TIMESTAMP_NTZ(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000.0) < '2024-01-01' GROUP BY \"month_year\", oi.\"product_id\", p.\"name\"), ranked AS (SELECT \"month_year\", \"product_id\", \"product_name\", \"sales\", \"cost\", \"profit\", ROW_NUMBER() OVER (PARTITION BY \"month_year\" ORDER BY \"profit\" DESC, \"product_id\" ASC) AS \"rn\" FROM monthly_product_profit) SELECT \"month_year\", \"product_id\", \"product_name\", \"sales\", \"cost\", \"profit\" FROM ranked WHERE \"rn\" = 1 ORDER BY \"month_year\"") t0 t1
  = (sql%([PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH product_monthly AS (SELECT TO_CHAR(TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000), 'YYYY-MM') AS month_year, oi.\"product_id\" AS product_id, p.\"name\" AS product_name, SUM(oi.\"sale_price\") AS sales, SUM(p.\"cost\") AS cost, SUM(oi.\"sale_price\" - p.\"cost\") AS profit FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000) < '2024-01-01' GROUP BY month_year, oi.\"product_id\", p.\"name\"), ranked AS (SELECT month_year, product_id, product_name, sales, cost, profit, ROW_NUMBER() OVER (PARTITION BY month_year ORDER BY profit DESC) AS rn FROM product_monthly) SELECT month_year, product_id, product_name, sales, cost, profit FROM ranked WHERE rn = 1 ORDER BY month_year") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq261_eq_0_2
