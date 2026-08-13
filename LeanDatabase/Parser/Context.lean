import LeanDatabase.Parser.Types
import LeanDatabase.Parser.Syntax
import LeanDatabase.SQLToolbox
import LeanDatabase.Operators.Scalar

/-!
# Elaboration context + per-operator (algebra) elaborators

This is the layer that joins the *syntax* (`Parser.Syntax`) to the *type model* (`Parser.Types`):
-/

open Lean Meta Elab Term

namespace LeanDatabase

/-! ## Type-probing for `AS` expressions -/

/-- Elaborate a `SELECT`-list expression, discovering its column type by trying each proxy type in
turn and keeping the first that elaborates. -/
def elabAsSql (stx: Syntax) : TermElabM (SQLTypeProxy × Expr) := do
  let res? : Option (SQLTypeProxy × Expr) ← SQLTypeProxy.list.findSomeM? (fun t => do
    let typeExpr := typeExpr t
    try
      let e ← withoutErrToSorry do
        elabTermEnsuringType stx typeExpr
      Term.synthesizeSyntheticMVarsNoPostponing
      pure (t, e)
    catch _ => pure none
  )
  match res? with
  | some res => pure res
  | none => throwError s!"Failed to parse type in AS clause: {← PrettyPrinter.ppCategory `term stx}"

/-- `CAST(x AS <type>)` — type-directed (see `Operators/Scalar.lean`). Unlike the opaque scalars,
CAST inspects the *source* type: `Int → FLOAT` is the genuine `Int → Rat` coercion (so a division
downstream is real, not integer — ROADMAP 2.4), while lossy directions stay opaque. -/
elab_rules : term
  | `(CAST($x AS $ty:sql_cast_type)) => do
    let xe ← elabTerm x none
    Term.synthesizeSyntheticMVarsNoPostponing
    let xt ← whnf (← instantiateMVars (← inferType xe))
    let isInt := xt.isConstOf ``Int
    let isRat := xt.isConstOf ``Rat
    let isStr := xt.isConstOf ``String
    let toFloat : TermElabM Expr := do
      if isRat then pure xe
      else if isInt then mkAppM ``LeanDatabase.Scalar.castIntToFloat #[xe]
      else if isStr then mkAppM ``LeanDatabase.Scalar.strToFloat #[xe]
      else throwError s!"CAST(_ AS FLOAT): unsupported source type {← ppExpr xt}"
    let toInt : TermElabM Expr := do
      if isInt then pure xe
      else if isRat then mkAppM ``LeanDatabase.Scalar.truncToInt #[xe]
      else if isStr then mkAppM ``LeanDatabase.Scalar.strToInt #[xe]
      else throwError s!"CAST(_ AS INT): unsupported source type {← ppExpr xt}"
    let toStr : TermElabM Expr := do
      if isStr then pure xe
      else if isInt then mkAppM ``LeanDatabase.Scalar.intToStr #[xe]
      else if isRat then mkAppM ``LeanDatabase.Scalar.floatToStr #[xe]
      else throwError s!"CAST(_ AS STRING): unsupported source type {← ppExpr xt}"
    -- `DATE`/`TIMESTAMP`/`VARIANT` are `String`-valued in our model; `BOOLEAN` is opaque.
    let toBool : TermElabM Expr := do
      if xt.isConstOf ``Bool then pure xe else mkAppM ``LeanDatabase.Scalar.toBoolOpaque #[xe]
    match ty with
    | `(sql_cast_type| INT) | `(sql_cast_type| INTEGER) | `(sql_cast_type| BIGINT)
    | `(sql_cast_type| NUMBER) => toInt
    | `(sql_cast_type| FLOAT) | `(sql_cast_type| DOUBLE) | `(sql_cast_type| REAL)
    | `(sql_cast_type| NUMERIC) | `(sql_cast_type| DECIMAL)
    | `(sql_cast_type| NUMBER($_,*)) | `(sql_cast_type| NUMERIC($_,*))
    | `(sql_cast_type| DECIMAL($_,*)) => toFloat
    | `(sql_cast_type| STRING) | `(sql_cast_type| TEXT) | `(sql_cast_type| VARCHAR)
    | `(sql_cast_type| CHAR) | `(sql_cast_type| VARCHAR($_)) | `(sql_cast_type| CHAR($_))
    | `(sql_cast_type| DATE) | `(sql_cast_type| TIMESTAMP) | `(sql_cast_type| DATETIME)
    | `(sql_cast_type| VARIANT) => toStr
    | `(sql_cast_type| BOOLEAN) => toBool
    | _ => throwUnsupportedSyntax

/-! ## Column-binding context -/

def withLetColumnVars  (columns : List ((Name × SQLTypeProxy) × Expr)) (typedTupleVar : Expr) (usedName : Name → Bool)
    (k : Array Expr → TermElabM α )  : TermElabM α := do
  match columns with
  | [] => k #[]
  | ((name, colType), projExpr) :: rest => do
    -- Only bind columns the query actually references; skipping the unused ones keeps the term (and
    -- the goal `grind` sees) narrow. The tuple lambda arg is bound regardless (in `mkLambdaLetsFVars`),
    -- so the relation type is unchanged — this is a pure dead-`let` elimination.
    if !usedName name then
      withLetColumnVars rest typedTupleVar usedName k
    else
    let colTypeExpr := typeExpr colType
    let funcName := name ++ `proj
    let tupleType ← inferType typedTupleVar
    let funcType ← mkArrow tupleType colTypeExpr
    withLetDecl funcName funcType projExpr fun funcVar => do
      let colExpr ← mkAppM' funcVar #[typedTupleVar]
      let colExpr ← zetaReduce colExpr
      withLetDecl name colTypeExpr colExpr fun localVar => do
        let letVars := #[funcVar, localVar]
        withLetColumnVars rest typedTupleVar usedName (fun restExpr => k (letVars ++ restExpr))

def mkLambdaLetsFVars (vars : List (Expr × Array Expr)) (k: TermElabM Expr) : TermElabM Expr := do
  match vars with
  | [] => k
  | (var, letVars) :: rest => do
    mkLambdaFVars #[var] (← mkLetFVars letVars (← mkLambdaLetsFVars rest k))

-- #eval Name.components `tableA.x |>.getLast?

def schemaWithFullNames (schemaName: Name) (schema : List (Name × SQLTypeProxy)) : List (Name × SQLTypeProxy) :=
  schema.map (fun (name, colType) =>
    let fullName :=
      if schemaName.isPrefixOf name then name else schemaName ++ name
    (fullName, colType))

theorem schemaWithFullNames_eq (schemaName: Name) (schema : List (Name × SQLTypeProxy)) :
    schemaWithFullNames schemaName schema = schema.map (fun (name, colType) =>
      let fullName := if schemaName.isPrefixOf name then name else schemaName ++ name
      (fullName, colType)) := by rfl

theorem schemaWithFullNames_length (schemaName: Name) (schema : List (Name × SQLTypeProxy)) :
    (schemaWithFullNames schemaName schema).length = schema.length := by simp [schemaWithFullNames]

syntax "COUNT" "(" "*" ")" : term
syntax "COUNT" "(" term ")" : term
syntax "COUNT" "(" "DISTINCT" term ")" : term
syntax "SUM" "(" term ")" : term
syntax "SUM" "(" "DISTINCT" term ")" : term
syntax "AVG" "(" term ")" : term
syntax "AVG" "(" "DISTINCT" term ")" : term
syntax "MIN" "(" term ")" : term
syntax "MAX" "(" term ")" : term
syntax "BOOL_AND" "(" term ")" : term
syntax "EVERY" "(" term ")" : term
syntax "BOOL_OR" "(" term ")" : term
syntax "COUNT_IF" "(" term ")" : term
syntax "APPROX_COUNT_DISTINCT" "(" term ")" : term
syntax "STDDEV" "(" term ")" : term
syntax "STDDEV_POP" "(" term ")" : term
syntax "STDDEV_SAMP" "(" term ")" : term
syntax "VARIANCE" "(" term ")" : term
syntax "VAR_POP" "(" term ")" : term
syntax "VAR_SAMP" "(" term ")" : term

def expandNames (labels : List Name) (stx: Syntax) (aliases : List (Name × Name) := []) :
    MetaM Syntax := do
  let pairs ← labels.filterMapM fun label => do
    let shorter? := label.components.getLast?
    pure <| shorter?.map fun shorter => (shorter, label.getPrefix)
  stx.replaceM fun id => do
    let idName := id.getId
    -- alias-qualified `o.col` → `base.col` (the table's canonical prefix)
    match aliases.find? (fun (a, _) => a != idName && a.isPrefixOf idName) with
    | some (a, base) => pure <| mkIdent <| idName.replacePrefix a base
    | none =>
      match pairs.find? (fun (shorter, _) => shorter.isPrefixOf idName) with
      | some (_, pfx) => pure <| mkIdent <| pfx ++ idName
      | none => return none

/--
Expressions for projection functions for each column in a schema, along with the type of the tuple that contains them.
-/
def columnProjectionsE (schema : List (Name × SQLTypeProxy)) :
  MetaM <| Expr × Expr × (List ((Name × SQLTypeProxy) × Expr)) := do
    let colTypes := schema.map (fun (_, colType) => colType)
    let listExpr ← sqlTypeListExpr colTypes
    let tupleType ← mkAppM ``TypedTupleOfList #[listExpr]
    let relType ← mkAppM ``TypedRelationOfList #[listExpr]
    let colExprs ← List.finRange colTypes.length |>.mapM fun i => do
        let index := toExpr i
        withLocalDeclD `typedTuple tupleType fun typedTuple => do
          let value ← mkAppM' typedTuple #[index]
          mkLambdaFVars #[typedTuple] value
    let schemaExprs := schema.zip colExprs
    return (tupleType, relType, schemaExprs)

def exprTypeListTuple (colExprsTypes : List (SQLTypeProxy × Expr)) : MetaM Expr := do
  colExprsTypes.foldrM (fun (colType, expr) acc => do
    mkAppM ``TypedTupleOfList.cons #[toExpr colType, expr, acc]) (mkConst ``TypedTupleOfList.nil)

/--
Projects onto a subcollection of columns. Returns expressions for the projection function, domain and codomain types.
-/
def subcolumsProjectionsE (schema : List (Name × SQLTypeProxy)) (includeColumn : Name → Bool) :
  MetaM <| Expr × Expr × Expr := do
    let colTypes := schema.map (fun (_, colType) => colType)
    let listExpr ← sqlTypeListExpr colTypes
    let domainE ← mkAppM ``TypedTupleOfList #[listExpr]
    let subcolTypes := schema.filterMap fun (name, colType) =>
      if includeColumn name then some colType else none
    let codomainE ← mkAppM ``TypedTupleOfList #[← sqlTypeListExpr subcolTypes]
    let projE ←
      withLocalDeclD `typedTuple domainE fun typedTuple => do
      let colExprs ← List.finRange schema.length |>.filterMapM fun i => do
        let index := toExpr i
        let (name, colType) := schema.get i
        if includeColumn name then do
          let value ← mkAppM' typedTuple #[index]
          pure <| some (colType, value)
        else
          pure none
      let value ← exprTypeListTuple colExprs
      mkLambdaFVars #[typedTuple] value
    return (projE, domainE, codomainE)

/--
info: LeanDatabase.TypedAgg.groupSum {n : ℕ} {colType : Fin n → Type} [(i : Fin n) → DecidableEq (colType i)] {K : Type}
  [DecidableEq K] (key : TypedTuple colType → K) (k : K) (rel : TypedRelation colType) (f : TypedTuple colType → ℤ) : ℤ
-/
#guard_msgs in
#check groupSum

/--
info: LeanDatabase.TypedAgg.groupCount {n : ℕ} {colType : Fin n → Type} [(i : Fin n) → DecidableEq (colType i)] {K : Type}
  [DecidableEq K] (key : TypedTuple colType → K) (k : K) (rel : TypedRelation colType) : ℕ
-/
#guard_msgs in
#check groupCount


def withSchemasTupleVars (schemas : List (Name × List (Name × SQLTypeProxy))) (usedName : Name → Bool)
    (k : List (Expr × Array Expr) → TermElabM α) : TermElabM α := do
  match schemas with
  | [] => k []
  | (schemaName, schema) :: rest => do
    let (type, _, columnExprs) ← columnProjectionsE (schemaWithFullNames schemaName schema)
    withLocalDeclD (schemaName ++ `coords) type fun typedTuple => do
      withLetColumnVars  columnExprs typedTuple usedName
        fun letVars => do
          withSchemasTupleVars rest usedName fun rest =>
          k ((typedTuple, letVars) :: rest)

/-- The aggregate operators we lift out of `SELECT`/`HAVING` over an arbitrary expression.
Adding an aggregate = one constructor here, one line each in `AggKind.op` / `.summand` / `.wrapNat`
/ `.resultType`, and one match arm in `liftAggExprs`. -/
inductive AggKind where
  | sum | min | max | avg | count
  | sumDistinct | countDistinct | avgDistinct
  | boolAnd | boolOr
  | stddev | variance
  deriving DecidableEq, Inhabited

/-- The summand shape: `void` (no argument, `COUNT(*)`), an `Int`/`Bool` expression, or a type-probed
expression (`COUNT(DISTINCT …)`, which counts distinct values of any column type). -/
inductive AggSummand | void | int | bool | probe

/-- The `group*` operator constant backing each aggregate. -/
def AggKind.op : AggKind → Name
  | .sum => ``groupSum
  | .min => ``groupMinInt
  | .max => ``groupMaxInt
  | .avg => ``groupAvg
  | .count => ``groupCount
  | .sumDistinct => ``groupSumDistinct
  | .countDistinct => ``groupCountDistinct
  | .avgDistinct => ``groupAvgDistinct
  | .boolAnd => ``groupBoolAnd
  | .boolOr => ``groupBoolOr
  | .stddev => ``groupStddev
  | .variance => ``groupVariance

/-- The summand each aggregate feeds its operator. -/
def AggKind.summand : AggKind → AggSummand
  | .count => .void
  | .countDistinct => .probe
  | .boolAnd | .boolOr => .bool
  | _ => .int

/-- Whether the operator returns `Nat` (so its result is wrapped with `Int.ofNat`). -/
def AggKind.wrapNat : AggKind → Bool
  | .count | .countDistinct => true
  | _ => false

/-- The SQL column type of the aggregate's result. -/
def AggKind.resultType : AggKind → SQLTypeProxy
  | .boolAnd | .boolOr => .bool
  | .avg | .avgDistinct | .stddev | .variance => .float   -- Rat-valued
  | _ => .int

/-- Builds one grouped aggregate per lifted `(freshName, kind, expr)`: each `expr` is elaborated
against a fresh tuple of `schema` into a `TypedTuple → Int` summand and fed to the operator named by
`kind.op`. `COUNT` ignores the summand and counts rows. -/
def groupAggExprsE (schema : List (Name × SQLTypeProxy)) (groupTerms : List Syntax.Term)
    (typedTupleVar relE : Expr) (aggs : List (Name × AggKind × Syntax.Term)) :
    TermElabM (List ((Name × SQLTypeProxy) × Expr)) := do
  if aggs.isEmpty then return []
  -- The group key `fun row => (key₁ row, …, keyₖ row)` and its tuple type (see Parser/GroupBy.lean).
  -- Two paths, deliberately: if every GROUP BY item is a bare column of the schema we use the robust
  -- index projection `subcolumsProjectionsE` (no term elaboration — matches the pre-expression
  -- behaviour exactly, so plain-column GROUP BY over joins keeps working); only a genuine *expression*
  -- key (`UPPER(col)`, `ROUND(lat,2)`, positional) needs the elaboration path. An empty `GROUP BY`
  -- (whole-table aggregate) is the empty tuple either way.
  let colNames := schema.map (·.1)
  let bareCols? : Option (List Name) := groupTerms.mapM fun t =>
    if t.raw.isIdent && colNames.contains t.raw.getId then some t.raw.getId else none
  let (keyMapE, codomainE) ← match bareCols? with
    | some names =>
        let (km, _, cod) ← subcolumsProjectionsE schema (fun n => names.contains n)
        pure (km, cod)
    | none =>
        withSchemasTupleVars [(.anonymous, schema)] (fun _ => true) fun vars => do
          let keyExprsTypes ← groupTerms.mapM elabAsSql
          let e ← mkLambdaLetsFVars vars (exprTypeListTuple keyExprsTypes)
          let cod ← mkAppM ``TypedTupleOfList #[← sqlTypeListExpr (keyExprsTypes.map (·.1))]
          pure (e, cod)
  let keyValue ← mkAppM' keyMapE #[typedTupleVar]
  aggs.mapM fun (name, kind, exprStx) => do
    -- summand `fun (t : TypedTuple schema) => (exprStx : <summand type>)`, absent for COUNT(*)
    let projE? ← match kind.summand with
      | .void => pure none
      | s => do
          let projE ← withSchemasTupleVars [(.anonymous, schema)] (fun _ => true) fun vars => do
            let body ← match s with
              | .int => elabTermEnsuringType exprStx (mkConst ``Int)
              | .bool => elabTermEnsuringType exprStx (mkConst ``Bool)
              | _ => Prod.snd <$> elabAsSql exprStx        -- `.probe`: discover the column type
            mkLambdaLetsFVars vars (pure body)
          pure (some projE)
    let aggE ← withLocalDeclD `k codomainE fun keyVar => do
      let base ← match projE? with
        | none => mkAppM kind.op #[keyMapE, keyVar, relE]
        | some projE => mkAppM kind.op #[keyMapE, keyVar, relE, projE]
      let call ← if kind.wrapNat then mkAppM ``Int.ofNat #[base] else pure base
      mkLambdaFVars #[keyVar] call
    let aggValue ← mkAppM' aggE #[keyValue]
    let aggValue ← mkLambdaFVars #[typedTupleVar] aggValue
    pure ((name, kind.resultType), aggValue)

def withSchemasGroupedTupleVars (schemas : List (Name × List (Name × SQLTypeProxy))) (usedName : Name → Bool)
    (groupTerms : List Syntax.Term) (relE : Expr) (aggs : List (Name × AggKind × Syntax.Term))
    (k : List (Expr × Array Expr) → TermElabM α) : TermElabM α := do
  match schemas with
  | [] => k []
  | (schemaName, schema) :: rest => do
    let schema := schemaWithFullNames schemaName schema
    let (type, _, columnExprs) ← columnProjectionsE schema
    withLocalDeclD (schemaName ++ `coords) type fun typedTupleE => do
      -- Columns the projection references stay bound as plain columns (filtered by `usedName` in
      -- `withLetColumnVars`); every aggregate is lifted by `liftAggExprs` and built via `groupAggExprsE`,
      -- which also forms the group key from `groupTerms`. In a legal `GROUP BY` the only plain columns
      -- referenced are the group keys (or columns inside a group expression), so this binds exactly them.
      let groupAggExprsExprs ← groupAggExprsE schema groupTerms typedTupleE relE aggs
      let columnExprs := columnExprs ++ groupAggExprsExprs
      withLetColumnVars  columnExprs typedTupleE usedName
        fun letVars => do
          withSchemasGroupedTupleVars rest usedName groupTerms relE [] fun rest =>
          k ((typedTupleE, letVars) :: rest)

def withTableVars (schemas : List (Name × List (Name × SQLTypeProxy)))  (k : List (Expr × Name × List (Name × SQLTypeProxy)) →  TermElabM α)  : TermElabM α := do
  match schemas with
  | [] => k []
  | (tableName, columns) :: rest => do
    let colTypes := columns.map (fun (_, colType) => colType)
    let listExpr ← sqlTypeListExpr colTypes
    let type ← mkAppM ``TypedRelationOfList #[listExpr]
    withLocalDeclD tableName type fun typedRel => do
      withTableVars rest ((fun l ↦ k ((typedRel, tableName, columns) :: l)))

/-! ## Building output tuples -/

def TypedTuple.cons {n : Nat} {colType : Fin n → Type} (a: α) (tuple : TypedTuple colType) :
    TypedTuple (Fin.cons α colType) := Fin.cons a tuple

def colTypeNil : Fin 0 → Type := fun ⟨i, h⟩ => by simp at h

def TypedTuple.nil : TypedTuple colTypeNil := fun ⟨i, h⟩ => by simp at h

def exprTypedTuple : List Expr → MetaM Expr
  | [] => return mkConst ``TypedTuple.nil
  | e :: es => do
    let rest ← exprTypedTuple es
    mkAppM ``TypedTuple.cons #[e, rest]

/-! ## Product / projection helpers (currently unused; kept for multi-table work) -/

section helpers

variable {n m : Nat}
variable {colType1 : Fin n → Type} [∀ i, DecidableEq (colType1 i)]
variable {colType2 : Fin m → Type} [∀ i, DecidableEq (colType2 i)]

def TypedRelation.map (f : TypedTuple colType1 → TypedTuple colType2) (labels : Fin m → String)
    (r : TypedRelation colType1) :
  TypedRelation colType2 := {labels := labels, rows := r.rows.image f}

abbrev colTypeOfProduct (colType1: Fin n → Type) (colType2: Fin m → Type) : Fin (n + m) →  Type :=
  fun ⟨i, h⟩ =>
    if h : i < n then
      colType1 ⟨i, h⟩
    else
      colType2 ⟨i - n, by grind⟩

def prodTypedTuple (t1 : TypedTuple colType1) (t2 : TypedTuple colType2) :
    TypedTuple (colTypeOfProduct colType1 colType2) := fun ⟨i, h⟩ => by
  if h : i < n then
    simp [colTypeOfProduct, h]
    exact t1 ⟨i, h⟩
  else
    simp [colTypeOfProduct, h]
    exact t2 ⟨i - n, by grind⟩

def leftProj (t : TypedTuple (colTypeOfProduct colType1 colType2)) : TypedTuple colType1 := fun ⟨i, h⟩ => by
 let t' := t ⟨i, by grind⟩
 simp [colTypeOfProduct, h] at t'
 exact t'

def rightProj (t : TypedTuple (colTypeOfProduct colType1 colType2)) : TypedTuple colType2 := fun ⟨i, h⟩ => by
 let t' := t ⟨i + n, by grind⟩
 simp [colTypeOfProduct] at t'
 exact t'

end helpers

/-- `SELECT`/`GROUP BY` output: map each row through `f` (the projection), labelled by `names`.
The result type `colTypeOfList types` is keyed on the **literal** `types` list (not `l.map (·.2)`),
so its `DecidableEq` instance reduces — `TypedRelation.ext`/`sql_equiv` then applies without hitting
an instances-transparency wall. -/
def TypedRelation.mapByList {colType : Fin n → Type} [∀ i, DecidableEq (colType i)]
    {types : List SQLTypeProxy} (r : TypedRelation colType) (names : List String)
    (f : TypedTuple colType → TypedTupleOfList types) : TypedRelationOfList types :=
  { labels := fun i => names.getD i.val "", rows := r.rows.image f }

/-- **Projection fusion.** Two stacked `mapByList`s (e.g. `SELECT … FROM (CTE that projects)`)
collapse to a single projection composing the row maps — `Finset.image_image` on the rows. This is
what lets `sql_equiv` see through a projecting CTE (ROADMAP 3.3). -/
@[simp, grind =] theorem TypedRelation.mapByList_mapByList {n : Nat} {colType : Fin n → Type}
    [∀ i, DecidableEq (colType i)] {types1 types2 : List SQLTypeProxy} (r : TypedRelation colType)
    (n1 n2 : List String) (f1 : TypedTuple colType → TypedTupleOfList types1)
    (f2 : TypedTupleOfList types1 → TypedTupleOfList types2) :
    (r.mapByList n1 f1).mapByList n2 f2 = r.mapByList n2 (fun t => f2 (f1 t)) := by
  simp only [TypedRelation.mapByList, Finset.image_image]; rfl

/-! ## Per-operator elaborators -/

-- This is the "WHERE" part of a SQL query, which is a function from a TypedRelation to a TypedRelation. This is to be applied to the database, which may be a single schema or built from multiple schemas.
def elabTypedTupleFilter (schemas : List (Name × List (Name × SQLTypeProxy))) (stx: Syntax) : TermElabM Expr := do
  withSchemasTupleVars schemas (stx.hasIdent) (fun vars =>
    mkLambdaLetsFVars vars (elabTermEnsuringType stx (mkConst ``Bool)))

def elabTypedTupleGroupFilter (schemas : List (Name × List (Name × SQLTypeProxy))) (stx: Syntax) (groupTerms : List Syntax.Term) (relE: Expr) (aggs : List (Name × AggKind × Syntax.Term)) : TermElabM Expr := do
  withSchemasGroupedTupleVars schemas (stx.hasIdent) groupTerms relE aggs (fun vars =>
    mkLambdaLetsFVars vars (elabTermEnsuringType stx (mkConst ``Bool)))

def elabTypedRelFilter (schemas : List (Name × List (Name × SQLTypeProxy))) (stx: Syntax) (combineRels : List Name → List Expr → TermElabM Expr) : TermElabM Expr := do
  withTableVars schemas fun tableVars => do
    let tableNames := tableVars.map (fun (_, name, _) => name)
    let vars := tableVars.map (fun (relVar, _, _) => relVar)
    let relVar ← combineRels tableNames vars
    let filter ← elabTypedTupleFilter schemas stx
    let e ← mkAppM ``restriction #[filter, relVar]
    mkLambdaFVars vars.toArray e


def elabTypedRelFilterSimple (schemas : List (Name × List (Name × SQLTypeProxy))) (stx: Syntax) :
  TermElabM Expr :=
  elabTypedRelFilter schemas stx fun _ vars =>
    match vars with
    | [relVar] => pure relVar
    | _ => throwError "Multiple tables in FROM clause not supported in this context"

def elabTypedTupleProjection (schemas : List (Name × List (Name × SQLTypeProxy))) (cols: List Syntax.Term) :
  TermElabM (Expr × List SQLTypeProxy) := do
  withSchemasTupleVars schemas (fun name => cols.any (fun col => col.raw.hasIdent name)) (fun vars => do
    let colExprsTypes ← cols.mapM elabAsSql
    -- let colExprs := colExprsTypes.map (fun (_, e) => e)
    let types := colExprsTypes.map (fun (t, _) => t)
    let e ← mkLambdaLetsFVars vars (exprTypeListTuple colExprsTypes)
    return (e, types)
  )

def elabTypedTupleGroupProjection (schemas : List (Name × List (Name × SQLTypeProxy))) (cols: List Syntax.Term) (groupTerms : List Syntax.Term) (relE : Expr) (aggs : List (Name × AggKind × Syntax.Term)) :
  TermElabM (Expr × List SQLTypeProxy) := do
  withSchemasGroupedTupleVars schemas (fun name => cols.any (fun col => col.raw.hasIdent name)) groupTerms relE aggs (fun vars => do
    let colExprsTypes ← cols.mapM elabAsSql
    -- let colExprs := colExprsTypes.map (fun (_, e) => e)
    let types := colExprsTypes.map (fun (t, _) => t)
    let e ← mkLambdaLetsFVars vars (exprTypeListTuple colExprsTypes)
    return (e, types)
  )

def elabTypedRelFilterProj (schemas : List (Name × List (Name × SQLTypeProxy)))
    (stx: Syntax) (colStxs : List (TSyntax `sql_col))
    (combineRels : List Name → List Expr → TermElabM Expr) : TermElabM (Expr × List SQLTypeProxy) := do
  withTableVars schemas fun tableVars => do
    let tableNames := tableVars.map (fun (_, name, _) => name)
    let rel ← combineRels tableNames (tableVars.map (fun (relVar, _, _) => relVar))
    let filter ← elabTypedTupleFilter schemas stx
    let e ← mkAppM ``restriction #[filter, rel]
    let cols := colStxs.map sqlColTerm
    let names := colStxs.map sqlColName
    let names := names.map (·.toString)
    let nameExpr := toExpr names
    let (m, types) ← elabTypedTupleProjection schemas cols
    let e' ← mkAppM ``TypedRelation.map #[m, nameExpr, e]
    let vars := tableVars.map (fun (relVar, _, _) => relVar)
    return (← mkLambdaFVars vars.toArray e', types)

end LeanDatabase
