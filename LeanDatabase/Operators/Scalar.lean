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

/-- Date/timestamp construction and truncation — dates are `String`s, so these are `String`-valued. -/
opaque toDate (x : String) : String := x
opaque toTimestamp (x : String) : String := x
opaque dateTrunc (unit : String) (x : String) : String := x

/-- String functions. -/
opaque upperOf (x : String) : String := x
opaque lowerOf (x : String) : String := x
opaque trimOf (x : String) : String := x
opaque lengthOf (x : String) : Int := 0
opaque concat (a : String) (b : String) : String := a
opaque substr (x : String) (start : Int) (len : Int) : String := x
opaque splitPart (x : String) (delim : String) (n : Int) : String := x
opaque regexpSubstr (x : String) (pat : String) : String := x
opaque replaceOf (x : String) (from_ : String) (to_ : String) : String := x

/-! ## `CAST` — a *real* coercion, never opaque (ROADMAP 2.4)

`CAST(int AS FLOAT)` must genuinely widen `Int → Rat`, because that is what turns *integer* division
into *real* division (`sf_bq030`). Modelling it opaquely would silently equate `a/b` (int division)
with `CAST(a AS FLOAT)/CAST(b AS FLOAT)` (real division) — a soundness hole. So the widening cast is
the honest `Int → Rat` coercion below. The *lossy* directions (`FLOAT → INT` truncation, casts to
string) carry no such hazard and are left opaque; they only ever need to cancel with themselves. -/

/-- `CAST(x AS FLOAT)` from an integer: the genuine `Int → Rat` coercion (NOT opaque). -/
def castIntToFloat (x : Int) : Rat := (x : Rat)

/-- `CAST(x AS INT)` from a float: lossy truncation — opaque (no laundering hazard). -/
opaque truncToInt (x : Rat) : Int := 0
/-- Casts to string — opaque, per source type. -/
opaque intToStr (x : Int) : String := ""
opaque floatToStr (x : Rat) : String := ""

end LeanDatabase.Scalar
