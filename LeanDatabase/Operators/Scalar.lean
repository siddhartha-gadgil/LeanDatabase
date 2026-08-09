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

/-- `ABS`/`CEIL`/`FLOOR`/`SIGN`/`SQRT`/`EXP`/`LN`/`TRUNC` — numeric endomorphisms, uninterpreted. -/
opaque abs {α : Type} (x : α) : α := x
opaque ceil {α : Type} (x : α) : α := x
opaque floor {α : Type} (x : α) : α := x
opaque sign {α : Type} (x : α) : α := x
opaque sqrtOf {α : Type} (x : α) : α := x
opaque expOf {α : Type} (x : α) : α := x
opaque lnOf {α : Type} (x : α) : α := x
opaque truncNum {α : Type} (x : α) : α := x

/-- Binary numeric functions, uninterpreted (`MOD`, `POWER`, `LOG`, `GREATEST`, `LEAST`). -/
opaque modOf {α : Type} (a b : α) : α := a
opaque powerOf {α : Type} (a b : α) : α := a
opaque logOf {α : Type} (a b : α) : α := a
opaque greatestOf {α : Type} (a b : α) : α := a
opaque leastOf {α : Type} (a b : α) : α := a

/-- Date-part extractors. Dates are `String`s here; each returns an `Int` component. -/
opaque yearOf (x : String) : Int := 0
opaque monthOf (x : String) : Int := 0
opaque dayOf (x : String) : Int := 0
opaque quarterOf (x : String) : Int := 0
opaque weekOf (x : String) : Int := 0
opaque hourOf (x : String) : Int := 0
opaque minuteOf (x : String) : Int := 0
opaque secondOf (x : String) : Int := 0
opaque dayOfWeek (x : String) : Int := 0
/-- `DATEDIFF(unit, a, b)` / `DATE_PART(part, d)` / `DATE_ADD`/`LAST_DAY` — dates are `String`s. -/
opaque dateDiff (unit a b : String) : Int := 0
opaque datePart (part d : String) : Int := 0
opaque dateAdd (unit : String) (n : Int) (d : String) : String := d
opaque lastDay (d : String) : String := d

/-- Date/timestamp construction and truncation — dates are `String`s, so these are `String`-valued. -/
opaque toDate (x : String) : String := x
opaque toTimestamp (x : String) : String := x
opaque nowVal : String := ""
opaque toChar {α : Type} (x : α) : String := ""
opaque toNumber {α : Type} (x : α) : Rat := 0
opaque dateTrunc (unit : String) (x : String) : String := x

/-- String functions. -/
opaque upperOf (x : String) : String := x
opaque lowerOf (x : String) : String := x
opaque trimOf (x : String) : String := x
opaque lengthOf (x : String) : Int := 0
opaque concat (a : String) (b : String) : String := a
opaque substr (x : String) (start : Int) (len : Int) : String := x
opaque substr2 (x : String) (start : Int) : String := x
opaque splitPart (x : String) (delim : String) (n : Int) : String := x
opaque regexpSubstr (x : String) (pat : String) : String := x
opaque replaceOf (x : String) (from_ : String) (to_ : String) : String := x
opaque regexpReplace (x pat rep : String) : String := x
opaque translateOf (s from_ to_ : String) : String := s
opaque regexpCount (s pat : String) : Int := 0
opaque regexpLike (s pat : String) : Bool := false
opaque bitand {α : Type} (a b : α) : α := a
opaque truncTo {α : Type} (x : α) (n : Int) : α := x
opaque splitOf (x : String) (delim : String) : String := x
opaque objectKeys (x : String) : String := x
opaque getPath (x : String) (path : String) : String := x
opaque arrayConstruct {α : Type} (a b : α) : String := ""
opaque leftOf (s : String) (n : Int) : String := s
opaque rightOf (s : String) (n : Int) : String := s
opaque containsOf (s sub : String) : Bool := false
opaque startsWithOf (s p : String) : Bool := false
opaque endsWithOf (s p : String) : Bool := false
opaque charIndexOf (sub s : String) : Int := 0
opaque instrOf (s sub : String) : Int := 0
opaque repeatOf (s : String) (n : Int) : String := s
opaque spaceOf (n : Int) : String := ""
opaque hashOf {α : Type} (x : α) : Int := 0
opaque md5Of (x : String) : String := x
opaque uuidString : String := ""
opaque toChar2 {α : Type} (x : α) (fmt : String) : String := ""
opaque stDistance {α : Type} (a b : α) : Rat := 0
opaque stMakePoint {α : Type} (a b : α) : String := ""
opaque haversine {α : Type} (a b c d : α) : Rat := 0
opaque ltrimOf (x : String) : String := x
opaque rtrimOf (x : String) : String := x
opaque initcapOf (x : String) : String := x
opaque reverseOf (x : String) : String := x
opaque lpadOf (x : String) (n : Int) (pad : String) : String := x
opaque rpadOf (x : String) (n : Int) (pad : String) : String := x
opaque strposOf (x : String) (sub : String) : Int := 0
opaque arrayToString (a : String) (delim : String) : String := a
/-- Snowflake semi-structured path access `v:key` / `v['key']` — an opaque sub-field of a VARIANT
(modelled as `String`). Cancels identically on both sides; the following `::TYPE` cast (if any) is
the real coercion. -/
opaque variantGet (v : String) (key : String) : String := v

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
/-- `CAST(str AS INT/FLOAT)` — opaque (a string, e.g. a VARIANT sub-field, has no numeric value we
model; sound because it's opaque, never a real coercion that could launder division). -/
opaque strToInt (x : String) : Int := 0
opaque strToFloat (x : String) : Rat := 0
/-- `CAST(x AS BOOLEAN)` from a non-Bool — opaque. -/
opaque toBoolOpaque {α : Type} (x : α) : Bool := false
/-- Casts to string — opaque, per source type. -/
opaque intToStr (x : Int) : String := ""
opaque floatToStr (x : Rat) : String := ""

end LeanDatabase.Scalar
