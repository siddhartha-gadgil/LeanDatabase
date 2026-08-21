import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq014 — crossskill equivalence(s)

Question: Can you help me figure out the revenue for the product category that has the highest number of customers making a purchase in their first non-cancelled and non-returned order?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq014

CREATE TABLE ORDERS («order_id» INT, «user_id» INT, «status» STRING, «gender» STRING, «created_at» INT, «returned_at» INT, «shipped_at» INT, «delivered_at» INT, «num_of_item» INT)
CREATE TABLE PRODUCTS («id» INT, «cost» FLOAT, «category» STRING, «name» STRING, «brand» STRING, «retail_price» FLOAT, «department» STRING, «sku» STRING, «distribution_center_id» INT)
CREATE TABLE ORDER_ITEMS («id» INT, «order_id» INT, «user_id» INT, «product_id» INT, «inventory_item_id» INT, «status» STRING, «created_at» INT, «shipped_at» INT, «delivered_at» INT, «returned_at» INT, «sale_price» FLOAT)

theorem eq_0_1 : ∀ t,
    (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH first_valid_orders AS (\n  SELECT \"user_id\", \"order_id\"\n  FROM (\n    SELECT DISTINCT \"user_id\", \"order_id\", \"created_at\",\n      ROW_NUMBER() OVER (PARTITION BY \"user_id\" ORDER BY \"created_at\" ASC) AS rn\n    FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\"\n    WHERE \"status\" NOT IN ('Cancelled', 'Returned')\n  ) sub\n  WHERE rn = 1\n),\nfirst_order_items AS (\n  SELECT fvo.\"user_id\", p.\"category\", oi.\"sale_price\"\n  FROM first_valid_orders fvo\n  JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" oi ON fvo.\"order_id\" = oi.\"order_id\"\n  JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" p ON oi.\"product_id\" = p.\"id\"\n),\ncategory_customer_counts AS (\n  SELECT \"category\", COUNT(DISTINCT \"user_id\") AS num_customers\n  FROM first_order_items\n  GROUP BY \"category\"\n),\ntop_category AS (\n  SELECT \"category\" FROM category_customer_counts ORDER BY num_customers DESC LIMIT 1\n)\nSELECT SUM(foi.\"sale_price\") AS REVENUE\nFROM first_order_items foi\nJOIN top_category tc ON foi.\"category\" = tc.\"category\";") t ~= (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH first_orders AS (\n    SELECT DISTINCT \"user_id\",\n           FIRST_VALUE(\"order_id\") OVER (PARTITION BY \"user_id\" ORDER BY \"created_at\") AS first_order_id\n    FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\"\n    WHERE \"status\" NOT IN ('Cancelled', 'Returned')\n),\nfirst_order_categories AS (\n    SELECT fo.\"user_id\", p.\"category\", oi.\"sale_price\"\n    FROM first_orders fo\n    INNER JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" oi\n        ON fo.first_order_id = oi.\"order_id\"\n    INNER JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" p\n        ON oi.\"product_id\" = p.\"id\"\n),\ncategory_customer_counts AS (\n    SELECT \"category\", COUNT(DISTINCT \"user_id\") AS customer_count\n    FROM first_order_categories\n    GROUP BY \"category\"\n    ORDER BY customer_count DESC\n    LIMIT 1\n),\ntop_cat AS (\n    SELECT \"category\" FROM category_customer_counts\n)\nSELECT CAST(SUM(\"sale_price\") AS FLOAT) AS REVENUE\nFROM first_order_categories\nWHERE \"category\" = (SELECT \"category\" FROM top_cat);") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq014
