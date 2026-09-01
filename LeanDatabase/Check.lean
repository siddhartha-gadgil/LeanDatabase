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
def parseSchema (schema : Json) : TermElabM (Name × List (Name × SQLTypeProxy)) := do
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
  -- The schema names come straight from the JSON (`ITM`), the hypothesis' table is lowered, so the
  -- lookup has to compare case-insensitively — as `parseSqlQuery` does for the query's own idents.
  let some (_, cols) := schemasStr.find? (fun (n, _) => lowerName n == tbl)
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
  else if let .ok fk := h.getObjValAs? (List Name) "foreign" then
    -- `"foreign": [childCol, parentTable, parentCol]` — referential integrity across two tables, so
    -- unlike the other kinds this one needs the *parent's* table variable and column projections too.
    match fk with
    | [c, ptbl, pcol] =>
      let pt := lowerName ptbl
      let some ptvar := tvarOf pt | throwError "HYPOTHESIS: unknown table {ptbl}"
      let some (_, pcols) := schemasStr.find? (fun (n, _) => lowerName n == pt)
        | throwError "HYPOTHESIS: unknown table {ptbl}"
      let (_, _, pSchemaExprs) ← columnProjectionsE (pcols.map (fun (c, ty) => (lowerName c, ty)))
      let pcl := lowerName pcol
      let some (_, pproj) := pSchemaExprs.find? (fun ((n, _), _) => n == pcl)
        | throwError "HYPOTHESIS: unknown column {pcol} in table {ptbl}"
      mkAppM ``LeanDatabase.ForeignKey #[← proj c, pproj, tvar, ptvar]
    | _ => throwError "HYPOTHESIS: `foreign` expects [childCol, parentTable, parentCol]"
  else if let .ok bj := h.getObjValAs? (List Name) "bijection" then
    match bj with
    | [a, b] => mkAppM ``LeanDatabase.SamePartition #[← proj a, ← proj b, tvar]
    | _ => throwError "HYPOTHESIS: `bijection` expects [a, b]"
  else
    throwError "HYPOTHESIS: expected one of `predicate`/`funcdep`/`unique`/`bijection`"

/-- Run `sql_equiv` on `mvar` and report whether it genuinely closed the goal.

An empty goal list is **not** sufficient: `Elab.runTactic` *admits* (i.e. `sorry`-closes) a goal when
the tactic throws, so a failing `sql_equiv` comes back as "no goals left". That is how the census used
to report `SELECT B FROM R WHERE A = 5 AND C < 1  ≡  SELECT B FROM R WHERE A < 10` as proved, a pair
VeriEQL refutes with a counterexample. So we also demand a **complete, `sorry`-free proof term**:
force the delayed assignments (`synthesizeSyntheticMVarsNoPostponing` — reading the assignment without
this is what previously *under*-reported valid proofs), then instantiate and inspect.

Returns the tactic's message on failure: `sql_equiv` now begins with a counterexample search, so a
failure can mean "these queries differ, here is the database" — which the census should report rather
than throw away. -/
private def proveMVar (mvar : Expr) : TermElabM (Bool × Option String) := do
  let tac ← `(tacticSeq| sql_equiv)
  try
    let (goals, _) ← Elab.runTactic mvar.mvarId! tac
    unless goals.isEmpty do return (false, none)
    let proof ← instantiateMVars mvar
    return (!proof.hasSorry, none)
  catch ex => pure (false, some (← ex.toMessageData.toString))

/-- Discharge `goal` under `props` as local assumptions (added one at a time, so the goal's metavariable
is created with every hypothesis already in context). -/
private def proveGoalUnderHyps (goal : Expr) : List Expr → TermElabM (Bool × Option String)
  | [] => do proveMVar (← mkFreshExprMVar goal)
  | p :: ps => withLocalDeclD `h p fun _ => proveGoalUnderHyps goal ps

/-- Discharge `body₁ = body₂` under `props` as local assumptions. -/
private def proveUnderHyps (body1 body2 : Expr) (props : List Expr) : TermElabM Bool := do
  return (← proveGoalUnderHyps (← mkEq body1 body2) props).1

/-- Prove `first ≡ second` — either as a plain function equality (no hypotheses) or, when
`hyps` is non-empty, as `body₁ = body₂` with the table fvars and hypotheses in local context
(mirroring a file's `theorem … (t) (h : hyp t) : … := by sql_equiv`). -/
private def checkPair (schemasStr : List (Name × List (Name × SQLTypeProxy)))
    (hyps : List Json) (firstStr secondStr : String) : TermElabM Bool := do
  let (firstExpr, _) ← parseSqlQuery schemasStr firstStr
  let (secondExpr, _) ← parseSqlQuery schemasStr secondStr
  if hyps.isEmpty then
    let mvar ← mkFreshExprMVar (← mkEq firstExpr secondExpr)
    return (← proveMVar mvar).1
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

/-- Proving census: one `{schemas, first, second, dataEq}` pair → does `sql_equiv` close the goal
`∀ tables, first ~= second` (when `dataEq`) or `first = second`? Mirrors a Problems `eq_i_j` theorem. -/
def provePair (data : Json) : TermElabM Json := do
  let .ok schemas := data.getObjValAs? (List Json) "schemas" | return json% {"proved": false, "error": "missing schemas"}
  let .ok first := data.getObjValAs? String "first" | return json% {"proved": false, "error": "missing first"}
  let .ok second := data.getObjValAs? String "second" | return json% {"proved": false, "error": "missing second"}
  let dataEq := (data.getObjValAs? Bool "dataEq").toOption.getD true
  -- Integrity constraints (a key, an FD, a per-row predicate) are *assumptions*, exactly as in a
  -- file's `HYPOTHESIS` block: most benchmark rewrites (e.g. dropping a `DISTINCT` over a key) are
  -- only equivalences under them, so a census without them measures the wrong thing.
  let hyps := (data.getObjValAs? (List Json) "hypotheses").toOption.getD []
  -- Elaboration and proving are reported separately: a pair whose *proof* runs out of budget did not
  -- fail to elaborate, and lumping the two together made timeouts look like unsupported SQL.
  let elab? : TermElabM (Except String (List (Name × List (Name × SQLTypeProxy)) × Expr × Expr)) := do
    try
      let schemasStr ← schemas.mapM parseSchema
      -- `sql_equiv` opens with a counterexample search; give its samplers the literals these queries
      -- mention, or every database it tries falls on the wrong side of `= 5` / `> 100000` / `= 'HELLO'`.
      LeanDatabase.Plausible.setPoolInEnv first second
      let (firstExpr, _) ← parseSqlQuery schemasStr first
      let (secondExpr, _) ← parseSqlQuery schemasStr second
      return .ok (schemasStr, firstExpr, secondExpr)
    catch ex => return .error (← ex.toMessageData.toString)
  match ← elab? with
  | .error e => return Json.mkObj [("proved", false), ("elaborated", false), ("error", Json.str e)]
  | .ok (schemasStr, firstExpr, secondExpr) =>
    try
      lambdaTelescope (← instantiateMVars firstExpr) fun tvars body1 => do
        let body2 ← instantiateLambda (← instantiateMVars secondExpr) tvars
        -- Building the goal can fail on its own: if the two queries have different *output column
        -- types* (a `LEFT JOIN` makes its right columns nullable, a plain join does not) there is no
        -- proposition to state, and the pair is not an equivalence for that reason alone.
        -- On a type mismatch (one side nullable, `Option τ` vs `τ`) fall back to the nullability-tolerant
        -- comparison `dataEqErased` (rows erased to monomorphic `UCell` lists), which is well-typed for
        -- any two column-type lists — SQL's "same values" notion, ignoring declared nullability.
        let goalType? ← try
            pure (some (← if dataEq then mkAppM ``LeanDatabase.dataEq #[body1, body2]
                          else mkEq body1 body2))
          catch _ => try pure (some (← mkAppM ``LeanDatabase.dataEqErased #[body1, body2]))
                     catch _ => pure none
        let some goalType := goalType?
          | return Json.mkObj [("proved", false), ("elaborated", true),
              ("counterexample", Json.str "the two queries have different output column types, \
                and not merely by nullability, so no database can make them equal")]
        let names := schemasStr.map (fun (n, _) => lowerName n)
        let tvarOf : Name → Option Expr := fun nm =>
          ((names.zip tvars.toList).find? (·.1 == nm)).map (·.2)
        let props ← hyps.mapM (hypothesisProp schemasStr tvarOf)
        let (ok, msg?) ← proveGoalUnderHyps goalType props
        -- `sql_equiv` starts with a counterexample search, so one kind of failure is worth far more
        -- than the rest: the pair is *not* an equivalence, and here is the database that shows it.
        let counterexample? := msg?.filter (fun m => (m.splitOn "not equivalent").length ≥ 2)
        return Json.mkObj [("proved", ok), ("elaborated", true),
          ("counterexample", match counterexample? with | some c => Json.str c | none => Json.null),
          -- A proof that ran out of budget is not a proof that failed on the merits.
          ("error", match msg?.filter (fun m => (m.splitOn "heartbeats").length ≥ 2) with
            | some m => Json.str m | none => Json.null)]
    catch ex =>
      return Json.mkObj [("proved", false), ("elaborated", true),
        ("error", Json.str (← ex.toMessageData.toString))]

def provePairCore (data : Json) : CoreM Json :=
  Core.withCurrHeartbeats (provePair data |>.run' {} |>.run' {})

/-- Debug: build the pair's goal, run `sql_equiv`, and return "PROVED", the residual goal count, or
`sql_equiv`'s failure message — so a failing pair can be diagnosed. -/
def debugPair (data : Json) : TermElabM String := do
  let .ok schemas := data.getObjValAs? (List Json) "schemas" | return "missing schemas"
  let .ok first := data.getObjValAs? String "first" | return "missing first"
  let .ok second := data.getObjValAs? String "second" | return "missing second"
  let dataEq := (data.getObjValAs? Bool "dataEq").toOption.getD true
  let schemasStr ← schemas.mapM parseSchema
  let (firstExpr, _) ← parseSqlQuery schemasStr first
  let (secondExpr, _) ← parseSqlQuery schemasStr second
  lambdaTelescope (← instantiateMVars firstExpr) fun tvars body1 => do
    let body2 ← instantiateLambda (← instantiateMVars secondExpr) tvars
    let goalType ← if dataEq then mkAppM ``LeanDatabase.dataEq #[body1, body2] else mkEq body1 body2
    let mvar ← mkFreshExprMVar goalType
    let tac ← `(tacticSeq| sql_equiv)
    -- A tactic error inside `runTactic` is *logged* and the goal admitted, so the reason is in the
    -- message log rather than thrown: remember where the log ends, and report what got added.
    let logMark := (← Core.getMessageLog).toList.length
    try
      withoutErrToSorry do
        let (goals, _) ← Elab.runTactic mvar.mvarId! tac
        let logged ← ((← Core.getMessageLog).toList.drop logMark).mapM (fun m => m.data.toString)
        -- Same admitted-goal trap as `proveMVar`: no goals left can still mean `sorry`.
        if goals.isEmpty then
          return if (← instantiateMVars mvar).hasSorry
                 then s!"FAILED (goal admitted by `sorry`):\n" ++ "\n".intercalate logged
                 else "PROVED"
        let strs ← goals.mapM fun g => do pure (← Meta.ppGoal g).pretty
        return s!"RESIDUAL ({goals.length} goals):\n" ++ "\n".intercalate strs
    catch e => return s!"FAILED: {← e.toMessageData.toString}"

def debugPairCore (data : Json) : CoreM String := do
  debugPair data |>.run' {} |>.run' {}

/-! ## Elaboration check (Lean-native corpus census)

`elabCheckOne` elaborates a single query against its schemas and reports the outcome **directly** from
the elaborator — no scraping of Lean's textual output. It catches the exception on failure and, on
success, still rejects a term that carries unresolved metavariables or `sorry` (an elaboration that
"succeeds" into an unprovable goal is a failure, not a pass). This is the authoritative corpus metric;
the Python driver only transpiles SQL and feeds `{schemas, query}` JSON. -/
def elabCheckOne (schemas : List Json) (sql : String) : TermElabM (Except String Unit) := do
  try
    let tables ← schemas.mapM parseSchema
    withoutErrToSorry do
      let (e, _) ← parseSqlQuery tables sql
      let e ← instantiateMVars e
      if e.hasExprMVar then return .error "elaborated with unresolved metavariables"
      else if e.hasSorry then return .error "elaborated with sorry"
      else return .ok ()
  catch ex => return .error (← ex.toMessageData.toString)

/-- Process one `{id?, schemas, query}` record → `{status: "ok"|"fail", error?}`. -/
def elabCheckCore (data : Json) : CoreM Json := do
  let run : TermElabM Json := do
    let .ok schemas := data.getObjValAs? (List Json) "schemas" | return json% {"status": "fail", "error": "missing schemas"}
    let .ok sql := data.getObjValAs? String "query" | return json% {"status": "fail", "error": "missing query"}
    match ← elabCheckOne schemas sql with
    | .ok _    => return json% {"status": "ok"}
    | .error e => return Json.mkObj [("status", "fail"), ("error", Json.str e)]
  run |>.run' {} |>.run' {}

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
