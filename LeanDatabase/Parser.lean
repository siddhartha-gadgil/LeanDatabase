import LeanDatabase.Parser.Types
import LeanDatabase.Parser.Syntax
import LeanDatabase.Parser.Context
import LeanDatabase.Parser.Query
import LeanDatabase.SQLEquiv

/-!
# SQL → `TypedRelation` parser

Aggregates the parser modules and exposes the public API. The pipeline:

* `Parser.Types`   — SQL type reification (`SQLTypeProxy`) and list-indexed schemas.
* `Parser.Syntax`  — the `sql_query` / `sql_from` surface syntax and `JOIN` desugaring.
* `Parser.Context` — column-binding elaboration context + per-operator (algebra) elaborators.
* `Parser.Query`   — `elabSqlQuery` and the `parse*` entry points.

The `checkEquiv` API below parses two `WHERE`-predicate strings and asks `sql_equiv` whether they are
equal — the entry point used by the `sql_process` executable.
-/

open Lean Meta Elab Term

namespace LeanDatabase

/-- Parse the `first`/`second` filter strings from a JSON record (with its `schema`) and report
whether `sql_equiv` proves them equal. -/
def checkEquiv (data: Json) : TermElabM Bool := do
    let .ok schema := data.getObjValAs? (List Json) "schema" | throwError "Missing schema"
    let schemaStr : List (Name × SQLTypeProxy) ←  schema.mapM fun colJson => do
      let .ok name := colJson.getObjValAs? Name "name" | throwError "Missing column name"
      let .ok sqlType := colJson.getObjValAs? String "type" | throwError "Missing column type"
      pure (name, sqlProxy sqlType)
    let .ok firstStr := data.getObjValAs? String "first" | throwError "Missing first expression"
    let .ok secondStr := data.getObjValAs? String "second" | throwError "Missing second expression"
    let (firstExpr, _) ← parseSqlQuery [(`table, schemaStr)] firstStr
    let (secondExpr, _) ← parseSqlQuery [(`table, schemaStr)] secondStr
    -- IO.eprintln s!"Parsed first expression: {← ppExpr firstExpr}"
    -- IO.eprintln s!"Parsed second expression: {← ppExpr secondExpr}"
    let goalType ←  mkEq firstExpr secondExpr
    let mvar ← mkFreshExprMVar goalType
    let tac ← `(tacticSeq| sql_equiv)
    try
      withoutErrToSorry do
        let (goals, _) ← Elab.runTactic mvar.mvarId! tac
        Term.synthesizeSyntheticMVarsNoPostponing
        let ass? ← getExprMVarAssignment? mvar.mvarId!
        match ass? with
        | some ass =>
          -- IO.eprintln s!"Proof: {← ppExpr ass}"
          let ass ← instantiateExprMVars ass
          Term.synthesizeSyntheticMVarsNoPostponing
          if ass.hasSorry then
            -- IO.eprintln "Proof contains sorry."
            return false
          -- else
          --   IO.eprintln "No sorry in proof"
        | none => IO.eprintln "No proof found."
        pure goals.isEmpty
    catch _ =>
        pure false

def checkEquivCore (data: Json) : CoreM Bool := do
    let res :=  checkEquiv data |>.run' {} |>.run' {}
    res

def dataEg := json% {"schema": [{"name": "age", "type": "Int"}, {"name": "isActive", "type": "Bool"}],
  "first": "SELECT * FROM table WHERE age > 30 AND isActive","second": "SELECT * FROM table WHERE age > 30 && isActive && age > 20"}

-- #eval checkEquiv dataEg

end LeanDatabase
