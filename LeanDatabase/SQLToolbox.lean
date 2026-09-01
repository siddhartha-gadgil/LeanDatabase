import LeanDatabase.RelationalAlgebra
import LeanDatabase.Operators.Aggregate

/-!
# Grind toolbox — database identities registered with `grind`

Importing this module turns a curated, *confluent* set of relational-algebra identities into
oriented `grind` rewrites, so downstream query-equivalence theorems over `TypedRelation` close
with a bare `grind +locals`. (The aggregation lemmas — grouping, `COUNT`/`SUM` coalesce, group
membership/max — are already registered in `LeanDatabase.Operators.Aggregate`, re-exported here.)

Everything tagged `@[grind =]` is an oriented, terminating rewrite — no commutativity /
associativity (those would loop), and no two rules sharing a left-hand side.
-/

namespace LeanDatabase

open LeanDatabase.TypedAgg

variable {n : Nat} {colType : Fin n → Type} [∀ i, DecidableEq (colType i)]

/-- **`HAVING SUM(...) ≠ 0` ⟹ the key survived**: a non-zero group `SUM` witnesses that the group is
non-empty, i.e. the key occurs among the aggregated table's keys. The `HAVING` counterpart of
`groupSum_eq_zero_of_not_mem`; lets `sql_equiv` recover "this key passed a `HAVING SUM(...) > c ≥ 0`
test, so it is present after the `WHERE`-restricted `GROUP BY`". -/
@[grind →] theorem mem_groupKeys_of_groupSum_ne_zero {K : Type} [DecidableEq K]
    (key : TypedTuple colType → K) (k : K) (rel : TypedRelation colType)
    (f : TypedTuple colType → Int) (h : groupSum key k rel f ≠ 0) : k ∈ groupKeys key rel := by
  by_contra hk
  exact h (groupSum_eq_zero_of_not_mem key k rel f hk)

/-- The witness form of `mem_groupKeys_of_groupSum_ne_zero`: a non-zero group `SUM` produces an
actual row of the group. Handed to `grind` directly so it can discharge "`HAVING SUM(...) ≠ 0` ⟹ ∃
such a row" without having to compose `mem_groupKeys_of_groupSum_ne_zero` with `mem_groupKeys`. -/
@[grind →] theorem exists_mem_of_groupSum_ne_zero {K : Type} [DecidableEq K]
    (key : TypedTuple colType → K) (k : K) (rel : TypedRelation colType)
    (f : TypedTuple colType → Int) (h : groupSum key k rel f ≠ 0) :
    ∃ t ∈ rel.rows, key t = k := by
  rw [← mem_groupKeys]
  exact mem_groupKeys_of_groupSum_ne_zero key k rel f h

/-- **`groupKeys` is monotone under `WHERE`**: a key present after a `restriction` is present in the
whole relation. The other half of matching two `GROUP BY`s whose bases differ by a `WHERE`. -/
@[grind →] theorem mem_groupKeys_of_mem_restriction {K : Type} [DecidableEq K]
    (key : TypedTuple colType → K) (p : TypedTuple colType → Bool) (rel : TypedRelation colType)
    (k : K) (h : k ∈ groupKeys key (restriction p rel)) : k ∈ groupKeys key rel := by
  simp only [mem_groupKeys, restriction, Finset.mem_filter] at h ⊢
  obtain ⟨t, ⟨ht, _⟩, hk⟩ := h
  exact ⟨t, ht, hk⟩

/-- **`HAVING` absorbs a `WHERE` on the base of a `GROUP BY`.** Two `GROUP BY`s whose per-key output
`mk` and `HAVING` predicate `H` both factor through the group key produce the same table even when
one scans `base` and the other its `WHERE p` `restriction` — provided every `H`-surviving row's key
still occurs after the `WHERE` (`hpres`). This is the whole-relation content of a `SUM(CASE)`+`HAVING`
≡ `WHERE`+`SUM`+`HAVING` rewrite; `hpres` is discharged from `HAVING SUM(...) > c ≥ 0` via
`exists_mem_of_groupSum_ne_zero`. -/
theorem image_where_absorb {K β : Type} [DecidableEq K] [DecidableEq β]
    (key : TypedTuple colType → K) (mk : TypedTuple colType → β) (H : TypedTuple colType → Bool)
    (p : TypedTuple colType → Bool) (base : TypedRelation colType)
    (hH : ∀ s t, key s = key t → H s = H t)
    (hmk : ∀ s t, key s = key t → mk s = mk t)
    (hpres : ∀ t ∈ base.rows, H t = true → key t ∈ groupKeys key (restriction p base)) :
    (restriction H base).rows.image mk = (restriction H (restriction p base)).rows.image mk := by
  apply Finset.ext; intro x
  simp only [Finset.mem_image, restriction, Finset.mem_filter]
  constructor
  · rintro ⟨t, ⟨ht, hHt⟩, rfl⟩
    obtain ⟨s, hs, hks⟩ := (mem_groupKeys _ _ _).mp (hpres t ht hHt)
    simp only [restriction, Finset.mem_filter] at hs
    exact ⟨s, ⟨⟨hs.1, hs.2⟩, (hH s t hks).trans hHt⟩, hmk s t hks⟩
  · rintro ⟨t, ⟨⟨ht, _⟩, hHt⟩, rfl⟩
    exact ⟨t, ⟨ht, hHt⟩, rfl⟩

/-- The empty relation has no rows. Exposed as a `@[simp]` rewrite (without tagging `emptyRel`
itself, which lives in `TypedRelation`) so `sql_equiv` can collapse `∅`-table queries — e.g.
`LEFT JOIN` against an empty table. -/
@[simp] theorem emptyRel_rows {n : Nat} {colType : Fin n → Type} [∀ i, DecidableEq (colType i)]
    (l : Fin n → String) : (emptyRel (colType := colType) l).rows = ∅ := rfl

/-- **`COUNT` partition** (`Bool` predicate form, matching `restriction`): `COUNT(WHERE p)` plus
    `COUNT(WHERE NOT p)` is `COUNT(*)`. Tagged `@[simp]` so `sql_equiv` closes the partition. -/
@[simp] theorem card_filter_true_add_false {α : Type} [DecidableEq α] (p : α → Bool) (s : Finset α) :
    (s.filter (fun a => p a = true)).card + (s.filter (fun a => p a = false)).card = s.card := by
  simp only [← Bool.not_eq_true]
  exact Finset.card_filter_add_card_filter_not _

/-- **`COUNT` partition by complementary predicates.** A robust generalization of
`card_filter_true_add_false`: it does NOT require the two filters to mention a single shared `p`.
This matters because `simp` De-Morgan-splits a compound `WHERE`/`!WHERE` (e.g. `a ∧ b` vs
`¬a ∨ ¬b`), after which no single `p` survives. Tagged `@[grind]` so `grind` matches the two
`card`s and discharges the `Q ↔ ¬P` side-condition (pure propositional/Boolean reasoning) itself —
closing the partition regardless of how `simp` rewrote the predicates. -/
@[grind =] theorem card_filter_add_card_filter_compl {α : Type} [DecidableEq α] (s : Finset α)
    (P Q : α → Prop) [DecidablePred P] [DecidablePred Q] (h : ∀ a, Q a ↔ ¬ P a) :
    (s.filter P).card + (s.filter Q).card = s.card := by
  have hQ : s.filter Q = s.filter (fun a => ¬ P a) := Finset.filter_congr (fun a _ => h a)
  rw [hQ]
  exact Finset.card_filter_add_card_filter_not _

/-- **`WHERE` congruence**: two `restriction`s are equal when their predicates agree on every row of
the input. The bridge for "the two `WHERE` predicates coincide on the actual data" hypotheses (e.g.
two different `LIKE` patterns that happen to match the same rows of this table). -/
theorem restriction_congr (p q : TypedTuple colType → Bool) (R : TypedRelation colType)
    (h : ∀ t ∈ R.rows, p t = q t) : restriction p R = restriction q R := by
  grind only [= restriction.eq_1, Finset.filter_congr]

/-! ### Optimizer-inspired `WHERE` rewrites (proven; `sqlglot.optimizer.simplify` counterparts)

`sql_equiv`'s `grind` already folds predicate-level boolean/comparison rules (`x>3 ∧ x>5 ≡ x>5`,
`a ∧ (a∨b) ≡ a`, De Morgan…). These are the *general* forms that also hold for **opaque** predicates,
where `grind` can't reason inside — discharged instead from an implication/equality, exactly like the
`UNIQUE`/`FUNCDEP`/`BIJECTION` `HYPOTHESIS` facts feed `restriction_congr`. Each carries a `grind_pattern`
so `grind +locals` fires it when the side condition is available (e.g. from a stated `HYPOTHESIS`). -/

/-- **Absorb a weaker conjunct** (`sqlglot`: `absorb_and_eliminate` + `_simplify_comparison`). If
`p ⟹ q` on every row, `σ_{p∧q} = σ_p` — generalises comparison-range merging and AND-absorption to any
predicates (incl. opaque), given the implication as a side condition. -/
@[simp]
theorem restriction_absorb_and (p q : TypedTuple colType → Bool) (R : TypedRelation colType)
    (h : ∀ t ∈ R.rows, p t = true → q t = true) :
    restriction (fun t => p t && q t) R = restriction p R := by
  apply restriction_congr; intro t ht
  simp_all only [Bool.and_eq_left_iff_imp, implies_true]

/-- **Absorb into a stronger disjunct** (`sqlglot`: `absorb_and_eliminate`). If `p ⟹ q` on every row,
`σ_{p∨q} = σ_q`. -/
@[simp]
theorem restriction_absorb_or (p q : TypedTuple colType → Bool) (R : TypedRelation colType)
    (h : ∀ t ∈ R.rows, p t = true → q t = true) :
    restriction (fun t => p t || q t) R = restriction q R := by
  apply restriction_congr; intro t ht
  cases hp : p t with
  | false => simp
  | true => simp [h t ht hp]

/-- **Constant propagation** (`sqlglot`: `propagate_constants`). Under `k = c`, replace `k` by `c` inside
any (even opaque) predicate `φ`: `σ_{k=c ∧ φ(k)} = σ_{k=c ∧ φ(c)}` — what `grind` cannot do when `φ` is
uninterpreted. -/
theorem restriction_const_prop {α : Type} [DecidableEq α]
    (k : TypedTuple colType → α) (c : α) (φ : α → Bool) (R : TypedRelation colType) :
    restriction (fun t => decide (k t = c) && φ (k t)) R
      = restriction (fun t => decide (k t = c) && φ c) R := by
  apply restriction_congr; intro t _
  by_cases hk : k t = c <;> simp [hk]

/-! ### GROUP-BY key normalization (`group_congr` + the per-aggregate congruences)

Two groupings that induce the **same per-row membership** on `rel` yield the same group — even at
different key *types*. This is the general law behind GROUP-BY key elimination: a **constant** key
component (`GROUP BY x, 2+3`) or a **functionally-determined** one (`GROUP BY deptno, sal` under
`WHERE deptno = 10`, so `deptno` is fixed) doesn't refine the partition. `sql_group_key` (in
`SQLEquiv`) applies the matching aggregate congruence, then `group_congr`, leaving the per-row key
equivalence for `grind` — which `t ∈ rel` (incl. a `WHERE` restriction) discharges. -/
theorem group_congr {K₁ K₂ : Type} [DecidableEq K₁] [DecidableEq K₂]
    (key₁ : TypedTuple colType → K₁) (k₁ : K₁) (key₂ : TypedTuple colType → K₂) (k₂ : K₂)
    (rel : TypedRelation colType)
    (h : ∀ t ∈ rel.rows, decide (key₁ t = k₁) = decide (key₂ t = k₂)) :
    group key₁ k₁ rel = group key₂ k₂ rel := by
  simp only [TypedAgg.group]; exact restriction_congr _ _ rel h

variable {K₁ K₂ : Type} [DecidableEq K₁] [DecidableEq K₂]
  (key₁ : TypedTuple colType → K₁) (k₁ : K₁) (key₂ : TypedTuple colType → K₂) (k₂ : K₂)
  (rel : TypedRelation colType) (f : TypedTuple colType → Int)

theorem groupCount_congr (h : group key₁ k₁ rel = group key₂ k₂ rel) :
    groupCount key₁ k₁ rel = groupCount key₂ k₂ rel := by simp only [TypedAgg.groupCount, h]
theorem groupSum_congr (h : group key₁ k₁ rel = group key₂ k₂ rel) :
    groupSum key₁ k₁ rel f = groupSum key₂ k₂ rel f := by simp only [TypedAgg.groupSum, h]
theorem groupMaxInt_congr (h : group key₁ k₁ rel = group key₂ k₂ rel) :
    groupMaxInt key₁ k₁ rel f = groupMaxInt key₂ k₂ rel f := by simp only [TypedAgg.groupMaxInt, h]
theorem groupMinInt_congr (h : group key₁ k₁ rel = group key₂ k₂ rel) :
    groupMinInt key₁ k₁ rel f = groupMinInt key₂ k₂ rel f := by simp only [TypedAgg.groupMinInt, h]
theorem groupAvg_congr (h : group key₁ k₁ rel = group key₂ k₂ rel) :
    groupAvg key₁ k₁ rel f = groupAvg key₂ k₂ rel f := by
  simp only [TypedAgg.groupAvg, TypedAgg.groupSum, TypedAgg.groupCount, h]

/-! ### Aggregate arithmetic (`SUM` linearity)

`grind` cannot reason inside a `∑`, so these are the laws behind optimizer rewrites like
`SUM(a + b) = SUM(a) + SUM(b)`, `SUM(c * x) = c * SUM(x)`. `@[simp]` (a valid normalizing direction —
split/pull sums out) so `sql_simp` fires them on a residual `groupSum …`. -/
section AggArith
variable {K : Type} [DecidableEq K] (key : TypedTuple colType → K) (k : K)
  (rel' : TypedRelation colType) (f g : TypedTuple colType → Int) (c : Int)

@[simp] theorem groupSum_add :
    groupSum key k rel' (fun t => f t + g t) = groupSum key k rel' f + groupSum key k rel' g := by
  simp only [TypedAgg.groupSum, Finset.sum_add_distrib]
@[simp] theorem groupSum_sub :
    groupSum key k rel' (fun t => f t - g t) = groupSum key k rel' f - groupSum key k rel' g := by
  simp only [TypedAgg.groupSum, Finset.sum_sub_distrib]
@[simp] theorem groupSum_mul_left :
    groupSum key k rel' (fun t => c * f t) = c * groupSum key k rel' f := by
  simp only [TypedAgg.groupSum, ← Finset.mul_sum]
@[simp] theorem groupSum_neg :
    groupSum key k rel' (fun t => -f t) = -groupSum key k rel' f := by
  simp only [TypedAgg.groupSum, Finset.sum_neg_distrib]
@[simp] theorem groupSum_zero : groupSum key k rel' (fun _ => 0) = 0 := by
  simp only [TypedAgg.groupSum, Finset.sum_const_zero]
/-- `COUNT(*)` of a group is `SUM(1)`. `@[grind]` (not `@[simp]`, to leave `COUNT` alone by default). -/
@[grind =] theorem groupCount_eq_groupSum_one :
    (groupCount key k rel' : Int) = groupSum key k rel' (fun _ => 1) := by
  simp [TypedAgg.groupCount, TypedAgg.groupSum, Finset.sum_const]
end AggArith


attribute [grind =]
  restriction_idempotence          -- σ_p(σ_p R) = σ_p R
  inter_idempotence                -- R ∩ R = R
  union_absorb_inter               -- R ∪ (R ∩ S) = R
  inter_absorb_union               -- R ∩ (R ∪ S) = R
  diff_empty                       -- R − ∅ = R
  union_identity                   -- R ∪ ∅ = R
  restriction_inter_distrib        -- σ_p(R ∩ S) = σ_p R ∩ σ_p S
  restriction_diff_distrib         -- σ_p(R − S) = σ_p R − σ_p S
  projection_compose               -- π_b(π_a R) = π_{a∘b} R          (collapses nested projection)
  inter_distrib_union              -- R ∩ (S ∪ T) = (R∩S) ∪ (R∩T)     (ONLY this direction; union_distrib_inter would loop)
  diff_diff_eq_diff_union          -- (R − S) − T = R − (S ∪ T)       (collapses nested minus)

end LeanDatabase
