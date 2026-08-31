import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq014_eq_0_1

CREATE TABLE ORDERS («order_id» INT, «user_id» INT, «status» STRING, «gender» STRING, «created_at» INT, «returned_at» INT, «shipped_at» INT, «delivered_at» INT, «num_of_item» INT)
CREATE TABLE PRODUCTS («id» INT, «cost» FLOAT, «category» STRING, «name» STRING, «brand» STRING, «retail_price» FLOAT, «department» STRING, «sku» STRING, «distribution_center_id» INT)
CREATE TABLE ORDER_ITEMS («id» INT, «order_id» INT, «user_id» INT, «product_id» INT, «inventory_item_id» INT, «status» STRING, «created_at» INT, «shipped_at» INT, «delivered_at» INT, «returned_at» INT, «sale_price» FLOAT)

theorem eq (t0 : TableRel ORDERS_schema) (t1 : TableRel PRODUCTS_schema) (t2 : TableRel ORDER_ITEMS_schema) :
    (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH first_valid_orders AS (SELECT \"user_id\", \"order_id\" FROM (SELECT DISTINCT \"user_id\", \"order_id\", \"created_at\", ROW_NUMBER() OVER (PARTITION BY \"user_id\" ORDER BY \"created_at\" ASC) AS rn FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\" WHERE NOT \"status\" IN ('Cancelled', 'Returned')) AS sub WHERE rn = 1), first_order_items AS (SELECT fvo.\"user_id\", p.\"category\", oi.\"sale_price\" FROM first_valid_orders AS fvo JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi ON fvo.\"order_id\" = oi.\"order_id\" JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\"), category_customer_counts AS (SELECT \"category\", COUNT(DISTINCT \"user_id\") AS num_customers FROM first_order_items GROUP BY \"category\"), top_category AS (SELECT \"category\" FROM category_customer_counts ORDER BY num_customers DESC LIMIT 1) SELECT SUM(foi.\"sale_price\") AS REVENUE FROM first_order_items AS foi JOIN top_category AS tc ON foi.\"category\" = tc.\"category\"") t0 t1 t2
  ~= (sql%([ORDERS_schema, PRODUCTS_schema, ORDER_ITEMS_schema]) "WITH first_orders AS (SELECT DISTINCT \"user_id\", FIRST_VALUE(\"order_id\") OVER (PARTITION BY \"user_id\" ORDER BY \"created_at\" ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_order_id FROM \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDERS\" WHERE NOT \"status\" IN ('Cancelled', 'Returned')), first_order_categories AS (SELECT fo.\"user_id\", p.\"category\", oi.\"sale_price\" FROM first_orders AS fo INNER JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"ORDER_ITEMS\" AS oi ON fo.first_order_id = oi.\"order_id\" INNER JOIN \"THELOOK_ECOMMERCE\".\"THELOOK_ECOMMERCE\".\"PRODUCTS\" AS p ON oi.\"product_id\" = p.\"id\"), category_customer_counts AS (SELECT \"category\", COUNT(DISTINCT \"user_id\") AS customer_count FROM first_order_categories GROUP BY \"category\" ORDER BY customer_count DESC LIMIT 1), top_cat AS (SELECT \"category\" FROM category_customer_counts) SELECT CAST(SUM(\"sale_price\") AS DOUBLE PRECISION) AS REVENUE FROM first_order_categories WHERE \"category\" = (SELECT \"category\" FROM top_cat)") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_bq014_eq_0_1
