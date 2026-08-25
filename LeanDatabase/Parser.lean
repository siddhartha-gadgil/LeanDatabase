import LeanDatabase.Parser.Types
import LeanDatabase.Parser.Syntax
import LeanDatabase.Parser.Context
import LeanDatabase.Parser.Query
import LeanDatabase.SQLEquiv
import LeanDatabase.LlmTactic.SQLEquivLLM

/-!
# SQL → `TypedRelation` parser

Aggregates the parser modules and exposes the public API. The pipeline:

* `Parser.Types`   — SQL type reification (`SQLTypeProxy`) and list-indexed schemas.
* `Parser.Syntax`  — the `sql_query` / `sql_from` surface syntax and `JOIN` desugaring.
* `Parser.Context` — column-binding elaboration context + per-operator (algebra) elaborators.
* `Parser.Query`   — `elabSqlQuery` and the `parse*` entry points.

The `sql%` term elaborator below splices a parsed query as a `TypedRelation` term. The JSON
equivalence-check entry point (`checkEquiv`, used by `sql_process`) lives in `LeanDatabase.Check`,
which can also depend on `Hypothesis`/`Constraints` (they import `Parser`, so it can't live here).
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

end LeanDatabase
