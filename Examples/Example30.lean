import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 30 — scalar subqueries in `SELECT` (Phase 3.4)

An **uncorrelated** scalar subquery `(SELECT AGG(x) FROM t [WHERE p])` in a select list is a
whole-relation aggregate (`relSum`/`relCount`/`relCountDistinct`) — a single `Int` constant broadcast
onto every output row. The inner `WHERE` is evaluated against the inner table alone (correlated
subqueries, which reference the outer row, are a follow-up).
-/

namespace Example30

CREATE TABLE orders (id INT, amt INT, region STRING)

/-- `SUM` subquery as a constant column, alongside an ordinary one; the outer `WHERE` commutes. -/
theorem sum_subquery :
    sql%([orders_schema]) "SELECT id, (SELECT SUM(amt) FROM orders) AS total FROM orders WHERE id > 1 AND id < 9"
      = sql%([orders_schema]) "SELECT id, (SELECT SUM(amt) FROM orders) AS total FROM orders WHERE id < 9 AND id > 1" := by
  sql_equiv

/-- A `COUNT(DISTINCT …)` subquery with its own (uncorrelated) `WHERE`. -/
theorem count_distinct_subquery :
    sql%([orders_schema]) "SELECT (SELECT COUNT(DISTINCT region) FROM orders WHERE amt > 0) AS c FROM orders WHERE id > 3"
      = sql%([orders_schema]) "SELECT (SELECT COUNT(DISTINCT region) FROM orders WHERE amt > 0) AS c FROM orders WHERE id > 3" := by
  sql_equiv

end Example30
