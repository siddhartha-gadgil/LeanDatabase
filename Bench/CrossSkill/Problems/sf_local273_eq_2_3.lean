import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local273_eq_2_3

CREATE TABLE PICKING_LINE («picklist_id» INT, «line_no» INT, «location_id» INT, «order_id» INT, «product_id» INT, «qty» FLOAT)
CREATE TABLE INVENTORY («id» INT, «location_id» INT, «product_id» INT, «purchase_id» INT, «qty» FLOAT)

theorem eq (t0 : TableRel PICKING_LINE_schema) (t1 : TableRel INVENTORY_schema) :
    (sql%([PICKING_LINE_schema, INVENTORY_schema]) "WITH order_products AS (SELECT pl.\"product_id\" AS product_id, pl.\"order_id\" AS order_id, SUM(pl.\"qty\") AS order_qty FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\" AS pl GROUP BY pl.\"product_id\", pl.\"order_id\"), inventory_fifo AS (SELECT i.\"PRODUCTID\" AS product_id, i.\"QUANTITY\" AS available_qty, i.\"PURCHASEDATE\", ROW_NUMBER() OVER (PARTITION BY i.\"PRODUCTID\" ORDER BY i.\"PURCHASEDATE\", i.\"QUANTITY\") AS rn FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"INVENTORY\" AS i), matched AS (SELECT op.product_id, op.order_id, op.order_qty, COALESCE(inv.available_qty, 0) AS available_qty, LEAST(op.order_qty, COALESCE(inv.available_qty, 0)) AS picked_qty FROM order_products AS op LEFT JOIN inventory_fifo AS inv ON op.product_id = inv.product_id), pick_pct AS (SELECT product_id, CASE WHEN order_qty > 0 THEN CAST(picked_qty AS DOUBLE PRECISION) / order_qty ELSE 0 END AS pick_percentage FROM matched) SELECT product_id AS PRODUCT_NAME, AVG(pick_percentage) AS AVG_PICK_PERCENTAGE FROM pick_pct GROUP BY product_id ORDER BY product_id") t0 t1
  ~= (sql%([PICKING_LINE_schema, INVENTORY_schema]) "WITH picking_orders AS (SELECT \"picklist_id\", \"line_no\", \"product_id\", \"qty\" FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\"), inventory_fifo AS (SELECT \"PRODUCTID\", \"PURCHASEDATE\", \"QUANTITY\", ROW_NUMBER() OVER (PARTITION BY \"PRODUCTID\" ORDER BY \"PURCHASEDATE\" ASC, \"QUANTITY\" ASC) AS rn FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"INVENTORY\"), pick_calc AS (SELECT po.\"product_id\" AS PRODUCT_NAME, po.\"qty\" AS order_qty, COALESCE(LEAST(po.\"qty\", inv.\"QUANTITY\"), 0) AS picked_qty FROM picking_orders AS po LEFT JOIN inventory_fifo AS inv ON po.\"product_id\" = inv.\"PRODUCTID\"), pick_pct AS (SELECT PRODUCT_NAME, CASE WHEN order_qty > 0 THEN (CAST(picked_qty * 1.0 AS DOUBLE PRECISION) / order_qty) * 100 ELSE 0 END AS pick_percentage FROM pick_calc) SELECT PRODUCT_NAME, ROUND(CAST(AVG(pick_percentage) AS DECIMAL), 1) AS AVG_PICK_PERCENTAGE FROM pick_pct GROUP BY PRODUCT_NAME ORDER BY PRODUCT_NAME") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local273_eq_2_3
