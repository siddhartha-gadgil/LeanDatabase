namespace LeanDatabase

/-!
## Typed Relations

This file defines typed relations, which are relations where each column has a specific type. The code so far is to get started and illusrate some basic operations.
-/

abbrev TypedTuple {n : Nat} (types : Fin n → Type) := (i : Fin n) → types i

def TypedRelation {n : Nat} (types : Fin n → Type) := List (TypedTuple types)

def projection {n m : Nat} (types : Fin n → Type) (indices : Fin m → Fin n) (rel : TypedRelation types) :
    TypedRelation (fun j => types (indices j)) :=
  rel.map (fun tuple j => tuple (indices j))

def typedColumn {n : Nat}  {types : Fin n → Type} {α : Type}
    (index : Fin n) (rel : TypedRelation types)(h : types index = α := by grind)  : List (α) :=
  rel.map (fun tuple => h ▸ tuple index) -- the ▸ is to cast types

def restriction {n : Nat} {types : Fin n → Type} (condition : (i : Fin n) → types i → Bool)
    (rel : TypedRelation types) : TypedRelation types :=
  rel.filter (fun tuple => ∀ i, condition i (tuple i))

theorem projection_length {n m : Nat} (types : Fin n → Type) (indices : Fin m → Fin n)
    (rel : TypedRelation types) :
    (projection types indices rel).length = rel.length := by
  simp [projection]

theorem restriction_length_le {n : Nat} {types : Fin n → Type}
    (condition : (i : Fin n) → types i → Bool) (rel : TypedRelation types) :
    (restriction condition rel).length ≤ rel.length := by
  simp [restriction]
  apply List.length_filter_le

theorem projection_compose {n m p : Nat} (types : Fin n → Type)
    (indices1 : Fin m → Fin n) (indices2 : Fin p → Fin m)
    (rel : TypedRelation types) :
    projection (fun j => types (indices1 j)) indices2 (projection types indices1 rel) =
    projection types (fun j => indices1 (indices2 j)) rel := by
  grind [List.map_eq_map_iff, projection]


end LeanDatabase
