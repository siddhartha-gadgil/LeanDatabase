import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq266_eq_1_3

CREATE TABLE PRODUCTS («id» INT, «cost» FLOAT, «category» STRING, «name» STRING, «brand» STRING, «retail_price» FLOAT, «department» STRING, «sku» STRING, «distribution_center_id» INT)
CREATE TABLE ORDER_ITEMS («id» INT, «order_id» INT, «user_id» INT, «product_id» INT, «inventory_item_id» INT, «status» STRING, «created_at» INT, «shipped_at» INT, «delivered_at» INT, «returned_at» INT, «sale_price» FLOAT)

theorem eq (t0 : TableRel PRODUCTS_schema) (t1 : TableRel ORDER_ITEMS_schema) :
    (sql%([PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_sales AS (SELECT EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000)) AS month_num, p.\"name\", p.\"retail_price\" - p.\"cost\" AS profit FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000)) = 2020), ranked AS (SELECT month_num, \"name\", profit, ROW_NUMBER() OVER (PARTITION BY month_num ORDER BY profit ASC, \"name\" ASC) AS rn FROM monthly_sales) SELECT \"name\" FROM ranked WHERE rn = 1 ORDER BY month_num") t0 t1
  ~= (sql%([PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_sales AS (SELECT DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000)) AS sale_month, p.\"name\", p.\"retail_price\" - p.\"cost\" AS profit FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(oi.\"created_at\" AS DOUBLE PRECISION) / 1000000)) = 2020), ranked AS (SELECT sale_month, \"name\", profit, ROW_NUMBER() OVER (PARTITION BY sale_month ORDER BY profit ASC) AS rn FROM monthly_sales) SELECT \"name\" FROM ranked WHERE rn = 1 ORDER BY sale_month ASC") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq266_eq_1_3
