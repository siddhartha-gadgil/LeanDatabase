import LeanDatabase.Parser.Context
import LeanDatabase.Operators.Values
import LeanDatabase.Parser.Alias
import LeanDatabase.Parser.GroupBy
import LeanDatabase.Parser.Handlers.Normalize
import LeanDatabase.Operators.CrossProduct
import LeanDatabase.Operators.Select
import LeanDatabase.Operators.OrderLimit
import LeanDatabase.Operators.Join

/-!
# Top-level query parsing

`parseTypedTupleFilter` / `parseTypedRelFilter` parse a `WHERE`-predicate string against a schema;
`elabSqlQuery` is the full `SELECT … FROM … WHERE …` entry point that dispatches on query shape and
composes the per-operator elaborators (`Parser.Context`) with the cross-product operator.

**To add a scalar / aggregate / clause / FROM form / dialect feature, see `Parser/README.md`** — each
extension point has one home.
-/

open Lean Meta Elab Term

namespace LeanDatabase

/-! ## Outer-join schema reconciliation

The `leftOuterJoin`/`rightOuterJoin`/`fullOuterJoin` operators return a `Fin.append`-shaped schema
whose null-padded side is `fun i => Option (colTypeOfList l i)`, but the rest of the parser (`WHERE`,
projection) works over the canonical `TypedRelationOfList` / `colTypeOfList (l.map .nullable)` form.
These reindexers convert the operator result back to the canonical list form by rebuilding each row
with `TypedTupleOfList.append` + `splitTuple` (the inner join gets this for free via
`TypedRelationOfList.append`). `ofOption` turns the `Option`-family right/left part into the
`.nullable`-list form; recursion on the list avoids `Fin.cast` gymnastics. -/

/-- A scalar subquery deferred to *projection-context* elaboration. Building the aggregate there —
rather than up front as a constant — lets a **correlated** inner `WHERE` (referencing outer columns)
resolve against the outer row's let-vars, which are in scope only inside the projection. -/
structure DeferredSubq where
  innerRel : Expr
  innerSchema : List (Name × SQLTypeProxy)
  kind : AggKind
  summand : Option Expr           -- `fun innerTuple => arg`, for SUM / COUNT(DISTINCT)
  cond : Option Syntax            -- inner `WHERE` (may reference outer columns)
  deriving Inhabited

initialize scalarSubqStash : IO.Ref (Array DeferredSubq) ← IO.mkRef #[]

/-- Placeholder for a scalar subquery; elaborated in the projection context so correlations bind. -/
syntax "sqlDeferredSubq% " num : term

elab_rules : term
  | `(sqlDeferredSubq% $i:num) => do
    let d := (← scalarSubqStash.get)[i.getNat]!
    let rel ← match d.cond with
      | some cond => do mkAppM ``restriction #[← elabTypedTupleFilter [(.anonymous, d.innerSchema)] cond, d.innerRel]
      | none => pure d.innerRel
    match d.kind with
    | .count => mkAppM ``Int.ofNat #[← mkAppM ``relCount #[rel]]
    | .sum => mkAppM ``relSum #[d.summand.get!, rel]
    | .countDistinct => mkAppM ``Int.ofNat #[← mkAppM ``relCountDistinct #[d.summand.get!, rel]]
    -- MAX / MIN reuse the grouped operators under a constant key (that group *is* the whole relation),
    -- so their existing `grind` lemmas apply unchanged.
    | .max | .min => do
      let (tupleType, _, _) ← columnProjectionsE d.innerSchema
      let key ← withLocalDeclD `t tupleType fun t => mkLambdaFVars #[t] (mkConst ``Unit.unit)
      mkAppM (if d.kind == .max then ``groupMaxInt else ``groupMinInt)
        #[key, mkConst ``Unit.unit, rel, d.summand.get!]
    | _ => throwError "scalar subquery: only SUM / COUNT / COUNT(DISTINCT) / MAX / MIN are supported"

def ofOption : {l : List SQLTypeProxy} →
    ((i : Fin l.length) → Option (colTypeOfList l i)) → TypedTupleOfList (l.map .nullable)
  | [], _ => TypedTupleOfList.nil
  | t :: rest, u =>
      TypedTupleOfList.cons (.nullable t) (u ⟨0, by simp⟩)
        (ofOption (l := rest) (fun ⟨i, hi⟩ => u ⟨i+1, by simp only [List.length_cons]; omega⟩))

variable {lA lB : List SQLTypeProxy}

/-- `LEFT JOIN` result → `lA ++ lB.map .nullable`. -/
def ofOuterLeft
    (r : TypedRelation (Fin.append (colTypeOfList lA) (fun i => Option (colTypeOfList lB i)))) :
    TypedRelationOfList (colsAppend lA (lB.map .nullable)) :=
  { labels := fun j => r.labels (Fin.cast (by simp [colsAppend_eq]) j),
    rows := r.rows.image (fun t => TypedTupleOfList.append (splitTuple t).1 (ofOption (splitTuple t).2)) }

/-- `RIGHT JOIN` result → `lA.map .nullable ++ lB`. -/
def ofOuterRight
    (r : TypedRelation (Fin.append (fun i => Option (colTypeOfList lA i)) (colTypeOfList lB))) :
    TypedRelationOfList (colsAppend (lA.map .nullable) lB) :=
  { labels := fun j => r.labels (Fin.cast (by simp [colsAppend_eq]) j),
    rows := r.rows.image (fun t => TypedTupleOfList.append (ofOption (splitTuple t).1) (splitTuple t).2) }

/-- `FULL JOIN` result → `lA.map .nullable ++ lB.map .nullable`. -/
def ofOuterFull
    (r : TypedRelation (Fin.append (fun i => Option (colTypeOfList lA i)) (fun i => Option (colTypeOfList lB i)))) :
    TypedRelationOfList (colsAppend (lA.map .nullable) (lB.map .nullable)) :=
  { labels := fun j => r.labels (Fin.cast (by simp [colsAppend_eq]) j),
    rows := r.rows.image (fun t => TypedTupleOfList.append (ofOption (splitTuple t).1) (ofOption (splitTuple t).2)) }

def parseTypedTupleFilter  (schemaStr : List (String × String)) (str : String) : TermElabM Expr := do
  let .ok stx := Parser.runParserCategory (← getEnv) `term str | throwError "Failed to parse filter expression: {str}"
  let schema := schemaStr.map (fun (name, colType) => (name.toName, sqlProxy colType))
  let schema := schemaWithFullNames `schema schema
  let labels := schema.map (fun (name, _) => name)
  let stx ← expandNames labels stx
  elabTypedTupleFilter [(`schema, schema)] stx

def parseTypedRelFilter  (schemasStr : List (String × List (String × String))) (str : String) : TermElabM Expr := do
  let .ok stx := Parser.runParserCategory (← getEnv) `term str | throwError "Failed to parse filter expression: {str}"
  let schemas := schemasStr.map (fun (schemaName, schema) =>
    let schema' := schema.map (fun (name, colType) => (name.toName, sqlProxy colType))
    (schemaName.toName, schema'))
  let schemas := schemas.map (fun (schemaName, schema) => (schemaName, schemaWithFullNames schemaName schema))
  let labels := schemas.foldl (fun acc (_, schema) => acc ++ schema.map (fun (name, _) => name)) []
  let stx ← expandNames labels stx
  elabTypedRelFilterSimple schemas stx

/-- Build the `STRING_AGG` summand: one string per row folding a DISTINCT marker, the delimiter, the
element and every ORDER BY key (via the opaque `toChar`), so aggregations differing in any of these
keep distinct summands and can't be wrongly equated (the aggregate itself is opaque). -/
def mkStrAgg (distinct : Bool) (d e : Syntax.Term) (ks : Array Syntax.Term) : TermElabM Syntax.Term := do
  let tc : Syntax.Term → TermElabM Syntax.Term := fun x => `($(mkIdent ``LeanDatabase.Scalar.toChar) $x)
  let mark : Syntax.Term := ⟨Syntax.mkStrLit (if distinct then "SAD|" else "SA|")⟩
  let mut acc ← `($mark ++ $d ++ $(← tc e))
  for k in ks do
    acc ← `($acc ++ $(← tc k))
  return acc

/-- Promote an arm relation's `Int` columns to `Rat` so an `INT` set-op arm unions with a `NUMBER`
arm (SQL numeric type unification). Returns the relation unchanged when its types already match. -/
def coerceRelTo (schema : List (Name × SQLTypeProxy)) (rel : Expr) (target : List SQLTypeProxy) :
    TermElabM Expr := do
  if schema.map (·.2) == target then return rel
  let cols ← (schema.zip target).mapM fun ((n, s), t) =>
    if s == t then pure (⟨mkIdent n⟩ : Syntax.Term) else `(($(mkIdent n) : Rat))
  let (m, _) ← elabTypedTupleProjection [(.anonymous, schema)] cols
  mkAppM ``TypedRelation.mapByList #[rel, toExpr (schema.map (·.1.toString)), m]

/-- Pull every aggregate call out of a term for the `GROUP BY` arm: each `AGG(expr)` is replaced by
a fresh column name and recorded `(name, kind, expr)` in the state, to be built uniformly by
`groupAggExprsE`. Columns and arbitrary expressions go through the same path (`SUM(age)` sums the
column `age`; `SUM(a*b)` sums the expression). `COUNT(*)` is a row count with a placeholder
summand that the `count` builder ignores. -/
partial def liftAggExprs (stx : Syntax) :
    StateT (Array (Name × AggKind × Syntax.Term)) TermElabM Syntax :=
  stx.replaceM fun node => do
    let record (kind : AggKind) (e : Syntax.Term) :
        StateT (Array (Name × AggKind × Syntax.Term)) TermElabM (Option Syntax) := do
      let name := Name.mkSimple s!"__agg{(← get).size}"
      modify (·.push (name, kind, e))
      return some (mkIdent name)
    match node with
    -- Aggregate `FILTER (WHERE p)` → aggregate over `CASE WHEN p THEN e …` (SUM/COUNT, sound).
    | `(SUM($e:term) FILTER(WHERE $p:term)) =>
        do record .sum (← `(CASE WHEN $p THEN $e:term ELSE 0 END))
    | `(COUNT(*) FILTER(WHERE $p:term)) =>
        do record .sum (← `(CASE WHEN $p THEN (1 : Int) ELSE (0 : Int) END))
    | `(COUNT($e:term) FILTER(WHERE $p:term)) =>
        do record .count (← `(CASE WHEN $p THEN $e:term END))
    -- `COUNT(DISTINCT e) FILTER(WHERE p)` → `COUNT(DISTINCT CASE WHEN p THEN e END)` (excluded rows NULL,
    -- which `COUNT` skips).
    | `(COUNT(DISTINCT $e:term) FILTER(WHERE $p:term)) =>
        do record .countDistinct (← `(CASE WHEN $p THEN $e:term END))
    -- MIN/MAX/AVG(e) FILTER(WHERE p): the `CASE` trick can't model their skip-NULL semantics (MIN/MAX/AVG
    -- reject the `Option`-typed CASE), so capture them opaquely — `groupFilterAgg` over `filterTag mark p e`.
    | `(MIN($e:term) FILTER(WHERE $p:term)) =>
        do record .filterAgg (← `($(mkIdent ``LeanDatabase.Scalar.filterTag) "min" ($p : Bool) $e))
    | `(MAX($e:term) FILTER(WHERE $p:term)) =>
        do record .filterAgg (← `($(mkIdent ``LeanDatabase.Scalar.filterTag) "max" ($p : Bool) $e))
    | `(AVG($e:term) FILTER(WHERE $p:term)) =>
        do record .filterAgg (← `($(mkIdent ``LeanDatabase.Scalar.filterTag) "avg" ($p : Bool) $e))
    | `(COUNT(DISTINCT $e:term)) => record .countDistinct e
    | `(APPROX_COUNT_DISTINCT($e:term)) => record .countDistinct e
    | `(SUM(DISTINCT $e:term))   => record .sumDistinct e
    | `(AVG(DISTINCT $e:term))   => record .avgDistinct e
    | `(BOOL_AND($e:term)) => record .boolAnd e
    | `(EVERY($e:term))    => record .boolAnd e
    | `(BOOL_OR($e:term))  => record .boolOr e
    | `(COUNT_IF($c:term)) => do record .sum (← `(CASE WHEN $c THEN (1 : Int) ELSE (0 : Int) END))
    | `(SUM($e:term))   => record .sum e
    | `(MIN($e:term))   => record .min e
    | `(MAX($e:term))   => record .max e
    | `(AVG($e:term))   => record .avg e
    | `(STDDEV($e:term)) | `(STDDEV_POP($e:term)) | `(STDDEV_SAMP($e:term)) => record .stddev e
    | `(VARIANCE($e:term)) | `(VAR_POP($e:term)) | `(VAR_SAMP($e:term)) => record .variance e
    | `(STRING_AGG(DISTINCT $e:term, $d:term ORDER BY $ks,*)) =>
        do record .stringAgg (← mkStrAgg true d e ks.getElems)
    | `(STRING_AGG($e:term, $d:term ORDER BY $ks,*)) =>
        do record .stringAgg (← mkStrAgg false d e ks.getElems)
    | `(STRING_AGG(DISTINCT $e:term, $d:term)) => do record .stringAgg (← mkStrAgg true d e #[])
    | `(STRING_AGG($e:term, $d:term))          => do record .stringAgg (← mkStrAgg false d e #[])
    | `(PERCENTILE_CONT($p:term) WITHIN GROUP (ORDER BY $e:term)) =>
        do record .percentile (← `($(mkIdent ``LeanDatabase.Scalar.pctTag) "cont" $p $e))
    | `(PERCENTILE_DISC($p:term) WITHIN GROUP (ORDER BY $e:term)) =>
        do record .percentile (← `($(mkIdent ``LeanDatabase.Scalar.pctTag) "disc" $p $e))
    | `(COUNT(CASE $[WHEN $cs THEN $_vs]* END))
    | `(COUNT(CASE $[WHEN $cs THEN $_vs]* ELSE NULL END)) => do
        -- `COUNT(CASE WHEN p THEN _ [ELSE NULL] END)` counts the rows where some `p` holds — a
        -- non-matching row is NULL, which `COUNT` skips. That is exactly
        -- `SUM(CASE WHEN p THEN 1 … ELSE 0 END)`, the indicator sum that
        -- `groupSum_case_eq_groupSum_where` folds into `COUNT(*) WHERE p`.
        let ones ← cs.mapM fun _ => `(term| (1 : Int))
        let e ← `(CASE $[WHEN $cs THEN $ones:term]* ELSE (0 : Int) END)
        record .sum e
    | `(COUNT(*))       => record .count ⟨Syntax.mkNumLit "0"⟩
    | `(COUNT($e:term)) => record .count e
    | _ => return none

/-- Flatten a top-level `AND`-conjunction into its conjuncts (`p AND q AND r` → `[p, q, r]`). Used by
`elabWhere` to peel `[NOT] EXISTS`/`[NOT] IN` subquery predicates out of a compound `WHERE`. -/
partial def flattenAnd (t : Syntax.Term) : List Syntax.Term :=
  match t with
  | `($a AND $b) => flattenAnd a ++ flattenAnd b
  | _ => [t]

/-- Does `stx` reference the table name `nm` anywhere (i.e. is a CTE self-recursive)? -/
partial def refsName (nm : Name) : Syntax → Bool
  | .ident _ _ val _ => val == nm
  | .node _ _ args => args.any (refsName nm)
  | _ => false

/-- Per-scope column fix-up: `expandNames` is global, so it pins a bare column to one fixed table —
wrong for other partition-`UNION` arms. Re-qualify a broken `A.col` (not an in-scope label) to the
unique in-scope column with the same last component; bare aliases and valid refs are left alone. Halts
at nested `sql_query` boundaries so a correlated inner ref keeps binding to its own scope. -/
partial def resolveInScope (scopeLabels : List Name) (stx : Syntax) : Syntax := Id.run do
  let lastOf : Name → Name := fun n => (n.components.getLast?).getD n
  stx.replaceM (m := Id) fun s => do
    match s with
    | `(sql_col| ( $_:sql_query ) AS $_:ident)
    | `(term| EXISTS ( $_:sql_query ))
    | `(term| NOT EXISTS ( $_:sql_query ))
    | `(term| $_:term IN ( $_:sql_query ))
    | `(term| $_:term NOT IN ( $_:sql_query )) => return some s
    | _ =>
      match s with
      | .ident info raw val _ =>
        if val.components.length ≥ 2 && !(scopeLabels.contains val) then
          -- `x.c` under a derived-table alias resolves against *that* alias's columns first
          -- (`itpv.itemn` → `itpv.itp.itemn`), so a same-named column elsewhere in scope can't clash.
          let sameLast := scopeLabels.filter (fun l => lastOf l == lastOf val)
          let pfx := val.getPrefix
          match sameLast.filter (fun l => pfx.isPrefixOf l) with
          | [uniq] => return some (.ident info raw uniq [])
          | _ => match sameLast with
            | [uniq] => return some (.ident info raw uniq [])
            | _ => return none
        else return none
      | _ => return none

/-- Map a Lean value type to its `SQLTypeProxy` (a bare `Nat` literal counts as `int`). -/
def proxyOfType (e : Expr) : MetaM (Option SQLTypeProxy) := do
  let e ← whnf e
  if e.isConstOf ``Int || e.isConstOf ``Nat then pure (some .int)
  else if e.isConstOf ``Rat then pure (some .float)
  else if e.isConstOf ``String then pure (some .string)
  else if e.isConstOf ``Bool then pure (some .bool)
  else pure none

/-- Build an inline `VALUES` relation. A cell is `some term` for a value or `none` for a SQL `NULL`.
Each column's base type comes from its first non-NULL cell; a column with any NULL becomes nullable
(`.nullable base`, so cells are `Option _`), and an **all-NULL** column defaults to `.nullable .int`
(the base type is unobservable — every value is `none`). NULL cells → `Option.none`, value cells in a
nullable column → `some v`. Columns are labelled `alias.col`. -/
def buildValues (rows : List (List (Option Syntax.Term))) (cols : List Name) (alias_ : Name) :
    TermElabM (Expr × List (Name × SQLTypeProxy)) := do
  let some row0 := rows.head? | throwError "VALUES: no rows"
  unless row0.length == cols.length do throwError "VALUES: row width ≠ column count"
  let ncols := row0.length
  -- Per column: base type from the first non-NULL cell, and whether any cell is NULL.
  let mut tysArr : Array SQLTypeProxy := #[]
  for j in [0:ncols] do
    let mut base? : Option SQLTypeProxy := none
    let mut hasNull := false
    for row in rows do
      match row[j]! with
      | none => hasNull := true
      | some cell =>
        if base?.isNone then
          let e ← elabTerm cell none
          Term.synthesizeSyntheticMVarsNoPostponing
          let some p ← proxyOfType (← instantiateMVars (← inferType e))
            | throwError "VALUES: unsupported cell type in {cell}"
          base? := some p
    let baseTy := base?.getD .int            -- all-NULL column: base is unobservable, default to int
    tysArr := tysArr.push (if hasNull then .nullable baseTy else baseTy)
  let tys := tysArr.toList
  let lE ← sqlTypeListExpr tys
  -- Each row → a `TypedTupleOfList tys` (built right-to-left with `cons`), each cell at its column type.
  let tuples ← rows.mapM fun row => do
    unless row.length == tys.length do throwError "VALUES: ragged rows"
    let mut tup ← mkAppOptM ``TypedTupleOfList.nil #[]
    for (cell?, ty) in (row.zip tys).reverse do
      let v ← match ty, cell? with
        | .nullable baseP, some cell => do                         -- value in a nullable column → `some v`
          mkAppM ``Option.some #[← elabTermEnsuringType cell (typeExpr baseP)]
        | .nullable baseP, none => mkAppOptM ``Option.none #[typeExpr baseP]   -- NULL → `none`
        | _, some cell => elabTermEnsuringType cell (typeExpr ty)
        | _, none => throwError "VALUES: NULL in a non-nullable column"        -- unreachable
      tup ← mkAppM ``TypedTupleOfList.cons #[toExpr ty, v, tup]
    pure tup
  let tupleTy ← mkAppM ``TypedTupleOfList #[lE]
  let rowsE ← mkListLit tupleTy tuples
  let labels := cols.map (fun c => toString (alias_ ++ c))
  let rel ← mkAppM ``valuesRel #[lE, ← mkListLit (mkConst ``String) (labels.map (mkStrLit ·)), rowsE]
  return (rel, (cols.map (alias_ ++ ·)).zip tys)

/-- If the `GROUP BY` items are a grouping-set construct (`ROLLUP`/`CUBE`/`GROUPING SETS`), return its
`spec` string (the reprinted construct — distinguishes ROLLUP vs CUBE vs different columns) and the flat
list of grouping columns (their union). The SELECT arm then groups over those columns and wraps the
result in the opaque `groupSetMark spec`. -/
def detectGroupingSet (items : Array Syntax.Term) : Option (String × Array Syntax.Term) := Id.run do
  unless items.size == 1 do return none
  let it := items[0]!
  let spec := (it.raw.reprint.getD "gs").trim
  match it with
  | `(ROLLUP($cols,*)) => return some (spec, cols.getElems)
  | `(CUBE($cols,*))   => return some (spec, cols.getElems)
  | `(GROUPING SETS($sets,*)) => do
      let mut cols : Array Syntax.Term := #[]
      for s in sets.getElems do
        match s with
        | `(grouping_set| ( $cs,* )) => for c in cs.getElems do
            unless cols.any (fun d => d.raw.reprint == c.raw.reprint) do cols := cols.push c
        | `(grouping_set| $t:term) =>
            unless cols.any (fun d => d.raw.reprint == t.raw.reprint) do cols := cols.push t
        | _ => pure ()
      return some (spec, cols)
  | _ => return none

/--
This is the main entry point for parsing a full SQL query (`SELECT` / `FROM` / `WHERE` / `GROUP BY`),
plus the binary set operators `UNION` / `UNION ALL` / `INTERSECT` / `EXCEPT` and parenthesised
grouping. Returns a function of the table variables, comparable for equality with `sql_equiv`.

Set-op arms recurse on each side (both return `fun tables => relation`), then β-apply the table vars
to recover each relation body, combine with `union` / `intersection`, etc. and re-bind once.
-/
partial def elabSqlQueryCore (tableVars : List (Expr × Name × List (Name × SQLTypeProxy)))
    (ctes : List (Name × Expr × List (Name × SQLTypeProxy))) (stx: Syntax) :
    TermElabM (Expr × List (Name × SQLTypeProxy)) :=  do
  let stx ← escapeJoin stx
  let vars := tableVars.map (fun (relVar, _, _) => relVar)
  match stx with
  | `(sql_query| ( $q:sql_query )) => elabSqlQueryCore tableVars ctes q
  | `(sql_query| VALUES $rows,*) => do
    -- Inline literal relation: constant in the table vars. Placeholder column names `c0…`; the outer
    -- `(…) AS t(cols)` from-source relabels them.
    let rowLists ← rows.getElems.toList.mapM fun r => match r with
      | `(sql_values_row| ( $es,* )) => es.getElems.toList.mapM fun c => match c with
          | `(sql_values_cell| NULL)     => pure (none : Option Syntax.Term)
          | `(sql_values_cell| $t:term)  => pure (some t)
          | _ => throwError "malformed VALUES cell"
      | _ => throwError "malformed VALUES row"
    let ncols := (rowLists.head?.map (·.length)).getD 0
    let names := (List.range ncols).map (fun i => Name.mkSimple s!"c{i}")
    let (rel, schema) ← buildValues rowLists names .anonymous
    return (← mkLambdaFVars vars.toArray rel, schema)
  | `(sql_query| WITH $cs:sql_cte,* $body:sql_query) => do
    -- Non-recursive CTEs: elaborate each body to a relation over the current base vars, re-qualify
    -- its columns under the CTE name, and make it available for lookup (inlined at each reference).
    -- Later CTEs may reference earlier ones, so the accumulator grows left-to-right.
    let mut ctes := ctes
    for c in cs.getElems do
      match c with
      | `(sql_cte| $name:ident AS ( $q:sql_query ))
      | `(sql_cte| $name:ident ( $_cols,* ) AS ( $q:sql_query )) => do
        let (lamQ, schemaQ) ← elabSqlQueryCore tableVars ctes q
        -- Explicit column list `c (a, b) AS (…)`: relabel the body's output columns to the given names.
        let schemaQ ← match c with
          | `(sql_cte| $_:ident ( $cols,* ) AS ( $_ )) =>
            pure <| (cols.getElems.toList.map (·.getId)).zip (schemaQ.map (·.2))
          | _ => pure schemaQ
        let cteExpr := lamQ.beta vars.toArray
        -- Keep the CTE body's original column names: `expandNames` only rewrites bare refs against
        -- base-table labels, so retaining those names lets `SELECT … FROM cte WHERE col …` resolve
        -- `col` the same way it would against the base table. (Positional relation ⇒ names are just
        -- metadata; the relation Expr is unchanged.)
        ctes := ctes ++ [(name.getId, cteExpr, schemaQ)]
      | _ => throwError "malformed CTE (expected `name AS (query)`)"
    elabSqlQueryCore tableVars ctes body
  | `(sql_query| WITH RECURSIVE $cs:sql_cte,* $body:sql_query) => do
    -- Like `WITH`, but a CTE whose body references its own name is a recursive fixpoint
    -- (`anchor UNION [ALL] step`) → the opaque `recursiveCte`. Non-self-referencing CTEs (allowed
    -- after `RECURSIVE` too) elaborate normally.
    let mut ctes := ctes
    for c in cs.getElems do
      let (name, q, cols?) ← match c with
        | `(sql_cte| $name:ident AS ( $q:sql_query )) => pure (name, q, none)
        | `(sql_cte| $name:ident ( $cols,* ) AS ( $q:sql_query )) => pure (name, q, some cols)
        | _ => throwError "malformed CTE (expected `name AS (query)`)"
      let (cteExpr, schemaQ) ←
        if refsName name.getId q.raw then
          match q with
          | `(sql_query| $anchor:sql_query $_op:sql_setop $step:sql_query) =>
            recursiveCteExpr ctes name.getId anchor step
          | `(sql_query| ( $anchor:sql_query $_op:sql_setop $step:sql_query )) =>
            recursiveCteExpr ctes name.getId anchor step
          | _ => throwError "recursive CTE `{name.getId}` must be `anchor UNION [ALL] step`"
        else do
          let (lamQ, schemaQ) ← elabSqlQueryCore tableVars ctes q
          pure (lamQ.beta vars.toArray, schemaQ)
      let schemaQ := match cols? with
        | some cols => (cols.getElems.toList.map (·.getId)).zip (schemaQ.map (·.2))
        | none => schemaQ
      ctes := ctes ++ [(name.getId, cteExpr, schemaQ)]
    elabSqlQueryCore tableVars ctes body
  | `(sql_query| $l:sql_query $op:sql_setop $r:sql_query) => do
    let (lamL, schemaL) ← elabSqlQueryCore tableVars ctes l
    let (lamR, schemaR) ← elabSqlQueryCore tableVars ctes r
    let tL := schemaL.map (·.2)
    let tR := schemaR.map (·.2)
    -- Unify the arm column types: identical stays; `INT` vs `FLOAT` promotes to `FLOAT` (numeric union);
    -- anything else is a genuine mismatch. Each arm is then coerced to the unified types before the op.
    let target? : Option (List SQLTypeProxy) :=
      if tL.length == tR.length then
        (tL.zip tR).mapM fun (a, b) =>
          if a == b then some a
          else if (a == .int && b == .float) || (a == .float && b == .int) then some .float
          else none
      else none
    let some target := target?
      | throwError "set operation requires both queries to have the same column types"
    let opName ← match op with
      -- Set semantics: a query denotes its result SET, so `UNION ALL` and `UNION` coincide
      | `(sql_setop| UNION ALL) | `(sql_setop| UNION) => pure ``union
      | `(sql_setop| INTERSECT ALL) | `(sql_setop| INTERSECT) => pure ``intersection
      | `(sql_setop| EXCEPT ALL) | `(sql_setop| EXCEPT)    => pure ``minus
      | _ => throwError "unknown set operation"
    let relL ← coerceRelTo schemaL (lamL.beta vars.toArray) target
    let relR ← coerceRelTo schemaR (lamR.beta vars.toArray) target
    let combined ← mkAppM opName #[relL, relR]
    return (← mkLambdaFVars vars.toArray combined, (schemaL.map (·.1)).zip target)
  -- One SELECT arm for every clause combination. Optional slots (`DISTINCT`, `WHERE`, `GROUP BY` +
  -- `HAVING`, `ORDER BY`, `LIMIT`) are each read once here, so a new clause/feature is added in a
  -- single place and applies to grouped and ungrouped queries alike. The pipeline is:
  -- FROM → WHERE → (project / group+aggregate + HAVING) → DISTINCT → ORDER BY / LIMIT.
  | `(sql_query| SELECT $[DISTINCT%$distinct?]? $sel:sql_cols FROM $dbs:sql_from $[WHERE $filter?]?
      $[GROUP BY $groups:term,* $[HAVING $having?]?]? $[ORDER BY $ord:sql_order_item,*]?
      $[LIMIT $lim:num]? $[OFFSET $_off:num]? $[;]?) => do
    let (productExpr, combinedSchema) ← productPair dbs
    -- Re-qualify column refs against this arm's own tables (see `resolveInScope`).
    let scopeLabels := combinedSchema.map (·.1)
    let sel : TSyntax `sql_cols := ⟨resolveInScope scopeLabels sel⟩
    let filter? := filter?.map (fun f => (⟨resolveInScope scopeLabels f⟩ : Syntax.Term))
    let havingT? := having?.join.map (fun h => (⟨resolveInScope scopeLabels h⟩ : Syntax.Term))
    -- A scalar subquery used as a *value* inside `WHERE`/`HAVING` becomes a stashed placeholder, like
    -- one in the SELECT list, so its (possibly correlated) inner `WHERE` elaborates with this row bound.
    let filterOrig? := filter?
    let filter? ← filter?.mapM stashTermSubqueries
    let havingT? ← havingT?.mapM stashTermSubqueries
    let filteredExpr ← match filter?, filterOrig? with
      | some filter, some orig => elabWhere productExpr combinedSchema filter orig
      | _, _ => pure productExpr
    let groupItems := ((groups.map (·.getElems)).getD #[]).map
      (fun g => (⟨resolveInScope scopeLabels g⟩ : Syntax.Term))
    -- Subquery aliases map to *nothing*: `itpv.pur.vendn` labels as `pur.vendn`, so a derived-table
    -- query and its flattened twin agree on output labels.
    let aliasMap := collectAliases dbs ++ (collectSubqueryAliases dbs).map (fun a => (a, .anonymous))
    -- `GROUP BY ROLLUP/CUBE/GROUPING SETS(…)`: group over the union of the construct's columns, then
    -- wrap the result in the opaque `groupSetMark spec` so identical grouping-set queries prove equal
    -- while distinct constructs never do. See `detectGroupingSet` / `groupSetMark`.
    let (groupItems, gsSpec?) := match detectGroupingSet groupItems with
      | some (spec, cols) => (cols, some spec)
      | none => (groupItems, none)
    let (rel, outSchema) ← elabSelect sel combinedSchema filteredExpr groupItems groups.isSome
      havingT? aliasMap
    let rel ← match gsSpec? with
      | some spec => mkAppM ``groupSetMark #[toExpr spec, rel]
      | none => pure rel
    let rel ← if distinct?.isSome then mkAppM ``distinct #[rel] else pure rel
    -- ORDER BY resolves against the (base-qualified) output labels, so baseify its column refs too.
    let ordCols? := ord.map (fun ords => ords.getElems.toList.map
      (fun o => ⟨baseifyIdents aliasMap (sqlColTerm (sqlOrderCol o))⟩))
    let limK? := lim.map (·.getNat)
    let rel ←
      try
        applyOrderLimit rel outSchema ordCols? limK?
      catch e =>
        -- The sort key didn't resolve against the output — `ORDER BY` sorts by a column/aggregate the
        -- SELECT projected away (only under a LIMIT, where the key must stay faithful). Re-project WITH
        -- the sort expressions kept as extra columns, `limit` over that, then trim the extras. Scoped to
        -- the col-list SELECT without DISTINCT; every working case still goes through `applyOrderLimit`.
        let extended? : Option (Syntax.TSepArray `sql_col ",") := match sel with
          | `(sql_cols| $cols:sql_col,*) => some cols
          | _ => none
        match extended?, limK?, ord, distinct? with
        | some cols, some k, some ords, none =>
          let extra ← ords.getElems.mapIdxM fun i o => do
            let t : Syntax.Term := ⟨sqlColTerm (sqlOrderCol o)⟩
            let al := mkIdent (Name.mkSimple s!"__sort{i}")
            `(sql_col| $t:term AS $al:ident)
          let extElems := cols.getElems ++ extra
          let extSel ← `(sql_cols| $extElems:sql_col,*)
          let (extRel, extSchema) ← elabSelect extSel combinedSchema filteredExpr groupItems
            groups.isSome having?.join aliasMap
          let outN := outSchema.length
          let (keyFn, _) ← elabTypedTupleProjection [(.anonymous, extSchema)]
            ((extSchema.drop outN).map (fun p => mkIdent p.1))
          let (trimFn, _) ← elabTypedTupleProjection [(.anonymous, extSchema)]
            ((extSchema.take outN).map (fun p => mkIdent p.1))
          let limited ← mkAppM ``limit #[toExpr k, keyFn, extRel]
          mkAppM ``TypedRelation.mapByList #[limited, toExpr (outSchema.map (·.1.toString)), trimFn]
        | _, _, _, _ => throw e
    return (← mkLambdaFVars vars.toArray rel, outSchema)
  | _ => throwError "Unexpected syntax for SQL query"
  where
  -- ORDER BY / LIMIT emit, shared by the plain and GROUP BY SELECT arms. ORDER BY erases only when
  -- no LIMIT is above it; under a LIMIT the sort key is folded into the opaque `limit` (S1). A bare
  -- LIMIT gets a canonical Unit key (the empty projection).
  applyOrderLimit (rel : Expr) (outSchema : List (Name × SQLTypeProxy))
      (ordCols? : Option (List Syntax.Term)) (limK? : Option Nat) : TermElabM Expr := do
    match limK? with
    | none =>
      -- No LIMIT: `ORDER BY` is the identity on a `Finset` (row order unobservable), so the sort key is
      -- irrelevant and we do NOT elaborate it — this lets `ORDER BY MAX(x)`/`SUM(x)` (an aggregate the
      -- output schema can't type) parse instead of failing in `elabAsSql`. The result is just `rel`.
      pure rel
    | some k => do
      -- Under a LIMIT the sort key IS observable (it picks *which* k rows), so it must be elaborated
      -- faithfully — never defaulted, which would unsoundly equate different `ORDER BY … LIMIT k`.
      let key ← match ordCols? with
        | some cols => Prod.fst <$> elabTypedTupleProjection [(.anonymous, outSchema)] cols
        | none => Prod.fst <$> elabTypedTupleProjection [(.anonymous, outSchema)] []
      mkAppM ``limit #[toExpr k, key, rel]
  -- A self-recursive CTE `name AS (anchor UNION [ALL] step)`: elaborate the anchor, bind `name` as an
  -- fvar of the anchor's schema, elaborate the step against it, then abstract the fvar into the
  -- `step` iterate and wrap in the opaque `recursiveCte`. Output schema = the anchor's.
  recursiveCteExpr (ctes : List (Name × Expr × List (Name × SQLTypeProxy)))
      (name : Name) (anchor step : TSyntax `sql_query) :
      TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    let vars := tableVars.map (fun (relVar, _, _) => relVar)
    let (lamA, schemaA) ← elabSqlQueryCore tableVars ctes anchor
    let anchorRel := lamA.beta vars.toArray
    let lExpr ← sqlTypeListExpr (schemaA.map (·.2))
    let cteTy ← mkAppM ``TypedRelationOfList #[lExpr]
    withLocalDeclD name cteTy fun cteVar => do
      let (lamS, schemaS) ← elabSqlQueryCore tableVars (ctes ++ [(name, cteVar, schemaA)]) step
      unless schemaS.map (·.2) == schemaA.map (·.2) do
        throwError "recursive CTE `{name}`: step columns don't match the anchor"
      let stepFn ← mkLambdaFVars #[cteVar] (lamS.beta vars.toArray)
      return (← mkAppM ``recursiveCte #[anchorRel, stepFn], schemaA)
  -- The FROM relation + its schema
  productPair (dbs: TSyntax `sql_from) : TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    match dbs with
    | `(sql_from| $db:ident) => do
      -- A dotted table name (`"DB"."SCH"."T"` → `DB.SCH.T`) resolves to the declared table by its
      -- last component when the full name isn't declared. CTEs shadow base tables.
      let full := db.getId
      let cands := full :: (match full.components.getLast? with
        | some last => if last == full then [] else [last]
        | none => [])
      match ctes.findSome? (fun (name, e, cols) => if cands.contains name then some (e, cols) else none) with
      | some (cteExpr, cteCols) => return (cteExpr, cteCols)
      | none =>
        let .some (tableExpr, _, columns) :=
          tableVars.findSome? (fun (e, name, cols) => if cands.contains name then some (e, name, cols) else none)
          | throwError s!"Unknown table {full}"
        return (tableExpr, columns)
    | `(sql_from| $t:ident AS $x:ident)
    | `(sql_from| $t:ident $x:ident) => do
      -- Aliased table/CTE (`t AS x` or bare `t x`): resolve the base and re-qualify its columns under
      -- the alias, so two aliases of the same base get distinct columns (self-joins, S3) and CTE
      -- references resolve. Rename to `x.<last component>` — works for base-table columns (already
      -- `base.col`) AND for CTE columns (bare `col`, which `replacePrefix` could not touch).
      let (e, cols) ← productPair (← `(sql_from| $t:ident))
      return (e, cols.map (fun (n, ty) => (x.getId ++ (n.components.getLast?).getD n, ty)))
    | `(sql_from| ( $sub:sql_query ) AS $al:ident $[( $cols,* )]?)
    | `(sql_from| ( $sub:sql_query ) $al:ident $[( $cols,* )]?) => do
      let (lamSub, subSchema) ← elabSqlQueryCore tableVars ctes sub
      let vars := tableVars.map (fun (relVar, _, _) => relVar)
      match cols with
      | some cs =>
        -- Explicit column-alias list: relabel the subquery's output columns to `alias.col`.
        let names := cs.getElems.toList.map (fun c => al.getId ++ c.getId)
        return (lamSub.beta vars.toArray, names.zip (subSchema.map (·.2)))
      | none =>
        -- Qualify each column under the alias by its OUTPUT name (the subquery column's last component,
        -- e.g. `emp.sal` → `t.sal`) — matching how `alias.col` is written and how `subqueryJoin`/
        -- `outerJoinSub` label a subquery RHS, so `t.sal` resolves when this subquery is a join operand.
        return (lamSub.beta vars.toArray,
          subSchema.map (fun (n, ty) => (al.getId ++ (n.components.getLast?).getD n, ty)))
    -- `LATERAL FLATTEN` — correlated unnest appended to the left FROM (see `flattenArm`). Matched
    -- before the plain comma so `f1 , LATERALFLATTEN(e) …` doesn't fall through to a cross product.
    | `(sql_from| $f1:sql_from , LATERALFLATTEN( $e:term ) AS $h:ident ( $cols:ident,* ))
    | `(sql_from| $f1:sql_from , LATERALFLATTEN( $e:term ) $h:ident ( $cols:ident,* )) =>
      flattenArm f1 e h.getId (cols.getElems.toList.map (·.getId))
    | `(sql_from| $f1:sql_from , LATERALFLATTEN( $e:term ) AS $h:ident)
    | `(sql_from| $f1:sql_from , LATERALFLATTEN( $e:term ) $h:ident) =>
      flattenArm f1 e h.getId [`seq, `key, `path, `index, `value, `this]
    -- `LATERAL SPLIT_TO_TABLE(s, d)`: unnest like FLATTEN over the opaque `splitOf s d` (captures both
    -- args, so different (string, delimiter) stay distinct — sound).
    | `(sql_from| $f1:sql_from , LATERAL SPLIT_TO_TABLE( $s:term , $d:term ) AS $h:ident)
    | `(sql_from| $f1:sql_from , LATERAL SPLIT_TO_TABLE( $s:term , $d:term ) $h:ident) =>
      flattenArm f1 (← `($(mkIdent ``LeanDatabase.Scalar.splitOf) $s $d)) h.getId
        [`seq, `key, `path, `index, `value, `this]
    | `(sql_from| $f1:sql_from , $f2:sql_from) => do
      let (e1, s1) ← productPair f1
      let (e2, s2) ← productPair f2
      return (← mkAppM ``TypedRelationOfList.append #[e1, e2], s1 ++ s2)
    | `(sql_from| $f1:sql_from LEFT JOIN $t:ident ON $cond:term)
    | `(sql_from| $f1:sql_from LEFT OUTER JOIN $t:ident ON $cond:term) =>
      outerJoin f1 t none cond ``leftOuterJoin ``ofOuterLeft false true
    | `(sql_from| $f1:sql_from RIGHT JOIN $t:ident ON $cond:term)
    | `(sql_from| $f1:sql_from RIGHT OUTER JOIN $t:ident ON $cond:term) =>
      outerJoin f1 t none cond ``rightOuterJoin ``ofOuterRight true false
    | `(sql_from| $f1:sql_from FULL JOIN $t:ident ON $cond:term)
    | `(sql_from| $f1:sql_from FULL OUTER JOIN $t:ident ON $cond:term) =>
      outerJoin f1 t none cond ``fullOuterJoin ``ofOuterFull true true
    | `(sql_from| $f1:sql_from NATURAL JOIN $t:ident) =>
      naturalJoin f1 (← `(sql_from| $t:ident))
    | `(sql_from| $f1:sql_from NATURAL JOIN $t:ident AS $x:ident)
    | `(sql_from| $f1:sql_from NATURAL JOIN $t:ident $x:ident) =>
      naturalJoin f1 (← `(sql_from| $t:ident AS $x:ident))
    -- Aliased-RHS joins: build with the alias-renamed right table (so self-joins get distinct cols).
    | `(sql_from| $f1:sql_from JOIN $t:ident AS $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from JOIN $t:ident $x:ident ON $cond:term) =>
      innerJoin f1 (← `(sql_from| $t:ident AS $x:ident)) (some cond)
    | `(sql_from| $f1:sql_from CROSS JOIN $t:ident AS $x:ident)
    | `(sql_from| $f1:sql_from CROSS JOIN $t:ident $x:ident) =>
      innerJoin f1 (← `(sql_from| $t:ident AS $x:ident)) none
    | `(sql_from| $f1:sql_from LEFT JOIN $t:ident AS $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from LEFT OUTER JOIN $t:ident AS $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from LEFT JOIN $t:ident $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from LEFT OUTER JOIN $t:ident $x:ident ON $cond:term) =>
      outerJoin f1 t (some x) cond ``leftOuterJoin ``ofOuterLeft false true
    | `(sql_from| $f1:sql_from RIGHT JOIN $t:ident AS $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from RIGHT OUTER JOIN $t:ident AS $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from RIGHT JOIN $t:ident $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from RIGHT OUTER JOIN $t:ident $x:ident ON $cond:term) =>
      outerJoin f1 t (some x) cond ``rightOuterJoin ``ofOuterRight true false
    | `(sql_from| $f1:sql_from FULL JOIN $t:ident AS $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from FULL OUTER JOIN $t:ident AS $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from FULL JOIN $t:ident $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from FULL OUTER JOIN $t:ident $x:ident ON $cond:term) =>
      outerJoin f1 t (some x) cond ``fullOuterJoin ``ofOuterFull true true
    -- Outer joins with a subquery RHS.
    | `(sql_from| $f1:sql_from LEFT $[OUTER]? JOIN ( $sub:sql_query ) AS $x:ident ON $cond:term) =>
      outerJoinSub f1 sub x.getId cond ``leftOuterJoin ``ofOuterLeft false true
    | `(sql_from| $f1:sql_from RIGHT $[OUTER]? JOIN ( $sub:sql_query ) AS $x:ident ON $cond:term) =>
      outerJoinSub f1 sub x.getId cond ``rightOuterJoin ``ofOuterRight true false
    | `(sql_from| $f1:sql_from FULL $[OUTER]? JOIN ( $sub:sql_query ) AS $x:ident ON $cond:term) =>
      outerJoinSub f1 sub x.getId cond ``fullOuterJoin ``ofOuterFull true true
    -- Parenthesised join group RHS: `f JOIN (g) ON cond` — `g` (e.g. `a CROSS JOIN b`) is its own FROM,
    -- so `innerJoin` elaborates it via `productPair` and joins the product to `f`.
    | `(sql_from| $f1:sql_from JOIN ( $g:sql_from ) ON $cond:term) =>
      innerJoin f1 g (some cond)
    -- Inner `JOIN ON` / `CROSS JOIN` handled here (not just via `escapeJoin`) so they compose with
    -- GROUP BY / ORDER BY / LIMIT, which `escapeJoin`'s whole-query rewrite doesn't reach (C1).
    | `(sql_from| $f1:sql_from JOIN $t:ident ON $cond:term) =>
      innerJoin f1 (← `(sql_from| $t:ident)) (some cond)
    | `(sql_from| $f1:sql_from CROSS JOIN $t:ident) =>
      innerJoin f1 (← `(sql_from| $t:ident)) none
    -- Subquery-RHS INNER / CROSS joins: elaborate the subquery, prefix its columns under the alias
    -- (`x.col`) so an `ON`/`WHERE` ref `x.col` resolves and can't clash with a same-named left column.
    | `(sql_from| $f1:sql_from JOIN ( $sub:sql_query ) AS $x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from JOIN ( $sub:sql_query ) $x:ident ON $cond:term) =>
      subqueryJoin f1 sub x.getId (some cond)
    | `(sql_from| $f1:sql_from CROSS JOIN ( $sub:sql_query ) AS $x:ident)
    | `(sql_from| $f1:sql_from CROSS JOIN ( $sub:sql_query ) $x:ident) =>
      subqueryJoin f1 sub x.getId none
    -- `JOIN u USING (a, b)` — inner join equating each shared column (`f.a = u.a AND …`).
    | `(sql_from| $f1:sql_from JOIN $t:ident USING ( $cols:ident,* )) => do
      let (e1, s1) ← productPair f1
      let (e2, s2) ← productPair (← `(sql_from| $t:ident))
      let combined := s1 ++ s2
      let lastOf : Name → Name := fun n => (n.components.getLast?).getD n
      let conds ← cols.getElems.toList.mapM fun c => do
        let cn := lastOf c.getId          -- `expandNames` may have qualified it to `t.id`
        let some (n1, _) := s1.find? (fun (n, _) => lastOf n == cn) | throwError s!"USING column {cn} not in left table"
        let some (n2, _) := s2.find? (fun (n, _) => lastOf n == cn) | throwError s!"USING column {cn} not in right table"
        `($(mkIdent n1) == $(mkIdent n2))
      let cond ← conds.foldlM (fun acc c => `($acc && $c)) (← `(true))
      let condExpr ← elabTypedTupleFilter [(.anonymous, combined)] cond
      return (← mkAppM ``restriction #[condExpr, ← mkAppM ``TypedRelationOfList.append #[e1, e2]], combined)
    | _ => throwError "Unsupported FROM clause: {← PrettyPrinter.ppCategory `sql_from dbs}"
  -- `LATERAL FLATTEN(e) AS h (cols)` — append flatten's six columns (qualified under `h`) to the
  -- left FROM `f1`. `e` is the per-row VARIANT/array input, elaborated as `fun outerRow => (e :
  -- String)` against `f1`'s schema so it may reference `f1`'s columns (including an earlier
  -- flatten's `h.value`). The opaque `lateralFlatten` keeps it sound (see `Parser/Types.lean`).
  flattenArm (f1 : TSyntax `sql_from) (e : Term) (h : Name) (colNames : List Name) :
      TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    let (e1, s1) ← productPair f1
    let fFn ← withSchemasTupleVars [(.anonymous, s1)] e.raw.hasIdent fun vars =>
      mkLambdaLetsFVars vars (elabTermEnsuringType e (mkConst ``String))
    let out ← mkAppM ``lateralFlatten #[e1, fFn]
    let names := if colNames.length == flattenCols.length then colNames
                 else [`seq, `key, `path, `index, `value, `this]
    let hcols := (names.zip flattenCols).map (fun (c, ty) => (h ++ c, ty))
    return (out, s1 ++ hcols)
  -- Inner / cross join: cross-product of `f1` and `rhs` (each elaborated by `productPair`, so an
  -- aliased RHS is already renamed), restricted by the `ON` predicate over the combined schema.
  innerJoin (f1 rhs : TSyntax `sql_from) (cond? : Option Term) :
      TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    let (e1, s1) ← productPair f1
    let (e2, s2) ← productPair rhs
    let combined := s1 ++ s2
    let appended ← mkAppM ``TypedRelationOfList.append #[e1, e2]
    match cond? with
    | some cond => do
      -- `ON` sits inside the FROM, so the SELECT arm's `resolveInScope` never saw it: re-qualify here
      -- (`x.origin_city` → the derived table's `x.flights.origin_city`).
      let cond : Term := ⟨resolveInScope (combined.map (·.1)) cond⟩
      let condExpr ← elabTypedTupleFilter [(.anonymous, combined)] cond
      return (← mkAppM ``restriction #[condExpr, appended], combined)
    | none => return (appended, combined)
  -- `A NATURAL JOIN B` — equi-join on every column name shared by the two sides (matched on the bare
  -- last component), then project the right side's duplicates away, so a bare reference to a shared
  -- column stays unambiguous and `SELECT *` doesn't repeat it.
  naturalJoin (f1 rhs : TSyntax `sql_from) : TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    let (e1, s1) ← productPair f1
    let (e2, s2) ← productPair rhs
    let lastOf : Name → Name := fun n => (n.components.getLast?).getD n
    let combined := s1 ++ s2
    let appended ← mkAppM ``TypedRelationOfList.append #[e1, e2]
    -- Each right-hand column that also occurs on the left, paired with its left counterpart.
    let shared := s2.filterMap fun (n, _) =>
      (s1.find? (fun (m, _) => lastOf m == lastOf n)).map (fun (m, _) => (m, n))
    if shared.isEmpty then return (appended, combined)
    let mut cond : Term ← `(true)
    for (m, n) in shared do
      cond ← `($cond && $(mkIdent m) = $(mkIdent n))
    let condExpr ← elabTypedTupleFilter [(.anonymous, combined)] cond
    let joined ← mkAppM ``restriction #[condExpr, appended]
    let keep := s1 ++ s2.filter (fun (n, _) => !shared.any (fun (_, d) => d == n))
    let (proj, types) ← elabTypedTupleProjection [(.anonymous, combined)]
      (keep.map (fun (n, _) => mkIdent n))
    let names := keep.map (·.1)
    return (← mkAppM ``TypedRelation.mapByList #[joined, toExpr (names.map (·.toString)), proj],
            names.zip types)
  -- Inner/cross join with a subquery RHS: elaborate the subquery, re-label its columns under the alias
  -- (`x.<last component>`) so `x.col` in the `ON`/`WHERE` resolves and stays distinct from a left column.
  subqueryJoin (f1 : TSyntax `sql_from) (sub : TSyntax `sql_query) (x : Name) (cond? : Option Term) :
      TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    let (e1, s1) ← productPair f1
    let (lamSub, subSchema) ← elabSqlQueryCore tableVars ctes sub
    let e2 := lamSub.beta (tableVars.map (·.1)).toArray
    let s2 := subSchema.map (fun (n, ty) => (x ++ (n.components.getLast?).getD n, ty))
    let combined := s1 ++ s2
    let appended ← mkAppM ``TypedRelationOfList.append #[e1, e2]
    match cond? with
    | some cond => do
      let condExpr ← elabTypedTupleFilter [(.anonymous, combined)] cond
      return (← mkAppM ``restriction #[condExpr, appended], combined)
    | none => return (appended, combined)
  -- `A LEFT/RIGHT/FULL OUTER JOIN t ON cond` → the corresponding operator, then reconciled back to
  -- the canonical list schema by `reindexName` (`ofOuterLeft`/…) so `WHERE`/projection over the
  -- result elaborate. The `ON` condition is a two-tuple predicate (left tuple, right tuple), exactly
  -- like the semi/anti-join correlations. The output schema wraps the null-padded side's columns in
  -- `.nullable` (their values become `Option`).
  outerJoin (f1 : TSyntax `sql_from) (t : TSyntax `ident) (rhsAlias : Option (TSyntax `ident))
      (cond : Term) (opName reindexName : Name) (nullLeft nullRight : Bool) :
      TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    let (e1, s1) ← productPair f1
    let (e2, s2raw) ← productPair (← `(sql_from| $t:ident))
    -- an aliased RHS renames its columns under the alias prefix (self-join safe). Prepend the alias to
    -- the last component so it works for base tables (`base.col`) AND CTEs (bare `col`) alike.
    let baseP := (t.getId.components.getLast?).getD t.getId
    let rhsP := (rhsAlias.map (·.getId)).getD baseP
    let s2 := match rhsAlias with
      | some x => s2raw.map (fun (n, ty) => (x.getId ++ (n.components.getLast?).getD n, ty))
      | none => s2raw
    let condExpr ← elabTypedTupleFilter [(.anonymous, s1), (rhsP, s2)] cond
    let joinExpr ← mkAppM opName #[e1, e2, condExpr]
    let reindexed ← mkAppM reindexName #[joinExpr]
    let nul : List (Name × SQLTypeProxy) → List (Name × SQLTypeProxy) :=
      List.map (fun (n, ty) => (n, .nullable ty))
    return (reindexed, (if nullLeft then nul s1 else s1) ++ (if nullRight then nul s2 else s2))
  -- Outer join with a subquery RHS (`… LEFT/RIGHT/FULL JOIN (subquery) AS x ON …`): like `outerJoin`
  -- but the right side is an elaborated subquery, its columns prefixed under the alias.
  outerJoinSub (f1 : TSyntax `sql_from) (sub : TSyntax `sql_query) (x : Name) (cond : Term)
      (opName reindexName : Name) (nullLeft nullRight : Bool) :
      TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    let (e1, s1) ← productPair f1
    let (lamSub, subSchema) ← elabSqlQueryCore tableVars ctes sub
    let e2 := lamSub.beta (tableVars.map (·.1)).toArray
    let s2 := subSchema.map (fun (n, ty) => (x ++ (n.components.getLast?).getD n, ty))
    let cond : Term := ⟨resolveInScope ((s1 ++ s2).map (·.1)) cond⟩
    let condExpr ← elabTypedTupleFilter [(.anonymous, s1), (x, s2)] cond
    let joinExpr ← mkAppM opName #[e1, e2, condExpr]
    let reindexed ← mkAppM reindexName #[joinExpr]
    let nul : List (Name × SQLTypeProxy) → List (Name × SQLTypeProxy) :=
      List.map (fun (n, ty) => (n, .nullable ty))
    return (reindexed, (if nullLeft then nul s1 else s1) ++ (if nullRight then nul s2 else s2))
  -- Apply a `WHERE` clause to `rel`. `[NOT] EXISTS (subquery)` and `x [NOT] IN (subquery)` become a
  -- `semijoin`/`antijoin`; anything else is an ordinary `restriction` by a tuple predicate.
  elabWhere (rel : Expr) (schema : List (Name × SQLTypeProxy)) (filter : Term)
      (usedStx : Syntax) : TermElabM Expr := do
    -- A single conjunct that is a `[NOT] EXISTS`/`[NOT] IN` subquery predicate → `semijoin`/`antijoin`
    -- of `rel` with the (correlated) subquery; `none` if `t` is an ordinary tuple predicate. `NOT (x IN
    -- …)`/`NOT EXISTS(…)` (the `NOT`-macro wrapping the subquery term) are handled too.
    let trySubqPred (rel : Expr) (t : Syntax.Term) : TermElabM (Option Expr) := do
      match t with
      | `(EXISTS ( $inner:sql_query ))          => some <$> elabExists rel schema inner none false
      | `(NOT EXISTS ( $inner:sql_query ))      => some <$> elabExists rel schema inner none true
      | `($oc:term IN ( $inner:sql_query ))     => some <$> elabExists rel schema inner (some oc) false
      | `($oc:term NOT IN ( $inner:sql_query )) => some <$> elabExists rel schema inner (some oc) true
      | `(NOT $inner:term) =>
        match inner with
        | `($oc:term IN ( $q:sql_query ))     => some <$> elabExists rel schema q (some oc) true
        | `($oc:term NOT IN ( $q:sql_query )) => some <$> elabExists rel schema q (some oc) false
        | `(EXISTS ( $q:sql_query ))          => some <$> elabExists rel schema q none true
        | _ => pure none
      | _ => pure none
    -- Peel subquery predicates out of a compound `WHERE p₁ AND p₂ AND …`: each `[NOT] EXISTS`/`[NOT] IN`
    -- conjunct becomes a semi/antijoin, the ordinary ones fold back into a single `restriction`. Sound:
    -- `σ_{p∧q} = σ_p ∘ σ_q`, and the (anti)joins keep `rel`'s rows so `schema` is unchanged throughout.
    let conjs := flattenAnd filter
    let mut relAcc := rel
    let mut plain : Array Syntax.Term := #[]
    let mut sawSubq := false
    for c in conjs do
      match ← trySubqPred relAcc c with
      | some r => relAcc := r; sawSubq := true
      | none   => plain := plain.push c
    if !sawSubq then
      -- No subquery predicate: elaborate the original filter as one tuple predicate (unchanged behavior).
      let f ← elabTypedTupleFilter [(.anonymous, schema)] filter usedStx
      mkAppM ``restriction #[f, rel]
    else if plain.isEmpty then
      return relAcc
    else
      -- re-AND the ordinary conjuncts: seed with the first, fold the rest.
      let combined ← (plain.toList.tail!).foldlM (fun (acc : Syntax.Term) t => `($acc && $t)) plain[0]!
      let f ← elabTypedTupleFilter [(.anonymous, schema)] combined usedStx
      mkAppM ``restriction #[f, relAcc]

  elabExists (rel : Expr) (outerSchema : List (Name × SQLTypeProxy)) (inner : TSyntax `sql_query)
      (inCol? : Option Term) (isNeg : Bool) : TermElabM Expr := do
    match inner with
    | `(sql_query| SELECT $[DISTINCT%$_d]? $sel:sql_cols FROM $sdb:sql_from $[WHERE $corr?]? $[;]?) => do
      -- `DISTINCT` in an IN/EXISTS subquery is irrelevant (set membership), so it is accepted and ignored.
      -- `productPair` elaborates any inner FROM (a base table, a subquery `(…) AS t`, a join, or VALUES),
      -- so no single-table restriction is needed — the correlation resolves against `sSchema` below.
      let (sExpr, sSchema) ← productPair sdb
      let corr ← match inCol?, corr? with
        | some oc, _ => do                                  -- `oc IN (SELECT c FROM …)`  ⇒  `oc = c`
          match sel with
          | `(sql_cols| $c:sql_col,*) =>
            let #[col] := c.getElems | throwError "IN subquery must SELECT exactly one column"
            `($oc = $(sqlColTerm col))
          | _ => throwError "IN subquery must SELECT exactly one column"
        | none, some corr => pure corr                      -- `EXISTS (… WHERE corr)`
        | none, none => throwError "EXISTS subquery needs a correlating WHERE condition"
      -- `.anonymous` for both: `productPair` already qualified the inner columns (`y.loc` under
      -- `DEPT AS Y`), so re-prefixing them by the base table would hide them from the correlation.
      let cond ← elabTypedTupleFilter [(.anonymous, outerSchema), (.anonymous, sSchema)] corr
      mkAppM (if isNeg then ``antijoin else ``semijoin) #[rel, sExpr, cond]
    | _ => throwError "subquery expects `SELECT … FROM table …`"

  -- Rewrite a scalar-subquery column `(SELECT AGG(x) FROM t [WHERE p]) AS n` to a `sqlDeferredSubq%`
  -- placeholder + stash entry. The inner *relation* (outer-independent) is built now via `productPair`;
  -- the inner `WHERE` — which may be **correlated** (reference outer columns) — is stored and
  -- elaborated later, inside the projection context, where the outer row's let-vars are in scope.
  stashSubq (q : TSyntax `sql_query) (name : TSyntax `ident) : TermElabM (TSyntax `sql_col) := do
    `(sql_col| $(← stashSubqTerm q):term AS $name:ident)

  -- The term half of `stashSubq`: stash the subquery and yield its placeholder, for a scalar subquery
  -- used as a *value* (`WHERE x = (SELECT MAX(y) FROM t)`) as well as in the SELECT list.
  stashSubqTerm (q : TSyntax `sql_query) : TermElabM Syntax.Term := do
    match q with
    | `(sql_query| SELECT $sel:sql_cols FROM $sdb:sql_from $[WHERE $p?]? $[;]?) => do
      let (rel, schema) ← productPair sdb
      let `(sql_cols| $c:sql_col,*) := sel | throwError "scalar subquery must SELECT one aggregate"
      let #[col1] := c.getElems | throwError "scalar subquery must SELECT one aggregate"
      let (_, aggs) ← (liftAggExprs (sqlColTerm col1)).run #[]
      let #[(_, kind, argStx)] := aggs
        | throwError "scalar subquery column must be a single aggregate (SUM/COUNT)"
      let mkSummand (asInt : Bool) : TermElabM Expr :=
        withSchemasTupleVars [(.anonymous, schema)] (fun _ => true) fun vars =>
          mkLambdaLetsFVars vars (if asInt then elabTermEnsuringType argStx (mkConst ``Int)
                                  else Prod.snd <$> elabAsSql argStx)
      let summand? ← match kind with
        | .count => pure none
        | .sum => some <$> mkSummand true
        | .countDistinct => some <$> mkSummand false
        | .max | .min => some <$> mkSummand true
        | _ => throwError "scalar subquery: only SUM / COUNT / COUNT(DISTINCT) / MAX / MIN are supported"
      let idx := (← scalarSubqStash.get).size
      scalarSubqStash.modify (·.push
        { innerRel := rel, innerSchema := schema, kind, summand := summand?, cond := p?.map (·.raw) })
      `((sqlDeferredSubq% $(quote idx)))
    | _ => do
      -- Any other shape (grouped, set-op, …): elaborate the inner query and take the opaque
      -- `relScalarOpaque` of it — sound, and enough for two equal inner relations to agree.
      let (lam, _) ← elabSqlQueryCore tableVars ctes q
      let rel := lam.beta (tableVars.map (fun (relVar, _, _) => relVar)).toArray
      Term.exprToSyntax (← mkAppM ``LeanDatabase.TypedAgg.relScalarOpaque #[rel])

  -- Replace every parenthesised scalar subquery inside a term by its stashed placeholder.
  stashTermSubqueries (t : Syntax.Term) : TermElabM Syntax.Term := do
    let out ← t.raw.replaceM fun s =>
      match s with
      | `(term| ( $q:sql_query )) => do pure (some (← stashSubqTerm q).raw)
      | _ => pure none
    pure ⟨out⟩

  preprocessScalarSubqueries (cols : Array (TSyntax `sql_col)) :
      TermElabM (Array (TSyntax `sql_col)) := do
    let mut out := #[]
    for col in cols do
      match col with
      | `(sql_col| ( $q:sql_query ) AS $name:ident) => out := out.push (← stashSubq q name)
      | _ => out := out.push col
    return out

  -- The SELECT projection: `*`, qualified star `t.*`, or a column list. A column list is *grouped*
  -- (via `elabTypedTupleGroupProjection` + optional HAVING) when there is a GROUP BY **or** an
  -- aggregate in the list — an ungrouped aggregate is just a group over the empty key. Otherwise it
  -- is a plain positional projection. Returns `(relation, output schema)`.
  elabSelect (sel : TSyntax `sql_cols) (combinedSchema : List (Name × SQLTypeProxy))
      (filteredExpr : Expr) (groupItems : Array Term) (hasGroupBy : Bool) (having? : Option Term)
      (aliasMap : List (Name × Name)) :
      TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    match sel with
    | `(sql_cols| *) => pure (filteredExpr, combinedSchema)
    | `(sql_cols| $t:ident . *) => do
      let pfx := t.getId
      let picked := combinedSchema.filter (fun (name, _) => pfx.isPrefixOf name)
      if picked.isEmpty then throwError s!"Unknown table {pfx} in `{pfx}.*`"
      let cols : List Syntax.Term := picked.map (fun (n, _) => mkIdent n)
      let names := picked.map (fun (n, _) => baseifyName aliasMap n)
      let (m, types) ← elabTypedTupleProjection [(.anonymous, combinedSchema)] cols
      pure (← mkAppM ``TypedRelation.mapByList #[filteredExpr, toExpr (names.map (·.toString)), m],
            names.zip types)
    | `(sql_cols| * , $cols:sql_col,*) => do
      -- `SELECT *, extra …` → expand `*` to every in-scope column, then treat as a plain column list.
      let starCols ← combinedSchema.toArray.mapM (fun (n, _) => `(sql_col| $(mkIdent n):ident))
      let all := starCols ++ cols.getElems
      elabSelect (← `(sql_cols| $all:sql_col,*)) combinedSchema filteredExpr groupItems hasGroupBy having? aliasMap
    | `(sql_cols| $t:ident . * , $cols:sql_col,*) => do
      let pfx := t.getId
      let picked := combinedSchema.filter (fun (name, _) => pfx.isPrefixOf name)
      if picked.isEmpty then throwError s!"Unknown table {pfx} in `{pfx}.*`"
      let starCols ← picked.toArray.mapM (fun (n, _) => `(sql_col| $(mkIdent n):ident))
      let all := starCols ++ cols.getElems
      elabSelect (← `(sql_cols| $all:sql_col,*)) combinedSchema filteredExpr groupItems hasGroupBy having? aliasMap
    | `(sql_cols| $cols:sql_col,*) => do
      let colStxs ← preprocessScalarSubqueries cols.getElems
      let colTerms := colStxs.map sqlColTerm
      -- An unaliased expression column is auto-named from its own text (`X.A + X.B` → `XAXB`), so
      -- baseify the *idents first*: otherwise two queries differing only in table alias get different
      -- output labels and stop being equal.
      let names := colStxs.map (fun c => sqlColName ⟨baseifyIdents aliasMap c.raw⟩)
        |>.toList |>.map (baseifyName aliasMap)
      let nameStrs := names.map (·.toString)
      let (liftedRaw, selAggs) ← (colTerms.toList.mapM liftAggExprs).run #[]
      if selAggs.isEmpty && !hasGroupBy then
        let (m, types) ← elabTypedTupleProjection [(.anonymous, combinedSchema)] colTerms.toList
        pure (← mkAppM ``TypedRelation.mapByList #[filteredExpr, toExpr nameStrs, m], names.zip types)
      else
        -- The group *key* is the list of GROUP BY terms (a bare column is just `term = col`);
        -- positional `GROUP BY 1` and SELECT-alias refs resolve here. See `Parser/GroupBy.lean`.
        let aliasPairs := ((colStxs.map sqlColName).zip colTerms).toList
        let groupTerms := (groupItems.map (resolveGroupItem colTerms aliasPairs)).toList
        let liftedCols : List Syntax.Term := liftedRaw.map (⟨·⟩)
        let (m, types) ← elabTypedTupleGroupProjection
          [(.anonymous, combinedSchema)] liftedCols groupTerms filteredExpr selAggs.toList
        let havingFilteredExpr ← match having? with
          | some having => do
            -- HAVING may reference a SELECT alias (`HAVING cnt > 150` where `cnt` is `COUNT(*) AS cnt`).
            -- Expand each such alias to its SELECT expression before lifting aggregates.
            let aliasPairs := (colStxs.map sqlColName).zip (colStxs.map sqlColTerm) |>.toList
            let having := having.raw.replaceM (m := Id) fun s => match s with
              | .ident _ _ v _ => (aliasPairs.find? (·.1 == v)).map (·.2.raw)
              | _ => none
            let (having, havAggs) ← (liftAggExprs having).run #[]
            let h ← elabTypedTupleGroupFilter
              [(.anonymous, combinedSchema)] having groupTerms filteredExpr havAggs.toList
            mkAppM ``restriction #[h, filteredExpr]
          | none => pure filteredExpr
        pure (← mkAppM ``TypedRelation.mapByList #[havingFilteredExpr, toExpr nameStrs, m],
              names.zip types)
    | _ => throwError "Unexpected SELECT column syntax"

def elabSqlQuery (tables : List (Name × List (Name × SQLTypeProxy))) (stx: Syntax) :
    TermElabM (Expr × List (Name × SQLTypeProxy)) := withTableVars tables fun tableVars => do
  let stx ← escapeJoin stx
  elabSqlQueryCore tableVars [] stx

-- SQL surface-syntax normalization (`normalizeSqlLiterals` + helpers) lives in `Parser/Handlers/Normalize.lean`.

/-- Fold a `Name`'s string components to lowercase (case-insensitive identifiers, C3). -/
def lowerName (n : Name) : Name :=
  n.components.foldl (init := Name.anonymous) fun acc c =>
    match c with
    | .str _ s => acc.str s.toLower
    | .num _ k => acc.num k
    | _ => acc

/-- Lowercase every `ident` in the parsed query — keyword atoms and string literals are untouched, so
`SELECT`/`FROM` and `'US'` are unaffected while `T."Col"` and table names fold. -/
def lowerIdents (stx : Syntax) : Syntax :=
  stx.replaceM (m := Id) fun s => match s with
    | .ident info raw val pre => some (.ident info raw (lowerName val) pre)
    | _ => none

/-- A column named like one of our function keywords (`YEAR`, `DATE`, `MAX`, `RANK`, …) is a reserved
token, so the tokenizer never offers it as an identifier and `SELECT YEAR FROM …` fails to parse.
Wrap such a *name use* (not a call) in `«…»`, which the tokenizer always reads as an identifier.
Only names this query's schema actually declares are touched, and `CAST(x AS DATE)` / `EXTRACT(YEAR
FROM x)` — where the keyword is the operator's own argument — are left alone. -/
def escapeReservedNames (env : Environment) (names : List String) (s : String) : String := Id.run do
  let tokens := Lean.Parser.getTokenTable env
  let isWordChar := fun (c : Char) => c.isAlphanum || c == '_'
  let cs := s.toList
  let mut out := ""
  let mut i := 0
  let mut inStr := false
  while h : i < cs.length do
    let c := cs[i]
    if c == '\'' then
      inStr := !inStr; out := out.push c; i := i + 1
    else if inStr || !(c.isAlpha || c == '_') then
      out := out.push c; i := i + 1
    else
      -- One word, plus the characters around it that decide whether it is a name use.
      let mut j := i
      let mut word := ""
      while h : j < cs.length do
        if isWordChar cs[j] then word := word.push cs[j]; j := j + 1 else break
      let prev := (cs.take i).reverse.dropWhile (· == ' ')
      let afterCall := (cs.drop j).dropWhile (· == ' ')
      let nextWord := String.ofList (afterCall.takeWhile isWordChar)
      let isCall := afterCall.head? == some '('
      let isCastTarget := (prev.take 2).reverse == ['A', 'S'] && (prev[2]? == some ' ')
      let isExtractPart := prev.head? == some '(' && nextWord.toUpper == "FROM"
      let dotted := prev.head? == some '.' || prev.head? == some '«'
      let declared := names.contains word.toLower
      let reserved := (tokens.find? word).isSome || (tokens.find? word.toUpper).isSome
      if declared && reserved && !isCall && !isCastTarget && !isExtractPart && !dotted then
        out := out ++ "«" ++ word ++ "»"
      else
        out := out ++ word
      i := j
  return out

def parseSqlQuery (tables : List (Name × List (Name × SQLTypeProxy))) (str : String) : TermElabM (Expr × List (Name × SQLTypeProxy)) := do
  let str := normalizeSqlLiterals str
  let str := escapeReservedNames (← getEnv)
    (tables.flatMap (fun (t, cols) => t.toString.toLower :: cols.map (·.1.toString.toLower))) str
  -- Case-insensitive identifiers: fold the schema and the query's idents to a common (lower) case.
  let tables := tables.map (fun (t, cols) => (lowerName t, cols.map (fun (c, ty) => (lowerName c, ty))))
  let tables := tables.map (fun (tableName, columns) => (tableName, schemaWithFullNames tableName columns))
  let stx ← match Parser.runParserCategory (← getEnv) `sql_query str with
    | .ok stx => pure stx
    | .error err => throwError "Failed to parse SQL query: {err}\n--- input ---\n{str}"
  let stx := lowerIdents stx
  -- Resolution labels: every base column `t.col`, plus each alias's columns under its own prefix
  -- (`x.col`), so an aliased table's columns — renamed to `x.col` by `productPair` — resolve, and two
  -- aliases of the same base table stay distinct (self-joins, S3).
  let baseLabels := tables.foldl (fun acc (_, columns) => acc ++ columns.map (·.1)) []
  let aliasLabels := (collectAliases stx).foldl (fun acc (al, base) =>
    match tables.find? (fun (n, _) => n == base) with
    | some (_, cols) => acc ++ cols.map (fun (n, _) => n.replacePrefix base al)
    | none => acc) []
  let stx ← expandNames (baseLabels ++ aliasLabels) stx (aliases := collectAliases stx)
    (subqAliases := collectCteNames stx)
  elabSqlQuery tables stx


/-! ## Smoke tests — the parser elaborates, and `grind` proves the equivalences -/

def egTypedTupleFilter := parseTypedTupleFilter [("age", "Int"), ("isactive", "Bool"), ("height", "Float")] "age > 30 && isactive"

def egTypedTupleFilter' := parseTypedTupleFilter [("age", "Int"), ("isactive", "Bool"), ("height", "Float")] "age > 30 && isactive && age > 20"

def egTypedRelFilter := parseTypedRelFilter [("table", [("age", "Int"), ("isactive", "Bool"), ("height", "Float")])] "age > 30 && isactive && height < 180"

def egTypedRelFilter' := parseTypedRelFilter [("table", [("age", "Int"), ("isactive", "Bool"), ("height", "Float")])] "age > 30 && isactive && age > 20 && height < 180"

def egSqlQuery := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)])] "SELECT * FROM table WHERE age > 30 && isactive && height < 180"

def egSqlQuery' := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)])] "SELECT * FROM table WHERE age > 30 && isactive && height < 180 && age > 20"

def egSqlQuery₁ := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)])] "SELECT age FROM table WHERE age > 30 && isactive && height < 180"

def egSqlQuery₂ := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)])] "SELECT age, height FROM table WHERE age > 30 && isactive && height < 180"

def egSqlQuery₃ := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)]), (`table2, [(`age, .int), (`isactive, .bool), (`height, .float)])] "SELECT * FROM table, table2  WHERE table.age > 30 && table.isactive && table.height < 180"

def egSqlQuery₄ := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)])] "SELECT 2 * age AS doubled_age FROM table WHERE age > 30 && isactive && height < 180"

def egSqlQuery₅ := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)])] "SELECT COUNT(*) AS count FROM table WHERE age > 30 && isactive && height < 180 GROUP BY age"

def egSqlQuery₆ := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)])] "SELECT SUM(age) AS count FROM table WHERE age > 30 && isactive && height < 180 GROUP BY isactive"

def egSqlQuery₇ := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)])] "SELECT SUM(age) AS sum FROM table WHERE age > 30 && isactive && height < 180 GROUP BY isactive HAVING SUM(age) < 100"

-- SELECT CASE WHEN age > 30 THEN 1 ELSE 0 END AS flag ...
def egSqlQuery₈ := parseSqlQuery [(`table, [(`age, .int), (`isactive, .bool), (`height, .float)])]
  "SELECT CASE WHEN age > 30 THEN 1 ELSE 0 END AS flag FROM table"

elab "egTypedTupleFilter%" : term => do
  let e ← egTypedTupleFilter
  return e

elab "egTypedTupleFilter%%" : term => do
  let e ← egTypedTupleFilter'
  return e

elab "egTypedRelFilter%" : term => do
  let e ← egTypedRelFilter
  return e

elab "egTypedRelFilter%%" : term => do
  let e ← egTypedRelFilter'
  return e

elab "egSqlQuery%" : term => do
  let (e, _) ← egSqlQuery
  return e

elab "egSqlQuery%%" : term => do
  let (e, _) ← egSqlQuery'
  return e

example : egSqlQuery% = egSqlQuery%% := by
  grind

elab "egSqlQuery₁" : term => do
  let (e, _) ← egSqlQuery₁
  return e

elab "egSqlQuery₂" : term => do
  let (e, _) ← egSqlQuery₂
  return e

elab "egSqlQuery₃" : term => do
  let (e, _) ← egSqlQuery₃
  return e

elab "egSqlQuery₄" : term => do
  let (e, _) ← egSqlQuery₄
  return e

elab "egSqlQuery₅" : term => do
  let (e, _) ← egSqlQuery₅
  return e

elab "egSqlQuery₆" : term => do
  let (e, _) ← egSqlQuery₆
  return e

elab "egSqlQuery₇" : term => do
  let (e, _) ← egSqlQuery₇
  return e

elab "egSqlQuery₈" : term => do
  let (e, _) ← egSqlQuery₈
  return e


-- #check egTypedTupleFilter%
set_option pp.funBinderTypes true in
/--
info: fun (table : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float]) ↦
  restriction
    (fun (coords : TypedTupleOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float]) ↦
      let table.age := coords 0;
      let table.isactive := coords 1;
      let table.height := coords 2;
      decide (table.age > 30) && table.isactive && decide (table.height < 180))
    table : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
  TypedRelation (colTypeOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float])
-/
#guard_msgs in
#check egSqlQuery%

/--
info: @[reducible] def LeanDatabase.TypedTupleOfList : List SQLTypeProxy → Type :=
fun l ↦ TypedTuple (colTypeOfList l)
-/
#guard_msgs in
#print TypedTupleOfList

example : TypedTupleOfList [] := by
  intro ⟨i, hi⟩
  simp at hi

/--
info: fun table ↦
  (restriction
        (fun coords ↦
          let table.age := coords 0;
          let table.isactive := coords 1;
          let table.height := coords 2;
          decide (table.age > 30) && table.isactive && decide (table.height < 180))
        table).mapByList
    ["table.age"] fun coords ↦
    let table.age := coords 0;
    TypedTupleOfList.cons SQLTypeProxy.int table.age
      TypedTupleOfList.nil : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
  TypedRelationOfList [SQLTypeProxy.int]
-/
#guard_msgs in
#check egSqlQuery₁


/--
info: fun table ↦
  (restriction
        (fun coords ↦
          let table.age := coords 0;
          let table.isactive := coords 1;
          let table.height := coords 2;
          decide (table.age > 30) && table.isactive && decide (table.height < 180))
        table).mapByList
    ["table.age", "table.height"] fun coords ↦
    let table.age := coords 0;
    let table.height := coords 2;
    TypedTupleOfList.cons SQLTypeProxy.int table.age
      (TypedTupleOfList.cons SQLTypeProxy.float table.height
        TypedTupleOfList.nil) : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
  TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.float]
-/
#guard_msgs in
#check egSqlQuery₂

-- example : egSqlQuery₃ := by
--   sorry

/--
info: fun table table2 ↦
  restriction
    (fun coords ↦
      let table.age := coords 0;
      let table.isactive := coords 1;
      let table.height := coords 2;
      decide (table.age > 30) && table.isactive && decide (table.height < 180))
    (table.append
      table2) : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
  TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
    TypedRelation
      (colTypeOfList
        [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float, SQLTypeProxy.int, SQLTypeProxy.bool,
          SQLTypeProxy.float])
-/
#guard_msgs in
#check egSqlQuery₃

/--
info: fun table ↦
  (restriction
        (fun coords ↦
          let table.age := coords 0;
          let table.isactive := coords 1;
          let table.height := coords 2;
          decide (table.age > 30) && table.isactive && decide (table.height < 180))
        table).mapByList
    ["doubled_age"] fun coords ↦
    let table.age := coords 0;
    TypedTupleOfList.cons SQLTypeProxy.int (2 * table.age)
      TypedTupleOfList.nil : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
  TypedRelationOfList [SQLTypeProxy.int]
-/
#guard_msgs in
#check egSqlQuery₄

/--
info: fun table ↦
  (restriction
        (fun coords ↦
          let table.age := coords 0;
          let table.isactive := coords 1;
          let table.height := coords 2;
          decide (table.age > 30) && table.isactive && decide (table.height < 180))
        table).mapByList
    ["count"] fun coords ↦
    let __agg0 :=
      (fun k ↦
          Int.ofNat
            (groupCount (fun typedTuple ↦ TypedTupleOfList.cons SQLTypeProxy.int (typedTuple 0) TypedTupleOfList.nil) k
              (restriction (fun coords ↦ decide (coords 0 > 30) && coords 1 && decide (coords 2 < 180)) table)))
        ((fun typedTuple ↦ TypedTupleOfList.cons SQLTypeProxy.int (typedTuple 0) TypedTupleOfList.nil) coords);
    TypedTupleOfList.cons SQLTypeProxy.int __agg0
      TypedTupleOfList.nil : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
  TypedRelationOfList [SQLTypeProxy.int]
-/
#guard_msgs in
#check egSqlQuery₅


/--
info: fun table ↦
  (restriction
        (fun coords ↦
          let table.age := coords 0;
          let table.isactive := coords 1;
          let table.height := coords 2;
          decide (table.age > 30) && table.isactive && decide (table.height < 180))
        table).mapByList
    ["count"] fun coords ↦
    let __agg0 :=
      (fun k ↦
          groupSum (fun typedTuple ↦ TypedTupleOfList.cons SQLTypeProxy.bool (typedTuple 1) TypedTupleOfList.nil) k
            (restriction (fun coords ↦ decide (coords 0 > 30) && coords 1 && decide (coords 2 < 180)) table)
            fun coords ↦ coords 0)
        ((fun typedTuple ↦ TypedTupleOfList.cons SQLTypeProxy.bool (typedTuple 1) TypedTupleOfList.nil) coords);
    TypedTupleOfList.cons SQLTypeProxy.int __agg0
      TypedTupleOfList.nil : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
  TypedRelationOfList [SQLTypeProxy.int]
-/
#guard_msgs in
#check egSqlQuery₆

/--
info: fun table ↦
  (restriction
        (fun coords ↦
          let __agg0 :=
            (fun k ↦
                groupSum (fun typedTuple ↦ TypedTupleOfList.cons SQLTypeProxy.bool (typedTuple 1) TypedTupleOfList.nil)
                  k (restriction (fun coords ↦ decide (coords 0 > 30) && coords 1 && decide (coords 2 < 180)) table)
                  fun coords ↦ coords 0)
              ((fun typedTuple ↦ TypedTupleOfList.cons SQLTypeProxy.bool (typedTuple 1) TypedTupleOfList.nil) coords);
          decide (__agg0 < 100))
        (restriction
          (fun coords ↦
            let table.age := coords 0;
            let table.isactive := coords 1;
            let table.height := coords 2;
            decide (table.age > 30) && table.isactive && decide (table.height < 180))
          table)).mapByList
    ["sum"] fun coords ↦
    let __agg0 :=
      (fun k ↦
          groupSum (fun typedTuple ↦ TypedTupleOfList.cons SQLTypeProxy.bool (typedTuple 1) TypedTupleOfList.nil) k
            (restriction (fun coords ↦ decide (coords 0 > 30) && coords 1 && decide (coords 2 < 180)) table)
            fun coords ↦ coords 0)
        ((fun typedTuple ↦ TypedTupleOfList.cons SQLTypeProxy.bool (typedTuple 1) TypedTupleOfList.nil) coords);
    TypedTupleOfList.cons SQLTypeProxy.int __agg0
      TypedTupleOfList.nil : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
  TypedRelationOfList [SQLTypeProxy.int]
-/
#guard_msgs in
#check egSqlQuery₇

/--
info: fun table ↦
  TypedRelation.mapByList table ["flag"] fun coords ↦
    let table.age := coords 0;
    TypedTupleOfList.cons SQLTypeProxy.int (if decide (table.age > 30) = true then 1 else 0)
      TypedTupleOfList.nil : TypedRelationOfList [SQLTypeProxy.int, SQLTypeProxy.bool, SQLTypeProxy.float] →
  TypedRelationOfList [SQLTypeProxy.int]
-/
#guard_msgs in
#check egSqlQuery₈

set_option pp.funBinderTypes true in
example : egTypedTupleFilter% = egTypedTupleFilter%% := by
  grind

set_option pp.funBinderTypes true in
example : egTypedRelFilter% = egTypedRelFilter%% := by
  grind

end LeanDatabase
