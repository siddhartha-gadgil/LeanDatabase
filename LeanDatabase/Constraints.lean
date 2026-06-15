import LeanDatabase.Operators.Aggregate

/-!
# Data constraints (hypotheses) — turning data-dependent equivalences into provable ones

Many SQL rewrites are equivalent only under a fact about the *data*, not the query — e.g. a
`GROUP BY name` vs `GROUP BY id, name` collapse holds exactly when `name` functionally determines
`id`. Our core `TypedRelation` algebra stays untouched (those rewrites are genuinely false in
general); instead a theorem takes the data fact as an explicit **hypothesis** and `sql_equiv`
discharges the rest. This file provides the reusable constraint primitives.
-/

namespace LeanDatabase

variable {n : Nat} {colType : Fin n → Type} [∀ i, DecidableEq (colType i)]

/-- **Functional dependency** `key → det` over `R`: any two rows of `R` agreeing on `key` agree on
`det`. (SQL: a column/expression is functionally determined by another within the table.) -/
def FuncDep {α β : Type} (key : TypedTuple colType → α) (det : TypedTuple colType → β)
    (R : TypedRelation colType) : Prop :=
  ∀ a ∈ R.rows, ∀ b ∈ R.rows, key a = key b → det a = det b

/-- **Same-partition ⇒ same group count.** If two group keys cut `R` into the same per-row classes
(`key1 s = key1 t ↔ key2 s = key2 t` for every row `s`), the group of `t` has the same `COUNT(*)`
under either key. The bridge from a functional dependency to a `GROUP BY`-granularity rewrite. -/
theorem cnt_eq_of_partition_eq {α β : Type} [DecidableEq α] [DecidableEq β]
    (key1 : TypedTuple colType → α) (key2 : TypedTuple colType → β)
    (R : TypedRelation colType) (t : TypedTuple colType)
    (h : ∀ s ∈ R.rows, (key1 s = key1 t) ↔ (key2 s = key2 t)) :
    TypedAgg.cnt key1 (key1 t) R = TypedAgg.cnt key2 (key2 t) R := by
  have hrows : (TypedAgg.grp key1 (key1 t) R).rows = (TypedAgg.grp key2 (key2 t) R).rows := by
    unfold TypedAgg.grp restriction
    apply Finset.filter_congr
    intro s hs
    simp only [decide_eq_true_eq]
    exact h s hs
  grind [TypedAgg.cnt]

/-- **`GROUP BY key` ≡ `GROUP BY (det, key)`** counts, given the FD `key → det`. The refined key
`(det, key)` and the coarse key `key` induce the same partition, so every group's `COUNT(*)` agrees
(hence any `ORDER BY COUNT(*)`/top-N over the groups agrees). `det` is listed first to match SQL
`GROUP BY id, name` written as `(id, name)`. -/
theorem cnt_pair_eq_of_FD {α β : Type} [DecidableEq α] [DecidableEq β]
    (key : TypedTuple colType → α) (det : TypedTuple colType → β)
    (R : TypedRelation colType) (hfd : FuncDep key det R)
    (t : TypedTuple colType) (ht : t ∈ R.rows) :
    TypedAgg.cnt key (key t) R = TypedAgg.cnt (fun s => (det s, key s)) (det t, key t) R := by
  apply cnt_eq_of_partition_eq
  intro s hs
  grind only [FuncDep]

/-- **`WHERE` congruence**: two `restriction`s are equal when their predicates agree on every row of
the input. The bridge for "the two `WHERE` predicates coincide on the actual data" hypotheses (e.g.
two different `LIKE` patterns that happen to match the same rows of this table). -/
theorem restriction_congr (p q : TypedTuple colType → Bool) (R : TypedRelation colType)
    (h : ∀ t ∈ R.rows, p t = q t) : restriction p R = restriction q R := by
  unfold restriction
  congr 1
  apply Finset.filter_congr
  intro t ht
  rw [h t ht]

end LeanDatabase
