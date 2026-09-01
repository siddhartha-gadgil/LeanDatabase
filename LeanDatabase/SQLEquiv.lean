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

/-- `sql_membership` under a hard budget — a *probe*, run on goals that may well not close.

`set_option maxHeartbeats … in` does not bound a macro-expanded tactic here, so the budget is imposed
directly; `withCurrHeartbeats` restarts the count so it is measured from this point rather than from
whatever the pipeline already spent. The bound is the whole point: unbounded, this spends a full
`grind` on the membership expansion of every goal it cannot close, minutes at a time on a join-heavy
pair — and a membership proof that has not landed within this much is not going to. -/
elab "sql_membership_probe" n:(num)? : tactic => do
  let budget := (n.map (·.getNat)).getD 20000
  let tac ← `(tactic| sql_membership)
  -- Exhausting the budget must read as "this branch did not work", not as an error: a `deterministic
  -- timeout` thrown from here propagates straight through the enclosing `try` and aborts the whole
  -- proof, which is what turned every pair the probe could not close into a reported timeout.
  try
    Lean.Core.withCurrHeartbeats <|
      withTheReader Lean.Core.Context
        (fun ctx => { ctx with maxHeartbeats := budget * 1000 }) <|
        Lean.Elab.Tactic.evalTactic tac
  catch _ =>
    throwError "sql_membership_probe: did not close the goal within its budget"

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

macro "sql_equiv" : tactic => `(tactic|
  first
  -- Nullability-tolerant goal (`dataEqErased`, from a `Option τ` vs `τ` output-type mismatch): unfold to
  -- the erased-row image equality. Erasure is computable, so a constant-relation erased goal `decide`s
  -- outright here (a terminal branch, since it fully closes); non-constant erased goals fall through to
  -- the pipeline, which unfolds `dataEqErased` again and reduces the image equality like any set equality.
  | (sql_guard_erased; simp only [LeanDatabase.dataEqErased]; sql_erased_decide; done)
  | (
   try (simp only [LeanDatabase.dataEqErased])
   -- Is this even an equivalence? Aborts with the offending database if not; otherwise a no-op.
   sql_disprove
   -- Constant relations (`VALUES` with no table reference) are a *decidable* finite computation — settle
   -- them directly rather than searching. No-op (fails fast) once any base table is involved.
   try sql_decide
   -- data-equivalence goal (`A ~= B`): unfold to `A.rows = B.rows` (labels/aliases erased), then reduce.
   try (simp only [LeanDatabase.dataEq])
   -- GROUP-BY key elimination on the clean projection goal, before the loop reshapes it. Deterministic,
   -- and ahead of the structural route: on a wide `NATURAL JOIN` with a `HAVING`, the membership
   -- expansion is enormous while this closes the goal outright.
   try sql_group_key
   -- On a very large goal (a seven-table join, say) the congruence loop below is dominated by
   -- `sql_simp`, whose `simp_all` runs out of budget before reaching the closers. The structural
   -- route rewrites instead of searching, so it is the one worth spending a huge goal's budget on.
   try sql_big_goal
   -- The structural route, on the goal as it stands. It is also a closing fallback below, but by then
   -- the loop has applied `TypedRelation.ext`/`Finset.image_congr` and the `A.rows = B.rows` shape the
   -- membership laws need is gone — a join equivalence closes here or not at all. Closes or backtracks.
   -- Capped: this runs on *every* goal, and on one it cannot close its `grind` would otherwise spend
   -- the whole (very large) budget before the rest of the pipeline gets a turn.
   try sql_membership_probe
   -- WHERE-congruence, deterministically, before the loop can reshape the per-row goal.
   try sql_where
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
     -- GROUP-BY key elimination, in case the loop reshaped the goal past the early attempt.
     | sql_group_key
     -- Last: the structural membership route. Tried after the cheap closers because it rewrites the
     -- goal wholesale; when they fail on a join/projection equality, this is what has a shape `grind`
     -- can actually reason about.
     | sql_membership
     -- Last resort: the constraints alone (a pair that is an equivalence *only* modulo its keys and
     -- foreign keys, with no rewriting needed beyond them).
     | sql_constraints)))

end LeanDatabase.SQLEquiv
