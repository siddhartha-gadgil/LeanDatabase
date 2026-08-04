import LeanDatabase.Parser.Context
import LeanDatabase.Operators.CrossProduct
import LeanDatabase.Operators.Select
import LeanDatabase.Operators.OrderLimit
import LeanDatabase.Operators.Join

/-!
# Top-level query parsing

`parseTypedTupleFilter` / `parseTypedRelFilter` parse a `WHERE`-predicate string against a schema;
`elabSqlQuery` is the full `SELECT … FROM … WHERE …` entry point that dispatches on query shape and
composes the per-operator elaborators (`Parser.Context`) with the cross-product operator.
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
    TypedRelationOfList (lA ++ lB.map .nullable) :=
  { labels := fun j => r.labels (Fin.cast (by simp) j),
    rows := r.rows.image (fun t => TypedTupleOfList.append (splitTuple t).1 (ofOption (splitTuple t).2)) }

/-- `RIGHT JOIN` result → `lA.map .nullable ++ lB`. -/
def ofOuterRight
    (r : TypedRelation (Fin.append (fun i => Option (colTypeOfList lA i)) (colTypeOfList lB))) :
    TypedRelationOfList (lA.map .nullable ++ lB) :=
  { labels := fun j => r.labels (Fin.cast (by simp) j),
    rows := r.rows.image (fun t => TypedTupleOfList.append (ofOption (splitTuple t).1) (splitTuple t).2) }

/-- `FULL JOIN` result → `lA.map .nullable ++ lB.map .nullable`. -/
def ofOuterFull
    (r : TypedRelation (Fin.append (fun i => Option (colTypeOfList lA i)) (fun i => Option (colTypeOfList lB i)))) :
    TypedRelationOfList (lA.map .nullable ++ lB.map .nullable) :=
  { labels := fun j => r.labels (Fin.cast (by simp) j),
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
    | `(COUNT(DISTINCT $e:term)) => record .countDistinct e
    | `(SUM(DISTINCT $e:term))   => record .sumDistinct e
    | `(AVG(DISTINCT $e:term))   => record .avgDistinct e
    | `(BOOL_AND($e:term)) => record .boolAnd e
    | `(EVERY($e:term))    => record .boolAnd e
    | `(BOOL_OR($e:term))  => record .boolOr e
    | `(SUM($e:term))   => record .sum e
    | `(MIN($e:term))   => record .min e
    | `(MAX($e:term))   => record .max e
    | `(AVG($e:term))   => record .avg e
    | `(COUNT(CASE $[WHEN $cs THEN $_vs]* END))
    | `(COUNT(CASE $[WHEN $cs THEN $_vs]* ELSE NULL END)) => do
        -- `COUNT(CASE WHEN p THEN _ [ELSE NULL] END)` counts the rows where some `p` holds — a
        -- non-matching row is NULL, which `COUNT` skips. That is exactly
        -- `SUM(CASE WHEN p THEN 1 … ELSE 0 END)`, the indicator sum that
        -- `groupSum_case_eq_groupSum_where` folds into `COUNT(*) WHERE p`.
        let ones ← cs.mapM fun _ => `(term| (1 : Int))
        let e ← `(CASE $[WHEN $cs THEN $ones]* ELSE (0 : Int) END)
        record .sum e
    | `(COUNT(*))       => record .count ⟨Syntax.mkNumLit "0"⟩
    | `(COUNT($e:term)) => record .count e
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
  | `(sql_query| WITH $cs:sql_cte,* $body:sql_query) => do
    -- Non-recursive CTEs: elaborate each body to a relation over the current base vars, re-qualify
    -- its columns under the CTE name, and make it available for lookup (inlined at each reference).
    -- Later CTEs may reference earlier ones, so the accumulator grows left-to-right.
    let mut ctes := ctes
    for c in cs.getElems do
      match c with
      | `(sql_cte| $name:ident AS ( $q:sql_query )) => do
        let (lamQ, schemaQ) ← elabSqlQueryCore tableVars ctes q
        let cteExpr := lamQ.beta vars.toArray
        -- Keep the CTE body's original column names: `expandNames` only rewrites bare refs against
        -- base-table labels, so retaining those names lets `SELECT … FROM cte WHERE col …` resolve
        -- `col` the same way it would against the base table. (Positional relation ⇒ names are just
        -- metadata; the relation Expr is unchanged.)
        ctes := ctes ++ [(name.getId, cteExpr, schemaQ)]
      | _ => throwError "malformed CTE (expected `name AS (query)`)"
    elabSqlQueryCore tableVars ctes body
  | `(sql_query| $l:sql_query $op:sql_setop $r:sql_query) => do
    let (lamL, schemaL) ← elabSqlQueryCore tableVars ctes l
    let (lamR, schemaR) ← elabSqlQueryCore tableVars ctes r
    unless schemaL.map (·.2) == schemaR.map (·.2) do
      throwError "set operation requires both queries to have the same column types"
    let opName ← match op with
      -- Set semantics: a query denotes its result SET, so `UNION ALL` and `UNION` coincide
      | `(sql_setop| UNION ALL) | `(sql_setop| UNION) => pure ``union
      | `(sql_setop| INTERSECT) => pure ``intersection
      | `(sql_setop| EXCEPT)    => pure ``minus
      | _ => throwError "unknown set operation"
    let combined ← mkAppM opName #[lamL.beta vars.toArray, lamR.beta vars.toArray]
    return (← mkLambdaFVars vars.toArray combined, schemaL)
  | `(sql_query| SELECT $[DISTINCT%$distinct?]? $sel:sql_cols FROM $dbs:sql_from $[WHERE $filter?]?
      $[ORDER BY $ord:sql_order_item,*]? $[LIMIT $lim:num]? $[;]?) => do
    let (productExpr, combinedSchema) ← productPair dbs
    let filteredExpr ← match filter? with
      | some filter => elabWhere productExpr combinedSchema filter
      | none => pure productExpr
    let (rel, outSchema) ← match sel with
      | `(sql_cols| *) => pure (filteredExpr, combinedSchema)
      | `(sql_cols| $t:ident . *) => do
        -- Qualified star `t.*`: project onto exactly the columns of table `t` (full names have
        -- prefix `t`). Reuses the same projection path as an explicit column list.
        let pfx := t.getId
        let picked := combinedSchema.filter (fun (name, _) => pfx.isPrefixOf name)
        if picked.isEmpty then throwError s!"Unknown table {pfx} in `{pfx}.*`"
        let names := picked.map (·.1)
        let cols : List Syntax.Term := names.map (fun n => mkIdent n)
        let nameStrs := names.map (·.toString)
        let (m, types) ← elabTypedTupleProjection [(.anonymous, combinedSchema)] cols
        let e' ← mkAppM ``TypedRelation.mapByList #[filteredExpr, toExpr nameStrs, m]
        pure (e', names.zip types)
      | `(sql_cols| $cols:sql_col,*) => do
        let colStxs := cols.getElems
        let colTerms := colStxs.map sqlColTerm
        let names := colStxs.map sqlColName |>.toList
        let nameStrs := names.map (·.toString)
        -- Ungrouped aggregate (`SELECT COUNT(*) FROM t`, no GROUP BY) = one whole-table group.
        let (liftedRaw, selAggs) ← (colTerms.toList.mapM fun t => liftAggExprs t).run #[]
        if selAggs.isEmpty then
          let (m, types) ← elabTypedTupleProjection [(.anonymous, combinedSchema)] colTerms.toList
          let e' ← mkAppM ``TypedRelation.mapByList #[filteredExpr, toExpr nameStrs, m]
          pure (e', names.zip types)
        else
          let liftedCols : List Syntax.Term := liftedRaw.map (⟨·⟩)
          let (m, types) ← elabTypedTupleGroupProjection
            [(.anonymous, combinedSchema)] liftedCols (fun _ => false) filteredExpr selAggs.toList
          let e' ← mkAppM ``TypedRelation.mapByList #[filteredExpr, toExpr nameStrs, m]
          pure (e', names.zip types)
      | _ => throwError "Unexpected syntax for SQL query"
    let rel ← if distinct?.isSome then mkAppM ``distinct #[rel] else pure rel
    let ordCols? := ord.map (fun ords => ords.getElems.toList.map (fun o => sqlColTerm (sqlOrderCol o)))
    let rel ← applyOrderLimit rel outSchema ordCols? (lim.map (·.getNat))
    return (← mkLambdaFVars vars.toArray rel, outSchema)
  | `(sql_query| SELECT $[DISTINCT%$distinct?]? $cols:sql_col,* FROM $dbs:sql_from $[WHERE $filter?]?
      GROUP BY $groups:ident,* $[HAVING $having?]? $[ORDER BY $ord:sql_order_item,*]? $[LIMIT $lim:num]? $[;]?) => do
    let groupNames := groups.getElems.map (fun stx => stx.getId)
    let inGroup := fun name => groupNames.any (fun g => g == name)
    let (productExpr, combinedSchema) ← productPair dbs
    let filteredExpr ← match filter? with
      | some filter => do
        let filter ← elabTypedTupleFilter [(.anonymous, combinedSchema)] filter
        mkAppM ``restriction #[filter, productExpr]
      | none => pure productExpr
    let colStxs := cols.getElems
    let colTerms := colStxs.map sqlColTerm
    let names := colStxs.map sqlColName |>.toList
    let nameStrs := names.map (·.toString)
    -- Lift aggregate expressions (`SUM(a*b)`, `MIN(...)`, …) out of the SELECT list / HAVING.
    let (liftedRaw, selAggs) ← (colTerms.toList.mapM fun t => liftAggExprs t).run #[]
    let liftedCols : List Syntax.Term := liftedRaw.map (⟨·⟩)
    let (m, types) ← elabTypedTupleGroupProjection
      [(.anonymous, combinedSchema)] liftedCols inGroup filteredExpr selAggs.toList
    let havingFilteredExpr ← match having? with
      | some having => do
        let (having, havAggs) ← (liftAggExprs having).run #[]
        let h ← elabTypedTupleGroupFilter
          [(.anonymous, combinedSchema)] having inGroup filteredExpr havAggs.toList
        mkAppM ``restriction #[h, filteredExpr]
      | none => pure filteredExpr
    let e' ← mkAppM ``TypedRelation.mapByList #[havingFilteredExpr, toExpr nameStrs, m]
    let outSchema := names.zip types
    let rel ← if distinct?.isSome then mkAppM ``distinct #[e'] else pure e'
    let ordCols? := ord.map (fun ords => ords.getElems.toList.map (fun o => sqlColTerm (sqlOrderCol o)))
    let rel ← applyOrderLimit rel outSchema ordCols? (lim.map (·.getNat))
    return (← mkLambdaFVars vars.toArray rel, outSchema)
  | _ => throwError "Unexpected syntax for SQL query"
  where
  -- ORDER BY / LIMIT emit, shared by the plain and GROUP BY SELECT arms. ORDER BY erases only when
  -- no LIMIT is above it; under a LIMIT the sort key is folded into the opaque `limit` (S1). A bare
  -- LIMIT gets a canonical Unit key (the empty projection).
  applyOrderLimit (rel : Expr) (outSchema : List (Name × SQLTypeProxy))
      (ordCols? : Option (List Syntax.Term)) (limK? : Option Nat) : TermElabM Expr := do
    let keyExpr? ← match ordCols? with
      | none => pure none
      | some cols => do
        let (key, _) ← elabTypedTupleProjection [(.anonymous, outSchema)] cols
        pure (some key)
    match limK? with
    | none =>
      match keyExpr? with
      | some key => mkAppM ``orderBy #[key, rel]
      | none => pure rel
    | some k => do
      let key ← match keyExpr? with
        | some key => pure key
        | none => do
          let (key, _) ← elabTypedTupleProjection [(.anonymous, outSchema)] []
          pure key
      mkAppM ``limit #[toExpr k, key, rel]
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
    | `(sql_from| $t:ident AS $_x:ident) =>
      -- Aliased table: refs `x.col` were already rewritten to `t.col` by `expandNames`, so we just
      -- resolve the base table `t` and keep its base-qualified columns.
      productPair (← `(sql_from| $t:ident))
    | `(sql_from| ( $sub:sql_query ) AS $_alias:ident) => do
      let (lamSub, subSchema) ← elabSqlQueryCore tableVars ctes sub
      let vars := tableVars.map (fun (relVar, _, _) => relVar)
      return (lamSub.beta vars.toArray, subSchema)
    | `(sql_from| $f1:sql_from , $f2:sql_from) => do
      let (e1, s1) ← productPair f1
      let (e2, s2) ← productPair f2
      return (← mkAppM ``TypedRelationOfList.append #[e1, e2], s1 ++ s2)
    | `(sql_from| $f1:sql_from LEFT JOIN $t:ident ON $cond:term)
    | `(sql_from| $f1:sql_from LEFT OUTER JOIN $t:ident ON $cond:term) =>
      outerJoin f1 t cond ``leftOuterJoin ``ofOuterLeft false true
    | `(sql_from| $f1:sql_from RIGHT JOIN $t:ident ON $cond:term)
    | `(sql_from| $f1:sql_from RIGHT OUTER JOIN $t:ident ON $cond:term) =>
      outerJoin f1 t cond ``rightOuterJoin ``ofOuterRight true false
    | `(sql_from| $f1:sql_from FULL JOIN $t:ident ON $cond:term)
    | `(sql_from| $f1:sql_from FULL OUTER JOIN $t:ident ON $cond:term) =>
      outerJoin f1 t cond ``fullOuterJoin ``ofOuterFull true true
    -- Aliased-RHS joins: the alias resolved away in `expandNames`, so delegate to the base table.
    | `(sql_from| $f1:sql_from JOIN $t:ident AS $_x:ident ON $cond:term) =>
      productPair (← `(sql_from| $f1:sql_from JOIN $t:ident ON $cond:term))
    | `(sql_from| $f1:sql_from CROSS JOIN $t:ident AS $_x:ident) =>
      productPair (← `(sql_from| $f1:sql_from CROSS JOIN $t:ident))
    | `(sql_from| $f1:sql_from LEFT JOIN $t:ident AS $_x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from LEFT OUTER JOIN $t:ident AS $_x:ident ON $cond:term) =>
      outerJoin f1 t cond ``leftOuterJoin ``ofOuterLeft false true
    | `(sql_from| $f1:sql_from RIGHT JOIN $t:ident AS $_x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from RIGHT OUTER JOIN $t:ident AS $_x:ident ON $cond:term) =>
      outerJoin f1 t cond ``rightOuterJoin ``ofOuterRight true false
    | `(sql_from| $f1:sql_from FULL JOIN $t:ident AS $_x:ident ON $cond:term)
    | `(sql_from| $f1:sql_from FULL OUTER JOIN $t:ident AS $_x:ident ON $cond:term) =>
      outerJoin f1 t cond ``fullOuterJoin ``ofOuterFull true true
    -- Inner `JOIN ON` / `CROSS JOIN` handled here (not just via `escapeJoin`) so they compose with
    -- GROUP BY / ORDER BY / LIMIT, which `escapeJoin`'s whole-query rewrite doesn't reach (C1).
    | `(sql_from| $f1:sql_from JOIN $t:ident ON $cond:term) => do
      let (e1, s1) ← productPair f1
      let (e2, s2) ← productPair (← `(sql_from| $t:ident))
      let combined := s1 ++ s2
      let appended ← mkAppM ``TypedRelationOfList.append #[e1, e2]
      let condExpr ← elabTypedTupleFilter [(.anonymous, combined)] cond
      return (← mkAppM ``restriction #[condExpr, appended], combined)
    | `(sql_from| $f1:sql_from CROSS JOIN $t:ident) => do
      let (e1, s1) ← productPair f1
      let (e2, s2) ← productPair (← `(sql_from| $t:ident))
      return (← mkAppM ``TypedRelationOfList.append #[e1, e2], s1 ++ s2)
    | _ => throwError "Unsupported FROM clause: {← PrettyPrinter.ppCategory `sql_from dbs}"
  -- `A LEFT/RIGHT/FULL OUTER JOIN t ON cond` → the corresponding operator, then reconciled back to
  -- the canonical list schema by `reindexName` (`ofOuterLeft`/…) so `WHERE`/projection over the
  -- result elaborate. The `ON` condition is a two-tuple predicate (left tuple, right tuple), exactly
  -- like the semi/anti-join correlations. The output schema wraps the null-padded side's columns in
  -- `.nullable` (their values become `Option`).
  outerJoin (f1 : TSyntax `sql_from) (t : TSyntax `ident) (cond : Term)
      (opName reindexName : Name) (nullLeft nullRight : Bool) :
      TermElabM (Expr × List (Name × SQLTypeProxy)) := do
    let (e1, s1) ← productPair f1
    let (e2, s2) ← productPair (← `(sql_from| $t:ident))
    let condExpr ← elabTypedTupleFilter [(.anonymous, s1), (t.getId, s2)] cond
    let joinExpr ← mkAppM opName #[e1, e2, condExpr]
    let reindexed ← mkAppM reindexName #[joinExpr]
    let nul : List (Name × SQLTypeProxy) → List (Name × SQLTypeProxy) :=
      List.map (fun (n, ty) => (n, .nullable ty))
    return (reindexed, (if nullLeft then nul s1 else s1) ++ (if nullRight then nul s2 else s2))
  -- Apply a `WHERE` clause to `rel`. `[NOT] EXISTS (subquery)` and `x [NOT] IN (subquery)` become a
  -- `semijoin`/`antijoin`; anything else is an ordinary `restriction` by a tuple predicate.
  elabWhere (rel : Expr) (schema : List (Name × SQLTypeProxy)) (filter : Term) : TermElabM Expr := do
    match filter with
    | `(EXISTS ( $inner:sql_query ))     => elabExists rel schema inner none false
    | `(NOT EXISTS ( $inner:sql_query )) => elabExists rel schema inner none true
    | `($oc:term IN ( $inner:sql_query ))     => elabExists rel schema inner (some oc) false
    | `($oc:term NOT IN ( $inner:sql_query )) => elabExists rel schema inner (some oc) true
    | _ => do
      let f ← elabTypedTupleFilter [(.anonymous, schema)] filter
      mkAppM ``restriction #[f, rel]

  elabExists (rel : Expr) (outerSchema : List (Name × SQLTypeProxy)) (inner : TSyntax `sql_query)
      (inCol? : Option Term) (isNeg : Bool) : TermElabM Expr := do
    match inner with
    | `(sql_query| SELECT $sel:sql_cols FROM $sdb:sql_from $[WHERE $corr?]? $[;]?) => do
      let some innerName := (getIdents sdb).head? | throwError "subquery expects a single inner table"
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
      let cond ← elabTypedTupleFilter [(.anonymous, outerSchema), (innerName, sSchema)] corr
      mkAppM (if isNeg then ``antijoin else ``semijoin) #[rel, sExpr, cond]
    | _ => throwError "subquery expects `SELECT … FROM table …`"

def elabSqlQuery (tables : List (Name × List (Name × SQLTypeProxy))) (stx: Syntax) :
    TermElabM (Expr × List (Name × SQLTypeProxy)) := withTableVars tables fun tableVars => do
  let stx ← escapeJoin stx
  elabSqlQueryCore tableVars [] stx

-- A `"…"` quoted **identifier**: strip the quotes, emit the inner text bare. Dots between quoted
-- parts (`"A"."B"`) sit outside the quotes, so the main loop copies them → `A.B`.
private def unquoteIdent : List Char → String → String × List Char
  | [], acc => (acc, [])
  | '"' :: rest, acc => (acc, rest)
  | c :: rest, acc => unquoteIdent rest (acc.push c)

private def convSingleQuoted : List Char → String → String × List Char
  | [], acc => (acc.push '"', [])
  | '\'' :: '\'' :: rest, acc => convSingleQuoted rest (acc.push '\'')   -- SQL `''` = escaped quote
  | '\'' :: rest, acc => (acc.push '"', rest)
  | '"' :: rest, acc => convSingleQuoted rest ((acc.push '\\').push '"') -- escape inner `"`
  | c :: rest, acc => convSingleQuoted rest (acc.push c)

private partial def normalizeGo : List Char → String → String
  | [], acc => acc
  | '"' :: rest, acc => let (acc, rest) := unquoteIdent rest acc; normalizeGo rest acc
  | '\'' :: rest, acc => let (acc, rest) := convSingleQuoted rest (acc.push '"'); normalizeGo rest acc
  | c :: rest, acc => normalizeGo rest (acc.push c)

-- `::` cast rewriting (C3): `X::TYPE` → `CAST(X AS TYPE)`, reusing the sound CAST elaborator. Output
-- is built as a *reversed* char list so the operand (already emitted) can be popped off its front.
private def dropSp : List Char → List Char
  | ' ' :: r => dropSp r
  | l => l
private def isOpChar (c : Char) : Bool := c.isAlphanum || c == '_' || c == '.' || c == '"'
-- pop a plain operand (ident/dotted/number/quoted) off the reversed output
private def takeRunBack : List Char → List Char → (List Char × List Char)
  | c :: rest, acc => if isOpChar c then takeRunBack rest (c :: acc) else (acc, c :: rest)
  | [], acc => (acc, [])
-- pop a balanced `(…)` group off the reversed output (head is the closing `)`)
private def takeBalancedBack : List Char → Nat → List Char → (List Char × List Char)
  | c :: rest, depth, acc =>
      let acc := c :: acc
      let depth := if c == ')' then depth + 1 else if c == '(' then depth - 1 else depth
      if c == '(' && depth == 0 then (acc, rest) else takeBalancedBack rest depth acc
  | [], _, acc => (acc, [])
-- extend an operand leftward over a preceding function name (`SUM(x)` not just `(x)`)
private def takeFuncName : List Char → List Char → (List Char × List Char)
  | c :: rest, acc => if c.isAlphanum || c == '_' then takeFuncName rest (c :: acc) else (acc, c :: rest)
  | [], acc => (acc, [])
-- read a bare type word, then discard an optional `(size)` the cast grammar doesn't take
private def takeTypeWord : List Char → List Char → (String × List Char)
  | c :: rest, acc => if c.isAlphanum || c == '_' then takeTypeWord rest (acc ++ [c]) else (acc.asString, c :: rest)
  | [], acc => (acc.asString, [])
private partial def dropParenSize : List Char → List Char
  | '(' :: rest => (rest.dropWhile (· != ')')).drop 1
  | l => l
private partial def castGo : List Char → List Char → List Char
  | [], out => out
  | ':' :: ':' :: rest, out =>
      let out := dropSp out
      let (operand, out') := match out with
        | ')' :: _ => let (p, rem) := takeBalancedBack out 0 []; takeFuncName rem p
        | _ => takeRunBack out []
      let (ty, rest2) := takeTypeWord (dropSp rest) []
      let emit := "CAST(" ++ operand.asString ++ " AS " ++ ty ++ ")"
      castGo (dropParenSize (dropSp rest2)) (emit.toList.reverse ++ out')
  | c :: rest, out => castGo rest (c :: out)

/-- Normalize SQL surface quoting to what the grammar accepts (C3): single-quoted string literals
`'…'` → the grammar's `"…"` form, double-quoted **identifiers** `"…"` → bare identifiers
(`"A"."B"."C"` → `A.B.C`), and `X::TYPE` → `CAST(X AS TYPE)`. -/
def normalizeSqlLiterals (s : String) : String :=
  (castGo (normalizeGo s.toList "").toList []).reverse.asString

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

def parseSqlQuery (tables : List (Name × List (Name × SQLTypeProxy))) (str : String) : TermElabM (Expr × List (Name × SQLTypeProxy)) := do
  let str := normalizeSqlLiterals str
  -- Case-insensitive identifiers: fold the schema and the query's idents to a common (lower) case.
  let tables := tables.map (fun (t, cols) => (lowerName t, cols.map (fun (c, ty) => (lowerName c, ty))))
  let tables := tables.map (fun (tableName, columns) => (tableName, schemaWithFullNames tableName columns))
  let .ok stx := Parser.runParserCategory (← getEnv) `sql_query str | throwError "Failed to parse SQL query: {str}"
  let stx := lowerIdents stx
  let labels := tables.foldl (fun acc (_, columns) => acc ++ columns.map (fun (name, _) => name)) []
  let aliases := collectAliases stx
  -- A base table under two aliases (self-join) would collapse to identical column names here; reject
  -- rather than silently merge them (needs per-alias column renaming — a follow-up).
  let bases := aliases.map (·.2)
  if bases.length != bases.eraseDups.length then
    throwError "self-join / same base table under multiple aliases is not yet supported"
  let stx ← expandNames labels stx aliases
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
