import Mathlib
import LeanDatabase.TypedRelation

namespace Multiset

variable {α : Type} [DecidableEq α]

/-
For proving properties here, if Multiset Mathlib properties doesnt work, check Lattice properties
-/

-- Helper: Intersection Distributes over Union (Lattice Property)
-- s ∩ (t ∪ u) = (s ∩ t) ∪ (s ∩ u)
theorem inter_union_distrib_left_exact (s t u : Multiset α) :
    s ∩ (t ∪ u) = s ∩ t ∪ s ∩ u := by
  exact inf_sup_left s t u

-- Helper: Union Distributes over Intersection
-- s ∪ (t ∩ u) = (s ∪ t) ∩ (s ∪ u)
theorem union_inter_distrib_left_exact (s t u : Multiset α) :
    s ∪ (t ∩ u) = (s ∪ t) ∩ (s ∪ u) := by
  exact sup_inf_left s t u

theorem union_empty (s : Multiset α) : s ∪ ∅ = s := by
  exact sup_bot_eq s

end Multiset

namespace LeanDatabase

/-
# Relational Algebra

We prove some of the basic properties of Relational Algebra on our existing definition.
-/

variable {n : Nat} {types : Fin n → Type}
variable [∀ i, DecidableEq (types i)]
variable [∀ i, LinearOrder (types i)]

/-! ### Commutativity & Associativity -/

-- Theorem: Union is Commutative ( R ∪ S = S ∪ R )
omit [(i : Fin n) → LinearOrder (types i)] in
theorem union_comm (r1 r2 : TypedRelation types) (h: r1.labels = r2.labels) :
    union r1 r2 = union r2 r1 := by
  simp only [union]
  congr 1
  exact sup_comm r1.rows r2.rows

-- Theorem: Union is Associative
-- (R ⋃ S) ⋃ T = R ⋃ (S ⋃ T)
omit [(i : Fin n) → LinearOrder (types i)] in
theorem union_assoc (r1 r2 r3 : TypedRelation types) :
    union (union r1 r2) r3 = union r1 (union r2 r3) := by
  simp only [union]
  congr 1
  exact sup_assoc r1.rows r2.rows r3.rows

-- Theorem: Intersection is Commutative ( R ∩ S = S ∩ R)
omit [(i : Fin n) → LinearOrder (types i)] in
theorem inter_comm (r1 r2 : TypedRelation types) (h: r1.labels = r2.labels) :
    intersection r1 r2 = intersection r2 r1 := by
  simp only [intersection]
  congr 1
  exact Multiset.inter_comm r1.rows r2.rows
  -- or inf_comm r1.rows r2.rows

-- Theorem: Idempotence of Intersection
-- R ∩ R = R
omit [(i : Fin n) → LinearOrder (types i)] in
theorem inter_idempotence (r : TypedRelation types) :
    intersection r r = r := by
  simp only [intersection]
  congr 1
  exact inf_idem r.rows

-- Theorem: Absorption Law
-- R ∪ (R ∩ S) = R
omit [(i : Fin n) → LinearOrder (types i)] in
theorem union_absorb_inter (r1 r2 : TypedRelation types):
    union r1 (intersection r1 r2) = r1 := by
  simp only [union, intersection]
  congr 1
  exact sup_inf_self


-- Theorem: Distributivity of Intersection over Union
-- R ∩ (S ∪ T) = (R ∩ S) ∪ (R ∩ T)
-- "Joining a combined table is the same as joining each part separately."
omit [(i : Fin n) → LinearOrder (types i)] in
theorem inter_distrib_union (r1 r2 r3 : TypedRelation types) :
    intersection r1 (union r2 r3) = union (intersection r1 r2) (intersection r1 r3) := by
  simp only [intersection, union]
  congr 1
  exact Multiset.inter_union_distrib_left_exact r1.rows r2.rows r3.rows

-- Theorem: Distributivity of Union over Intersection
-- R ∪ (S ∩ T) = (R ∪ S) ∩ (R ∪ T)
omit [(i : Fin n) → LinearOrder (types i)] in
theorem union_distrib_inter (r1 r2 r3 : TypedRelation types) :
    union r1 (intersection r2 r3) = intersection (union r1 r2) (union r1 r3) := by
  simp only [union, intersection]
  congr 1
  exact Multiset.union_inter_distrib_left_exact r1.rows r2.rows r3.rows

-- Theorem: Dual Absorption Law
-- R ∩ (R ∪ S) = R
omit [(i : Fin n) → LinearOrder (types i)] in
theorem inter_absorb_union (r1 r2 : TypedRelation types) :
    intersection r1 (union r1 r2) = r1 := by
  simp only [intersection, union]
  congr 1
  exact inf_sup_self

-- Theorem: Difference Chain
-- (R - S) - T = R - (S ∪ T)
-- "Excluding S then excluding T is the same as excluding (S or T) at once."
-- NOTE: This theorem is FALSE for Multisets when Union is Max (Lattice Join).
-- Counterexample: 10 - max(2, 3) = 7, but (10 - 2) - 3 = 5.
-- It is only true if Union is Add (+), or if we are using Sets.
-- theorem diff_diff_eq_diff_union (r s t : TypedRelation types) :
--    minus (minus r s) t = minus r (union s t) := by sorry

-- Theorem: Identity for Difference
-- R - ∅ = R
omit [(i : Fin n) → LinearOrder (types i)] in
theorem diff_empty (r : TypedRelation types) :
    minus r (emptyRel r.labels) = r := by
  simp only [minus, emptyRel]
  congr 1
  exact Multiset.sub_zero r.rows

-- Theorem: Zero for Difference (Left)
-- ∅ - R = ∅
omit [(i : Fin n) → LinearOrder (types i)] in
theorem empty_diff (r : TypedRelation types) :
    (minus (emptyRel r.labels) r).rows = ∅ := by
  simp only [minus, emptyRel]
  exact zero_tsub r.rows

-- Theorem: Self-Difference is Empty
-- R - R = ∅
omit [(i : Fin n) → LinearOrder (types i)] in
theorem diff_self (r : TypedRelation types) :
    (minus r r).rows = ∅ := by
    simp only [minus]
    exact tsub_self r.rows

/-! ### Distributivity-/

-- Theorem: Selection Distributes over Union
-- σ_p(R ∪ S) = σ_p(R) ∪ σ_p(S)
omit [(i : Fin n) → LinearOrder (types i)] in
theorem restriction_union_distrib (p : TypedTuple types → Bool)
    (r1 r2 : TypedRelation types) :
    restriction p (union r1 r2) = union (restriction p r1) (restriction p r2) := by
  simp only [restriction, union]
  congr 1
  exact Multiset.filter_union (fun t ↦ p t = true) r1.rows r2.rows

-- Theorem: Selection Distributes over Intersection
-- σ_p(R ∩ S) = σ_p(R) ∩ σ_p(S)
omit [(i : Fin n) → LinearOrder (types i)] in
theorem restriction_inter_distrib (p : TypedTuple types → Bool)
    (r1 r2 : TypedRelation types) :
    restriction p (intersection r1 r2) = intersection (restriction p r1) (restriction p r2) := by
  simp only [restriction, intersection]
  congr 1
  exact Multiset.filter_inter (fun t ↦ p t = true) r1.rows r2.rows

-- Theorem: Difference of Restrictions
-- σ_P(R) - σ_Q(R) = σ_{P ∧ ¬Q}(R)
-- "Subtracting a filtered set from another filtered set (of the same source)
theorem restriction_diff_conj_restriction (p q : TypedTuple types → Bool) (r : TypedRelation types) :
    minus (restriction p r) (restriction q r) = restriction (fun t => p t && !q t) r := by
  simp only [minus, restriction]
  congr 1
  ext x
  simp only [Multiset.count_sub, Multiset.count_filter]
  sorry

  -- Theorem: De Morgan's Law for Difference
-- R - (S ∪ T) = (R - S) ∩ (R - T)
theorem diff_union_distrib (r s t : TypedRelation types) :
    minus r (union s t) = intersection (minus r s) (minus r t) := by
  simp only [minus, union, intersection]
  congr 1
  ext x
  sorry
