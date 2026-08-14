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
-- then finish the projection per-row. Guarded by `done`: it backtracks whenever it does not fully
-- close, so it is harmless to every hypothesis-free proof.
macro "sql_hypothesis" : tactic => `(tactic|
  (apply TypedRelation.ext (by rfl)
   simp only [TypedRelation.mapByList, restriction]
   try (rw [Finset.filter_true_of_mem (fun _ _ => by grind +locals)])
   first
     | (apply Finset.image_congr; intro _ _; grind +locals)
     | (sql_simp; grind +locals)
   done))

-- Projection reduction: a `SELECT`-projection equality whose two sides agree column-by-column but
-- where a projected expression differs by ring-equal arithmetic (`round (S*100/C) = round (100*S/C)`,
-- operand reordering, …). Unfold `mapByList`/`restriction` to expose the `Finset.image`, reduce to one
-- output row, split the tuple into its columns (`cons_inj`), and close each by `grind`. Guarded by
-- `done` so it backtracks and stays harmless to proofs it does not fully close.
macro "sql_project" : tactic => `(tactic|
  (apply TypedRelation.ext (by rfl)
   simp only [TypedRelation.mapByList, restriction]
   apply Finset.image_congr; intro _ _
   simp only [TypedTupleOfList.cons_inj, TypedTupleOfList.cons_nil_inj, true_and, and_true]
   grind +locals
   done))

-- Functional-dependency reduction: `GROUP BY a, b ≡ GROUP BY a` on the per-group `COUNT(*)`, given a
-- `FuncDepEq`/`FUNCDEP a -> b`/`UNIQUE` hypothesis. Reduce to the group-count equality, then close via
-- `cnt_eq_of_partition_eq` — the finer and coarse keys induce the same partition, discharged by
-- specialising the (name-free) FD hypothesis at the two rows. `done`-guarded; harmless otherwise.
macro "sql_funcdep" : tactic => `(tactic|
  (apply TypedRelation.ext (by rfl)
   simp only [TypedRelation.mapByList]
   apply Finset.image_congr; intro x hx
   simp only [TypedTupleOfList.cons_inj, TypedTupleOfList.cons_nil_inj, true_and, and_true,
     Int.ofNat.injEq]
   apply cnt_eq_of_partition_eq (t := x)
   intro s hs
   simp only [TypedTupleOfList.cons_inj, TypedTupleOfList.cons_nil_inj]
   have := (‹FuncDepEq _ _ _› : FuncDepEq _ _ _) s hs x hx
   constructor <;> intro h <;> grind
   done))

-- Bijection reduction: `COUNT(DISTINCT a) = COUNT(DISTINCT b)` given a `BIJECTION a b` hypothesis (the
-- columns induce the same partition). Reduce to `card (image …) = card (image …)`, then
-- `card_image_eq_of_fiber` with the partition discharged from the (name-free) bijection hypothesis. Self-
-- gates: `card_image_eq_of_fiber` only unifies with a distinct-count goal. `done`-guarded, harmless else.
macro "sql_bijection" : tactic => `(tactic|
  (apply TypedRelation.ext (by rfl)
   simp only [TypedRelation.mapByList, restriction]
   apply Finset.image_congr; intro x hx
   simp only [TypedTupleOfList.cons_inj, TypedTupleOfList.cons_nil_inj, true_and, and_true,
     relCountDistinct, Int.ofNat.injEq]
   apply card_image_eq_of_fiber
   intro a ha b hb
   simp only [TypedAgg.group, restriction, Finset.mem_filter] at ha hb
   first
     | exact (‹SamePartition _ _ _› : SamePartition _ _ _) a ha.1.1 b hb.1.1
     | exact (‹SamePartition _ _ _› : SamePartition _ _ _) a ha.1 b hb.1
     | exact (‹SamePartition _ _ _› : SamePartition _ _ _) a ha b hb
   done))

macro "sql_equiv" : tactic => `(tactic|
  (
   repeat (first
     | refine limit_congr ?_
     | sql_outer_join
     | sql_hypothesis
     | sql_bijection
     | sql_funcdep
     | sql_project
     | (apply TypedRelation.ext <;> try rfl)
     | refine Finset.filter_congr (fun _ _ => ?_)
     | refine Finset.image_congr (fun _ _ => ?_)
     | sql_simp
     | (apply funext; intro _))
   all_goals (first
     | grind +locals
     | (apply Finset.ext; sql_simp; grind +locals))))

end LeanDatabase.SQLEquiv
