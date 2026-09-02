import LeanDatabase.RelationalAlgebra
import LeanDatabase.Operators.Aggregate
import LeanDatabase.CurriedPredicates
import LeanDatabase.SQLToolbox
import LeanDatabase.Operators
import LeanDatabase.Constraints
import LeanDatabase.Parser.Context
import LeanDatabase.DataEquiv
import LeanDatabase.Membership
import LeanDatabase.Plausible.Tactic

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
-- GROUP-BY key elimination: two `GROUP BY`s whose keys induce the same partition (a constant or
-- functionally-determined key component was dropped). Expose the image, reduce to the per-row output
-- equality and its aggregate column, apply the aggregate congruence + `group_congr`, and close the
-- per-row key equivalence *deterministically* by `simp` (cons injectivity + the row's `WHERE`
-- membership) — no `grind`.
macro "sql_group_key" : tactic => `(tactic|
  (simp only [LeanDatabase.TypedRelation.mapByList_rows]
   apply Finset.image_congr; intro _ ht
   simp only [TypedTupleOfList.cons_inj, TypedTupleOfList.cons_nil_inj, true_and, and_true]
   -- `COUNT` returns `Nat` cast to `Int`; peel the cast so the count congruence unifies.
   try simp only [Nat.cast_inj, Int.ofNat.injEq, Int.natCast_inj]
   first
     -- SUM linearity: `SUM(a+b) = SUM(a)+SUM(b)` etc. — the `@[simp]` groupSum laws rewrite the LHS to
     -- match the RHS, closing by `rfl`. Deterministic, no `grind`.
     | (simp only [LeanDatabase.groupSum_add, LeanDatabase.groupSum_sub, LeanDatabase.groupSum_mul_left,
         LeanDatabase.groupSum_neg, LeanDatabase.groupSum_zero]; done)
     -- Key elimination: aggregate congruence → `group_congr` → per-row key equivalence closed by `simp`.
     | ((first
          | apply LeanDatabase.groupSum_congr | apply LeanDatabase.groupCount_congr
          | apply LeanDatabase.groupMaxInt_congr | apply LeanDatabase.groupMinInt_congr
          | apply LeanDatabase.groupAvg_congr)
        apply LeanDatabase.group_congr
        intro _ _
        simp_all only [restriction, Finset.mem_coe, Finset.mem_filter, decide_eq_true_eq,
          decide_eq_decide, TypedTupleOfList.cons_inj, TypedTupleOfList.cons_nil_inj, and_true,
          true_and])))

-- WHERE-congruence, closed in one step: reduce `σ_p R = σ_q R` to the per-row predicate equality and
-- close that. The loop below has the same congruence, but keeps rewriting the per-row goal afterwards
-- and can leave it in a shape `grind` no longer closes; applied once and closed immediately, it does.
-- `done`-guarded, so it backtracks and stays harmless to everything else.
macro "sql_where" : tactic => `(tactic|
  (refine restriction_congr _ _ _ (fun _ _ => ?_)
   grind +locals
   done))

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

/-- **Use the integrity constraints in context.** A key (`FuncDepEq k id`) says two rows agreeing on
`k` are the same row; a foreign key (`ForeignKey f g R S`) *supplies* a parent row for every child row
— which is exactly the side condition a join-elimination rewrite needs and the one thing no amount of
rewriting can invent. Both are `∀`/`∃` facts about the table variables, so they are handed to `grind`
with their definitions unfolded, rather than left as opaque hypotheses it cannot look inside. -/
macro "sql_constraints" : tactic => `(tactic|
  grind +locals [LeanDatabase.ForeignKey, LeanDatabase.FuncDepEq, LeanDatabase.SamePartition])

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
   first | grind +locals | sql_constraints | tauto))

-- Subquery-flattening (a derived table / subquery in FROM ≡ the inlined join). Like `sql_membership`,
-- but adds the `exists_eq_*`/`exists_and_*` laws — which collapse the intermediate row the derived
-- table introduces (`∃ v, … ∧ cons(…) = v`) so both sides reduce to the same first-order formula — and
-- closes with `aesop`, whose existential-witness search matches the join witnesses `grind` will not
-- chain. Kept SEPARATE from `sql_membership` (and tried after it): the extra `exists_*` rewrites derail
-- `grind` on some aggregate goals, and `aesop` is dear, so this only runs when the cheaper routes fail.
-- `synthInstance.maxHeartbeats` is raised because the wide membership `simp`/`aesop` blow the default.
-- `done`-guarded, so it backtracks and stays harmless to everything it does not fully close.
macro "sql_flatten" : tactic => `(tactic|
  set_option synthInstance.maxHeartbeats 1000000 in
  (try simp only [LeanDatabase.dataEq]
   first
     | apply Finset.ext
     | (apply TypedRelation.ext (by rfl); apply Finset.ext)
   try intro _
   try simp only [List.cons_append, List.nil_append]
   try simp only [sql_mem, Finset.mem_image, Finset.mem_filter, Finset.mem_product,
     Finset.mem_union, Finset.mem_inter, Finset.mem_sdiff, Prod.exists,
     decide_eq_true_eq, Bool.and_eq_true, Bool.or_eq_true, Bool.not_eq_true,
     exists_and_left, exists_and_right, exists_eq_left, exists_eq_right,
     exists_eq_left', exists_eq_right']
   aesop
   done))

-- `sql_membership` under a hard heartbeat budget: bounds the `grind` on the membership expansion so a
-- join-heavy pair it cannot close gives up instead of spending the whole (very large) budget. The
-- budget's timeout is a *deterministic* one and is uncatchable, so this branch is only for the
-- standalone census; `sql_equiv_safe` (used by `sql_equiv_llm`) omits it. See `sql_equiv_safe`.
elab "sql_membership_probe" n:(num)? : tactic => do
  let budget := (n.map (·.getNat)).getD 20000
  Lean.Core.withCurrHeartbeats <|
    withTheReader Lean.Core.Context
      (fun ctx => { ctx with maxHeartbeats := budget * 1000 }) <|
      Lean.Elab.Tactic.evalTactic (← `(tactic| sql_membership))

/-- On an oversized goal, go straight to the structural route and finish there — succeeding (and
closing the goal) or failing outright, so `sql_equiv`'s `try` moves on. Only the size test lives here;
`sql_membership` does the work. -/
elab "sql_big_goal" : tactic => do
  let ty ← Lean.Elab.Tactic.getMainGoal >>= (·.getType)
  if ty.approxDepth ≤ 96 then Lean.throwError "goal is not oversized"
  Lean.Elab.Tactic.evalTactic (← `(tactic| sql_membership_probe 400000))

-- Constant relations (`VALUES`, no table reference): a closed decidable prop, so `decide` settles it —
-- no search. Errors instantly on a real table binder, so it is a safe early attempt.
macro "sql_decide" : tactic => `(tactic| (try simp only [LeanDatabase.dataEq]; decide))

/-- `decide`, but ONLY when the goal is genuinely constant (no free variables). A `dataEqErased` goal
over a base table is `image eraseRow (…t0…) = …`; bare `decide` there tries to evaluate a symbolic
`Finset` and hangs unboundedly, so we gate on `hasFVar` and fall through otherwise. -/
elab "sql_erased_decide" : tactic => do
  let ty ← Lean.instantiateMVars (← Lean.Elab.Tactic.getMainGoal >>= (·.getType))
  if ty.hasFVar then Lean.throwError "erased goal is not constant"
  else Lean.Elab.Tactic.evalTactic (← `(tactic| decide))

/-- Fail unless the goal really is a `dataEqErased` equivalence.

Without it the branch below runs `simp only [dataEqErased]` on *every* goal. Even where that makes no
progress it perturbs the state enough that the alternatives `first` falls back to stop matching — a
plain `σ_p R = σ_q R` then no longer takes the WHERE-congruence branch it otherwise would. -/
elab "sql_guard_erased" : tactic => do
  let ty ← Lean.instantiateMVars (← (← Lean.Elab.Tactic.getMainGoal).getType)
  unless ty.isAppOf ``LeanDatabase.dataEqErased do
    throwError "not an erased-equivalence goal"

-- Shared head: unfold erased/data-eq goals, refute non-equivalences, settle constant relations, and
-- run the deterministic GROUP-BY key elimination before the loop can reshape the goal.
macro "sql_equiv_head" : tactic => `(tactic|
  (try (simp only [LeanDatabase.dataEqErased])
   sql_disprove
   try sql_decide
   try (simp only [LeanDatabase.dataEq])
   try sql_group_key))

-- The congruence/normalisation loop: repeatedly reshape both sides toward a comparable form. The
-- WHERE-congruence (`σ_p R = σ_q R` ↦ per-row `p t = q t`) precedes `ext`, which would hide that shape.
macro "sql_equiv_loop" : tactic => `(tactic|
  repeat (first
    | refine limit_congr ?_
    | sql_outer_join | sql_hypothesis | sql_bijection | sql_funcdep | sql_project
    | refine restriction_congr _ _ _ (fun _ _ => ?_)
    | (apply TypedRelation.ext <;> try rfl)
    | refine Finset.filter_congr (fun _ _ => ?_)
    | refine Finset.image_congr (fun _ _ => ?_)
    | sql_simp
    | (apply funext; intro _)))

-- Cheap closing fallbacks (relation/function/Finset equalities, GROUP-BY key elimination, arithmetic
-- residues) — each closes the goal or backtracks. No membership route: these can only fail *cleanly*.
macro "sql_cheap_closers" : tactic => `(tactic|
  first
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
    | sql_group_key)

-- Full `sql_equiv`: head + the structural membership route (bounded probe up front on the clean
-- `A.rows = B.rows` shape, unbounded in the closers) + loop + closers. The membership branches can hit
-- an *uncatchable* deterministic timeout on a pair they cannot close, so this is for standalone use and
-- the census; `sql_equiv_llm` runs `sql_equiv_safe`, which omits them and so always fails cleanly.
macro "sql_equiv" : tactic => `(tactic|
  first
  | (sql_guard_erased; simp only [LeanDatabase.dataEqErased]; sql_erased_decide; done)
  | (sql_equiv_head
     try sql_big_goal
     try sql_membership_probe
     try sql_where
     sql_equiv_loop
     all_goals (first | sql_cheap_closers | sql_membership | sql_constraints | sql_flatten)))

-- Membership-free `sql_equiv`: same pipeline without the structural route, so it can only fail
-- cleanly. `sql_equiv_llm` runs this first (then the LLM), so a genuine failure falls through reliably.
macro "sql_equiv_safe" : tactic => `(tactic|
  first
  | (sql_guard_erased; simp only [LeanDatabase.dataEqErased]; sql_erased_decide; done)
  | (sql_equiv_head
     try sql_where
     sql_equiv_loop
     all_goals (first | sql_cheap_closers | sql_constraints)))

end LeanDatabase.SQLEquiv
