import LeanDatabase.Parser.Context
import LeanDatabase.Operators.Select
import LeanDatabase.SimpAttr

/-!
# Membership normal form — the informed route to a query equivalence

`sql_equiv`'s closing phase used to be a blind `first | grind | …` cascade over whatever shape the
goal happened to have. This module supplies the missing *structural* step, and it is the same
reduction VeriEQL performs before handing the problem to Z3: an equivalence between two relational
expressions is equivalent to a **first-order membership condition** over the base rows,

    A.rows = B.rows   ↔   ∀ x, x ∈ A.rows ↔ x ∈ B.rows

and each operator has a membership law that pushes `∈` one layer inward (`σ` → `∧`, `π`/`×` → `∃`,
`∪` → `∨`, …). Rewriting with those laws until only base-table memberships remain turns the goal into
pure first-order logic over rows, where `grind` does the witness reasoning — unbounded, where their
Z3 query is bounded.

The laws live in their own `sql_mem` simp set (not the global one) so they only fire where we ask,
and the operator definitions are *not* unfolded: unfolding `Finset.image`/`filter` drops to
`Multiset`/`Quot` and the `Finset.mem_*` lemmas stop applying.
-/

open Lean

namespace LeanDatabase

-- Part of the set: a join's column list must be literal *in every pass*, or the membership and
-- indexing laws stop unifying (the `++` survives inside `DecidableEq` instance arguments).
attribute [sql_mem] List.cons_append List.nil_append

variable {n : Nat} {colType : Fin n → Type} [∀ i, DecidableEq (colType i)]

/-- `x ∈ σ_p(R)` ↔ `x ∈ R ∧ p x`. -/
@[sql_mem] theorem mem_restriction_rows (p : TypedTuple colType → Bool) (r : TypedRelation colType)
    (x : TypedTuple colType) : x ∈ (restriction p r).rows ↔ x ∈ r.rows ∧ p x = true := by
  simp [restriction, Finset.mem_filter]

/-- `DISTINCT` is the identity on a `Finset` of rows. -/
@[sql_mem] theorem mem_distinct_rows (r : TypedRelation colType) (x : TypedTuple colType) :
    x ∈ (distinct r).rows ↔ x ∈ r.rows := by simp [distinct]

/-- `x ∈ π_f(R)` ↔ some row of `R` maps to `x`. -/
@[sql_mem] theorem mem_mapByList_rows {types : List SQLTypeProxy} (r : TypedRelation colType)
    (names : List String) (f : TypedTuple colType → TypedTupleOfList types)
    (x : TypedTupleOfList types) :
    x ∈ (TypedRelation.mapByList r names f).rows ↔ ∃ t ∈ r.rows, f t = x := by
  simp [TypedRelation.mapByList, Finset.mem_image]

/-- `x ∈ π_f(R)` for the computed `SELECT`. -/
@[sql_mem] theorem mem_select_rows {p : Nat} {outCT : Fin p → Type} [∀ i, DecidableEq (outCT i)]
    (labels : Fin p → String) (f : TypedTuple colType → TypedTuple outCT)
    (r : TypedRelation colType) (x : TypedTuple outCT) :
    x ∈ (select labels f r).rows ↔ ∃ t ∈ r.rows, f t = x := by
  simp [select, Finset.mem_image]

/-- `x ∈ R × S` ↔ `x` is the concatenation of a row of `R` and a row of `S`. This is the law that was
missing: a join is `image append (R ×ˢ S)`, and without it the product never reaches `∃`-form. -/
@[sql_mem] theorem mem_append_rows {l1 l2 : List SQLTypeProxy}
    (r : TypedRelationOfList l1) (s : TypedRelationOfList l2) (x : TypedTupleOfList (l1 ++ l2)) :
    x ∈ (TypedRelationOfList.append r s).rows ↔
      ∃ a ∈ r.rows, ∃ b ∈ s.rows, TypedTupleOfList.append a b = x := by
  simp [Finset.mem_image, Finset.mem_product]
  constructor
  · rintro ⟨a, b, ⟨ha, hb⟩, rfl⟩; exact ⟨a, ha, b, hb, rfl⟩
  · rintro ⟨a, ha, b, hb, rfl⟩; exact ⟨a, b, ⟨ha, hb⟩, rfl⟩

/-- The join shape as it actually reaches the goal: `.rows` of an `append` is a projection of a
structure literal, so it reduces to `image f (A ×ˢ B)` before any lemma phrased in terms of `append`
can fire — and such a lemma could not match anyway, since the concatenated column list is already a
literal and `l₁ ++ l₂` is not invertible by matching. Stated over an arbitrary `f`, it matches. -/
@[sql_mem] theorem mem_image_product {α β γ : Type} [DecidableEq γ]
    (f : α × β → γ) (A : Finset α) (B : Finset β) (x : γ) :
    x ∈ Finset.image f (A ×ˢ B) ↔ ∃ a ∈ A, ∃ b ∈ B, f (a, b) = x := by
  simp only [Finset.mem_image, Finset.mem_product, Prod.exists]
  constructor
  · rintro ⟨a, b, ⟨ha, hb⟩, rfl⟩; exact ⟨a, ha, b, hb, rfl⟩
  · rintro ⟨a, ha, b, hb, rfl⟩; exact ⟨a, b, ⟨ha, hb⟩, rfl⟩

/-! ### Tuple decomposition

After the membership laws, the residue is equalities between a *built* tuple and a row **variable**
(`cons v r = a`). A row is a function `Fin n → …`, so `grind` would need extensionality plus a case
split on the index — the "funext explodes tuples" wall. These laws do that split once, structurally,
turning such an equality into component equations: the same fixed-arity tuple encoding VeriEQL uses
in SMT. They only fire on `cons … = a` / `a = cons …`, and recurse into the tail, so they terminate. -/

/-- `cons v r = a` ↔ head and tail agree componentwise. -/
@[sql_mem] theorem cons_eq_iff {t : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v : t.type) (r : TypedTupleOfList rest) (a : TypedTupleOfList (t :: rest)) :
    TypedTupleOfList.cons t v r = a ↔
      v = a ⟨0, by simp⟩ ∧ r = fun (i : Fin rest.length) => a ⟨i.val + 1, by simp⟩ := by
  constructor
  · rintro rfl
    refine ⟨rfl, ?_⟩
    funext i
    rfl
  · rintro ⟨rfl, rfl⟩
    funext ⟨i, hi⟩
    cases i with
    | zero => rfl
    | succ j => rfl

/-- The mirror orientation (`a = cons v r`). -/
@[sql_mem] theorem eq_cons_iff {t : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v : t.type) (r : TypedTupleOfList rest) (a : TypedTupleOfList (t :: rest)) :
    a = TypedTupleOfList.cons t v r ↔
      v = a ⟨0, by simp⟩ ∧ r = fun (i : Fin rest.length) => a ⟨i.val + 1, by simp⟩ := by
  rw [eq_comm, cons_eq_iff]

/-- Every row of a non-empty column list is a `cons` of its head entry and its tail. -/
theorem tuple_eta {t : SQLTypeProxy} {rest : List SQLTypeProxy} (a : TypedTupleOfList (t :: rest)) :
    a = TypedTupleOfList.cons t (a ⟨0, by simp⟩)
          (fun (i : Fin rest.length) => a ⟨i.val + 1, by simp⟩) := by
  funext ⟨i, hi⟩
  cases i with
  | zero => rfl
  | succ j => rfl

/-- **Quantifying over a row = quantifying over its columns.** This is VeriEQL's tuple encoding: a
tuple is a record of scalars, so an existential over a row becomes existentials over its fields, and
every equation between rows becomes equations between *scalars* — first-order facts `grind` can chain,
instead of equalities between `Fin n → τ` functions that need extensionality plus a case split.
Terminates on a literal column list: each step shortens the list. -/
@[sql_mem] theorem exists_tuple_cons {t : SQLTypeProxy} {rest : List SQLTypeProxy}
    (P : TypedTupleOfList (t :: rest) → Prop) :
    (∃ a : TypedTupleOfList (t :: rest), P a) ↔
      ∃ (v : t.type) (r : TypedTupleOfList rest), P (TypedTupleOfList.cons t v r) := by
  constructor
  · rintro ⟨a, ha⟩
    exact ⟨a ⟨0, by simp⟩, fun i => a ⟨i.val + 1, by simp⟩, by rwa [← tuple_eta]⟩
  · rintro ⟨v, r, h⟩
    exact ⟨_, h⟩

/-- The base case of `exists_tuple_cons`: there is exactly one empty row. -/
@[sql_mem] theorem exists_tuple_nil (P : TypedTupleOfList [] → Prop) :
    (∃ a : TypedTupleOfList [], P a) ↔ P TypedTupleOfList.nil := by
  constructor
  · rintro ⟨a, ha⟩
    have : a = TypedTupleOfList.nil := by funext ⟨i, hi⟩; simp at hi
    rwa [this] at ha
  · exact fun h => ⟨_, h⟩

/-- `cons` at index 0 is its head — the companion of `TypedTupleOfList.cons_succ` for the tail. -/
@[sql_mem] theorem cons_zero {t : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v : t.type) (r : TypedTupleOfList rest) (h : 0 < (t :: rest).length) :
    TypedTupleOfList.cons t v r ⟨0, h⟩ = v := rfl

/-- `cons` at a successor index is the tail's entry (the companion of `cons_zero`). -/
@[sql_mem] theorem cons_succ_apply {t : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v : t.type) (r : TypedTupleOfList rest) (i : Nat) (h : i + 1 < (t :: rest).length) :
    TypedTupleOfList.cons t v r ⟨i + 1, h⟩ = r ⟨i, by simp at h; omega⟩ := rfl

/-- A join row in `cons` form. Unfolding `append` with `simp` would also reduce the `cons` it
produces (it is `@[reducible]`) back into a raw `match`, which no law matches; these two `rfl` laws
peel one column at a time and keep the result in `cons` form for `cons_eq_iff`. -/
@[sql_mem] theorem append_cons {t : SQLTypeProxy} {rest l2 : List SQLTypeProxy}
    (a : TypedTupleOfList (t :: rest)) (b : TypedTupleOfList l2) :
    TypedTupleOfList.append a b
      = TypedTupleOfList.cons t (a ⟨0, by simp⟩)
          (TypedTupleOfList.append (fun (i : Fin rest.length) => a ⟨i.val + 1, by simp⟩) b) := rfl

@[sql_mem] theorem append_nil {l2 : List SQLTypeProxy}
    (a : TypedTupleOfList []) (b : TypedTupleOfList l2) :
    TypedTupleOfList.append a b = b := rfl

/-- The empty tail: two `TypedTupleOfList []` rows are always equal, so the recursion in
`cons_eq_iff` bottoms out in `True` rather than a vacuous function equality. -/
@[sql_mem] theorem nil_tuple_eq (a b : TypedTupleOfList []) : (a = b) ↔ True := by
  simp only [iff_true]
  funext ⟨i, hi⟩
  simp at hi

/-! ### Peeling a join row

`append_cons` rewrites `append a b` into a `cons` whose tail is another `append`, so `simp` will not
iterate it (the recursion shrinks a type index it cannot see). These peel a whole literal-width left
row in one step. The `show` matters: written plainly, the statement's type is `[t₀, t₁] ++ l₂`, while
the goal's type has already been normalised to `t₀ :: t₁ :: l₂` by `List.cons_append` — and then the
two never unify. Stating it at the reduced type is what makes it fire. Each is `rfl`. -/

@[sql_mem] theorem append_row_1 {t0 : SQLTypeProxy} {l2 : List SQLTypeProxy}
    (v0 : t0.type) (b : TypedTupleOfList l2) :
    (TypedTupleOfList.append (TypedTupleOfList.cons t0 v0 (TypedTupleOfList.nil)) b : TypedTupleOfList (t0 :: l2)) = TypedTupleOfList.cons t0 v0 (b) := rfl

@[sql_mem] theorem append_row_2 {t0 t1 : SQLTypeProxy} {l2 : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (b : TypedTupleOfList l2) :
    (TypedTupleOfList.append (TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.nil))) b : TypedTupleOfList (t0 :: t1 :: l2)) = TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (b)) := rfl

@[sql_mem] theorem append_row_3 {t0 t1 t2 : SQLTypeProxy} {l2 : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (b : TypedTupleOfList l2) :
    (TypedTupleOfList.append (TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.nil)))) b : TypedTupleOfList (t0 :: t1 :: t2 :: l2)) = TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (b))) := rfl

@[sql_mem] theorem append_row_4 {t0 t1 t2 t3 : SQLTypeProxy} {l2 : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (b : TypedTupleOfList l2) :
    (TypedTupleOfList.append (TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.nil))))) b : TypedTupleOfList (t0 :: t1 :: t2 :: t3 :: l2)) = TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (b)))) := rfl

@[sql_mem] theorem append_row_5 {t0 t1 t2 t3 t4 : SQLTypeProxy} {l2 : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (v4 : t4.type) (b : TypedTupleOfList l2) :
    (TypedTupleOfList.append (TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.nil)))))) b : TypedTupleOfList (t0 :: t1 :: t2 :: t3 :: t4 :: l2)) = TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (b))))) := rfl

@[sql_mem] theorem append_row_6 {t0 t1 t2 t3 t4 t5 : SQLTypeProxy} {l2 : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (v4 : t4.type) (v5 : t5.type) (b : TypedTupleOfList l2) :
    (TypedTupleOfList.append (TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (TypedTupleOfList.nil))))))) b : TypedTupleOfList (t0 :: t1 :: t2 :: t3 :: t4 :: t5 :: l2)) = TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (b)))))) := rfl

@[sql_mem] theorem append_row_7 {t0 t1 t2 t3 t4 t5 t6 : SQLTypeProxy} {l2 : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (v4 : t4.type) (v5 : t5.type) (v6 : t6.type) (b : TypedTupleOfList l2) :
    (TypedTupleOfList.append (TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (TypedTupleOfList.cons t6 v6 (TypedTupleOfList.nil)))))))) b : TypedTupleOfList (t0 :: t1 :: t2 :: t3 :: t4 :: t5 :: t6 :: l2)) = TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (TypedTupleOfList.cons t6 v6 (b))))))) := rfl

@[sql_mem] theorem append_row_8 {t0 t1 t2 t3 t4 t5 t6 t7 : SQLTypeProxy} {l2 : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (v4 : t4.type) (v5 : t5.type) (v6 : t6.type) (v7 : t7.type) (b : TypedTupleOfList l2) :
    (TypedTupleOfList.append (TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (TypedTupleOfList.cons t6 v6 (TypedTupleOfList.cons t7 v7 (TypedTupleOfList.nil))))))))) b : TypedTupleOfList (t0 :: t1 :: t2 :: t3 :: t4 :: t5 :: t6 :: t7 :: l2)) = TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (TypedTupleOfList.cons t6 v6 (TypedTupleOfList.cons t7 v7 (b)))))))) := rfl

@[sql_mem] theorem append_row_9 {t0 t1 t2 t3 t4 t5 t6 t7 t8 : SQLTypeProxy} {l2 : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (v4 : t4.type) (v5 : t5.type) (v6 : t6.type) (v7 : t7.type) (v8 : t8.type) (b : TypedTupleOfList l2) :
    (TypedTupleOfList.append (TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (TypedTupleOfList.cons t6 v6 (TypedTupleOfList.cons t7 v7 (TypedTupleOfList.cons t8 v8 (TypedTupleOfList.nil)))))))))) b : TypedTupleOfList (t0 :: t1 :: t2 :: t3 :: t4 :: t5 :: t6 :: t7 :: t8 :: l2)) = TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (TypedTupleOfList.cons t6 v6 (TypedTupleOfList.cons t7 v7 (TypedTupleOfList.cons t8 v8 (b))))))))) := rfl

/-! ### Indexing a built row

A row reaches the goal applied to a **numeral** index (`t 0`, `t 3`), which is `Fin.ofNat` and does not
match a `Fin.mk` pattern, so the `⟨0, _⟩`-keyed laws above never fire on it. These spell the numeral
cases out (each is `rfl`); the width covers every table in the benchmarks. -/

@[sql_mem] theorem cons_num_0 {t0 : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v0 : t0.type) (r : TypedTupleOfList rest) :
    TypedTupleOfList.cons t0 v0 r 0 = v0 := rfl

@[sql_mem] theorem cons_num_1 {t0 t1 : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (r : TypedTupleOfList rest) :
    TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 r) 1 = v1 := rfl

@[sql_mem] theorem cons_num_2 {t0 t1 t2 : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (r : TypedTupleOfList rest) :
    TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 r)) 2 = v2 := rfl

@[sql_mem] theorem cons_num_3 {t0 t1 t2 t3 : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (r : TypedTupleOfList rest) :
    TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 r))) 3 = v3 := rfl

@[sql_mem] theorem cons_num_4 {t0 t1 t2 t3 t4 : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (v4 : t4.type) (r : TypedTupleOfList rest) :
    TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 r)))) 4 = v4 := rfl

@[sql_mem] theorem cons_num_5 {t0 t1 t2 t3 t4 t5 : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (v4 : t4.type) (v5 : t5.type) (r : TypedTupleOfList rest) :
    TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 r))))) 5 = v5 := rfl

@[sql_mem] theorem cons_num_6 {t0 t1 t2 t3 t4 t5 t6 : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (v4 : t4.type) (v5 : t5.type) (v6 : t6.type) (r : TypedTupleOfList rest) :
    TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (TypedTupleOfList.cons t6 v6 r)))))) 6 = v6 := rfl

@[sql_mem] theorem cons_num_7 {t0 t1 t2 t3 t4 t5 t6 t7 : SQLTypeProxy} {rest : List SQLTypeProxy}
    (v0 : t0.type) (v1 : t1.type) (v2 : t2.type) (v3 : t3.type) (v4 : t4.type) (v5 : t5.type) (v6 : t6.type) (v7 : t7.type) (r : TypedTupleOfList rest) :
    TypedTupleOfList.cons t0 v0 (TypedTupleOfList.cons t1 v1 (TypedTupleOfList.cons t2 v2 (TypedTupleOfList.cons t3 v3 (TypedTupleOfList.cons t4 v4 (TypedTupleOfList.cons t5 v5 (TypedTupleOfList.cons t6 v6 (TypedTupleOfList.cons t7 v7 r))))))) 7 = v7 := rfl

@[sql_mem] theorem mem_union_rows (r s : TypedRelation colType) (x : TypedTuple colType) :
    x ∈ (union r s).rows ↔ x ∈ r.rows ∨ x ∈ s.rows := by simp [union]

@[sql_mem] theorem mem_intersection_rows (r s : TypedRelation colType) (x : TypedTuple colType) :
    x ∈ (intersection r s).rows ↔ x ∈ r.rows ∧ x ∈ s.rows := by simp [intersection]

@[sql_mem] theorem mem_minus_rows (r s : TypedRelation colType) (x : TypedTuple colType) :
    x ∈ (minus r s).rows ↔ x ∈ r.rows ∧ x ∉ s.rows := by simp [minus]

end LeanDatabase
