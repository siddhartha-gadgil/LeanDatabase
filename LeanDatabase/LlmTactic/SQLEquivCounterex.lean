import LeanDatabase.SQLEquiv
import LeanDatabase.Operators.Values
import LeanDatabase.Plausible.Lemmas

/-!
# Counterexample checking for `sql_equiv_llm`

When the model judges a goal `∀ tables, Q1 ~= Q2` UNPROVABLE, it can instead supply a concrete
counterexample database (rows per table). This module BUILDS those tables as real `TableRel` values
(`valuesRel`, which dedups to a Finset — set semantics, reusing the same construction Plausible's
sampler interprets into), substitutes them for the goal's table binders, and asks Lean to
**`decide` the negation**. A `decide`-checked `¬ (Q1 db ~= Q2 db)` is a real disproof — the pair is
genuinely non-equivalent as stated (e.g. it needed an absent key/FK). The LLM only proposes the
witness; Lean is the judge. (`instDecidableDataEq` in `Plausible.Lemmas` makes `~=` decidable.)
-/

open Lean Meta Elab Tactic

namespace LeanDatabase.SQLEquivLLM

/-- The Lean type a proxy denotes, as an `Expr` (mirrors `SQLTypeProxy.type`). -/
def proxyTypeExpr : SQLTypeProxy → Expr
  | .int => mkConst ``Int
  | .bool => mkConst ``Bool
  | .float => mkConst ``Rat
  | .string | .timestamp => mkConst ``String
  | .nullable t => mkApp (mkConst ``Option [levelZero]) (proxyTypeExpr t)

/-- A value literal of type `ty.type` from a JSON scalar (null/number/string/bool).

A cell that does not match its column's type is an **error**, not a silently-coerced default. It used
to be the latter — a `null` or a string in an `INT` column became `0` — so a supplied database could
be quietly replaced by a different one, and the "difference" the checker then reported was between the
two queries on an input nobody wrote. -/
partial def mkCell (ty : SQLTypeProxy) (j : Json) : MetaM Expr := do
  match ty with
  | .int => match j.getInt? with
    | .ok v => return toExpr v
    | .error _ => throwError "cell {j} is not an INT"
  | .bool => match j.getBool? with
    | .ok v => return toExpr v
    | .error _ => throwError "cell {j} is not a BOOL"
  | .float => match j.getNum? with
    | .ok n => return toExpr ((n.mantissa : Rat) / (10 : Rat) ^ n.exponent)
    | .error _ => throwError "cell {j} is not a FLOAT"
  | .string | .timestamp => match j.getStr? with
    | .ok v => return toExpr v
    | .error _ => throwError "cell {j} is not a STRING"
  | .nullable t =>
    if j.isNull then return mkApp (mkConst ``Option.none [levelZero]) (proxyTypeExpr t)
    else return mkApp2 (mkConst ``Option.some [levelZero]) (proxyTypeExpr t) (← mkCell t j)

/-- Build a `TypedTupleOfList l` from a row of JSON cells.

The width must match the table exactly. Padding short rows with nulls and letting `zip` drop the extra
cells of long ones meant a row of the wrong shape was accepted as some *other* row — which is how
counterexamples got reported against 2-column tables handed 3 values. -/
def mkRow (l : List SQLTypeProxy) (vals : List Json) : MetaM Expr := do
  unless vals.length == l.length do
    throwError "row has {vals.length} value(s) but the table has {l.length} column(s): {Json.arr vals.toArray}"
  let mut acc := mkConst ``LeanDatabase.TypedTupleOfList.nil
  for (ty, j) in (l.zip vals).reverse do
    acc ← mkAppM ``LeanDatabase.TypedTupleOfList.cons #[toExpr ty, ← mkCell ty j, acc]
  return acc

/-- Build a concrete `TableRel`/`TypedRelationOfList l` from JSON rows via `valuesRel`. -/
def mkTable (l : List SQLTypeProxy) (rows : List (List Json)) : MetaM Expr := do
  let tupleTy := mkApp (mkConst ``LeanDatabase.TypedTupleOfList) (toExpr l)
  let rowExprs ← rows.mapM (mkRow l)
  let rowsList := rowExprs.foldr (fun r acc => mkApp3 (mkConst ``List.cons [levelZero]) tupleTy r acc)
                    (mkApp (mkConst ``List.nil [levelZero]) tupleTy)
  let labels := mkApp (mkConst ``List.nil [levelZero]) (mkConst ``String)
  mkAppM ``LeanDatabase.valuesRel #[toExpr l, labels, rowsList]

/-- Reduce an `Expr` for a `List SQLTypeProxy` to the Lean value, structurally. -/
partial def parseProxy (e : Expr) : Option SQLTypeProxy :=
  match e.getAppFnArgs with
  | (``SQLTypeProxy.int, _) => some .int
  | (``SQLTypeProxy.bool, _) => some .bool
  | (``SQLTypeProxy.float, _) => some .float
  | (``SQLTypeProxy.string, _) => some .string
  | (``SQLTypeProxy.timestamp, _) => some .timestamp
  | (``SQLTypeProxy.nullable, #[t]) => (parseProxy t).map .nullable
  | _ => none

partial def parseProxyList (e : Expr) : MetaM (Option (List SQLTypeProxy)) := do
  match (← whnf e).getAppFnArgs with
  | (``List.nil, _) => return some []
  | (``List.cons, #[_, hd, tl]) => do
    let some h := parseProxy (← whnf hd) | return none
    let some t ← parseProxyList tl | return none
    return some (h :: t)
  | _ => return none

/-- The column-proxy list of a relation fvar's type (`TableRel`/`TypedRelationOfList l` or
`TypedRelation (colTypeOfList l)`), if it is a relation. -/
def relColTypes (ty : Expr) : MetaM (Option (List SQLTypeProxy)) := do
  let ty ← whnfR ty
  let l? : Option Expr := match ty.getAppFnArgs with
    | (``LeanDatabase.TypedRelationOfList, #[l]) => some l
    | (``LeanDatabase.TypedRelation, #[_, ct, _]) =>  -- `@TypedRelation n (colTypeOfList l) inst`
      match ct.getAppFnArgs with
      | (``LeanDatabase.colTypeOfList, #[l]) => some l
      | _ => none
    | _ => none
  match l? with
  | none => return none
  | some l => parseProxyList (← Meta.reduce l)   -- reduce `EMP_schema.2.map (·.2)` to a literal list

/-- Given the goal's table binders (fvars) in order and a per-table list of JSON rows, substitute
concrete `valuesRel` tables and try to `decide` the NEGATION. Returns `some report` on a verified
disproof, `none` otherwise. `db` is positional: `db[i]` are the rows for the i-th table binder. -/
def checkCounterexample (goalTy : Expr) (tableFVars : Array (Expr × List SQLTypeProxy))
    (db : List (List (List Json))) : TacticM (Option String) := do
  -- Build a concrete table per binder (missing entries → empty table).
  let tables ← (List.range tableFVars.size).mapM fun i => do
    let (_, l) := tableFVars[i]!
    mkTable l (db.getD i [])
  let concrete := goalTy.replaceFVars (tableFVars.map (·.1)) tables.toArray
  -- Verify: `decide` proves the NEGATION (i.e. the concrete equivalence is decidably false).
  let negProp := mkApp (mkConst ``Not) concrete
  try
    let _ ← mkDecideProof negProp
    return some "decide-verified: the two queries differ on the given database (non-equivalent)."
  catch _ => return none

/-- The goal's relation binders (fvars whose type is a `TableRel`/`TypedRelation…`), in context order,
paired with their column-proxy lists. -/
def getTableBinders : TacticM (Array (Expr × List SQLTypeProxy)) := withMainContext do
  let mut out := #[]
  for decl in (← getLCtx) do
    if decl.isImplementationDetail then continue
    if let some l ← relColTypes decl.type then
      out := out.push (decl.toExpr, l)
  return out

/-- Parse the model's counterexample reply — a JSON array of tables, each a list of rows, each a list
of scalar cells — into the positional `db` shape. -/
def parseDb (raw : String) : Option (List (List (List Json))) := do
  let s := ((raw.replace "```json" "").replace "```" "").trimAscii.toString
  let .ok j := Json.parse s | none
  let .ok tables := j.getArr? | none
  tables.toList.mapM fun t => do
    let .ok rows := t.getArr? | none
    rows.toList.mapM fun r => do
      let .ok cells := r.getArr? | none
      pure cells.toList

/-- `plausible_sql`, like `plausible`/`sql_disprove`, is for a query-equivalence goal — with NO argument
it *searches* for a counterexample database (delegates to `sql_disprove`); with a JSON argument it
*checks a supplied* counterexample. The JSON is positional: `[rowsForT0, rowsForT1, …]`, each a list of
rows, each a list of column values (null / number / string / true|false).

Used on a goal `¬ (∀ tables, Q1 ~= Q2)` (the `CounterExample/` artifacts), it closes it: builds the
supplied tables, specialises the (impossible) equivalence to them, and derives `False` by `decide` —
so the disproof is machine-checked, the LLM only proposing the witness. -/
elab "plausible_sql" arg:(str)? : tactic => do
  match arg with
  | none => evalTactic (← `(tactic| sql_disprove))
  | some jsonStx =>
    let some db := parseDb jsonStx.getString
      | throwError "plausible_sql: counterexample is not a JSON array of tables"
    let goalTy ← instantiateMVars (← getMainTarget)
    -- Expect `¬ (∀ tables, Q1 ~= Q2)` (i.e. `(∀ tables, …) → False`).
    let some p := (← whnf goalTy).arrow?.map (·.1)
      | throwError "plausible_sql: goal is not `¬ (∀ tables, Q1 ~= Q2)`"
    let pf ← forallTelescopeReducing p fun tvars _ => do
      let mut tables := #[]
      for h : i in [0:tvars.size] do
        let some l ← relColTypes (← inferType tvars[i]) | throwError "binder {i} is not a table"
        tables := tables.push (← mkTable l (db.getD i []))
      withLocalDeclD `h p fun hh => do
        let happ := mkAppN hh tables
        let notPf ← mkDecideProof (mkApp (mkConst ``Not) (← inferType happ))
        mkLambdaFVars #[hh] (← mkAppOptM ``absurd #[none, some (mkConst ``False), some happ, some notPf])
    (← getMainGoal).assign pf
    logInfo s!"plausible_sql: found a counter-example — the two queries differ on the supplied database\n{jsonStx.getString}"

/-- The second-prompt instruction: rows only, JSON, no text. -/
def counterexPrompt : String := String.intercalate "\n" [
  "You judged this goal UNPROVABLE. Prove it by giving a COUNTEREXAMPLE database: concrete rows for",
  "each table binder such that the two queries return DIFFERENT result SETS.",
  "Base tables are SETS — rows within a table must be DISTINCT (identical rows collapse to one); to make",
  "a COUNT/GROUP BY differ, rows sharing a group key must still differ in another column.",
  "Output ONLY a JSON array; element i is the list of rows for the i-th table binder (t0, t1, … in the",
  "order shown in the goal). Each row is a list of column values in schema order (null for NULL,",
  "true/false for BOOL, numbers for INT, strings for STRING). NO text, NO markdown, NO fences." ]

end LeanDatabase.SQLEquivLLM
