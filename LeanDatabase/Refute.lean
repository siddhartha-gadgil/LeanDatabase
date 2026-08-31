import LeanDatabase.Check

/-!
# Bounded refutation — the disproving half

Our proof route can only ever *prove*. VeriEQL's other half is that a bounded symbolic database plus
Z3 yields a **counterexample** when two queries differ, which is what tells you a pair is not worth
proving at all (29 of the 61 Literature pairs are genuinely inequivalent).

We get the same information the concrete way: build small databases, run both queries on them by
kernel/interpreter evaluation, and report the first database on which the two results differ. Bounded
and incomplete — silence here means "no small counterexample", never "equivalent" — but a hit is a
*proof of inequivalence* modulo our semantics, and it is cheap.

Values are drawn from a tiny domain, since a counterexample for a query over a handful of predicates
almost always exists inside one: it is the same rationale as their small bound (their Fig. 15 shows
most benchmarks are refuted at bound 2).
-/

open Lean Meta Elab Term

namespace LeanDatabase

/-- Row-set equality as a **Bool**. Building `Decidable.decide (A.rows = B.rows)` in meta code makes
instance search run on an un-reduced application and fail; here the instance is resolved once, at
definition time, so the interpreter only has to run it. -/
def rowsEqB {n : Nat} {ct : Fin n → Type} [∀ i, DecidableEq (ct i)]
    (a b : TypedRelation ct) : Bool := a.rows = b.rows

/-- The sample values we try per column type, in order. -/
private def sampleValues : SQLTypeProxy → List Expr
  | .int => [toExpr (0 : Int), toExpr (1 : Int), toExpr (-1 : Int)]
  | .bool => [toExpr false, toExpr true]
  | .string | .timestamp => [toExpr "", toExpr "a"]
  | _ => []

/-- One concrete row of the given column list, choosing each column's value by `pick`. -/
private def buildRow (cols : List SQLTypeProxy) (pick : Nat → Nat) : MetaM (Option Expr) := do
  let mut acc ← mkAppOptM ``TypedTupleOfList.nil #[]
  for (ty, i) in cols.zipIdx.reverse do
    let vals := sampleValues ty
    if h : vals.isEmpty then return none
    let v := vals[pick i % vals.length]!
    acc ← mkAppM ``TypedTupleOfList.cons #[toExpr ty, v, acc]
  return some acc

/-- A concrete relation over `cols` with the given rows. -/
private def buildRelation (cols : List SQLTypeProxy) (rows : List Expr) : MetaM Expr := do
  let lE ← sqlTypeListExpr cols
  let tupleTy ← mkAppM ``TypedTupleOfList #[lE]
  let rowList ← mkListLit tupleTy rows
  let rowSet ← mkAppM ``List.toFinset #[rowList]
  let labels ← withLocalDeclD `i (← mkAppM ``Fin #[toExpr cols.length]) fun i =>
    mkLambdaFVars #[i] (toExpr "")
  mkAppOptM ``TypedRelation.mk #[none, none, none, labels, rowSet]

/-- Try to refute `first ≡ second` on databases of at most `bound` rows per table. Returns
`{refuted, rows?}` — `rows?` describes the first differing database. -/
def refutePair (data : Json) (bound : Nat := 2) (tries : Nat := 24) : TermElabM Json := do
  try
    let .ok schemas := data.getObjValAs? (List Json) "schemas" | return json% {"refuted": false}
    let .ok first := data.getObjValAs? String "first" | return json% {"refuted": false}
    let .ok second := data.getObjValAs? String "second" | return json% {"refuted": false}
    let schemasStr ← schemas.mapM parseSchema
    let (firstExpr, _) ← parseSqlQuery schemasStr first
    let (secondExpr, _) ← parseSqlQuery schemasStr second
    let colLists := schemasStr.map (fun (_, cols) => cols.map (·.2))
    for seed in List.range tries do
      -- A cheap deterministic spread: table `t`, row `r`, column `i` gets sample `seed/(…) + …`.
      let nRows := 1 + seed % bound
      let mut rels : Array Expr := #[]
      let mut ok := true
      for (cols, t) in colLists.zipIdx do
        let mut rows : List Expr := []
        for r in List.range nRows do
          match ← buildRow cols (fun i => seed / (i + 1) + r * 2 + t) with
          | some row => rows := rows ++ [row]
          | none => ok := false
        if !ok then break
        rels := rels.push (← buildRelation cols rows)
      unless ok do return json% {"refuted": false, "error": "unsupported column type"}
      let a := (← instantiateMVars firstExpr).beta rels
      let b := (← instantiateMVars secondExpr).beta rels
      let dec ← mkAppM ``LeanDatabase.rowsEqB #[a, b]
      try
        if !(← unsafe evalExpr Bool (mkConst ``Bool) dec) then
          return Json.mkObj [("refuted", true), ("rows", Json.num nRows), ("seed", Json.num seed)]
      catch ex =>
        -- Evaluation is where an opaque scalar (or any non-computable operator) shows up; report it
        -- once rather than silently reading as "no counterexample".
        return Json.mkObj [("refuted", false), ("error", Json.str (← ex.toMessageData.toString))]
    return json% {"refuted": false}
  catch ex => return Json.mkObj [("refuted", false), ("error", Json.str (← ex.toMessageData.toString))]

unsafe def refutePairCore (data : Json) (bound : Nat := 2) (tries : Nat := 24) : CoreM Json :=
  Core.withCurrHeartbeats (refutePair data bound tries |>.run' {} |>.run' {})

end LeanDatabase
