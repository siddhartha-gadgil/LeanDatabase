import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Window functions (`ROW_NUMBER`/`RANK`/`LAG`/… `OVER (…)`)

These are **order-dependent** — their value depends on the row order within a partition — but a
`TypedRelation`'s rows are an unordered `Finset`. So there is no correct concrete definition, and we
model them **opaquely** (`Scalar.winOf`, keyed by a per-function marker + the PARTITION BY/ORDER BY key
values). Two queries using the *same* window expression cancel by congruence; *different* window specs
stay unprovable — never silently equated. This is the same soundness stance as `LIMIT`: elaborate and
prove the trivially-true, refuse to invent the rest.
-/

namespace Window

CREATE TABLE T (a INT, b INT, g STRING)

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

end Window
