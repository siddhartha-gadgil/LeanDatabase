import Mathlib
import LeanDatabase.TypedRelation
import LeanDatabase.Operators.Aggregate

/-!
# Multiset semantics for SQL

Our main system works on `TypedRelation`, which is a Finset based semantics for SQL.
However, SQL is actually based on multisets, which allows for duplicate rows.

This file presents a multiset based semantics for SQL, `TypedRelationMS`.
We also prove for 2 queries that, bag semantic equivalence => set semantic equivalence.
The other fails.

The bridge is a single function — deduplication `Multiset.toFinset` — and the two theorems are its
functionality (equal inputs → equal outputs) and its contrapositive. We never need to reason about the
query *functions*: the statement is algebraic in the result relations.
-/

namespace LeanDatabase

variable {n : ℕ} {colType : Fin n → Type} [∀ i, DecidableEq (colType i)]

/-- **Multiset (bag) analogue of `TypedRelation`.** Rows are a `Multiset`, so duplicates are kept —
SQL's true semantics, where `UNION ALL`, `COUNT(*)`, `SUM`, … see multiplicity. -/
structure TypedRelationMS (colType : Fin n → Type) [∀ i, DecidableEq (colType i)] where
  labels : Fin n → String
  rows   : Multiset (TypedTuple colType)

/-- Deduplicate a bag relation into the `Finset` relation our main system compares (SQL's implicit
`DISTINCT` when we quotient by multiplicity). This is the *only* bridge between the two semantics. -/
def TypedRelationMS.toSet (r : TypedRelationMS colType) : TypedRelation colType :=
  { labels := r.labels, rows := r.rows.toFinset }

/-- **Bag equivalence**: same rows *with multiplicity* — real SQL's `=`. -/
def dataEqMS (A B : TypedRelationMS colType) : Prop := A.rows = B.rows

/-- **Set equivalence**: same rows *ignoring multiplicity* — what our `TypedRelation` system proves.
Equivalently `(A.toSet).rows = (B.toSet).rows`. -/
def dataEqSet (A B : TypedRelationMS colType) : Prop := A.rows.toFinset = B.rows.toFinset

/-- **Bag equivalence ⇒ set equivalence.**
If two query results are equal as multisets, then their deduplications are equal — `Multiset.toFinset`
is a function, so it respects equality. (Membership view: `x ∈ A.toSet ↔ x ∈ A.rows ↔ x ∈ B.rows ↔
x ∈ B.toSet`, so the two sets have the same elements.) -/
theorem dataEqMS_imp_dataEqSet {A B : TypedRelationMS colType} (h : dataEqMS A B) : dataEqSet A B :=
  congrArg Multiset.toFinset h

/-- **Set difference ⇒ bag difference** — the contrapositive of the above.
If the deduplicated (set) results differ, the bags must already differ. So **any counterexample our
set system finds is a genuine SQL (bag) counterexample**: our *disproofs* are sound for real multiset
SQL — no bag evaluator required. -/
theorem setDiff_imp_bagDiff {A B : TypedRelationMS colType} (h : ¬ dataEqSet A B) : ¬ dataEqMS A B :=
  mt dataEqMS_imp_dataEqSet h

/-- Lifted to **queries** (functions from a database to a result): bag-equivalent queries are
set-equivalent, pointwise. This is the statement that matters for the tool — our set-equivalence
*proofs* are implied by, but do not imply, real SQL equivalence. -/
theorem query_bagEquiv_imp_setEquiv {DB : Type} (Q₁ Q₂ : DB → TypedRelationMS colType)
    (h : ∀ db, dataEqMS (Q₁ db) (Q₂ db)) : ∀ db, dataEqSet (Q₁ db) (Q₂ db) :=
  fun db => dataEqMS_imp_dataEqSet (h db)

/-- **The bridge that rescues proofs.** If BOTH query results are already duplicate-free (`Nodup` —
e.g. `SELECT DISTINCT`, a `UNION`, or an output carrying a key), then set equivalence UPGRADES to bag
equivalence: a duplicate-free bag *equals* its own dedup, so `set-equal ⇒ bag-equal`.

So we never need a bag evaluator: prove set-equivalence as usual, then separately certify the two
outputs have no duplicates (a syntactic check — a top-level `DISTINCT`/`UNION`, or an output key). That
turns a set-proof into a genuine SQL (multiset) equivalence for the common case (duplicate-free
outputs — the norm when base tables have primary keys). -/
theorem bagEq_of_setEq_of_nodup {A B : TypedRelationMS colType}
    (hA : A.rows.Nodup) (hB : B.rows.Nodup) (h : dataEqSet A B) : dataEqMS A B := by
  have hd : A.rows.dedup = B.rows.dedup := by
    rw [← Multiset.toFinset_val, ← Multiset.toFinset_val]; exact congrArg Finset.val h
  rwa [Multiset.dedup_eq_self.2 hA, Multiset.dedup_eq_self.2 hB] at hd

/-- **The converse fails**: set-equal does *not* imply bag-equal. Witness (one `Unit` column): the bag
`{r}` and the bag `{r, r}` both deduplicate to `{r}` (so `dataEqSet`), yet differ as multisets (so
`¬ dataEqMS`). This is why our set-*proofs* are only SQL-equivalences on the multiplicity-insensitive
fragment, while our set-*disproofs* are always genuine. -/
theorem setEq_not_imp_bagEq :
    ∃ A B : TypedRelationMS (colType := fun _ : Fin 1 => Unit), dataEqSet A B ∧ ¬ dataEqMS A B := by
  let r : TypedTuple (fun _ : Fin 1 => Unit) := fun _ => ()
  refine ⟨⟨fun _ => "", {r}⟩, ⟨fun _ => "", r ::ₘ {r}⟩, ?_, ?_⟩
  · simp [dataEqSet]
  · simp [dataEqMS]

/-- Bag (multiset) `COUNT(*)` — the real-SQL count, WITH multiplicity. -/
def relCountMS (r : TypedRelationMS colType) : Nat := Multiset.card r.rows

/-- **Our `COUNT(*)` is a DISTINCT count** — `relCount` over the set view is `Finset.card`, i.e. the number
of distinct rows, which is ≤ the real-SQL bag count. Not a bug: a `COUNT(*)` over a projection that dropped
a key sees the collapsed rows. This is *why* the Calcite `COUNT(*)`-over-projection pairs looked different. -/
theorem relCount_toSet_le_bag (r : TypedRelationMS colType) :
    relCount r.toSet ≤ relCountMS r := by
  simpa [relCount, TypedRelationMS.toSet, relCountMS] using Multiset.toFinset_card_le r.rows

/-- **The exact boundary: our set `COUNT(*)` equals real bag `COUNT(*)` iff the rows are `Nodup`** — i.e. the
relation carries a key / is `DISTINCT`. So a set-proof about `COUNT(*)` is a genuine real-SQL fact exactly
when both sides' rows are duplicate-free; otherwise it is set-only. Same `Nodup` boundary governs SUM/AVG. -/
theorem relCount_toSet_eq_bag_iff_nodup (r : TypedRelationMS colType) :
    relCount r.toSet = relCountMS r ↔ r.rows.Nodup := by
  simpa [relCount, TypedRelationMS.toSet, relCountMS] using
    (Multiset.toFinset_card_eq_card_iff_nodup (m := r.rows))

end LeanDatabase
