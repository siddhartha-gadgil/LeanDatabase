import Lean
import Mathlib
import LeanDatabase.TypedRelation

/-!
# SQL type reification (`SQLTypeProxy`) and list-indexed schemas

The foundational layer of the parser: a closed, finite universe of SQL column types
(`SQLTypeProxy`) that maps to concrete Lean types, plus the canonical *list-indexed* schema
encoding (`colTypeOfList` / `TypedTupleOfList` / `TypedRelationOfList`) that every parsed query
elaborates against.

This file deliberately depends only on `TypedRelation` (no SQL syntax), so the syntax layer and
the type layer can be developed independently — the elaboration layer (`Parser.Context`,
`Parser.Query`) is what ties them together.
-/

open Lean Meta

namespace LeanDatabase

/-- The closed universe of SQL column types we model. `ToExpr` lets the meta layer reflect a proxy
back into a term; `DecidableEq` drives the schema decidable-equality instance below. -/
inductive SQLTypeProxy where
  | int
  | bool
  | float
  | string
  | timestamp
  | nullable : SQLTypeProxy → SQLTypeProxy   -- a NULL-able column: `.type` becomes `Option _`
deriving Repr, DecidableEq, ToExpr


/-- The Lean type a proxy denotes. `@[reducible]` so type-class search sees through it. -/
@[reducible]
def SQLTypeProxy.type : SQLTypeProxy → Type
  | .int => Int
  | .bool => Bool
  | .float => Rat
  | .string => String
  | .timestamp => String
  | .nullable t => Option t.type

/-- Types the `AS`-clause probe tries. Includes each base type wrapped in `nullable` (one level —
NULL columns are `Option base`), so a `NULLIF`/nullable projection discovers its type. -/
def SQLTypeProxy.list : List SQLTypeProxy :=
  let base := [SQLTypeProxy.int, .bool, .float, .string, .timestamp]
  base ++ base.map .nullable

/-- Order a nullable column with `NULL` as the bottom element (NULLS FIRST). `Option α = WithBot α`
definitionally, so we borrow `WithBot`'s `LinearOrder`. This exists only so a nullable column's
`TypedRelation` satisfies the per-column `LinearOrder` the DDL macro emits; NULL ordering is not
otherwise observable under set semantics. Mathlib has no `LinearOrder (Option α)`, so no diamond. -/
instance instLinearOrderOption {α : Type} [LinearOrder α] : LinearOrder (Option α) :=
  WithBot.linearOrder


/-! ## NULL-propagating arithmetic

SQL evaluates any arithmetic with a `NULL` operand to `NULL`, so a nullable value (`NULLIF`, an
outer-join column, a nullable `CASE`) has to mix with ordinary arithmetic. These are exactly that
lifting — `Option.map`/`bind`, no approximation — and they are declared **only** for the numeric
column types `Option ℤ` / `Option ℚ`, so `WithBot ℕ` (`MAX`/`MIN`) keeps Mathlib's instances. The
mixed ℤ/ℚ shapes are spelled out because Lean's `binop%` inserts either an `ℤ → ℚ` coercion *or* an
`α → Option α` one, never both, so `CAST(a AS DOUBLE) / NULLIF(b, 0)` needs the combination named. -/

private def onR (f : α → β → γ) (a : α) (b : Option β) : Option γ := b.map (f a)
private def onL (f : α → β → γ) (a : Option α) (b : β) : Option γ := a.map (f · b)
private def on2 (f : α → β → γ) (a : Option α) (b : Option β) : Option γ := do pure (f (← a) (← b))

instance : Add (Option Int) := ⟨on2 (· + ·)⟩
instance : Add (Option Rat) := ⟨on2 (· + ·)⟩
instance : HAdd Rat (Option Int) (Option Rat) := ⟨onR (fun a b => a + (b : Rat))⟩
instance : HAdd (Option Int) Rat (Option Rat) := ⟨onL (fun a b => (a : Rat) + b)⟩
instance : HAdd Int (Option Rat) (Option Rat) := ⟨onR (fun a b => (a : Rat) + b)⟩
instance : HAdd (Option Rat) Int (Option Rat) := ⟨onL (fun a b => a + (b : Rat))⟩

instance : Sub (Option Int) := ⟨on2 (· - ·)⟩
instance : Sub (Option Rat) := ⟨on2 (· - ·)⟩
instance : HSub Rat (Option Int) (Option Rat) := ⟨onR (fun a b => a - (b : Rat))⟩
instance : HSub (Option Int) Rat (Option Rat) := ⟨onL (fun a b => (a : Rat) - b)⟩
instance : HSub Int (Option Rat) (Option Rat) := ⟨onR (fun a b => (a : Rat) - b)⟩
instance : HSub (Option Rat) Int (Option Rat) := ⟨onL (fun a b => a - (b : Rat))⟩

instance : Mul (Option Int) := ⟨on2 (· * ·)⟩
instance : Mul (Option Rat) := ⟨on2 (· * ·)⟩
instance : HMul Rat (Option Int) (Option Rat) := ⟨onR (fun a b => a * (b : Rat))⟩
instance : HMul (Option Int) Rat (Option Rat) := ⟨onL (fun a b => (a : Rat) * b)⟩
instance : HMul Int (Option Rat) (Option Rat) := ⟨onR (fun a b => (a : Rat) * b)⟩
instance : HMul (Option Rat) Int (Option Rat) := ⟨onL (fun a b => a * (b : Rat))⟩

instance : Div (Option Int) := ⟨on2 (· / ·)⟩
instance : Div (Option Rat) := ⟨on2 (· / ·)⟩
instance : HDiv Rat (Option Int) (Option Rat) := ⟨onR (fun a b => a / (b : Rat))⟩
instance : HDiv (Option Int) Rat (Option Rat) := ⟨onL (fun a b => (a : Rat) / b)⟩
instance : HDiv Int (Option Rat) (Option Rat) := ⟨onR (fun a b => (a : Rat) / b)⟩
instance : HDiv (Option Rat) Int (Option Rat) := ⟨onL (fun a b => a / (b : Rat))⟩

instance instDecidableEqProxyType : (t : SQLTypeProxy) → DecidableEq t.type
  | .int => inferInstance
  | .bool => inferInstance
  | .float => inferInstance
  | .string => inferInstance
  | .timestamp => inferInstance
  | .nullable t => have := instDecidableEqProxyType t; inferInstance

/-- The `Expr` of the Lean type a proxy denotes (the term-level mirror of `SQLTypeProxy.type`). -/
def typeExpr : SQLTypeProxy → Expr
  | .int => mkConst ``Int
  | .bool => mkConst ``Bool
  | .float => mkConst ``Rat
  | .string => mkConst ``String
  | .timestamp => mkConst ``String
  | .nullable t => mkApp (mkConst ``Option [0]) (typeExpr t)

/-- Map a DDL type string (`VARCHAR(…)`, `BIGINT`, `TIMESTAMP`, …) to a proxy. Matched by prefix,
defaulting to `string` for anything unrecognized. -/
def sqlProxy (sqlType : String) : SQLTypeProxy :=
  let s := sqlType.toLower
  if s.startsWith "varchar" then .string
  else if s.startsWith "int" then .int
  else if s.startsWith "bool" then .bool
  else if s.startsWith "float" then .float
  else if s.startsWith "double" then .float
  else if s.startsWith "real" then .float
  -- NUMBER/NUMERIC/DECIMAL carry an unknown scale → treat as real (Rat), never Int, so a division
  -- can't be laundered from real to truncating (the CAST hazard 2.4, at the DDL).
  else if s.startsWith "number" then .float
  else if s.startsWith "numeric" then .float
  else if s.startsWith "decimal" then .float
  else if s.startsWith "bigint" then .int
  else if s.startsWith "smallint" then .int
  else if s.startsWith "text" then .string
  else if s.startsWith "char" then .string
  else if s.startsWith "varchar" then .string
  else if s.startsWith "date" then .string
  else if s.startsWith "timestamp" then .timestamp
  else .string -- default to string for unrecognized types

/-- A schema as `Fin n → Type`, indexing a `List SQLTypeProxy` positionally. This is the canonical
form every parsed query targets. -/
@[reducible]
def colTypeOfList : (l : List SQLTypeProxy) → Fin l.length → Type
  -- Defined by *structural recursion* rather than `fun i => (l.get i).type`: `List.get` is
  -- semireducible, so the latter does not compute at `instances` transparency, and any term that
  -- indexes a row (`cons v r 0`) then fails to typecheck once `cons` itself is left folded — which is
  -- exactly what the membership route needs (`LeanDatabase/Membership.lean`).
  | t :: _, ⟨0, _⟩ => t.type
  | _ :: rest, ⟨i + 1, h⟩ => colTypeOfList rest ⟨i, by simp only [List.length_cons] at h; omega⟩

/-- The recursive definition agrees with the `List.get` one, which is how the generic per-column
instances below are still built. -/
theorem colTypeOfList_eq : ∀ (l : List SQLTypeProxy) (i : Fin l.length),
    colTypeOfList l i = (l.get i).type
  | _ :: _, ⟨0, _⟩ => rfl
  | _ :: rest, ⟨i + 1, h⟩ => colTypeOfList_eq rest ⟨i, by simp only [List.length_cons] at h; omega⟩

/-- Every column type is `Inhabited` — needed by the outer-join operators (`leftOuterJoin` uses a
default to build the `NULL`-padded rows). `Option _` is inhabited by `none`. -/
instance instInhabitedProxyType : (t : SQLTypeProxy) → Inhabited t.type
  | .int => inferInstance
  | .bool => inferInstance
  | .float => inferInstance
  | .string => inferInstance
  | .timestamp => inferInstance
  | .nullable _ => inferInstance

instance sqlTypeInhabited (l : List SQLTypeProxy) : (i : Fin l.length) → Inhabited (colTypeOfList l i) :=
  fun i => (colTypeOfList_eq l i) ▸ instInhabitedProxyType (l.get i)

/-- Every column type is a `LinearOrder` (needed by the per-column order the `CREATE TABLE` macro
otherwise emitted by hand). Provided generically here so many-column tables need no per-column
instance. `Option _` via `instLinearOrderOption`. -/
instance instLinearOrderProxyType : (t : SQLTypeProxy) → LinearOrder t.type
  | .int => inferInstance
  | .bool => inferInstance
  | .float => inferInstance
  | .string => inferInstance
  | .timestamp => inferInstance
  | .nullable t => @instLinearOrderOption _ (instLinearOrderProxyType t)

instance sqlTypeLinearOrder (l : List SQLTypeProxy) : (i : Fin l.length) → LinearOrder (colTypeOfList l i) :=
  fun i => (colTypeOfList_eq l i) ▸ instLinearOrderProxyType (l.get i)

instance sqlTypeDecEq (l: List SQLTypeProxy) : (i : Fin l.length) → DecidableEq (colTypeOfList l i) := by
  match l with
  | [] =>
    intro ⟨i, hi⟩
    simp at hi
  | t :: rest =>
    intro ⟨i, hi⟩
    match i with
    | 0 => exact inferInstance
    | j+1 =>
      exact sqlTypeDecEq rest ⟨j, by simp at hi; assumption⟩

-- Testing that decidable equality works for the generated types
example (l: List SQLTypeProxy) : TypedRelation (colTypeOfList l) :=
  emptyRel (fun _ => "dummy")

@[reducible]
def TypedTupleOfList (l: List SQLTypeProxy) : Type :=
  TypedTuple (colTypeOfList l)

@[reducible]
def TypedRelationOfList (l: List SQLTypeProxy) : Type :=
  TypedRelation (colTypeOfList l)

@[reducible]
def TypedTupleOfList.nil : TypedTupleOfList [] := fun ⟨i, hi⟩ => by simp at hi

-- NOT `@[reducible]`: a reducible `cons` is unfolded by `simp`/`grind` into `fun i => match i …`,
-- and congruence closure cannot then relate two rows built from equal components (that would need
-- rewriting under a binder). Keeping it folded is what lets the membership route reason about rows
-- as records — `cons_zero`/`cons_succ_apply` (Membership.lean) keep indexing computable.
def TypedTupleOfList.cons (t : SQLTypeProxy) (x: t.type) (ts : TypedTupleOfList rest) :
  TypedTupleOfList (t :: rest) := fun ⟨i, hi⟩ =>
  match i with
  | 0 => by simp [colTypeOfList]; exact x
  | j+1 => ts ⟨j, by grind⟩

/-- A single-column `TypedTupleOfList` is determined by its one entry — lets `simp`/`grind` reduce
a `key t = k` equality between wrapped `GROUP BY` keys down to plain component equality, which is
what the `HAVING`/`WHERE` predicate is actually stated in terms of. -/
@[simp]
theorem TypedTupleOfList.cons_nil_inj {t : SQLTypeProxy} {x y : t.type} :
    (TypedTupleOfList.cons t x TypedTupleOfList.nil = TypedTupleOfList.cons t y TypedTupleOfList.nil) ↔ x = y := by
  constructor
  · intro h
    have := congrFun h (0 : Fin 1)
    simpa [TypedTupleOfList.cons, colTypeOfList] using this
  · rintro rfl
    rfl

/-- The tail entry of a `cons` at a successor index — definitionally the tail (`rfl`). -/
theorem TypedTupleOfList.cons_succ {t : SQLTypeProxy} {rest : List SQLTypeProxy}
    (x : t.type) (xs : TypedTupleOfList rest) (i : Fin rest.length) :
    TypedTupleOfList.cons t x xs i.succ = xs i := rfl

/-- **General `cons` injectivity** — a multi-column `GROUP BY`/projection key equality splits into its
component equalities. Generalises `cons_nil_inj` past the single-column case, so `simp` reduces a
wrapped multi-key equality (`(a,b) = (a',b')`) to `a = a' ∧ b = b'` — what the `GROUP BY`-under-FD and
multi-column projection proofs are stated in. -/
@[simp]
theorem TypedTupleOfList.cons_inj {t : SQLTypeProxy} {rest : List SQLTypeProxy}
    {x y : t.type} {xs ys : TypedTupleOfList rest} :
    (TypedTupleOfList.cons t x xs = TypedTupleOfList.cons t y ys) ↔ (x = y ∧ xs = ys) := by
  constructor
  · intro h
    refine ⟨?_, ?_⟩
    · have e0 : TypedTupleOfList.cons t x xs ⟨0, Nat.succ_pos _⟩ = x := rfl
      have e1 : TypedTupleOfList.cons t y ys ⟨0, Nat.succ_pos _⟩ = y := rfl
      have := congrFun h (⟨0, Nat.succ_pos _⟩ : Fin (rest.length + 1))
      rw [e0, e1] at this
      exact this
    · funext i
      have := congrFun h i.succ
      rwa [TypedTupleOfList.cons_succ, TypedTupleOfList.cons_succ] at this
  · rintro ⟨rfl, rfl⟩; rfl

@[reducible]
def TypedTupleOfList.append (ts1 : TypedTupleOfList l1) (ts2 : TypedTupleOfList l2) :
  TypedTupleOfList (l1 ++ l2) := match l1 with
  | [] => ts2
  | t :: rest => TypedTupleOfList.cons t (ts1 ⟨0, by simp⟩) (TypedTupleOfList.append (fun ⟨i, hi⟩ => ts1 ⟨i+1, by grind⟩)  ts2)

@[reducible]
def TypedRelationOfList.nil : TypedRelationOfList [] :=
  {labels := fun ⟨i, hi⟩ => by simp at hi, rows := Finset.empty}

@[reducible]
def TypedRelationOfList.append (r1 : TypedRelationOfList l1) (r2 : TypedRelationOfList l2) :
  TypedRelationOfList (l1 ++ l2) :=
  {labels := fun ⟨i, hi⟩ => by
    simp at hi
    exact if h : i < l1.length then r1.labels ⟨i, h⟩ else r2.labels ⟨i - l1.length, by grind⟩,
   rows := (r1.rows ×ˢ r2.rows).image (fun ((ts1 : TypedTupleOfList l1), (ts2 : TypedTupleOfList l2)) => TypedTupleOfList.append ts1 ts2)}


/-! ## `LATERAL FLATTEN` — correlated array/semi-structured unnest (opaque)

Snowflake's `LATERAL FLATTEN(input => e)` (sqlglot emits it as `LATERAL UNNEST(input => e) AS
h(SEQ, KEY, PATH, INDEX, VALUE, THIS)`) expands an array/`VARIANT` value — per outer row — into a
table of six columns. We model it as one **opaque, correlated** operator: `lateralFlatten R f`
appends flatten's six columns to `R`, where `f : row → String` extracts the (VARIANT-as-`String`)
input from each outer row. It is opaque, so `sql_equiv` can only equate `lateralFlatten R₁ f₁` with
`lateralFlatten R₂ f₂` when `R₁ ≡ R₂` and `f₁ ≡ f₂` — a genuine equality (same unnest of the same
input). Different inputs stay unprovable, so no false equivalence can be derived. -/

/-- The six columns `FLATTEN` produces, in sqlglot's emitted order
`(SEQ, KEY, PATH, INDEX, VALUE, THIS)`. `VALUE`/`THIS` are `VARIANT`, modelled (like every VARIANT)
as `String`. -/
@[reducible] def flattenCols : List SQLTypeProxy :=
  [.int, .string, .string, .int, .string, .string]

/-- Correlated `LATERAL FLATTEN`: for each row of `R`, unnest `f row` (its VARIANT/array input) into
flatten's six columns, appended to the row. Opaque — sound by congruence (see the section note). -/
opaque lateralFlatten {l : List SQLTypeProxy}
    (R : TypedRelationOfList l) (f : TypedTupleOfList l → String) :
    TypedRelationOfList (l ++ flattenCols) :=
  TypedRelationOfList.append R (emptyRel (fun _ => ""))

/-- `WITH RECURSIVE cte AS (anchor UNION ALL step) …` — the recursive CTE's value is the least
fixpoint of `anchor ∪ step(cte)`, which we can't compute, so model it as one **opaque** operator over
the (faithful) `anchor` relation and the `step` iterate function. Sound by congruence, exactly like
`lateralFlatten`: two recursive CTEs are provably equal only when both `anchor` and `step` are — a
genuine equality; different recursions stay unprovable. -/
opaque recursiveCte {l : List SQLTypeProxy}
    (anchor : TypedRelationOfList l) (step : TypedRelationOfList l → TypedRelationOfList l) :
    TypedRelationOfList l := anchor

/-- Reflect a `List SQLTypeProxy` into the `Expr` of the corresponding Lean-level list. -/
def sqlTypeListExpr (l: List SQLTypeProxy) : MetaM Expr := do
  match l with
  | [] => mkAppOptM ``List.nil #[mkConst ``SQLTypeProxy]
  | t :: rest =>
    mkAppM ``List.cons #[toExpr t, ← sqlTypeListExpr rest]

end LeanDatabase
