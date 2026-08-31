import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local034_eq_1_2

CREATE TABLE OLIST_ORDER_PAYMENTS («order_id» STRING, «payment_sequential» INT, «payment_type» STRING, «payment_installments» INT, «payment_value» FLOAT)
CREATE TABLE OLIST_ORDER_ITEMS («order_id» STRING, «order_item_id» INT, «product_id» STRING, «seller_id» STRING, «shipping_limit_date» STRING, «price» FLOAT, «freight_value» FLOAT)
CREATE TABLE OLIST_PRODUCTS («product_id» STRING, «product_category_name» STRING, «product_name_lenght» FLOAT, «product_description_lenght» FLOAT, «product_photos_qty» FLOAT, «product_weight_g» FLOAT, «product_length_cm» FLOAT, «product_height_cm» FLOAT, «product_width_cm» FLOAT)

theorem eq (t0 : TableRel OLIST_ORDER_PAYMENTS_schema) (t1 : TableRel OLIST_ORDER_ITEMS_schema) (t2 : TableRel OLIST_PRODUCTS_schema) :
    (sql%([OLIST_ORDER_PAYMENTS_schema, OLIST_ORDER_ITEMS_schema, OLIST_PRODUCTS_schema]) "WITH order_cat AS (/* Deduplicate: each order appears once per category */ SELECT DISTINCT oi.\"order_id\", p.\"product_category_name\" AS category FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDER_ITEMS\" AS oi JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_PRODUCTS\" AS p ON oi.\"product_id\" = p.\"product_id\" WHERE NOT p.\"product_category_name\" IS NULL), category_payments AS (/* Count payments per category per payment type */ SELECT oc.category, pay.\"payment_type\" AS ptype, COUNT(*) AS num_payments FROM order_cat AS oc JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDER_PAYMENTS\" AS pay ON oc.\"order_id\" = pay.\"order_id\" GROUP BY oc.category, pay.\"payment_type\"), ranked AS (/* Find the most preferred payment method per category */ SELECT category, ptype, num_payments, ROW_NUMBER() OVER (PARTITION BY category ORDER BY num_payments DESC) AS rn FROM category_payments) SELECT AVG(num_payments) AS AVG_TOP_PAYMENT_COUNT FROM ranked WHERE rn = 1") t0 t1 t2
  ~= (sql%([OLIST_ORDER_PAYMENTS_schema, OLIST_ORDER_ITEMS_schema, OLIST_PRODUCTS_schema]) "WITH category_payment_counts AS (SELECT p.\"product_category_name\", op.\"payment_type\", COUNT(DISTINCT op.\"order_id\" || '-' || op.\"payment_sequential\") AS payment_count FROM \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDER_PAYMENTS\" AS op JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_ORDER_ITEMS\" AS oi ON op.\"order_id\" = oi.\"order_id\" JOIN \"BRAZILIAN_E_COMMERCE\".\"BRAZILIAN_E_COMMERCE\".\"OLIST_PRODUCTS\" AS p ON oi.\"product_id\" = p.\"product_id\" WHERE NOT p.\"product_category_name\" IS NULL GROUP BY p.\"product_category_name\", op.\"payment_type\"), top_payment_per_category AS (SELECT \"product_category_name\", MAX(payment_count) AS top_payment_count FROM category_payment_counts GROUP BY \"product_category_name\") SELECT AVG(top_payment_count) AS \"AVG_TOP_PAYMENT_COUNT\" FROM top_payment_per_category") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_local034_eq_1_2
