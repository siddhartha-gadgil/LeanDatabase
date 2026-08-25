import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local274 — crossskill equivalence(s)

Question: Which products were picked for order 421, and what is the average number of units picked for each product, using FIFO (First-In, First-Out) method?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local274

CREATE TABLE PRODUCTS («id» INT, «name» STRING, «group_id» INT)
CREATE TABLE PICKING_LINE («picklist_id» INT, «line_no» INT, «location_id» INT, «order_id» INT, «product_id» INT, «qty» FLOAT)

theorem eq_0_1 :
    sql%([PRODUCTS_schema, PICKING_LINE_schema]) "SELECT p.\"NAME\" AS PRODUCT_NAME, AVG(pl.\"qty\") AS AVG_UNITS_PICKED FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\" AS pl JOIN \"ORACLE_SQL\".\"ORACLE_SQL\".\"PRODUCTS\" AS p ON pl.\"product_id\" = p.\"ID\" WHERE pl.\"order_id\" = 421 GROUP BY p.\"NAME\" ORDER BY AVG_UNITS_PICKED DESC" = sql%([PRODUCTS_schema, PICKING_LINE_schema]) "SELECT p.\"NAME\" AS \"PRODUCT_NAME\", AVG(pl.\"qty\") AS \"AVG_UNITS_PICKED\" FROM \"ORACLE_SQL\".\"ORACLE_SQL\".\"PICKING_LINE\" AS pl JOIN \"ORACLE_SQL\".\"ORACLE_SQL\".\"PRODUCTS\" AS p ON pl.\"product_id\" = p.\"ID\" WHERE pl.\"order_id\" = 421 GROUP BY p.\"NAME\", pl.\"product_id\" ORDER BY pl.\"product_id\"" := by
  first | sql_equiv | sorry

end Bench_sf_local274
