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

/-- `sql%(schema) "SELECT … FROM … WHERE …"` — a term-level elaborator that parses a **raw SQL
string** against `schema` and splices in the resulting `TypedRelation` term.

```lean
abbrev sch : List (Name × List (Name × SQLTypeProxy)) :=
  [(`t, [(`age, .int), (`active, .bool)])]

theorem and_reorder :
    sql%(sch) "SELECT * FROM t WHERE age > 30 AND active"
      = sql%(sch) "SELECT * FROM t WHERE active AND age > 30" := by sql_equiv
```

`schema` is any Lean term of type `List (Name × List (Name × SQLTypeProxy))`; it is evaluated at
elaboration time (via `evalExpr`) and handed to `parseSqlQuery`. -/
elab "sql%" "(" schemaStx:term ")" queryStr:str : term => do
  let schemaTy ← elabType (← `(List (Name × List (Name × SQLTypeProxy))))
  let schemaExpr ← elabTermEnsuringType schemaStx (some schemaTy)
  let schemaExpr ← instantiateMVars schemaExpr
  let schema ← unsafe evalExpr (List (Name × List (Name × SQLTypeProxy))) schemaTy schemaExpr
  let (e, _) ← parseSqlQuery schema queryStr.getString
  return e


/-- Parse the `first`/`second` filter strings from a JSON record (with its `schema`) and report
whether `sql_equiv` proves them equal. -/
def checkEquiv (data: Json) : TermElabM Bool := do
    let .ok schemas := data.getObjValAs? (List Json) "schemas" | throwError "Missing schema"
    let schemasStr : List (Name × List (Name × SQLTypeProxy)) ←  schemas.mapM (fun schema => do
      let .ok  name := schema.getObjValAs? Name "name" | throwError "Missing schema name"
      let .ok cols := schema.getObjValAs? (List Json) "columns" | throwError "Missing schema columns"
      let colStrs : List (Name × SQLTypeProxy) ← cols.mapM fun colJson => do
        let .ok name := colJson.getObjValAs? Name "name" | throwError "Missing column name"
        let .ok sqlType := colJson.getObjValAs? String "type" | throwError "Missing column type"
        pure (name, sqlProxy sqlType)
      pure (name, colStrs))
    let .ok queries := data.getObjValAs? (List String) "queries" | throwError "Missing queries"
    match queries with
    | [] => throwError "No queries provided"
    | firstStr :: restStrs =>
      for secondStr in restStrs do
        let (firstExpr, _) ← parseSqlQuery schemasStr firstStr
        let (secondExpr, _) ← parseSqlQuery schemasStr secondStr
        -- IO.eprintln s!"Parsed first expression: {← ppExpr firstExpr}"
        -- IO.eprintln s!"Parsed second expression: {← ppExpr secondExpr}"
        let goalType ←  mkEq firstExpr secondExpr
        let mvar ← mkFreshExprMVar goalType
        let tac ← `(tacticSeq| sql_equiv)
        let check ←
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
        unless check do
          return false
      return true

def checkEquivCore (data: Json) : CoreM Bool := do
    let res :=  checkEquiv data |>.run' {} |>.run' {}
    res

def dataEg := json% {"schemas": [{"name": "table", "columns": [{"name": "age", "type": "Int"}, {"name": "isActive", "type": "Bool"}]}],
  "queries": ["SELECT * FROM table WHERE age > 30 AND isActive", "SELECT * FROM table WHERE age > 30 && isActive && age > 20"]}

/-- info: true -/
#guard_msgs in
#eval checkEquiv dataEg

end LeanDatabase
