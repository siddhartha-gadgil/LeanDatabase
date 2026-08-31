import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local273_eq_0_3

CREATE TABLE PICKING_LINE («picklist_id» INT, «line_no» INT, «location_id» INT, «order_id» INT, «product_id» INT, «qty» FLOAT)
CREATE TABLE INVENTORY («id» INT, «location_id» INT, «product_id» INT, «purchase_id» INT, «qty» FLOAT)

theorem eq (t0 : TableRel PICKING_LINE_schema) (t1 : TableRel INVENTORY_schema) :
    (sql%([PICKING_LINE_schema, INVENTORY_schema]) "WITH order_products AS (/* Get the required quantity per order per product from picking_line */ SELECT \"order_id\", \"product_id\", SUM(\"qty\") AS required_qty FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\" GROUP BY \"order_id\", \"product_id\"), inventory_ranked AS (/* Rank inventory by earliest purchase date and smallest quantity (FIFO) */ SELECT \"PRODUCTID\", \"WAREHOUSEID\", \"AISLE\", \"POSITION\", \"PURCHASEDATE\", \"QUANTITY\", SUM(\"QUANTITY\") OVER (PARTITION BY \"PRODUCTID\" ORDER BY \"PURCHASEDATE\", \"QUANTITY\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_qty, SUM(\"QUANTITY\") OVER (PARTITION BY \"PRODUCTID\" ORDER BY \"PURCHASEDATE\", \"QUANTITY\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) - \"QUANTITY\" AS prev_cumulative_qty FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"INVENTORY\"), fifo_allocation AS (/* For each order-product, calculate the overlapping range with each inventory slot */ SELECT op.\"order_id\", op.\"product_id\", op.required_qty, ir.\"QUANTITY\" AS inv_quantity, ir.\"PURCHASEDATE\", GREATEST(0, LEAST(op.required_qty, ir.cumulative_qty) - GREATEST(0, ir.prev_cumulative_qty)) AS picked_qty /* The picked quantity is the overlapping range */ FROM order_products AS op LEFT JOIN inventory_ranked AS ir ON op.\"product_id\" = ir.\"PRODUCTID\"), pick_percentage AS (SELECT fa.\"product_id\" AS PRODUCT_NAME, CASE WHEN fa.required_qty > 0 THEN CAST(COALESCE(SUM(fa.picked_qty), 0) AS DOUBLE PRECISION) / fa.required_qty * 100 ELSE 0 END AS pick_pct FROM fifo_allocation AS fa GROUP BY fa.\"product_id\", fa.required_qty, fa.\"order_id\") SELECT PRODUCT_NAME, AVG(pick_pct) AS AVG_PICK_PERCENTAGE FROM pick_percentage GROUP BY PRODUCT_NAME ORDER BY PRODUCT_NAME") t0 t1
  ~= (sql%([PICKING_LINE_schema, INVENTORY_schema]) "WITH picking_orders AS (SELECT \"picklist_id\", \"line_no\", \"product_id\", \"qty\" FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\"), inventory_fifo AS (SELECT \"PRODUCTID\", \"PURCHASEDATE\", \"QUANTITY\", ROW_NUMBER() OVER (PARTITION BY \"PRODUCTID\" ORDER BY \"PURCHASEDATE\" ASC, \"QUANTITY\" ASC) AS rn FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"INVENTORY\"), pick_calc AS (SELECT po.\"product_id\" AS PRODUCT_NAME, po.\"qty\" AS order_qty, COALESCE(LEAST(po.\"qty\", inv.\"QUANTITY\"), 0) AS picked_qty FROM picking_orders AS po LEFT JOIN inventory_fifo AS inv ON po.\"product_id\" = inv.\"PRODUCTID\"), pick_pct AS (SELECT PRODUCT_NAME, CASE WHEN order_qty > 0 THEN (CAST(picked_qty * 1.0 AS DOUBLE PRECISION) / order_qty) * 100 ELSE 0 END AS pick_percentage FROM pick_calc) SELECT PRODUCT_NAME, ROUND(CAST(AVG(pick_percentage) AS DECIMAL), 1) AS AVG_PICK_PERCENTAGE FROM pick_pct GROUP BY PRODUCT_NAME ORDER BY PRODUCT_NAME") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local273_eq_0_3
