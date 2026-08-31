import LeanDatabase.RelationalAlgebra
import LeanDatabase.Operators.Aggregate
import LeanDatabase.CurriedPredicates
import LeanDatabase.SQLToolbox
import LeanDatabase.Operators
import LeanDatabase.Constraints
import LeanDatabase.Parser.Context
import LeanDatabase.DataEquiv
import LeanDatabase.Membership

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

/-- **The membership route** — the informed reduction, and the analogue of what VeriEQL hands to Z3.

`A ~= B` is `A.rows = B.rows`, which `Finset.ext` turns into `∀ x, x ∈ A.rows ↔ x ∈ B.rows`; the
`sql_mem` laws (`LeanDatabase/Membership.lean`) then push `∈` through the algebra — `σ` to `∧`, `π`
and `×` to `∃`, `∪` to `∨` — and decompose the row equalities that fall out into per-column ones,
until only memberships in *base* tables remain. What is left is a first-order formula over rows, which
`grind` closes; unlike their bounded encoding, the result holds for every database.

`List.cons_append`/`List.nil_append` are essential rather than cosmetic: a join's column list reaches
the goal as `l₁ ++ l₂` inside the `DecidableEq` instance while the ambient type is already the literal
list, and until those agree *no* membership lemma unifies — not even `Finset.mem_image`. -/
macro "sql_membership" : tactic => `(tactic|
  (try simp only [LeanDatabase.dataEq]
   first
     | apply Finset.ext
     | (apply TypedRelation.ext (by rfl); apply Finset.ext)
     | skip
   try intro _
   -- Two passes: the first makes the appended column lists literal (so the membership lemmas can
   -- unify at all), the second pushes `∈` through the algebra and splits the row equalities.
   try simp only [List.cons_append, List.nil_append]
   try simp only [sql_mem, Finset.mem_image, Finset.mem_filter, Finset.mem_product,
     Finset.mem_union, Finset.mem_inter, Finset.mem_sdiff, Prod.exists,
     decide_eq_true_eq, Bool.and_eq_true, Bool.or_eq_true, Bool.not_eq_true]
   first | grind +locals | tauto))

macro "sql_equiv" : tactic => `(tactic|
  (
   -- data-equivalence goal (`A ~= B`): unfold to `A.rows = B.rows` (labels/aliases erased), then reduce.
   try (simp only [LeanDatabase.dataEq])
   repeat (first
     | refine limit_congr ?_
     | sql_outer_join
     | sql_hypothesis
     | sql_bijection
     | sql_funcdep
     | sql_project
     -- WHERE-congruence: reduce `σ_p R = σ_q R` to the per-row predicate equality `p t = q t`, which
     -- `grind +locals` then closes — this is where optimizer-style rewrites land (constant propagation
     -- into opaque scalars, absorption/comparison-merge under a HYPOTHESIS). See `restriction_*` in
     -- SQLToolbox. Must precede `TypedRelation.ext`, which would first split off `.rows` and hide the
     -- `σ_p R = σ_q R` shape.
     | refine restriction_congr _ _ _ (fun _ _ => ?_)
     | (apply TypedRelation.ext <;> try rfl)
     | refine Finset.filter_congr (fun _ _ => ?_)
     | refine Finset.image_congr (fun _ _ => ?_)
     | sql_simp
     | (apply funext; intro _))
   -- Closing fallbacks — tried in order, each fully closes the goal or backtracks (so appending more
   -- only ever proves *more*, never breaks an existing proof). Covers: relation/function/Finset
   -- equalities, the membership route (`x ∈ σ/π/∪` unfolds to `∧`/`∨`), and arithmetic residues.
   all_goals (first
     | grind +locals
     | (apply Finset.ext; (try sql_simp); grind +locals)
     | (apply Finset.ext; intro _; (try sql_simp); grind +locals)
     | (apply TypedRelation.ext (by rfl); (try sql_simp); grind +locals)
     | (funext _; (try sql_simp); grind +locals)
     | (apply Finset.ext; intro _
        simp only [Finset.mem_filter, Finset.mem_image, Finset.mem_union, Finset.mem_inter,
          Finset.mem_sdiff]
        (try sql_simp); first | grind +locals | tauto)
     | (sql_simp; first | grind +locals | tauto | omega)
     | (funext _; apply Finset.ext; intro _; (try sql_simp); first | grind +locals | tauto)
     -- Last: the structural membership route. Tried after the cheap closers because it rewrites the
     -- goal wholesale; when they fail on a join/projection equality, this is what has a shape `grind`
     -- can actually reason about.
     | sql_membership)))

end LeanDatabase.SQLEquiv
