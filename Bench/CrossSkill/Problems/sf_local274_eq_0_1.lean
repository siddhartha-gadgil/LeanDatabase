import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local274_eq_0_1

CREATE TABLE PRODUCTS («id» INT, «name» STRING, «group_id» INT)
CREATE TABLE PICKING_LINE («picklist_id» INT, «line_no» INT, «location_id» INT, «order_id» INT, «product_id» INT, «qty» FLOAT)

theorem eq (t0 : TableRel PRODUCTS_schema) (t1 : TableRel PICKING_LINE_schema) :
    (sql%([PRODUCTS_schema, PICKING_LINE_schema]) "SELECT p.\"NAME\" AS PRODUCT_NAME, AVG(pl.\"qty\") AS AVG_UNITS_PICKED FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\" AS pl JOIN \"ORACLE_SQL\".\"ORACLE_SQL\".\"PRODUCTS\" AS p ON pl.\"product_id\" = p.\"ID\" WHERE pl.\"order_id\" = 421 GROUP BY p.\"NAME\" ORDER BY AVG_UNITS_PICKED DESC") t0 t1
  = (sql%([PRODUCTS_schema, PICKING_LINE_schema]) "SELECT p.\"NAME\" AS \"PRODUCT_NAME\", AVG(pl.\"qty\") AS \"AVG_UNITS_PICKED\" FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\" AS pl JOIN \"ORACLE_SQL\".\"ORACLE_SQL\".\"PRODUCTS\" AS p ON pl.\"product_id\" = p.\"ID\" WHERE pl.\"order_id\" = 421 GROUP BY p.\"NAME\", pl.\"product_id\" ORDER BY pl.\"product_id\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local274_eq_0_1
