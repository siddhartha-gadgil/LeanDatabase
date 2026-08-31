import LeanDatabase.Parser.Types

/-!
# `VALUES` — inline literal relations

`VALUES (v₁₁, …), (v₂₁, …), …` is a relation whose rows are the given constant tuples. `valuesRel`
builds one from an explicit `List` of tuples (deduped into the `Finset` by set semantics) plus the
column labels, so an equivalence like `SELECT A+B FROM (VALUES (10,1),(20,3)) = (VALUES (11),(23))`
reduces to a concrete `Finset` computation `grind`/`decide` can close.
-/

namespace LeanDatabase

def valuesRel (l : List SQLTypeProxy) (labels : List String)
    (rows : List (TypedTupleOfList l)) : TypedRelationOfList l :=
  { labels := fun i => labels.getD i.val "", rows := rows.toFinset }

end LeanDatabase
