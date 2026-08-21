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
    (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_product_sales AS (\n    SELECT\n        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP(o.\"created_at\" / 1000000)), 'YYYY-MM') AS \"MONTH\",\n        p.\"name\" AS \"PRODUCT_NAME\",\n        p.\"brand\" AS \"BRAND\",\n        p.\"category\" AS \"CATEGORY\",\n        COUNT(*) AS \"TOTAL_SALES\",\n        ROUND(SUM(oi.\"sale_price\"), 2) AS \"TOTAL_REVENUE\",\n        o.\"status\" AS \"ORDER_STATUS\"\n    FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" oi\n    JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\" o ON oi.\"order_id\" = o.\"order_id\"\n    JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" p ON oi.\"product_id\" = p.\"id\"\n    WHERE o.\"status\" = 'Complete'\n      AND p.\"brand\" IS NOT NULL\n      AND TO_TIMESTAMP(o.\"created_at\" / 1000000) < '2024-07-01'\n    GROUP BY\n        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP(o.\"created_at\" / 1000000)), 'YYYY-MM'),\n        p.\"name\",\n        p.\"brand\",\n        p.\"category\",\n        o.\"status\"\n),\nranked AS (\n    SELECT\n        *,\n        ROW_NUMBER() OVER (\n            PARTITION BY \"MONTH\"\n            ORDER BY \"TOTAL_SALES\" DESC, \"TOTAL_REVENUE\" DESC\n        ) AS rn\n    FROM monthly_product_sales\n)\nSELECT\n    \"MONTH\",\n    \"PRODUCT_NAME\",\n    \"BRAND\",\n    \"CATEGORY\",\n    \"TOTAL_SALES\",\n    \"TOTAL_REVENUE\",\n    \"ORDER_STATUS\"\nFROM ranked\nWHERE rn = 1\nORDER BY \"MONTH\";") t ~= (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH monthly_product_sales AS (\n    SELECT\n        TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP(o.\"created_at\" / 1000000)), 'YYYY-MM') AS month,\n        p.\"id\" AS product_id,\n        p.\"name\" AS product_name,\n        p.\"brand\" AS brand,\n        p.\"category\" AS category,\n        COUNT(oi.\"id\") AS total_sales,\n        ROUND(SUM(oi.\"sale_price\"), 2) AS total_revenue,\n        o.\"status\" AS order_status\n    FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" oi\n    JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\" o\n        ON oi.\"order_id\" = o.\"order_id\"\n    JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" p\n        ON oi.\"product_id\" = p.\"id\"\n    WHERE o.\"status\" = 'Complete'\n      AND p.\"brand\" IS NOT NULL\n      AND TO_TIMESTAMP(o.\"created_at\" / 1000000) < '2024-07-01'\n    GROUP BY\n        DATE_TRUNC('month', TO_TIMESTAMP(o.\"created_at\" / 1000000)),\n        p.\"id\", p.\"name\", p.\"brand\", p.\"category\", o.\"status\"\n),\nranked AS (\n    SELECT *,\n        ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_sales DESC, total_revenue DESC) AS rn\n    FROM monthly_product_sales\n)\nSELECT month, product_name, brand, category, total_sales, total_revenue, order_status\nFROM ranked\nWHERE rn = 1\nORDER BY month;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq197
