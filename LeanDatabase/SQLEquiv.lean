import LeanDatabase.RelationalAlgebra
import LeanDatabase.TypedAggregation
import LeanDatabase.CurriedPredicates
import LeanDatabase.SQLToolbox

open LeanDatabase LeanDatabase.TypedAgg

/-!
This file is meant to be imported by the examples, to give them access to the `sql_equiv` tactic.
This file would contain all dependencies imported, to give all theorems and definitions for `simp` and `grind` to work in `sql_equiv`.
-/

namespace LeanDatabase.SQLEquiv

/-- `sql_simp` — the normalisation pass: unfold the `@[simp]` query/operator definitions and
fire the `@[simp]`-tagged database identities, using local hypotheses (`simp_all`) to discharge
side-conditions like `t ∈ table`. It puts a goal in a shape `grind` can finish. -/
macro "sql_simp" : tactic => `(tactic| simp_all)

/-!
Creating a `sql_equiv` tactic to prove equivalences between SQL queries, by doing `simp` and `grind` using definitions produced and grinding on locals.

Idea is to use JUST this tactic to prove equivalences between SQL queries.

Possible future work: extend this tactic to also be able to disprove using `plausible` (counterexample search).
-/

macro "sql_equiv" : tactic => `(tactic|
  first
    | grind +locals
    | (sql_simp; grind +locals)
    -- for tackling Example11: reduce a relation eq to per-row (so `sql_simp` gets the
    | (apply TypedRelation.ext <;>
        first
          | rfl
          | (refine Finset.filter_congr (fun o ho => ?_); sql_simp <;> grind +locals)
          | (sql_simp <;> grind +locals))
    | (sql_simp; done)
    | fail "sql_equiv failed to prove equivalence"
)

end LeanDatabase.SQLEquiv
