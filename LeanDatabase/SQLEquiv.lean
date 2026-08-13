import LeanDatabase.RelationalAlgebra
import LeanDatabase.Operators.Aggregate
import LeanDatabase.CurriedPredicates
import LeanDatabase.SQLToolbox
import LeanDatabase.Operators
import LeanDatabase.Constraints
import LeanDatabase.Parser.Context

open LeanDatabase LeanDatabase.TypedAgg

/-!
This file is meant to be imported by the examples, to give them access to the `sql_equiv` tactic.
This file would contain all dependencies imported, to give all theorems and definitions for `simp` and `grind` to work in `sql_equiv`.

## What `sql_equiv` proves

`sql_equiv` proves **set-equivalence**: the two queries denote the *same result set*, over a
`TypedRelation` whose `rows` is a `Finset` and whose base tables are assumed to have distinct rows.
A proved `sql%(…) = sql%(…)` is therefore **not** a claim about bag (multiset) or ordered SQL:
-/

namespace LeanDatabase.SQLEquiv

/-- `sql_simp` — the normalisation pass: unfold the `@[simp]` query/operator definitions and
fire the `@[simp]`-tagged database identities, using local hypotheses (`simp_all`) to discharge
side-conditions like `t ∈ table`. It puts a goal in a shape `grind` can finish. -/
macro "sql_simp" : tactic => `(tactic| simp_all [Finset.filter_filter, Finset.image_image])

-- Outer-join reduction: `A LEFT JOIN B WHERE right IS NULL` ≡ the null-padded anti-join. The broad
-- `sql_simp` rewrites `Option.isNone` away from the pushdown lemma's LHS, so it can't fire there;
-- this branch unfolds *only* `restriction`/`isNull` and lets the tagged lemma reduce the join. It is
-- guarded by `done` so it backtracks (restoring the goal) whenever it does not fully close — hence
-- harmless to every non-outer-join proof.
macro "sql_outer_join" : tactic => `(tactic|
  (apply TypedRelation.ext (by rfl)
   simp only [restriction, isNull, leftOuterJoin_filter_isNull_eq_antijoin_pad]
   done))

-- Data-hypothesis reduction: an equivalence that holds only *given* `HYPOTHESIS` facts (each a
-- reducible `∀ row ∈ t.rows, p row`, so `grind +locals` e-matches it at the row on its own). We expose
-- the underlying `Finset.image`/`Finset.filter`, drop any `WHERE` that a hypothesis makes redundant,
-- then finish the projection per-row — deliberately *not* `funext`-ing the output tuple (that explodes
-- it into `match`-on-`Fin` goals `grind` can't close). Guarded by `done`: it backtracks whenever it
-- does not fully close, so it is harmless to every hypothesis-free proof.
macro "sql_hypothesis" : tactic => `(tactic|
  (apply TypedRelation.ext (by rfl)
   simp only [TypedRelation.mapByList, restriction]
   try (rw [Finset.filter_true_of_mem (fun _ _ => by grind +locals)])
   first
     | (apply Finset.image_congr; intro _ _; grind +locals)
     | (sql_simp; grind +locals)
   done))

macro "sql_equiv" : tactic => `(tactic|
  (
   repeat (first
     | refine limit_congr ?_
     | sql_outer_join
     | sql_hypothesis
     | (apply TypedRelation.ext <;> try rfl)
     | refine Finset.filter_congr (fun _ _ => ?_)
     | refine Finset.image_congr (fun _ _ => ?_)
     | sql_simp
     | (apply funext; intro _))
   all_goals (first
     | grind +locals
     | (apply Finset.ext; sql_simp; grind +locals))))

end LeanDatabase.SQLEquiv
