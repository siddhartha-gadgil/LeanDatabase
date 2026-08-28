import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq197 — crossskill equivalence(s)

Question: For each month prior to July 2024, identify the single best-selling product (determined by highest sales volume, with total revenue as a tiebreaker) among all orders with a 'Complete' status and products with non-null brands. Return a report showing the month, product name, brand, category, total sales, rounded total revenue, and order status for these monthly top performers.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq197

CREATE TABLE ORDERS («order_id» INT, «user_id» INT, «status» STRING, «gender» STRING, «created_at» INT, «returned_at» INT, «shipped_at» INT, «delivered_at» INT, «num_of_item» INT)
CREATE TABLE PRODUCTS («id» INT, «cost» FLOAT, «category» STRING, «name» STRING, «brand» STRING, «retail_price» FLOAT, «department» STRING, «sku» STRING, «distribution_center_id» INT)
CREATE TABLE ORDER_ITEMS («id» INT, «order_id» INT, «user_id» INT, «product_id» INT, «inventory_item_id» INT, «status» STRING, «created_at» INT, «shipped_at» INT, «delivered_at» INT, «returned_at» INT, «sale_price» FLOAT)

theorem eq_0_1 : ∀ t,
    (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_product_sales AS (SELECT TO_CHAR(DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000)), 'YYYY-MM') AS \"MONTH\", p.\"name\" AS \"PRODUCT_NAME\", p.\"brand\" AS \"BRAND\", p.\"category\" AS \"CATEGORY\", COUNT(*) AS \"TOTAL_SALES\", ROUND(SUM(oi.\"sale_price\"), 2) AS \"TOTAL_REVENUE\", o.\"status\" AS \"ORDER_STATUS\" FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\" AS o ON oi.\"order_id\" = o.\"order_id\" JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE o.\"status\" = 'Complete' AND NOT p.\"brand\" IS NULL AND TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000) < '2024-07-01' GROUP BY TO_CHAR(DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000)), 'YYYY-MM'), p.\"name\", p.\"brand\", p.\"category\", o.\"status\"), ranked AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY \"MONTH\" ORDER BY \"TOTAL_SALES\" DESC, \"TOTAL_REVENUE\" DESC) AS rn FROM monthly_product_sales) SELECT \"MONTH\", \"PRODUCT_NAME\", \"BRAND\", \"CATEGORY\", \"TOTAL_SALES\", \"TOTAL_REVENUE\", \"ORDER_STATUS\" FROM ranked WHERE rn = 1 ORDER BY \"MONTH\"") t ~= (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_product_sales AS (SELECT TO_CHAR(DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000)), 'YYYY-MM') AS month, p.\"id\" AS product_id, p.\"name\" AS product_name, p.\"brand\" AS brand, p.\"category\" AS category, COUNT(oi.\"id\") AS total_sales, ROUND(SUM(oi.\"sale_price\"), 2) AS total_revenue, o.\"status\" AS order_status FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\" AS o ON oi.\"order_id\" = o.\"order_id\" JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\" WHERE o.\"status\" = 'Complete' AND NOT p.\"brand\" IS NULL AND TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000) < '2024-07-01' GROUP BY DATE_TRUNC('MONTH', TO_TIMESTAMP(CAST(o.\"created_at\" AS DOUBLE PRECISION) / 1000000)), p.\"id\", p.\"name\", p.\"brand\", p.\"category\", o.\"status\"), ranked AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_sales DESC, total_revenue DESC) AS rn FROM monthly_product_sales) SELECT month, product_name, brand, category, total_sales, total_revenue, order_status FROM ranked WHERE rn = 1 ORDER BY month") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq197
