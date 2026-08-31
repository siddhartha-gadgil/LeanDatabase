import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local273_eq_1_2

CREATE TABLE PICKING_LINE («picklist_id» INT, «line_no» INT, «location_id» INT, «order_id» INT, «product_id» INT, «qty» FLOAT)
CREATE TABLE INVENTORY («id» INT, «location_id» INT, «product_id» INT, «purchase_id» INT, «qty» FLOAT)

theorem eq (t0 : TableRel PICKING_LINE_schema) (t1 : TableRel INVENTORY_schema) :
    (sql%([PICKING_LINE_schema, INVENTORY_schema]) "WITH order_requirements AS (/* Get each order's required quantity per product from PICKING_LINE */ SELECT \"order_id\", \"product_id\", SUM(\"qty\") AS required_qty FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\" GROUP BY \"order_id\", \"product_id\"), inventory_fifo AS (/* Rank inventory locations per product in FIFO order (earliest purchase date, then smallest quantity) */ SELECT \"PRODUCTID\", \"WAREHOUSEID\", \"AISLE\", \"POSITION\", \"PURCHASEDATE\", \"QUANTITY\", SUM(\"QUANTITY\") OVER (PARTITION BY \"PRODUCTID\" ORDER BY \"PURCHASEDATE\" ASC, \"QUANTITY\" ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_qty FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"INVENTORY\"), picks AS (/* For each order-product, calculate how much is picked from each inventory location */ SELECT o.\"order_id\", o.\"product_id\", o.required_qty, COALESCE(GREATEST(0, LEAST(i.cum_qty, o.required_qty) - GREATEST(i.cum_qty - i.\"QUANTITY\", 0)), 0) AS picked_qty FROM order_requirements AS o LEFT JOIN inventory_fifo AS i ON o.\"product_id\" = i.\"PRODUCTID\"), order_pick_pct AS (/* Calculate pick percentage per order-product */ SELECT \"order_id\", \"product_id\", required_qty, SUM(picked_qty) AS total_picked, CASE WHEN required_qty > 0 THEN CAST(SUM(picked_qty) AS DOUBLE PRECISION) / required_qty ELSE 0 END AS pick_percentage FROM picks GROUP BY \"order_id\", \"product_id\", required_qty) SELECT p.\"product_id\" AS PRODUCT_NAME, AVG(p.pick_percentage) AS AVG_PICK_PERCENTAGE FROM order_pick_pct AS p GROUP BY p.\"product_id\" ORDER BY p.\"product_id\"") t0 t1
  ~= (sql%([PICKING_LINE_schema, INVENTORY_schema]) "WITH order_products AS (SELECT pl.\"product_id\" AS product_id, pl.\"order_id\" AS order_id, SUM(pl.\"qty\") AS order_qty FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\" AS pl GROUP BY pl.\"product_id\", pl.\"order_id\"), inventory_fifo AS (SELECT i.\"PRODUCTID\" AS product_id, i.\"QUANTITY\" AS available_qty, i.\"PURCHASEDATE\", ROW_NUMBER() OVER (PARTITION BY i.\"PRODUCTID\" ORDER BY i.\"PURCHASEDATE\", i.\"QUANTITY\") AS rn FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"INVENTORY\" AS i), matched AS (SELECT op.product_id, op.order_id, op.order_qty, COALESCE(inv.available_qty, 0) AS available_qty, LEAST(op.order_qty, COALESCE(inv.available_qty, 0)) AS picked_qty FROM order_products AS op LEFT JOIN inventory_fifo AS inv ON op.product_id = inv.product_id), pick_pct AS (SELECT product_id, CASE WHEN order_qty > 0 THEN CAST(picked_qty AS DOUBLE PRECISION) / order_qty ELSE 0 END AS pick_percentage FROM matched) SELECT product_id AS PRODUCT_NAME, AVG(pick_percentage) AS AVG_PICK_PERCENTAGE FROM pick_pct GROUP BY product_id ORDER BY product_id") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local273_eq_1_2
