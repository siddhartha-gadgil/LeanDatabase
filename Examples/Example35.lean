import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Common table expressions (`WITH`) and window functions

Two query-composition features, one file.

**CTEs.** A non-recursive `WITH c AS (…) …` is inlined at each reference (see `elabSqlQueryCore` in
`Parser/Query.lean` — a parser construct, no runtime operator). Inlining is transparent, so a CTE is
provably equal to the query with its body substituted in.

**Window functions.** `ROW_NUMBER`/`RANK`/`LAG`/… `OVER (…)` are *order-dependent*, but a
`TypedRelation`'s rows are an unordered `Finset` — no correct concrete definition exists, so we model
them **opaquely** (`Scalar.winOf`, keyed by a per-function marker + the PARTITION/ORDER key values).
Same window on both sides cancels by congruence; different specs stay unprovable (never silently
equated — the `LIMIT` soundness stance).
-/

namespace CTEWindow

CREATE TABLE Orders (id INT, amount INT, status STRING)
CREATE TABLE T (a INT, b INT, g STRING)

/-! ## CTEs -/

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

/-- An explicit CTE column list `c (x, y) AS (…)` renames the body's output columns. -/
theorem cte_column_list :
    sql%([Orders_schema]) "WITH c (x, y) AS (SELECT id, amount FROM Orders) SELECT x, y FROM c"
      = sql%([Orders_schema]) "SELECT id AS x, amount AS y FROM Orders" := by sql_equiv

/-! ## Window functions -/

/-- The same window on both sides cancels — a rewrite around an untouched window proves. -/
theorem same_window_reorders_where :
    sql%([T_schema])
        "SELECT ROW_NUMBER() OVER (PARTITION BY g ORDER BY a DESC) AS rn FROM T WHERE a > 1 AND b > 2"
      = sql%([T_schema])
        "SELECT ROW_NUMBER() OVER (PARTITION BY g ORDER BY a DESC) AS rn FROM T WHERE b > 2 AND a > 1" := by
  sql_equiv

/-- `RANK`/`LAG` likewise elaborate and cancel when identical. -/
theorem rank_lag_same :
    sql%([T_schema])
        "SELECT RANK() OVER (ORDER BY a) AS r, LAG(b, 1) OVER (PARTITION BY g ORDER BY a) AS l FROM T"
      = sql%([T_schema])
        "SELECT RANK() OVER (ORDER BY a) AS r, LAG(b, 1) OVER (PARTITION BY g ORDER BY a) AS l FROM T" := by
  sql_equiv

end CTEWindow
