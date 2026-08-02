import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 27 — `LEFT`/`RIGHT`/`FULL [OUTER] JOIN` in SQL surface syntax

Phase 5 codegen: the outer joins can now be written directly in `sql%`. The parser elaborates
`A LEFT JOIN B ON …` to the `leftOuterJoin` operator (RIGHT/FULL likewise), and the null-padded
side's columns become nullable (`Option`) in the output schema. `OUTER` is an accepted synonym, and
the `ON` condition is a two-tuple predicate over the left and right rows (so unqualified column names
resolve against the right schema just as they do in `WHERE EXISTS` correlations).

The operator result (a `Fin.append`-shaped schema) is reconciled back to the canonical
`colTypeOfList` list form by `ofOuterLeft`/`ofOuterRight`/`ofOuterFull` (`Parser/Query.lean`), so
`WHERE` and column-projection *over* an outer-join result elaborate too — the null-padded side's
columns are nullable (`Option`), reachable via `IS NULL`/`COALESCE`.
-/

namespace Example27

CREATE TABLE customers (id INT)
CREATE TABLE orders (cust_id INT, amount INT)

/-- `LEFT JOIN` and `LEFT OUTER JOIN` are synonyms, and unqualified/qualified `ON` agree (both
resolve to `customers.id = orders.cust_id`). -/
theorem left_outer_synonym :
    sql%([customers_schema, orders_schema]) "SELECT * FROM customers LEFT JOIN orders ON id = cust_id"
      = sql%([customers_schema, orders_schema]) "SELECT * FROM customers LEFT OUTER JOIN orders ON customers.id = orders.cust_id" := by
  sql_equiv

/-- `RIGHT [OUTER] JOIN` parses to `rightOuterJoin`. -/
theorem right_outer_synonym :
    sql%([customers_schema, orders_schema]) "SELECT * FROM customers RIGHT JOIN orders ON id = cust_id"
      = sql%([customers_schema, orders_schema]) "SELECT * FROM customers RIGHT OUTER JOIN orders ON id = cust_id" := by
  sql_equiv

/-- `FULL [OUTER] JOIN` parses to `fullOuterJoin`. -/
theorem full_outer_synonym :
    sql%([customers_schema, orders_schema]) "SELECT * FROM customers FULL JOIN orders ON id = cust_id"
      = sql%([customers_schema, orders_schema]) "SELECT * FROM customers FULL OUTER JOIN orders ON id = cust_id" := by
  sql_equiv

/-- A real rewrite over a parsed outer join: the `ON` equality commutes. -/
theorem on_condition_commutes :
    sql%([customers_schema, orders_schema]) "SELECT * FROM customers LEFT JOIN orders ON id = cust_id"
      = sql%([customers_schema, orders_schema]) "SELECT * FROM customers LEFT JOIN orders ON cust_id = id" := by
  sql_equiv

/-- `WHERE` *over* a LEFT JOIN result: the (now nullable) right column is reachable via `IS NULL`,
and the `WHERE` conjuncts commute — so projection/`WHERE` over an outer join really elaborate. -/
theorem where_over_left_join_commutes :
    sql%([customers_schema, orders_schema])
        "SELECT * FROM customers LEFT JOIN orders ON id = cust_id WHERE amount IS NULL AND id > 3"
      = sql%([customers_schema, orders_schema])
        "SELECT * FROM customers LEFT JOIN orders ON id = cust_id WHERE id > 3 AND amount IS NULL" := by
  sql_equiv

/-- `COALESCE` over a nullable right column, projected out of a LEFT JOIN. -/
theorem coalesce_over_left_join :
    sql%([customers_schema, orders_schema])
        "SELECT COALESCE(amount, 0) AS amt FROM customers LEFT JOIN orders ON id = cust_id WHERE id > 1 AND id < 9"
      = sql%([customers_schema, orders_schema])
        "SELECT COALESCE(amount, 0) AS amt FROM customers LEFT JOIN orders ON id = cust_id WHERE id < 9 AND id > 1" := by
  sql_equiv

end Example27
