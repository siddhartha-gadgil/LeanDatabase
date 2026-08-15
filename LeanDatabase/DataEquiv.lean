import LeanDatabase.TypedRelation

/-!
# Data-equivalence (equivalence up to output presentation)

The crossskill task calls two SQL queries equivalent when they return the **same answer** — the same
set of result rows. Output column *names* (`… AS alias`) are presentation, not data: two queries that
differ only in an alias are equivalent. But full Lean equality of `TypedRelation` also compares the
`labels` field, so an alias difference makes `A = B` *false* even when the data is identical.

`A ~= B` (`dataEq`) is the honest notion: **the rows are equal, ignoring labels**. It requires the same
column types in the same order (a genuine column *reordering* changes the tuple type and is out of
scope here — that needs a labelled-column permutation). `A = B → A ~= B`, so a `~=` goal is never
stronger than the corresponding equality, and `sql_equiv` discharges it by unfolding to `.rows = .rows`.
-/

namespace LeanDatabase

variable {n : Nat} {colType : Fin n → Type} [∀ i, DecidableEq (colType i)]

/-- `A ~= B` — same rows, ignoring column labels (aliasing). The crossskill "same answer" notion. -/
def dataEq (A B : TypedRelation colType) : Prop := A.rows = B.rows

@[inherit_doc] infix:50 " ~= " => dataEq

@[refl, simp] theorem dataEq_refl (A : TypedRelation colType) : A ~= A := rfl

/-- Full equality is stronger than data-equivalence. -/
theorem dataEq_of_eq {A B : TypedRelation colType} (h : A = B) : A ~= B := by rw [h]

theorem dataEq_symm {A B : TypedRelation colType} (h : A ~= B) : B ~= A := Eq.symm h
theorem dataEq_trans {A B C : TypedRelation colType} (h1 : A ~= B) (h2 : B ~= C) : A ~= C :=
  Eq.trans h1 h2

end LeanDatabase
