import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 30 — scalar subqueries in `SELECT` (Phase 3.4)

A scalar subquery `(SELECT AGG(x) FROM t [WHERE p])` in a select list is a whole-relation aggregate
(`relSum`/`relCount`/`relCountDistinct`). **Uncorrelated**, it is a single `Int` constant broadcast
onto every row. **Correlated** (its inner `WHERE` references the outer row), it is elaborated inside
the projection so the outer columns bind — the value is then computed per outer row.
-/

namespace Example30

CREATE TABLE orders (id INT, amt INT, region STRING)
CREATE TABLE lines (oid INT, qty INT)

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

/-- A **correlated** subquery: the inner `WHERE l.oid = o.id` references the outer row `o`, so the
per-order line total is computed per outer row. The outer `WHERE` conjuncts commute. -/
theorem correlated_subquery :
    sql%([orders_schema, lines_schema])
        "SELECT o.id, (SELECT SUM(l.qty) FROM lines AS l WHERE l.oid = o.id) AS total FROM orders AS o WHERE o.amt > 1 AND o.amt < 9"
      = sql%([orders_schema, lines_schema])
        "SELECT o.id, (SELECT SUM(l.qty) FROM lines AS l WHERE l.oid = o.id) AS total FROM orders AS o WHERE o.amt < 9 AND o.amt > 1" := by
  sql_equiv

end Example30
