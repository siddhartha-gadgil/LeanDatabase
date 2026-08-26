import LeanDatabase.Parser.Syntax

/-!
# GROUP BY

## What it means
`SELECT k, AGG(x) FROM t GROUP BY k` partitions the rows of `t` by the value of `k` and returns one
row per partition, carrying `k` and the aggregate of `x` over that partition.

## How we model it (set semantics — no dedicated grouping operator)
A `TypedRelation`'s rows are a `Finset`, so a query already denotes a *set*. We exploit that: a grouped
`SELECT` is elaborated as an ordinary per-row projection

    row ↦ (key(row), AGG-over-the-group-of key(row))

and the `Finset.image` inside `mapByList` **deduplicates** it. Every row of a partition maps to the
*same* output tuple (same key, and the aggregate depends only on the key), so the set collapses to
exactly one row per group. The aggregates (`groupSum key k rel`, `groupCount key k rel`, …) recompute
per key over the whole relation; the dedup does the partitioning. Hence `GROUP BY` needs no special
relation former — only a **key function**.

## The key is an expression, not just a column
`groupCount`/`groupSum` take any `key : TypedTuple → K` with `[DecidableEq K]`. A bare column is just
the special case `row ↦ row.col`; `GROUP BY UPPER(col)` uses `row ↦ UPPER(row.col)`, and
`GROUP BY ROUND(lat, 2), lon` a pair. So a `GROUP BY` item is a full **term**, and the key tuple is
built by projecting each term — the same machinery a `SELECT` projection uses (`groupAggExprsE` in
`Parser/Context.lean`). A positional `GROUP BY 1` is resolved *here* to the 1st SELECT item's term
before elaboration. Example the model proves equal:

    SELECT UPPER(city) AS c, COUNT(*) FROM t GROUP BY UPPER(city)
      ≡  SELECT UPPER(city) AS c, COUNT(*) FROM t GROUP BY 1
-/

open Lean

namespace LeanDatabase

/-- Resolve one `GROUP BY` item to the key term to elaborate: a positional `n` becomes the n-th SELECT
column's term (1-based); a bare ident that names a SELECT **alias** becomes that alias's expression
(`GROUP BY session_day` where `session_day` is `CAST(…) AS session_day`); everything else is passed
through unchanged. The key is elaborated against the *input* schema (columns keep their alias prefix,
e.g. `s.dept`), exactly like a SELECT column — so, unlike `ORDER BY`, the term is **not** base-qualified. -/
def resolveGroupItem (selCols : Array Syntax.Term) (aliases : List (Name × Syntax.Term))
    (item : Syntax.Term) : Syntax.Term :=
  match item.raw.isNatLit? with
  | some n => (selCols[n - 1]?).getD item          -- out of range: left to error at elaboration
  | none   =>
    match item.raw with
    | .ident _ _ v _ => ((aliases.find? (·.1 == v)).map (·.2)).getD item
    | _ => item

end LeanDatabase
