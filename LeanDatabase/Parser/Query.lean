import LeanDatabase.Parser.Context
import LeanDatabase.Parser.Alias
import LeanDatabase.Parser.GroupBy
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
    | _ => throwError "scalar subquery: only SUM / COUNT / COUNT(DISTINCT) are supported"

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
  -- One SELECT arm for every clause combination. Optional slots (`DISTINCT`, `WHERE`, `GROUP BY` +
  -- `HAVING`, `ORDER BY`, `LIMIT`) are each read once here, so a new clause/feature is added in a
  -- single place and applies to grouped and ungrouped queries alike. The pipeline is:
  -- FROM → WHERE → (project / group+aggregate + HAVING) → DISTINCT → ORDER BY / LIMIT.
  | `(sql_query| SELECT $[DISTINCT%$distinct?]? $sel:sql_cols FROM $dbs:sql_from $[WHERE $filter?]?
      $[GROUP BY $groups:term,* $[HAVING $having?]?]? $[ORDER BY $ord:sql_order_item,*]?
      $[LIMIT $lim:num]? $[OFFSET $_off:num]? $[;]?) => do
    let (productExpr, combinedSchema) ← productPair dbs
    let filteredExpr ← match filter? with
      | some filter => elabWhere productExpr combinedSchema filter
      | none => pure productExpr
    let groupItems := (groups.map (·.getElems)).getD #[]
    let aliasMap := collectAliases dbs
    let (rel, outSchema) ← elabSelect sel combinedSchema filteredExpr groupItems groups.isSome
      having?.join aliasMap
    let rel ← if distinct?.isSome then mkAppM ``distinct #[rel] else pure rel
    -- ORDER BY resolves against the (base-qualified) output labels, so baseify its column refs too.
    let ordCols? := ord.map (fun ords => ords.getElems.toList.map
      (fun o => ⟨baseifyIdents aliasMap (sqlColTerm (sqlOrderCol o))⟩))
    let rel ← applyOrderLimit rel outSchema ordCols? (lim.map (·.getNat))
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
      -- Aliased table (`t AS x` or bare `t x`): resolve the base and rename its columns to the alias
      -- prefix, so two aliases of the *same* base table get distinct columns (self-joins, S3). The
      -- relation is positional, so renaming labels is all that's needed.
      let (e, cols) ← productPair (← `(sql_from| $t:ident))
      let baseP := (t.getId.components.getLast?).getD t.getId
      return (e, cols.map (fun (n, ty) => (n.replacePrefix baseP x.getId, ty)))
    | `(sql_from| ( $sub:sql_query ) AS $_alias:ident)
    | `(sql_from| ( $sub:sql_query ) $_alias:ident) => do
      let (lamSub, subSchema) ← elabSqlQueryCore tableVars ctes sub
      let vars := tableVars.map (fun (relVar, _, _) => relVar)
      return (lamSub.beta vars.toArray, subSchema)
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
    -- Inner `JOIN ON` / `CROSS JOIN` handled here (not just via `escapeJoin`) so they compose with
    -- GROUP BY / ORDER BY / LIMIT, which `escapeJoin`'s whole-query rewrite doesn't reach (C1).
    | `(sql_from| $f1:sql_from JOIN $t:ident ON $cond:term) =>
      innerJoin f1 (← `(sql_from| $t:ident)) (some cond)
    | `(sql_from| $f1:sql_from CROSS JOIN $t:ident) =>
      innerJoin f1 (← `(sql_from| $t:ident)) none
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
    -- an aliased RHS renames its columns to the alias prefix (self-join safe)
    let baseP := (t.getId.components.getLast?).getD t.getId
    let rhsP := (rhsAlias.map (·.getId)).getD baseP
    let s2 := match rhsAlias with
      | some x => s2raw.map (fun (n, ty) => (n.replacePrefix baseP x.getId, ty))
      | none => s2raw
    let condExpr ← elabTypedTupleFilter [(.anonymous, s1), (rhsP, s2)] cond
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

  -- Rewrite a scalar-subquery column `(SELECT AGG(x) FROM t [WHERE p]) AS n` to a `sqlDeferredSubq%`
  -- placeholder + stash entry. The inner *relation* (outer-independent) is built now via `productPair`;
  -- the inner `WHERE` — which may be **correlated** (reference outer columns) — is stored and
  -- elaborated later, inside the projection context, where the outer row's let-vars are in scope.
  stashSubq (q : TSyntax `sql_query) (name : TSyntax `ident) : TermElabM (TSyntax `sql_col) := do
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
        | _ => throwError "scalar subquery: only SUM / COUNT / COUNT(DISTINCT) are supported"
      let idx := (← scalarSubqStash.get).size
      scalarSubqStash.modify (·.push
        { innerRel := rel, innerSchema := schema, kind, summand := summand?, cond := p?.map (·.raw) })
      `(sql_col| (sqlDeferredSubq% $(quote idx)) AS $name:ident)
    | _ => throwError "unsupported scalar subquery shape"

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
    | `(sql_cols| $cols:sql_col,*) => do
      let colStxs ← preprocessScalarSubqueries cols.getElems
      let colTerms := colStxs.map sqlColTerm
      let names := colStxs.map sqlColName |>.toList |>.map (baseifyName aliasMap)
      let nameStrs := names.map (·.toString)
      let (liftedRaw, selAggs) ← (colTerms.toList.mapM liftAggExprs).run #[]
      if selAggs.isEmpty && !hasGroupBy then
        let (m, types) ← elabTypedTupleProjection [(.anonymous, combinedSchema)] colTerms.toList
        pure (← mkAppM ``TypedRelation.mapByList #[filteredExpr, toExpr nameStrs, m], names.zip types)
      else
        -- The group *key* is the list of GROUP BY terms (a bare column is just `term = col`);
        -- positional `GROUP BY 1` resolves to the nth SELECT term. See `Parser/GroupBy.lean`.
        let groupTerms := (groupItems.map (resolveGroupItem colTerms)).toList
        let liftedCols : List Syntax.Term := liftedRaw.map (⟨·⟩)
        let (m, types) ← elabTypedTupleGroupProjection
          [(.anonymous, combinedSchema)] liftedCols groupTerms filteredExpr selAggs.toList
        let havingFilteredExpr ← match having? with
          | some having => do
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

-- A `"…"` quoted **identifier** → a Lean guillemet identifier `«…»`, which is immune to keyword
-- collisions (a column named `"YEAR"`/`"END"`/`"COUNT"` won't hit the function/keyword token). The
-- resulting `Name` is the same as the bare form, so it still matches the (case-folded) schema. Dots
-- between quoted parts (`"A"."B"`) sit outside the quotes, so the main loop copies them → `«A».«B»`.
private def unquoteIdent : List Char → String → String × List Char
  | [], acc => (acc.push '»', [])
  | '"' :: rest, acc => (acc.push '»', rest)
  | c :: rest, acc => unquoteIdent rest (acc.push c)

private def convSingleQuoted : List Char → String → String × List Char
  | [], acc => (acc.push '"', [])
  | '\'' :: '\'' :: rest, acc => convSingleQuoted rest (acc.push '\'')   -- SQL `''` = escaped quote
  | '\'' :: rest, acc => (acc.push '"', rest)
  | '"' :: rest, acc => convSingleQuoted rest ((acc.push '\\').push '"') -- escape inner `"`
  | c :: rest, acc => convSingleQuoted rest (acc.push c)

private partial def normalizeGo : List Char → String → String
  | [], acc => acc
  | '"' :: rest, acc => let (acc, rest) := unquoteIdent rest (acc.push '«'); normalizeGo rest acc
  | '\'' :: rest, acc => let (acc, rest) := convSingleQuoted rest (acc.push '"'); normalizeGo rest acc
  | c :: rest, acc => normalizeGo rest (acc.push c)

-- `::` cast rewriting (C3): `X::TYPE` → `CAST(X AS TYPE)`, reusing the sound CAST elaborator. Output
-- is built as a *reversed* char list so the operand (already emitted) can be popped off its front.
private def dropSp : List Char → List Char
  | ' ' :: r => dropSp r
  | l => l
private def isOpChar (c : Char) : Bool :=
  c.isAlphanum || c == '_' || c == '.' || c == '"' || c == '«' || c == '»'
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
-- Pop the operand ending at the head of the reversed output `out`: a balanced `(…)` call (with its
-- function name) if it ends in `)`, else a plain column run. Shared by `castGo`/`pathGo`.
private def popOperand (out : List Char) : List Char × List Char :=
  match out with
  | ')' :: _ => let (p, rem) := takeBalancedBack out 0 []; takeFuncName rem p
  | _ => takeRunBack out []
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
      let (operand, out') := popOperand out
      let (ty, rest2) := takeTypeWord (dropSp rest) []
      let emit := "CAST(" ++ operand.asString ++ " AS " ++ ty ++ ")"
      castGo (dropParenSize (dropSp rest2)) (emit.toList.reverse ++ out')
  | c :: rest, out => castGo rest (c :: out)

-- Strip SQL comments (`-- …` to end of line, `/* … */`), skipping over string literals so a `--` or
-- `/*` inside a string is preserved. Runs first, before any other normalization.
private partial def dropBlockComment : List Char → List Char
  | '*' :: '/' :: rest => rest
  | _ :: rest => dropBlockComment rest
  | [] => []
-- Case-insensitive prefix match; returns the remaining chars after `kw` on success.
private def ciPrefix : List Char → List Char → Option (List Char)
  | [], rest => some rest
  | k :: ks, c :: cs => if k == c.toLower then ciPrefix ks cs else none
  | _ :: _, [] => none

-- At a word boundary, `INNER JOIN` → ` JOIN` (the redundant qualifier reuses the plain-`JOIN` grammar).
private def dropInnerKW : List Char → Option (List Char)
  | l =>
    match ciPrefix ['i','n','n','e','r'] l with
    | some (w :: after) =>
        if w == ' ' || w == '\n' || w == '\t' then
          match ciPrefix ['j','o','i','n'] ((w :: after).dropWhile fun c => c == ' ' || c == '\n' || c == '\t') with
          | some _ => some (' ' :: (w :: after).dropWhile fun c => c == ' ' || c == '\n' || c == '\t')
          | none => none
        else none
    | _ => none

mutual
private partial def stripComments : List Char → String → String
  | [], acc => acc
  | '-' :: '-' :: rest, acc => stripComments (rest.dropWhile (· != '\n')) acc
  | '/' :: '*' :: rest, acc => stripComments (dropBlockComment rest) acc
  | '\'' :: rest, acc => copyQuotedFwd '\'' rest (acc.push '\'')
  | '"' :: rest, acc => copyQuotedFwd '"' rest (acc.push '"')
  | c :: rest, acc =>
      let boundary := acc.isEmpty || !(acc.back.isAlphanum || acc.back == '_')
      match (if boundary && (c == 'I' || c == 'i') then dropInnerKW (c :: rest) else none) with
      | some rest' => stripComments rest' acc
      | none => stripComments rest (acc.push c)
private partial def copyQuotedFwd (q : Char) : List Char → String → String
  | c :: rest, acc => if c == q then stripComments rest (acc.push c) else copyQuotedFwd q rest (acc.push c)
  | [], acc => acc
end

-- `AS <keyword>` alias support: keywords like `YEAR`/`MONTH`/`DATE`/`COUNT` are reserved tokens, so a
-- column/table alias that reuses one won't parse. Guillemet-wrap it (`AS «YEAR»`). A cast type
-- (`CAST(x AS DATE)`) is left alone — it is always followed by `)`/`(`, which the rule excludes.
private def isWordChar (c : Char) : Bool := c.isAlphanum || c == '_'

private def ciTake : List Char → List Char → List Char → Option (List Char × List Char)
  | [], rest, acc => some (acc.reverse, rest)
  | k :: ks, c :: cs, acc => if k == c.toLower then ciTake ks cs (c :: acc) else none
  | _ :: _, [], _ => none

-- Longest-first so `dayofweek`/`timestamp` win over their `day`/`time` prefixes.
private def aliasKWList : List (List Char) :=
  ["dayofweek","timestamp","quarter","second","minute","month","count","week","hour","year","date","time","day"].map (·.toList)

private def tryAliasKW : List (List Char) → List Char → Option (List Char × List Char)
  | [], _ => none
  | kw :: rest, l =>
    match ciTake kw l [] with
    | some (orig, rem) =>
        match rem with
        | c :: _ => if isWordChar c then tryAliasKW rest l else some (orig, rem)
        | []     => some (orig, rem)
    | none => tryAliasKW rest l

-- On seeing `AS`, if a collision keyword follows (not a cast type), return the matched keyword chars
-- and the remainder after it; else none.
private def matchAsAlias (l : List Char) : Option (List Char × List Char) :=
  match ciTake ['a','s'] l [] with
  | some (_, sp :: r1) =>
      if sp == ' ' || sp == '\n' || sp == '\t' then
        let r1 := (sp :: r1).dropWhile fun c => c == ' ' || c == '\n' || c == '\t'
        match tryAliasKW aliasKWList r1 with
        | some (kw, r2) =>
            match r2.dropWhile (fun c => c == ' ' || c == '\n' || c == '\t') with
            | c :: _ => if c == '(' || c == ')' then none else some (kw, r2)
            | []     => some (kw, r2)
        | none => none
      else none
  | _ => none

-- Copy a quoted run (up to and including the closing `q`) verbatim.
private def copyQuotedRun (q : Char) : List Char → String → String × List Char
  | c :: rest, acc => if c == q then (acc.push c, rest) else copyQuotedRun q rest (acc.push c)
  | [], acc => (acc, [])

-- `LEFT(`/`RIGHT(` (the string functions) collide with the `LEFT`/`RIGHT` JOIN keywords, which breaks
-- join chains (an `ON` term greedily tries `LEFT(…)` as an application). Rename the *function* form to
-- a distinct token so `LEFT`/`RIGHT` are join-only. Only fires when a `(` follows.
private def matchFnRename (l : List Char) : Option (String × List Char) :=
  let tryKW (kw : List Char) (repl : String) : Option (String × List Char) :=
    match ciTake kw l [] with
    | some (_, rem) =>
        match rem.dropWhile (fun c => c == ' ' || c == '\n' || c == '\t') with
        | '(' :: _ => some (repl, rem)
        | _ => none
    | none => none
  (tryKW ['l','e','f','t'] "LEFTSTR").orElse fun _ => tryKW ['r','i','g','h','t'] "RIGHTSTR"

private partial def wrapAliasGo : List Char → String → String
  | [], acc => acc
  | '\'' :: rest, acc => let (s, r) := copyQuotedRun '\'' rest (String.singleton '\''); wrapAliasGo r (acc ++ s)
  | '"'  :: rest, acc => let (s, r) := copyQuotedRun '"'  rest (String.singleton '"');  wrapAliasGo r (acc ++ s)
  | c :: rest, acc =>
      let boundary := acc.isEmpty || !(isWordChar acc.back)
      let fn := if boundary && (c == 'l' || c == 'L' || c == 'r' || c == 'R') then matchFnRename (c :: rest) else none
      match fn with
      | some (repl, rest') => wrapAliasGo rest' (acc ++ repl)
      | none =>
        match (if boundary && (c == 'a' || c == 'A') then matchAsAlias (c :: rest) else none) with
        | some (kw, rest') => wrapAliasGo rest' (acc ++ "AS «" ++ kw.asString ++ "»")
        | none => wrapAliasGo rest (acc.push c)

-- Semi-structured path access `v:key` / `v['key']` → `VARIANTGET(v, 'key')`, at the string level so
-- `:` doesn't clash with Lean's type ascription. Runs before quote/`::` normalization.
private def takeToChar (q : Char) : List Char → String → String × List Char
  | c :: rest, acc => if c == q then (acc, rest) else takeToChar q rest (acc.push c)
  | [], acc => (acc, [])
private def takeKeyWord : List Char → String → String × List Char
  | c :: rest, acc =>
      if c.isAlphanum || c == '_' || c == '.' then takeKeyWord rest (acc.push c) else (acc, c :: rest)
  | [], acc => (acc, [])
private def readKey : List Char → String × List Char
  | '"' :: rest => takeToChar '"' rest ""
  | '\'' :: rest => takeToChar '\'' rest ""
  | l => takeKeyWord l ""
private def copyStrTo (q : Char) : List Char → List Char → List Char × List Char
  | c :: rest, out => if c == q then (c :: out, rest) else copyStrTo q rest (c :: out)
  | [], out => (out, [])
private partial def pathGo : List Char → List Char → List Char
  | [], out => out
  | '\'' :: rest, out => let (out, rest) := copyStrTo '\'' rest ('\'' :: out); pathGo rest out
  | '"' :: rest, out => let (out, rest) := copyStrTo '"' rest ('"' :: out); pathGo rest out
  | ':' :: ':' :: rest, out => pathGo rest (':' :: ':' :: out)          -- leave `::` for castGo
  | ':' :: rest, out =>
      let out := dropSp out
      let (operand, out') := popOperand out
      let (key, rest') := readKey (dropSp rest)
      let emit := "VARIANTGET(" ++ operand.asString ++ ", '" ++ key ++ "')"
      pathGo rest' (emit.toList.reverse ++ out')
  | '[' :: rest, out =>
      -- `operand['key']` access only — a *quoted* key must follow, so array literals `[1,2]` are left
      -- alone.
      match out, dropSp rest with
      | h :: _, (q :: _) =>
        if (isOpChar h || h == ')') && (q == '\'' || q == '"') then
          let (operand, out') := popOperand out
          let (key, rest0) := readKey (dropSp rest)
          let rest' := (rest0.dropWhile (· != ']')).drop 1
          let emit := "VARIANTGET(" ++ operand.asString ++ ", '" ++ key ++ "')"
          pathGo rest' (emit.toList.reverse ++ out')
        else pathGo rest ('[' :: out)
      | _, _ => pathGo rest ('[' :: out)
  | c :: rest, out => pathGo rest (c :: out)

/-- Normalize SQL surface syntax to what the grammar accepts (C3): path access `v:key`/`v['key']` →
`VARIANTGET`, `'…'` strings → `"…"`, double-quoted **identifiers** → bare idents, `X::TYPE` → `CAST`. -/
def normalizeSqlLiterals (s : String) : String :=
  let s := stripComments s.toList ""
  let s := wrapAliasGo s.toList ""
  let s := (pathGo s.toList []).reverse.asString
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
  -- Resolution labels: every base column `t.col`, plus each alias's columns under its own prefix
  -- (`x.col`), so an aliased table's columns — renamed to `x.col` by `productPair` — resolve, and two
  -- aliases of the same base table stay distinct (self-joins, S3).
  let baseLabels := tables.foldl (fun acc (_, columns) => acc ++ columns.map (·.1)) []
  let aliasLabels := (collectAliases stx).foldl (fun acc (al, base) =>
    match tables.find? (fun (n, _) => n == base) with
    | some (_, cols) => acc ++ cols.map (fun (n, _) => n.replacePrefix base al)
    | none => acc) []
  let stx ← expandNames (baseLabels ++ aliasLabels) stx
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
