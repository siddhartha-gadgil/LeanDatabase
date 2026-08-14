import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000

/-!
# Cross-row hypotheses: `FUNCDEP` and `UNIQUE`

A *functional dependency* `a → b` ("any two rows agreeing on `a` agree on `b`") and *uniqueness* of a
key are **two-row** facts, so they can't be a per-row `HYPOTHESIS T "pred"`. They are declared with
their own sugar — `HYPOTHESIS fd : T FUNCDEP a -> b` / `HYPOTHESIS u : T UNIQUE k` — which elaborate to
`FuncDepEq` (in `Constraints.lean`), the same `Prop` the bridge lemma `cnt_eq_of_partition_eq` consumes.

Given the FD, `GROUP BY a, b` collapses to `GROUP BY a` (equal per-group `COUNT(*)`), because the finer
key `(a,b)` and the coarse key `a` cut the table into the same row-classes.
-/

namespace FunctionalDependency

CREATE TABLE Emp (a INT, b INT)

HYPOTHESIS emp_fd : Emp FUNCDEP a -> b       -- a → b
HYPOTHESIS emp_key : Emp UNIQUE a            -- a is a key (a → whole row)

/-- `GROUP BY a, b` collapses to `GROUP BY a` **given the FD `a → b`** — closed by `sql_equiv`'s
`sql_funcdep` branch (reduce to the group-count, then the FD makes the two keys induce one partition). -/
theorem groupby_collapse_under_fd (t : TableRel Emp_schema) (hfd : emp_fd t) :
    (sql%([Emp_schema]) "SELECT a, COUNT(*) AS c FROM Emp GROUP BY a, b") t
      = (sql%([Emp_schema]) "SELECT a, COUNT(*) AS c FROM Emp GROUP BY a") t := by
  sql_equiv

end FunctionalDependency
