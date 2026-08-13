import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000

/-!
# Bucket-2 (cross-row) hypotheses need **no new syntax** — reuse the existing `Constraints` defs

A *functional dependency* `a → b` ("any two rows agreeing on `a` agree on `b`") is a two-row fact,
so it can't be a per-row `HYPOTHESIS T "pred"`. But it is already a plain Lean `Prop` — `FuncDepEq`
in `Constraints.lean` — usable as an ordinary theorem antecedent, and the bridge lemma
`cnt_eq_of_partition_eq` (also there) turns it into a `GROUP BY`-granularity rewrite.

This validates the approach end-to-end: `GROUP BY a, b ≡ GROUP BY a` (on the `COUNT(*)` per group)
holds **given** `a → b`, proved with existing machinery only. The proof below is the raw, unsugared
form — a `HYPOTHESIS a -> b : Emp` surface form and a `sql_funcdep` tactic branch would hide the
boilerplate (the `cnt_eq_of_partition_eq` bridge + the component-wise partition argument).
-/

namespace FunctionalDependency

CREATE TABLE Emp (a INT, b INT)

/-- `GROUP BY a, b` collapses to `GROUP BY a` (same `COUNT(*)` per group) **given the FD `a → b`**:
the finer key `(a,b)` and the coarse key `a` cut the table into the same row-classes. -/
theorem groupby_collapse_under_fd (t : TableRel Emp_schema)
    (hfd : FuncDepEq (fun r => r (0 : Fin 2)) (fun r => r (1 : Fin 2)) t) :
    (sql%([Emp_schema]) "SELECT a, COUNT(*) AS c FROM Emp GROUP BY a, b") t
      = (sql%([Emp_schema]) "SELECT a, COUNT(*) AS c FROM Emp GROUP BY a") t := by
  apply TypedRelation.ext (by rfl)
  simp only [TypedRelation.mapByList]
  apply Finset.image_congr; intro x hx
  beta_reduce
  -- the two output rows agree except in the `COUNT(*)` component; reduce to that group-count equality
  refine congrArg (fun n : Nat => TypedTupleOfList.cons SQLTypeProxy.int (x 0)
      (TypedTupleOfList.cons SQLTypeProxy.int (Int.ofNat n) TypedTupleOfList.nil)) ?_
  -- the FD makes `(a,b)` and `a` induce the same partition → equal group counts
  apply cnt_eq_of_partition_eq (t := x)
  intro s hs
  unfold FuncDepEq at hfd
  constructor
  · intro h
    have h0 : s (0 : Fin 2) = x (0 : Fin 2) := by
      have := congrFun h (0 : Fin 2); simpa [TypedTupleOfList.cons, colTypeOfList] using this
    rw [TypedTupleOfList.cons_nil_inj]; exact h0
  · intro h0
    rw [TypedTupleOfList.cons_nil_inj] at h0
    have h1 : s (1 : Fin 2) = x (1 : Fin 2) := hfd s hs x hx h0
    funext i; fin_cases i <;> simp [TypedTupleOfList.cons, colTypeOfList] <;> assumption

end FunctionalDependency
