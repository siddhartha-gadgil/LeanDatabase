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

Note on scope: whole-relation (`SELECT *`) outer joins parse and elaborate; column-projection and
`WHERE` *over* an outer-join result need a `Fin.append`→`colTypeOfList` schema reconciliation (the
inner join gets this for free via `TypedRelationOfList.append`) — that is the next codegen step.
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

end Example27
