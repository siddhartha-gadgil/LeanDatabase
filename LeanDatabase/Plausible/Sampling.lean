import LeanDatabase.Parser.Types
import LeanDatabase.Plausible.Constants
import Plausible

/-!
# Sampling a database

`plausible` needs one thing to search for a counterexample database: a `SampleableExt` instance for a
relation. A row is a function `Fin n → …`, which can be neither printed nor shrunk, so we go the
standard `SampleableExt` route — sample a **proxy** (`RowProxy`, a plain record of column values) that
*is* `Repr`/`Shrinkable`/`Arbitrary`, and interpret it into a real row.

Shrinking then works at two levels: drop rows from the database, then simplify the values inside the
rows that remain — which is what turns a random hit into the small, readable database a person can
check by hand.

**Set semantics.** `interp` runs the sampled rows through `List.toFinset`, so duplicates collapse
*before* either query sees them: a database this module produces is always a set, and a counterexample
can never be a multiplicity artefact. `Plausible.Lemmas.sample_toFinset_dedup` pins that down.
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

/-- Integers and strings are drawn half the time from the **literals mined out of the query pair**
(`Plausible/Constants.lean`) — a predicate like `WHERE SIZE > 100000` or `WHERE YX = 'HELLO'` is false
on essentially every random value, so without this the search never gets past it. -/
instance instArbitraryProxyType : (t : SQLTypeProxy) → Arbitrary t.type
  -- The pool is read *inside* the generator, once per draw. Reading it while building the instance
  -- would capture whatever the pool held when the module was initialised: nothing.
  | .int => ⟨do
      let (ints, _) := LeanDatabase.Plausible.minedConstants ()
      LeanDatabase.Plausible.withMined ints (Arbitrary.arbitrary (α := Int))⟩
  -- Strings also draw from a tiny fixed alphabet: two rows must be able to *agree* on a string column
  -- or every join over one is empty and both queries trivially return nothing.
  | .string | .timestamp => ⟨do
      let (_, strs) := LeanDatabase.Plausible.minedConstants ()
      LeanDatabase.Plausible.withMined (strs ++ #["", "a", "b"]) (Arbitrary.arbitrary (α := String))⟩
  | .bool => inferInstance
  -- Rationals are sampled as small integers: the equivalences we test compare and combine them, so
  -- denominators are not where counterexamples hide.
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

/-- Shrink a row one column at a time (the head first, then the tail). -/
instance instShrinkableRow : {l : List SQLTypeProxy} → Shrinkable (RowProxy l)
  | [] => ⟨fun _ => []⟩
  | t :: rest => ⟨fun r =>
      match r with
      | .cons v tail =>
        ((instShrinkableProxyType t).shrink v).map (fun v' => .cons v' tail) ++
          ((instShrinkableRow (l := rest)).shrink tail).map (fun tail' => .cons v tail')⟩

/-! ## Relations -/

/-- A relation is sampled as a **list of rows**, deduplicated into the `Finset`. All labels are `""`:
`~=` ignores them, and a label difference is never the interesting counterexample. -/
instance instSampleableRelation {l : List SQLTypeProxy} :
    SampleableExt (TypedRelationOfList l) where
  proxy := List (RowProxy l)
  interp rows := { labels := fun _ => "", rows := (rows.map RowProxy.interp).toFinset }

end LeanDatabase
