import LeanDatabase.Parser
import LeanDatabase.Hypothesis
import LeanDatabase.Constraints

/-!
# Equivalence-check entry point (`sql_process`)

`checkEquiv` parses the `queries` of a JSON record against its `schemas` and asks `sql_equiv` whether
they are equal. Optional `hypotheses` declare **data assumptions** — the JSON analogue of a file's
`HYPOTHESIS` block: each becomes a local hypothesis about a table, so equivalences that only hold under
a stated fact (all rows satisfy a predicate, a functional dependency, a key, a value bijection) are
provable *under that assumption* while staying sound.

A hypothesis object names its `table` and one of:
* `"predicate": "<bool WHERE-expr>"` — every row satisfies the predicate (`RowsSatisfy`);
* `"funcdep": ["a", "b"]`            — functional dependency `a → b` (`FuncDepEq`);
* `"unique":  "k"`                   — `k` is a key (`FuncDepEq k id`);
* `"bijection": ["a", "b"]`          — `a` and `b` induce the same partition (`SamePartition`).

Lives in its own module (not `Parser`) because it references `RowsSatisfy`/`FuncDepEq`/`SamePartition`,
which import `Parser` and would otherwise form a cycle.
-/

open Lean Meta Elab Term

namespace LeanDatabase

/-- Parse one `schemas` entry into the `(name, columns)` shape the parser expects. -/
private def parseSchema (schema : Json) : TermElabM (Name × List (Name × SQLTypeProxy)) := do
  let .ok name := schema.getObjValAs? Name "name" | throwError "Missing schema name"
  let .ok cols := schema.getObjValAs? (List Json) "columns" | throwError "Missing schema columns"
  let colStrs : List (Name × SQLTypeProxy) ← cols.mapM fun colJson => do
    let .ok name := colJson.getObjValAs? Name "name" | throwError "Missing column name"
    let .ok sqlType := colJson.getObjValAs? String "type" | throwError "Missing column type"
    pure (name, sqlProxy sqlType)
  pure (name, colStrs)

/-- Build the `Prop` for one hypothesis JSON as a fact about the table fvar `tvar`
(of type `TypedRelationOfList …`). -/
private def hypothesisProp
    (schemasStr : List (Name × List (Name × SQLTypeProxy)))
    (tvarOf : Name → Option Expr) (h : Json) : TermElabM Expr := do
  let .ok tblRaw := h.getObjValAs? Name "table" | throwError "HYPOTHESIS: missing `table`"
  let tbl := lowerName tblRaw
  let some tvar := tvarOf tbl | throwError "HYPOTHESIS: unknown table {tblRaw}"
  let some (_, cols) := schemasStr.find? (·.1 == tbl)
    | throwError "HYPOTHESIS: unknown table {tblRaw}"
  let (tupleType, _, schemaExprs) ← columnProjectionsE (cols.map (fun (c, ty) => (lowerName c, ty)))
  let proj (c : Name) : TermElabM Expr := do
    let cl := lowerName c
    match schemaExprs.find? (fun ((n, _), _) => n == cl) with
    | some (_, e) => pure e
    | none => throwError "HYPOTHESIS: unknown column {c} in table {tblRaw}"
  if let .ok pred := h.getObjValAs? String "predicate" then
    -- per-row: extract the `WHERE` predicate `p` from a single-table parse, assert it on every row.
    let (e, _) ← parseSqlQuery [(tbl, cols)] s!"SELECT * FROM {tbl} WHERE {pred}"
    let .lam _ _ body _ := (← instantiateMVars e) | throwError "HYPOTHESIS: unexpected predicate shape"
    let (fn, args) := body.getAppFnArgs
    unless fn == ``LeanDatabase.restriction && args.size ≥ 5 do
      throwError "HYPOTHESIS: `predicate` did not produce a WHERE filter"
    mkAppM ``LeanDatabase.RowsSatisfy #[args[3]!, tvar]
  else if let .ok fd := h.getObjValAs? (List Name) "funcdep" then
    match fd with
    | [a, b] => mkAppM ``LeanDatabase.FuncDepEq #[← proj a, ← proj b, tvar]
    | _ => throwError "HYPOTHESIS: `funcdep` expects [a, b]"
  else if let .ok k := h.getObjValAs? Name "unique" then
    -- `k` determines the whole row: `det` is the identity `fun r => r` (matching the file `UNIQUE` sugar).
    let idTuple ← withLocalDeclD `r tupleType fun r => mkLambdaFVars #[r] r
    mkAppM ``LeanDatabase.FuncDepEq #[← proj k, idTuple, tvar]
  else if let .ok bj := h.getObjValAs? (List Name) "bijection" then
    match bj with
    | [a, b] => mkAppM ``LeanDatabase.SamePartition #[← proj a, ← proj b, tvar]
    | _ => throwError "HYPOTHESIS: `bijection` expects [a, b]"
  else
    throwError "HYPOTHESIS: expected one of `predicate`/`funcdep`/`unique`/`bijection`"

/-- Run `sql_equiv` on `mvar` and report whether it closed with a `sorry`-free proof. -/
private def proveMVar (mvar : Expr) : TermElabM Bool := do
  let tac ← `(tacticSeq| sql_equiv)
  try
    withoutErrToSorry do
      let (goals, _) ← Elab.runTactic mvar.mvarId! tac
      Term.synthesizeSyntheticMVarsNoPostponing
      match ← getExprMVarAssignment? mvar.mvarId! with
      | some ass =>
        let ass ← instantiateExprMVars ass
        Term.synthesizeSyntheticMVarsNoPostponing
        if ass.hasSorry then return false
        pure goals.isEmpty
      | none => pure false
  catch _ => pure false

/-- Discharge `body₁ = body₂` under `props` as local assumptions (added one at a time). -/
private def proveUnderHyps (body1 body2 : Expr) : List Expr → TermElabM Bool
  | [] => do proveMVar (← mkFreshExprMVar (← mkEq body1 body2))
  | p :: ps => withLocalDeclD `h p fun _ => proveUnderHyps body1 body2 ps

/-- Prove `first ≡ second` — either as a plain function equality (no hypotheses) or, when
`hyps` is non-empty, as `body₁ = body₂` with the table fvars and hypotheses in local context
(mirroring a file's `theorem … (t) (h : hyp t) : … := by sql_equiv`). -/
private def checkPair (schemasStr : List (Name × List (Name × SQLTypeProxy)))
    (hyps : List Json) (firstStr secondStr : String) : TermElabM Bool := do
  let (firstExpr, _) ← parseSqlQuery schemasStr firstStr
  let (secondExpr, _) ← parseSqlQuery schemasStr secondStr
  if hyps.isEmpty then
    let mvar ← mkFreshExprMVar (← mkEq firstExpr secondExpr)
    proveMVar mvar
  else
    lambdaTelescope (← instantiateMVars firstExpr) fun tvars body1 => do
      let body2 ← instantiateLambda (← instantiateMVars secondExpr) tvars
      let names := schemasStr.map (fun (n, _) => lowerName n)
      let tvarOf : Name → Option Expr := fun nm =>
        ((names.zip tvars.toList).find? (·.1 == nm)).map (·.2)
      let props ← hyps.mapM (hypothesisProp schemasStr tvarOf)
      proveUnderHyps body1 body2 props

/-- Parse the `queries` of a JSON record (with its `schemas` and optional `hypotheses`) and report
whether `sql_equiv` proves each equal to the first. -/
def checkEquiv (data : Json) : TermElabM Bool := do
  let .ok schemas := data.getObjValAs? (List Json) "schemas" | throwError "Missing schema"
  let schemasStr ← schemas.mapM parseSchema
  let hyps := (data.getObjValAs? (List Json) "hypotheses").toOption.getD []
  let .ok queries := data.getObjValAs? (List String) "queries" | throwError "Missing queries"
  match queries with
  | [] => throwError "No queries provided"
  | firstStr :: restStrs =>
    for secondStr in restStrs do
      unless ← checkPair schemasStr hyps firstStr secondStr do
        return false
    return true

def checkEquivCore (data : Json) : CoreM Bool := do
  checkEquiv data |>.run' {} |>.run' {}

def dataEg := json% {"schemas": [{"name": "table", "columns": [{"name": "age", "type": "Int"}, {"name": "isActive", "type": "Bool"}]}],
  "queries": ["SELECT * FROM table WHERE age > 30 AND isActive", "SELECT * FROM table WHERE age > 30 && isActive && age > 20"]}

/-- info: true -/
#guard_msgs in
#eval checkEquiv dataEg

/-- A data assumption (`age > 30` on every row) makes a redundant `WHERE age > 30` collapse. -/
def dataEgHyp := json% {"schemas": [{"name": "table", "columns": [{"name": "age", "type": "Int"}, {"name": "isActive", "type": "Bool"}]}],
  "hypotheses": [{"table": "table", "predicate": "age > 30"}],
  "queries": ["SELECT * FROM table WHERE isActive AND age > 30", "SELECT * FROM table WHERE isActive"]}

/-- info: true -/
#guard_msgs in
#eval checkEquiv dataEgHyp

end LeanDatabase
