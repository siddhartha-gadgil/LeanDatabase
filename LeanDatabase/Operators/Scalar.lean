import LeanDatabase.RelationalAlgebra

/-!
# Scalar functions — uninterpreted (opaque) by default

`ROUND`, date-part extractors, string functions, … almost always appear *identically on both sides*
of a corpus equivalence, so they cancel by congruence and need **no** semantics. We model each as an
`opaque` constant: `Scalar.round x n = x` is deliberately **unprovable** (so we never launder a
rounding difference into an equality), while two identical `round x n` applications are equal by
`rfl`, and `round a n = round b n` reduces to `a = b`. That is exactly the behaviour Phase 2 wants.

A uniform dispatcher (à la `AggKind`) is *not* used here: result types differ per function
(`YEAR : String → Int`, `ROUND : α → α`, `UPPER : String → String`), so no single signature fits.
Instead every scalar is one `opaque` constant below plus one macro line in `Parser/Syntax.lean`.

**`CAST` is deliberately absent** — `CAST(int AS float)` changes division semantics and must be a real
coercion, not an opaque function (ROADMAP 2.4), so it is handled separately, not here.

Dates/timestamps are modelled as `String` (see `sqlProxy`), so the date extractors take `String`.
-/

namespace LeanDatabase.Scalar

/-- `ROUND(x)` / `ROUND(x, n)` — opaque; the digit count is carried but uninterpreted. -/
opaque round {α : Type} (x : α) (digits : Int) : α := x

/-- `ABS`/`CEIL`/`FLOOR` — numeric endomorphisms, uninterpreted. -/
opaque abs {α : Type} (x : α) : α := x
opaque ceil {α : Type} (x : α) : α := x
opaque floor {α : Type} (x : α) : α := x

/-- Date-part extractors. Dates are `String`s here; each returns an `Int` component. -/
opaque yearOf (x : String) : Int := 0
opaque monthOf (x : String) : Int := 0
opaque dayOf (x : String) : Int := 0

/-- String functions. -/
opaque upperOf (x : String) : String := x
opaque lowerOf (x : String) : String := x
opaque trimOf (x : String) : String := x
opaque lengthOf (x : String) : Int := 0

end LeanDatabase.Scalar
