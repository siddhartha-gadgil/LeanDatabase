import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq197_eq_0_1

CREATE TABLE ORDERS («order_id» INT, «user_id» INT, «status» STRING, «gender» STRING, «created_at» INT, «returned_at» INT, «shipped_at» INT, «delivered_at» INT, «num_of_item» INT)
CREATE TABLE PRODUCTS («id» INT, «cost» FLOAT, «category» STRING, «name» STRING, «brand» STRING, «retail_price» FLOAT, «department» STRING, «sku» STRING, «distribution_center_id» INT)
CREATE TABLE ORDER_ITEMS («id» INT, «order_id» INT, «user_id» INT, «product_id» INT, «inventory_item_id» INT, «status» STRING, «created_at» INT, «shipped_at» INT, «delivered_at» INT, «returned_at» INT, «sale_price» FLOAT)

theorem eq (t0 : TableRel ORDERS_schema) (t1 : TableRel PRODUCTS_schema) (t2 : TableRel ORDER_ITEMS_schema) :
    (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_product_sales AS (SELECT TO_CHAR(DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000)), 'YYYY-MM') AS \"MONTH\", p.\"name\" AS \"PRODUCT_NAME\", p.\"brand\" AS \"BRAND\", p.\"category\" AS \"CATEGORY\", COUNT(*) AS \"TOTAL_SALES\", ROUND(SUM(oi.\"sale_price\"), 2) AS \"TOTAL_REVENUE\", o.\"status\" AS \"ORDER_STATUS\" FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\" AS o ON oi.\"order_id\" = o.\"order_id\" JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE o.\"status\" = 'Complete' AND NOT p.\"brand\" IS NULL AND TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000) < '2024-07-01' GROUP BY TO_CHAR(DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000)), 'YYYY-MM'), p.\"name\", p.\"brand\", p.\"category\", o.\"status\"), ranked AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY \"MONTH\" ORDER BY \"TOTAL_SALES\" DESC, \"TOTAL_REVENUE\" DESC) AS rn FROM monthly_product_sales) SELECT \"MONTH\", \"PRODUCT_NAME\", \"BRAND\", \"CATEGORY\", \"TOTAL_SALES\", \"TOTAL_REVENUE\", \"ORDER_STATUS\" FROM ranked WHERE rn = 1 ORDER BY \"MONTH\"") t0 t1 t2
  ~= (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_product_sales AS (SELECT TO_CHAR(DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000)), 'YYYY-MM') AS month, p.\"id\" AS product_id, p.\"name\" AS product_name, p.\"brand\" AS brand, p.\"category\" AS category, COUNT(oi.\"id\") AS total_sales, ROUND(SUM(oi.\"sale_price\"), 2) AS total_revenue, o.\"status\" AS order_status FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\" AS o ON oi.\"order_id\" = o.\"order_id\" JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE o.\"status\" = 'Complete' AND NOT p.\"brand\" IS NULL AND TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000) < '2024-07-01' GROUP BY DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000)), p.\"id\", p.\"name\", p.\"brand\", p.\"category\", o.\"status\"), ranked AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_sales DESC, total_revenue DESC) AS rn FROM monthly_product_sales) SELECT month, product_name, brand, category, total_sales, total_revenue, order_status FROM ranked WHERE rn = 1 ORDER BY month") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_bq197_eq_0_1
