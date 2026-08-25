import LeanDatabase.Operators.Aggregate

/-!
# Window aggregates (`AGG(e) OVER (PARTITION BY k)`)

A window **aggregate** attaches to every row the aggregate of `e` over that row's *partition* — the set
of rows sharing its `PARTITION BY` key — **keeping all rows** (unlike `GROUP BY`, which collapses each
partition to one row). Crucially this is **order-independent**: the value depends only on the *set* of
rows in the partition, so it is well-defined on a `Finset` and sound in our set semantics.

That makes a window aggregate a thin wrapper over the existing grouped aggregates: the window value at a
row `t` is just the grouped aggregate over the partition keyed by `key t`, i.e. `groupSum key (key t) rel`.
No new relational former is needed — a window `SELECT` is an ordinary projection whose new column is
`windowAgg`. (The order-*dependent* windows — `ROW_NUMBER`/`RANK`/`LAG`/`LEAD` and running aggregates
with an in-window `ORDER BY` — are **not** here: a `Finset` has no row order, so they cannot be modelled
soundly and are rejected at parse time rather than approximated.)
-/

namespace LeanDatabase.TypedAgg

open LeanDatabase

variable {n : Nat} {colType : Fin n → Type} [∀ i, DecidableEq (colType i)]
variable {K : Type} [DecidableEq K]

/-- `agg(f) OVER (PARTITION BY key)` at row `t`: the aggregate `g` of the partition keyed by `key t`,
computed over the whole relation `rel`. Parameterised by the grouped-aggregate operator `g` (one of
`groupSum`/`groupCount`/… ) so every window aggregate reuses the corresponding `GROUP BY` scalar. -/
@[reducible] def windowAgg {A : Type}
    (g : (TypedTuple colType → K) → K → TypedRelation colType → A)
    (key : TypedTuple colType → K) (rel : TypedRelation colType) (t : TypedTuple colType) : A :=
  g key (key t) rel

/-- The whole-relation window `OVER ()` (empty `PARTITION BY`): every row shares the one trivial key, so
the partition is the whole relation. -/
@[reducible] def windowAggAll {A : Type}
    (g : (TypedTuple colType → Unit) → Unit → TypedRelation colType → A)
    (rel : TypedRelation colType) (_t : TypedTuple colType) : A :=
  g (fun _ => ()) () rel

end LeanDatabase.TypedAgg
