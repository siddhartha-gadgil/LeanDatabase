import LeanDatabase.Parser.Types
import Plausible

/-!
# Property-based refutation — `plausible` over databases

The proof route can only ever *prove*. VeriEQL's other half is a counterexample when two queries
differ, which is what tells you a pair is not worth proving at all (29 of the 61 Literature pairs are
genuinely inequivalent). We get that from `plausible`, Lean's property-based tester: give it a way to
*sample* a database and it will search for a differing one and then **shrink** it, exactly like their
minimal counterexample models.

All it needs is a `SampleableExt` instance for a relation. A row is a function `Fin n → …`, which is
neither printable nor shrinkable, so we sample the standard `SampleableExt` way — through a **proxy**
(`RowProxy`, a plain inductive record of column values) that is `Repr`/`Shrinkable`/`Arbitrary`, and
interpret it into a real row. Shrinking then works at both levels: fewer rows, and smaller values in
each row.

    example (t : TypedRelationOfList [.int, .int, .int]) :
        (sql%([R_schema]) "SELECT B FROM R WHERE A = 5 AND C < 1") t
      ~= (sql%([R_schema]) "SELECT B FROM R WHERE A < 10") t := by
      plausible
-/

open Plausible

namespace LeanDatabase

/-! ## Per-column-type instances

`SQLTypeProxy.type` is a `match`, so each class has to be provided by recursion on the proxy. -/

instance instReprProxyType : (t : SQLTypeProxy) → Repr t.type
  | .int | .bool | .string | .timestamp | .float => inferInstance
  | .nullable t => @instReprOption _ (instReprProxyType t)

instance instShrinkableProxyType : (t : SQLTypeProxy) → Shrinkable t.type
  | .int | .bool | .string | .timestamp => inferInstance
  | .float => ⟨fun _ => []⟩
  | .nullable t => @Option.shrinkable _ (instShrinkableProxyType t)

instance instArbitraryProxyType : (t : SQLTypeProxy) → Arbitrary t.type
  | .int | .bool | .string | .timestamp => inferInstance
  -- Rationals are sampled as small integers: the equivalences we test compare and combine them, so
  -- the denominators are not where counterexamples hide.
  | .float => ⟨do return ((← Arbitrary.arbitrary (α := Int)) : Rat)⟩
  | .nullable t => @Option.Arbitrary _ (instArbitraryProxyType t)

/-! ## Rows -/

/-- The sampling proxy for a row: a plain record of column values, so it can be printed and shrunk.
`TypedTupleOfList` itself is a function type and can be neither. -/
inductive RowProxy : List SQLTypeProxy → Type
  | nil : RowProxy []
  | cons {t : SQLTypeProxy} {rest : List SQLTypeProxy} : t.type → RowProxy rest → RowProxy (t :: rest)

/-- Interpret a sampled row as an actual tuple. -/
def RowProxy.interp : {l : List SQLTypeProxy} → RowProxy l → TypedTupleOfList l
  | [], .nil => TypedTupleOfList.nil
  | t :: _, .cons v r => TypedTupleOfList.cons t v r.interp

/-- Column values of a sampled row, for printing. -/
def RowProxy.reprList : {l : List SQLTypeProxy} → RowProxy l → List Std.Format
  | [], .nil => []
  | t :: _, .cons v r => (instReprProxyType t).reprPrec v 0 :: r.reprList

instance : {l : List SQLTypeProxy} → Repr (RowProxy l) :=
  fun {_} => ⟨fun r _ => Std.Format.paren (Std.Format.joinSep r.reprList ", ")⟩

instance instArbitraryRow : {l : List SQLTypeProxy} → Arbitrary (RowProxy l)
  | [] => ⟨return .nil⟩
  | t :: rest => ⟨do
      let v ← (instArbitraryProxyType t).arbitrary
      let r ← (instArbitraryRow (l := rest)).arbitrary
      return .cons v r⟩

/-- Shrink a row by shrinking one column at a time (the head first, then the tail). -/
instance instShrinkableRow : {l : List SQLTypeProxy} → Shrinkable (RowProxy l)
  | [] => ⟨fun _ => []⟩
  | t :: rest => ⟨fun r =>
      match r with
      | .cons v tail =>
        ((instShrinkableProxyType t).shrink v).map (fun v' => .cons v' tail) ++
          ((instShrinkableRow (l := rest)).shrink tail).map (fun tail' => .cons v tail')⟩

/-! ## Relations -/

/-- A relation is sampled as a **list of rows** (deduplicated into the `Finset`), so `plausible`
shrinks a counterexample database by dropping rows and then by simplifying the values in them. All
labels are `""`: `~=` ignores them, and a label difference is never the interesting counterexample. -/
instance instSampleableRelation {l : List SQLTypeProxy} :
    SampleableExt (TypedRelationOfList l) where
  proxy := List (RowProxy l)
  interp rows := { labels := fun _ => "", rows := (rows.map RowProxy.interp).toFinset }

end LeanDatabase
