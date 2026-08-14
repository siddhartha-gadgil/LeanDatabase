import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Common table expressions (`WITH`)

A non-recursive `WITH c AS (…) …` is **query composition**: each CTE body elaborates to a relation and
is *inlined* at every reference (see `elabSqlQueryCore` in `Parser/Query.lean` — there is no runtime
`WITH` operator, so this is a parser construct, not an `Operators/` definition). Because inlining is
transparent, a CTE is provably equal to the query with its body substituted in — which is exactly the
rewrite crossskill variants use ("factor the subquery into a CTE"). `sql_equiv` proves these directly.
-/

namespace CTE

CREATE TABLE Orders (id INT, amount INT, status STRING)

/-- A projecting CTE is just its body. -/
theorem cte_project :
    sql%([Orders_schema]) "WITH c AS (SELECT id, amount FROM Orders) SELECT id, amount FROM c"
      = sql%([Orders_schema]) "SELECT id, amount FROM Orders" := by sql_equiv

/-- A filtered CTE followed by a further filter fuses into one combined `WHERE`. -/
theorem cte_filter_fuses :
    sql%([Orders_schema])
        "WITH c AS (SELECT * FROM Orders WHERE amount > 100) SELECT * FROM c WHERE status = 'x'"
      = sql%([Orders_schema]) "SELECT * FROM Orders WHERE amount > 100 AND status = 'x'" := by
  sql_equiv

/-- Chained CTEs (a later one references an earlier one) inline transitively. -/
theorem cte_chained :
    sql%([Orders_schema])
        "WITH a AS (SELECT * FROM Orders WHERE amount > 100),
              b AS (SELECT * FROM a WHERE status = 'x')
         SELECT id FROM b"
      = sql%([Orders_schema]) "SELECT id FROM Orders WHERE amount > 100 AND status = 'x'" := by
  sql_equiv

end CTE
