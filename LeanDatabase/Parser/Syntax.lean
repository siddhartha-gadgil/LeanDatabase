import Lean
open Lean
/-!
# SQL surface syntax

The `sql_query` / `sql_from` / `sql_cols` / `sql_col` syntax categories, the `macro_rules` that
desugar `JOIN` / `CROSS JOIN` into comma-separated cartesian products, and the term-level
`AND` / `OR` / `NOT` combinators that let `WHERE` predicates be written SQL-style.

Pure syntax: depends only on `Lean`, not on the type layer (`Parser.Types`). The two are joined in
`Parser.Query`.
-/

open Lean

namespace LeanDatabase

declare_syntax_cat sql_query
declare_syntax_cat sql_from
declare_syntax_cat sql_cols
syntax "*" : sql_cols
syntax ident "." "*" : sql_cols     -- qualified star `t.*` — every column of table `t`
declare_syntax_cat sql_col
syntax ident : sql_col
syntax term "AS" ident : sql_col
syntax (priority := low) term : sql_col                            -- bare computed column, auto-named
syntax (priority := high) "(" sql_query ")" "AS" ident : sql_col   -- scalar subquery `(SELECT AGG … ) AS name` (3.4)
syntax sql_col,* : sql_cols
-- `SELECT *, expr …` / `SELECT t.*, expr …` — a star followed by more columns (the plain-`*` and
-- `sql_col,*` productions can't mix, so these carry the leftover list explicitly).
syntax "*" "," sql_col,* : sql_cols
syntax ident "." "*" "," sql_col,* : sql_cols

/-- Auto-name for a bare (unaliased) computed column: its source text with non-ident chars dropped,
so `SUM(amt)` → `SUMamt`. Deterministic, so both sides of an equivalence agree. -/
def autoColName (t : Syntax) : Name :=
  Name.mkSimple <| String.ofList ((t.reprint.getD "col").toList.filter (fun c => c.isAlphanum || c == '_'))

-- Scalar-subquery columns are rewritten to `term AS ident` before this is called, so the subquery
-- case is unreachable here.
def sqlColTerm : TSyntax `sql_col → Syntax.Term
  | `(sql_col| $col:ident) => col
  | `(sql_col| $col:term AS $_:ident) => col
  | `(sql_col| $col:term) => col
  -- A scalar-subquery column should be preprocessed to `term AS ident` before this; if one slips
  -- through, return a placeholder that fails elaboration cleanly rather than `panic`-ing the process.
  | _ => ⟨mkIdent `__unexpected_scalar_subquery⟩

def sqlColName : TSyntax `sql_col → Name
  | `(sql_col| $col:ident) => col.getId
  | `(sql_col| $_:term AS $x:ident) => x.getId
  | `(sql_col| ( $_:sql_query ) AS $x:ident) => x.getId
  | `(sql_col| $col:term) => autoColName col.raw
  | _ => `__unexpected_col

-- `ORDER BY` items carry an optional `ASC`/`DESC`. Under set semantics row order is not observable,
-- so the direction is parsed then discarded — `orderBy` is the identity either way.
declare_syntax_cat sql_order_dir
syntax " ASC " : sql_order_dir
syntax " DESC " : sql_order_dir
declare_syntax_cat sql_nulls
syntax "NULLS" "FIRST" : sql_nulls
syntax "NULLS" "LAST" : sql_nulls
declare_syntax_cat sql_order_item
syntax sql_col (sql_order_dir)? (sql_nulls)? : sql_order_item

/-- Strip the (ignored) `ASC`/`DESC`/`NULLS …` off an `ORDER BY` item, recovering the column. -/
def sqlOrderCol : TSyntax `sql_order_item → TSyntax `sql_col
  | `(sql_order_item| $c:sql_col $[$_dir:sql_order_dir]? $[$_nulls:sql_nulls]?) => c
  | _ => unreachable!

-- Base Cases (The atomic sources of data)
syntax ident : sql_from                               -- 1. Standard table name
syntax ident "AS" ident : sql_from                    -- 1b. Aliased table (`t AS x`)
syntax ident ident : sql_from                         -- 1c. Bare alias (`t x`) — the corpus norm
-- Subquery with alias, and an optional column-alias list `(c1, c2)` (used by `VALUES` and renames).
syntax "(" sql_query ")" "AS" ident ("(" ident,* ")")? : sql_from       -- 2. Subquery with AS-alias
syntax "(" sql_query ")" ident ("(" ident,* ")")? : sql_from             -- 2b. Subquery with bare alias
-- `VALUES (v,…),(v,…)` — an inline literal relation (a query producing constant rows). A cell is a
-- `term` OR the literal `NULL` (only here — NULL is never a bare term, so `col = NULL` stays unwritable;
-- see the `NULL` section below). A column with any `NULL` cell becomes a nullable `Option _` column.
declare_syntax_cat sql_values_cell
syntax term : sql_values_cell
syntax "NULL" : sql_values_cell
declare_syntax_cat sql_values_row
syntax "(" sql_values_cell,+ ")" : sql_values_row
syntax "VALUES" sql_values_row,+ : sql_query

-- `LATERAL FLATTEN` (Snowflake array/VARIANT unnest). The normalizer canonicalises sqlglot's
-- `, LATERAL UNNEST(input => e) AS h(SEQ, KEY, PATH, INDEX, VALUE, THIS)` (and the no-`input =>` /
-- bare-alias / no-collist variants) to `, LATERALFLATTEN(e) AS h (…)`. Left-associative on the
-- preceding `sql_from`, so a later flatten's input may reference an earlier one (`p` off `h.value`).
syntax sql_from "," "LATERALFLATTEN" "(" term ")" "AS" ident "(" ident,* ")" : sql_from
syntax sql_from "," "LATERALFLATTEN" "(" term ")" ident "(" ident,* ")" : sql_from
syntax sql_from "," "LATERALFLATTEN" "(" term ")" "AS" ident : sql_from
syntax sql_from "," "LATERALFLATTEN" "(" term ")" ident : sql_from
-- `LATERAL SPLIT_TO_TABLE(str, delim)` — Snowflake row-per-token unnest; modelled like FLATTEN over
-- the (opaque) split value, so its rows are `(SEQ, KEY, PATH, INDEX, VALUE, THIS)` with `VALUE` a token.
syntax sql_from "," "LATERAL" "SPLIT_TO_TABLE" "(" term "," term ")" "AS" ident : sql_from
syntax sql_from "," "LATERAL" "SPLIT_TO_TABLE" "(" term "," term ")" ident : sql_from

-- Recursive Cases (Chaining joins from left to right)
-- Parenthesised join group as a JOIN RHS: `f INNER JOIN (a CROSS JOIN b) ON …` — the group elaborates
-- to its own product, then joins `f`. Distinct from the `(sql_query) AS x` subquery RHS (a group starts
-- with a table name, a subquery with `SELECT`).
syntax sql_from "JOIN" "(" sql_from ")" "ON" term : sql_from
syntax sql_from "JOIN" ident "ON" term : sql_from     -- 3. Explicit Inner Join
syntax sql_from "JOIN" ident "USING" "(" ident,* ")" : sql_from   -- 3b. USING (shared columns)
syntax sql_from "CROSS" "JOIN" ident : sql_from       -- 4. Cross Join
syntax sql_from "," sql_from : sql_from              -- 5. Comma-separated (Cartesian Product)
-- 6. Outer joins — elaborated directly to `leftOuterJoin`/`rightOuterJoin`/`fullOuterJoin`
-- (`Parser/Query.lean`); the right (resp. left / both) columns become nullable `Option` in the
-- output schema. `OUTER` is optional (SQL synonym), so each has a with/without form.
syntax sql_from "LEFT" "JOIN" ident "ON" term : sql_from
syntax sql_from "LEFT" "OUTER" "JOIN" ident "ON" term : sql_from
syntax sql_from "RIGHT" "JOIN" ident "ON" term : sql_from
syntax sql_from "RIGHT" "OUTER" "JOIN" ident "ON" term : sql_from
syntax sql_from "FULL" "JOIN" ident "ON" term : sql_from
syntax sql_from "FULL" "OUTER" "JOIN" ident "ON" term : sql_from

-- 7. Aliased-RHS join forms (`… JOIN t AS x ON …`). The alias resolves away in `expandNames`, so
-- these delegate to the base-table join in `productPair`.
syntax sql_from "JOIN" ident "AS" ident "ON" term : sql_from
syntax sql_from "CROSS" "JOIN" ident "AS" ident : sql_from
syntax sql_from "LEFT" "JOIN" ident "AS" ident "ON" term : sql_from
syntax sql_from "LEFT" "OUTER" "JOIN" ident "AS" ident "ON" term : sql_from
syntax sql_from "RIGHT" "JOIN" ident "AS" ident "ON" term : sql_from
syntax sql_from "RIGHT" "OUTER" "JOIN" ident "AS" ident "ON" term : sql_from
syntax sql_from "FULL" "JOIN" ident "AS" ident "ON" term : sql_from
syntax sql_from "FULL" "OUTER" "JOIN" ident "AS" ident "ON" term : sql_from
-- 7b. Bare-alias RHS (`… JOIN t x ON …`) — same, without `AS`.
syntax sql_from "JOIN" ident ident "ON" term : sql_from
syntax sql_from "CROSS" "JOIN" ident ident : sql_from
syntax sql_from "LEFT" "JOIN" ident ident "ON" term : sql_from
syntax sql_from "LEFT" "OUTER" "JOIN" ident ident "ON" term : sql_from
syntax sql_from "RIGHT" "JOIN" ident ident "ON" term : sql_from
syntax sql_from "RIGHT" "OUTER" "JOIN" ident ident "ON" term : sql_from
syntax sql_from "FULL" "JOIN" ident ident "ON" term : sql_from
syntax sql_from "FULL" "OUTER" "JOIN" ident ident "ON" term : sql_from
-- 7d. `NATURAL JOIN` — equi-join on every shared column name, duplicates projected away
-- (`naturalJoin` in `Parser/Query.lean`).
syntax sql_from "NATURAL" "JOIN" ident : sql_from
syntax sql_from "NATURAL" "JOIN" ident "AS" ident : sql_from
syntax sql_from "NATURAL" "JOIN" ident ident : sql_from
-- 7c. Subquery RHS (`… JOIN (subquery) AS x ON …`) for INNER / CROSS joins.
syntax sql_from "JOIN" "(" sql_query ")" "AS" ident "ON" term : sql_from
syntax sql_from "JOIN" "(" sql_query ")" ident "ON" term : sql_from
syntax sql_from "CROSS" "JOIN" "(" sql_query ")" "AS" ident : sql_from
syntax sql_from "CROSS" "JOIN" "(" sql_query ")" ident : sql_from
-- 7e. Subquery RHS for LEFT / RIGHT / FULL outer joins (`OUTER` optional).
syntax sql_from "LEFT" (&"OUTER")? "JOIN" "(" sql_query ")" "AS" ident "ON" term : sql_from
syntax sql_from "RIGHT" (&"OUTER")? "JOIN" "(" sql_query ")" "AS" ident "ON" term : sql_from
syntax sql_from "FULL" (&"OUTER")? "JOIN" "(" sql_query ")" "AS" ident "ON" term : sql_from

-- A **scalar subquery** used as a value (`WHERE x = (SELECT MAX(y) FROM t)`). Only the parenthesised
-- query shape parses here, so an ordinary parenthesised term is untouched.
syntax:max (priority := low) "(" sql_query ")" : term

-- An **uninterpreted predicate** over whole rows (`B1(X)`, `B(X, Y)`) — the shape the equivalence
-- literature writes for "an arbitrary condition". Its arguments are FROM items (or columns); it
-- elaborates (`Parser/Context.lean`) to an opaque `Bool` of exactly those values, so the same
-- predicate on the same row agrees and nothing else is assumed. Registered scalar functions
-- (`SQRT(x)`, `COUNT(*)`, …) are keyword tokens, so they never match this rule.
syntax:max (priority := low) ident noWs "(" ident,* ")" : term

-- `GROUP BY` items are full terms: a bare column, an expression (`UPPER(col)`, `ROUND(lat, 2)`), or a
-- positional `1` (nth SELECT column). See `Parser/GroupBy.lean` for how the group *key* is built.
syntax "SELECT " (" DISTINCT ")? sql_cols " FROM " sql_from (" WHERE " term)?  (" GROUP " " BY " term,* (" HAVING " term)?)? (" ORDER " " BY " sql_order_item,*)? (" LIMIT " num)? (" OFFSET " num)? (";")? : sql_query

-- Binary set operators on whole queries, as one keyword-parameterised production. Our relations
-- are `Finset`s (sets), so `UNION ALL` maps to set `union` too (no bag semantics).
declare_syntax_cat sql_setop
syntax " UNION " " ALL " : sql_setop
syntax " UNION " : sql_setop
syntax " INTERSECT " " ALL " : sql_setop
syntax " INTERSECT " : sql_setop
syntax " EXCEPT " " ALL " : sql_setop
syntax " EXCEPT " : sql_setop
syntax:40 sql_query:40 sql_setop sql_query:41 : sql_query

-- Parenthesised query, for grouping set-ops: `a UNION (a INTERSECT b)`.
syntax:max "(" sql_query ")" : sql_query

-- Common table expressions: `WITH x AS (q), y AS (q) SELECT …`. Each CTE is a local relation binding,
-- inlined at every reference (`Parser/Query.lean`). `WITH RECURSIVE` allows a CTE whose body is
-- `anchor UNION [ALL] step` to reference itself; it elaborates to the opaque `recursiveCte` fixpoint.
declare_syntax_cat sql_cte
syntax ident "AS" "(" sql_query ")" : sql_cte
syntax ident "(" ident,+ ")" "AS" "(" sql_query ")" : sql_cte   -- explicit column list `c (a, b) AS (…)`
syntax:max "WITH" sql_cte,+ sql_query : sql_query
syntax:max "WITH" "RECURSIVE" sql_cte,+ sql_query : sql_query

-- macro_rules -- Gemini generated (then fixed) rules for desugaring JOINs and CROSS JOINs into comma-separated FROM clauses with WHERE conditions; GROUP BY omitted for now.
--   -----------------------------------------------------------------------------
--   -- CASE A: The query ALREADY has an existing WHERE clause
--   -----------------------------------------------------------------------------
--   -- 1. Desugar INNER JOIN -> Replace with comma, append condition via AND

--   | `(sql_query| SELECT $items FROM $f:sql_from JOIN $tNext:ident ON $onCond WHERE $whereCond $[;]?) =>
--       `(sql_query| SELECT $items FROM $f, $tNext:ident WHERE $whereCond AND $onCond;)

--   -- 2. Desugar CROSS JOIN -> Replace with comma, leave WHERE unchanged

--   | `(sql_query| SELECT $items FROM $f:sql_from CROSS JOIN $tNext:ident WHERE $whereCond $[;]?) =>
--       `(sql_query| SELECT $items FROM $f, $tNext:ident WHERE $whereCond ;)

--   -----------------------------------------------------------------------------
--   -- CASE B: The query does NOT have a WHERE clause yet
--   -----------------------------------------------------------------------------
--   -- 3. Desugar INNER JOIN -> Initialize the WHERE clause with the ON condition

--   | `(sql_query| SELECT $items FROM $f:sql_from JOIN $tNext:ident ON $onCond:term $[;]?) =>
--       `(sql_query| SELECT $items FROM $f, $tNext:ident WHERE $onCond ;)

--   -- 4. Desugar CROSS JOIN -> Replace with comma, no WHERE clause needed

--   | `(sql_query| SELECT $items FROM $f:sql_from CROSS JOIN $tNext:ident $[;]?) =>
--       `(sql_query| SELECT $items FROM $f, $tNext:ident;)

partial def escapeJoin (stx : Syntax) : MetaM <| TSyntax `sql_query := do
  match stx with
  | `(sql_query| SELECT $items FROM $f:sql_from JOIN $tNext:ident ON $onCond:term WHERE $whereCond $[;]?) =>
      escapeJoin <| ← `(sql_query| SELECT $items FROM $f, $tNext:ident WHERE $whereCond && $onCond;)
  | `(sql_query| SELECT $items FROM $f:sql_from CROSS JOIN $tNext:ident WHERE $whereCond $[;]?) =>
      escapeJoin <| ← `(sql_query| SELECT $items FROM $f, $tNext:ident WHERE $whereCond ;)
  | `(sql_query| SELECT $items FROM $f:sql_from JOIN $tNext:ident ON $onCond:term $[;]?) =>
      escapeJoin <| ← `(sql_query| SELECT $items FROM $f, $tNext:ident WHERE $onCond ;)
  | `(sql_query| SELECT $items FROM $f:sql_from CROSS JOIN $tNext:ident $[;]?) =>
      escapeJoin <| ← `(sql_query| SELECT $items FROM $f, $tNext:ident;)
  | _ => return ⟨stx⟩

partial def getIdents (stx : TSyntax `sql_from) : List Name :=
  match stx with
  | `(sql_from| $db:ident) => [db.getId]
  | `(sql_from| $t:ident AS $_:ident) => [t.getId]
  | `(sql_from| $t:ident $_:ident) => [t.getId]
  | `(sql_from| $f1:sql_from , $f2:sql_from) => getIdents f1 ++ getIdents f2
  | _ => []

-- Table-alias handling (`collectAliases`, `baseifyName`, `baseifyIdents`) lives in `Parser/Alias.lean`.

/-! ## Term-level `WHERE`-predicate combinators -/

-- macro "SELECT" " * " "FROM" ident "WHERE" t:term : term =>
--     return t

macro:30 t:term "AND" s:term : term =>
  `($t && $s)

macro:30 t:term "OR" s:term : term =>
  `($t || $s)

-- SQL `<>` (not-equal), at comparison precedence.
macro:50 a:term:51 " <> " b:term:51 : term =>
  `($a != $b)

-- SQL `x IN (a, b, …)` desugars to an `OR`-chain of equalities.
macro:50 x:term:51 " IN " "(" elems:term,+ ")" : term => do
  let cmps ← elems.getElems.mapM fun e => `($x == $e)
  cmps.foldlM (fun acc c => `($acc || $c)) (← `(false))

-- SQL `x NOT IN (a, b, …)` — negation of `IN`.
macro:50 x:term:51 " NOT " " IN " "(" elems:term,+ ")" : term => do
  let cmps ← elems.getElems.mapM fun e => `($x == $e)
  let chain ← cmps.foldlM (fun acc c => `($acc || $c)) (← `(false))
  `(!($chain))

-- `GROUP BY ROLLUP/CUBE/GROUPING SETS(…)` — grouping-set constructs. They parse as terms (so the
-- existing `GROUP BY term,*` accepts them) and are intercepted in `Parser/Query.lean`'s SELECT arm,
-- which groups over the union of their columns and wraps the result in the opaque `groupSetMark`.
syntax:max "ROLLUP" "(" term,+ ")" : term
syntax:max "CUBE" "(" term,+ ")" : term
declare_syntax_cat grouping_set
syntax "(" term,* ")" : grouping_set
syntax term : grouping_set
syntax:max "GROUPING" &"SETS" "(" grouping_set,+ ")" : term
-- `GROUPING(a, …)` flag scalar → opaque `groupingOf` over its args folded into a tuple.
syntax:max "GROUPING" "(" term,+ ")" : term
macro_rules
  | `(GROUPING($args,*)) => do
      let es := args.getElems
      let mut tup : Term := es.back!
      for i in [1:es.size] do tup ← `(($(es[es.size - 1 - i]!), $tup))
      `($(Lean.mkIdent `LeanDatabase.Scalar.groupingOf) $tup)

-- SQL `x BETWEEN a AND b` (inclusive). The inner `AND` is part of BETWEEN; the `:51` args keep the
-- boolean `AND` macro (prec 30) from swallowing it.
macro:50 x:term:51 " BETWEEN " a:term:51 " AND " b:term:51 : term =>
  `($a ≤ $x && $x ≤ $b)
macro:50 x:term:51 " NOT " " BETWEEN " a:term:51 " AND " b:term:51 : term =>
  `(!($a ≤ $x && $x ≤ $b))

-- `x IS TRUE|FALSE` / `x IS NOT TRUE|FALSE` on a `Bool` column.
macro:50 x:term:51 " IS " " TRUE " : term => `($x == true)
macro:50 x:term:51 " IS " " FALSE " : term => `($x == false)
macro:50 x:term:51 " IS " " NOT " " TRUE " : term => `($x != true)
macro:50 x:term:51 " IS " " NOT " " FALSE " : term => `($x != false)
-- `a IS [NOT] DISTINCT FROM b` — null-safe (in)equality; approximated by `!=` / `==`.
macro:50 a:term:51 " IS " " DISTINCT " " FROM " b:term:51 : term => `($a != $b)
macro:50 a:term:51 " IS " " NOT " " DISTINCT " " FROM " b:term:51 : term => `($a == $b)

-- SQL `x LIKE pat` — string match with `%`/`_` wildcards. `strLike` lives in `Operators/Like.lean`
-- (not imported here, to keep `Syntax` pure), so emit a raw ident that resolves at the use-site.
macro:50 x:term:51 " LIKE " p:term:51 : term =>
  `($(Lean.mkIdent (`LeanDatabase ++ `strLike)) $p $x)
-- `x NOT LIKE p` — negated match; `x ILIKE p` — case-insensitive match.
macro:50 x:term:51 " NOT " " LIKE " p:term:51 : term =>
  `(!$(Lean.mkIdent (`LeanDatabase ++ `strLike)) $p $x)
macro:50 x:term:51 " ILIKE " p:term:51 : term =>
  `($(Lean.mkIdent (`LeanDatabase ++ `strILike)) $p $x)

/-! ## `NULL` — the sound 2-valued gates

We model nullable columns as `Option _` but expose NULL only through constructs that reduce to a
`Bool` or a non-null value, so no 3-valued logic is needed and no unsoundness can arise. There is
**deliberately no bare `NULL` term**: `col = NULL` cannot be written (so the classic `WHERE NOT(x =
NULL)` Kleene trap is impossible), and a raw nullable column in a comparison fails to typecheck
(`Option τ` vs `τ`) rather than silently mis-evaluating. Full 3-valued predicates are future work. -/
/-- `x IS NULL` / `x IS NOT NULL` dispatched on whether the column is nullable: a real `Option` uses
`isNone`/`isSome`; a non-nullable base column (a bare `τ`) can never be NULL, so it is `false`/`true`.
The non-`Option` fallback is low-priority so the `Option` instance always wins. -/
class SqlNullable (α : Type) where
  isNull : α → Bool
  isNotNull : α → Bool
instance : SqlNullable (Option α) where
  isNull := Option.isNone
  isNotNull := Option.isSome
/-- A non-nullable base column can never be NULL. Low priority so the `Option` instance always wins;
named so the simp lemmas below can rewrite the class method through it. -/
instance (priority := low) instSqlNullableBase {α : Type} : SqlNullable α where
  isNull _ := false
  isNotNull _ := true
-- Reduce the `Option` dispatch back to raw `isNone`/`isSome` so the outer-join `IS NULL` lemma still fires.
@[simp, grind =] theorem SqlNullable.isNull_option (x : Option α) :
    SqlNullable.isNull x = x.isNone := rfl
@[simp, grind =] theorem SqlNullable.isNotNull_option (x : Option α) :
    SqlNullable.isNotNull x = x.isSome := rfl
-- A base (non-`Option`) column never satisfies `IS NULL`, so such a filter is a no-op (drops nothing).
@[simp, grind =] theorem SqlNullable.isNull_base {α : Type} (x : α) :
    @SqlNullable.isNull α instSqlNullableBase x = false := rfl
@[simp, grind =] theorem SqlNullable.isNotNull_base {α : Type} (x : α) :
    @SqlNullable.isNotNull α instSqlNullableBase x = true := rfl

-- `x IS NULL` / `x IS NOT NULL` — 2-valued (`SqlNullable`), works on nullable and base columns alike.
syntax:50 term:51 " IS " " NULL " : term
syntax:50 term:51 " IS " " NOT " " NULL " : term
-- `COALESCE(x, d)` / `IFNULL(x, d)` — first non-null; `NULLIF(a, b)` — NULL when equal, else `a`.
-- `COALESCE`/`CONCAT` are variadic (folded to the 2-arg forms).
syntax:max "COALESCE" "(" term,+ ")" : term
syntax:max "IFNULL" "(" term "," term ")" : term
syntax:max "NULLIF" "(" term "," term ")" : term
macro_rules
  | `($x IS NULL)      => `(LeanDatabase.SqlNullable.isNull $x)
  | `($x IS NOT NULL)  => `(LeanDatabase.SqlNullable.isNotNull $x)
  | `(COALESCE($x))          => `($x)
  | `(COALESCE($x, $xs,*))   => `(Option.getD $x (COALESCE($xs,*)))
  | `(IFNULL($x, $d))   => `(Option.getD $x $d)
  | `(NULLIF($a, $b))   => `(if $a == $b then none else some $a)

-- `CONCAT(a, b, …)` — variadic, right-folded onto the binary `Scalar.concat`.
syntax:max "CONCAT" "(" term,+ ")" : term
open Lean in
macro_rules
  | `(CONCAT($a))        => `($a)
  | `(CONCAT($a, $bs,*)) => `($(mkIdent `LeanDatabase.Scalar.concat) $a (CONCAT($bs,*)))

-- `REGEXP_SUBSTR`/`REGEXP_EXTRACT`/`REGEXP_REPLACE` accept extra positional args (position,
-- occurrence, flags, capture group) — drop them. `REGEXP_EXTRACT` is BigQuery's spelling of SUBSTR.
syntax:max "REGEXP_SUBSTR" "(" term "," term "," term,+ ")" : term
syntax:max "REGEXP_EXTRACT" "(" term "," term "," term,+ ")" : term
syntax:max "REGEXP_REPLACE" "(" term "," term "," term "," term,+ ")" : term
open Lean in
macro_rules
  | `(REGEXP_SUBSTR($s, $p, $_rest,*))       => `($(mkIdent `LeanDatabase.Scalar.regexpSubstr) $s $p)
  | `(REGEXP_EXTRACT($s, $p, $_rest,*))      => `($(mkIdent `LeanDatabase.Scalar.regexpSubstr) $s $p)
  | `(REGEXP_REPLACE($s, $p, $r, $_rest,*))  => `($(mkIdent `LeanDatabase.Scalar.regexpReplace) $s $p $r)

-- No-arg "current time" functions (opaque), bool/typed literals, and a couple null helpers.
open Lean in macro:max "NOW" "(" ")" : term => `($(mkIdent `LeanDatabase.Scalar.nowVal))
open Lean in macro:max "GETDATE" "(" ")" : term => `($(mkIdent `LeanDatabase.Scalar.nowVal))
open Lean in macro:max "UUID_STRING" "(" ")" : term => `($(mkIdent `LeanDatabase.Scalar.uuidString))
open Lean in macro "CURRENT_DATE" : term => `($(mkIdent `LeanDatabase.Scalar.nowVal))
open Lean in macro "CURRENT_TIMESTAMP" : term => `($(mkIdent `LeanDatabase.Scalar.nowVal))
open Lean in macro "SYSDATE" : term => `($(mkIdent `LeanDatabase.Scalar.nowVal))
macro "TRUE" : term => `(true)
macro "FALSE" : term => `(false)
-- Typed literals `DATE '…'` / `TIMESTAMP '…'` / `TIME '…'` — the (normalized) string value.
macro "DATE" s:str : term => `($s)
macro "TIMESTAMP" s:str : term => `($s)
macro "TIME" s:str : term => `($s)
syntax:max "NULLIFZERO" "(" term ")" : term
syntax:max "ZEROIFNULL" "(" term ")" : term
macro_rules
  | `(NULLIFZERO($x)) => `(NULLIF($x, 0))
  | `(ZEROIFNULL($x)) => `(COALESCE($x, 0))

-- SQL `EXISTS (subquery)` / `NOT EXISTS (subquery)` — correlated; intercepted as a `WHERE` form by
-- `Parser.Query` (→ `semijoin` / `antijoin`), so this syntax is only ever matched, never elaborated.
syntax:90 "EXISTS" "(" sql_query ")" : term
syntax:90 "NOT" "EXISTS" "(" sql_query ")" : term

-- SQL `x IN (subquery)` / `x NOT IN (subquery)` — also intercepted by `Parser.Query` (→
-- `semijoin`/`antijoin` on the implicit equality `x = innerColumn`). Distinct from the IN-list forms.
syntax:90 term:91 " IN " "(" sql_query ")" : term
syntax:90 term:91 " NOT " " IN " "(" sql_query ")" : term

-- `t:term:50` (comparison level) so `NOT` binds looser than `=`/`<`/`>` but tighter than `AND`/`OR`:
-- `NOT a = b` is `NOT (a = b)`, and `NOT a AND b` is `(NOT a) AND b` — matching SQL precedence.
macro:85 "NOT" t:term:50 : term =>
  `(!$t)

-- SQL searched `CASE WHEN c1 THEN v1 … [ELSE d] END`. A branch value is a `term` OR `NULL` (value
-- position only — `NULL` is never a standalone term, so `col = NULL` stays unwriteable, the 3VL trap
-- intact). `($c : Bool)` coerces a `Decidable` `Prop` like `age > 30` to `decide (…)`, so a condition
-- has the SAME shape as a `WHERE` predicate.
-- • No `NULL` anywhere AND an `ELSE` present → nested `if ($c : Bool) then vᵢ else …` over the branch
--   terms (identical shape to before, so `groupSum_case_eq_groupSum_where` still folds `SUM(CASE)`).
-- • Any `NULL` branch, `ELSE NULL`, or no `ELSE` → `Option`-typed: `some vᵢ` per non-null branch, `none`
--   for a `NULL`/absent one (the AS-clause probe then finds the `nullable` column type). The
--   `COUNT(CASE WHEN p THEN _ END)` shape is intercepted by `liftAggExprs` before this macro fires.
declare_syntax_cat sql_case_val
syntax term : sql_case_val
syntax "NULL" : sql_case_val
syntax:90 "CASE" ( "WHEN" term "THEN" sql_case_val ) + ( "ELSE" sql_case_val )? "END" : term
macro_rules
  | `(CASE $[WHEN $cs THEN $vs]* $[ELSE $d]? END) => do
      let toOpt : TSyntax `sql_case_val → MacroM (Option Term) := fun s => match s with
        | `(sql_case_val| NULL)    => pure none
        | `(sql_case_val| $t:term) => pure (some t)
        | _ => Macro.throwUnsupported
      let vOpts ← vs.mapM toOpt
      let dOpt ← d.mapM toOpt                       -- Option (Option Term): outer none = no ELSE
      let nullable := vOpts.any Option.isNone || (match dOpt with | some (some _) => false | _ => true)
      let branches := cs.zip vOpts
      -- The folds are annotated: `foldrM` otherwise infers the accumulator as bare `Syntax` and the
      -- `if … then … else $acc` quotation then rejects it.
      if nullable then
        let base : Term ← match dOpt with | some (some t) => `(some $t) | _ => `(none)
        let step : (Term × Option Term) → Term → MacroM Term := fun (c, vo) acc => do
          let v : Term ← match vo with | some x => `(some $x) | none => `(none)
          `(if ($c : Bool) then $v else $acc)
        branches.foldrM (β := Term) step base
      else
        let some (some base) := dOpt | Macro.throwUnsupported
        let step : (Term × Option Term) → Term → MacroM Term := fun (c, vo) acc => do
          let some v := vo | Macro.throwUnsupported
          `(if ($c : Bool) then $v else $acc)
        branches.foldrM (β := Term) step base

-- Simple `CASE e WHEN v1 THEN r1 … [ELSE d] END` → the searched form comparing `e == vᵢ`.
syntax:90 "CASE" term ( "WHEN" term "THEN" term ) + "ELSE" term "END" : term
syntax:90 "CASE" term ( "WHEN" term "THEN" term ) + "END" : term
macro_rules
  | `(CASE $e:term $[WHEN $vs THEN $rs]* ELSE $d END) => do
      let cs ← vs.mapM fun v => `($e == $v)
      `(CASE $[WHEN $cs THEN $rs:term]* ELSE $d:term END)
  | `(CASE $e:term $[WHEN $vs THEN $rs]* END) => do
      let cs ← vs.mapM fun v => `($e == $v)
      `(CASE $[WHEN $cs THEN $rs:term]* END)


/-! ## Scalar functions

Uninterpreted-by-default: each SQL scalar becomes an `opaque` constant from `Operators/Scalar.lean`
(emitted as a fully-qualified ident so this file stays dependency-free, as with `LIKE`). Identical
calls cancel by congruence. Adding a scalar = one `opaque` there + one syntax/macro line here.
`CAST` is intentionally *not* here — it needs a real coercion. -/
open Lean in
/-- `scalarN "SQLNAME" "constName"` declares a 1/2/3-arg SQL scalar in one line: the syntax **and**
the rewrite to `LeanDatabase.Scalar.constName` (emitted hygiene-free, since this file doesn't import
`Scalar`). Adding an ordinary opaque scalar = one `opaque` in `Scalar.lean` + one line below. -/
macro "scalar1" kw:str fn:str : command => do
  let nm : Name := `LeanDatabase.Scalar ++ fn.getString.toName
  `(macro:max $kw:str "(" x:term ")" : term => `($$(mkIdent $(quote nm)) $$x))
macro "scalar2" kw:str fn:str : command => do
  let nm : Name := `LeanDatabase.Scalar ++ fn.getString.toName
  `(macro:max $kw:str "(" a:term "," b:term ")" : term => `($$(mkIdent $(quote nm)) $$a $$b))
macro "scalar3" kw:str fn:str : command => do
  let nm : Name := `LeanDatabase.Scalar ++ fn.getString.toName
  `(macro:max $kw:str "(" a:term "," b:term "," c:term ")" : term =>
      `($$(mkIdent $(quote nm)) $$a $$b $$c))
macro "scalar4" kw:str fn:str : command => do
  let nm : Name := `LeanDatabase.Scalar ++ fn.getString.toName
  `(macro:max $kw:str "(" a:term "," b:term "," c:term "," d:term ")" : term =>
      `($$(mkIdent $(quote nm)) $$a $$b $$c $$d))

-- The scalar table — one line each (numeric, string, date). All opaque, cancel by congruence.
scalar1 "ABS" "abs"
scalar1 "CEIL" "ceil"
scalar1 "FLOOR" "floor"
scalar1 "SIGN" "sign"
scalar1 "CEILING" "ceil"
scalar1 "TRY_TO_DATE" "toDate"
scalar1 "TRY_TO_TIMESTAMP" "toTimestamp"
scalar1 "TRY_TO_NUMBER" "toNumber"
scalar1 "TRY_TO_DOUBLE" "toNumber"
scalar1 "TRY_TO_DECIMAL" "toNumber"
scalar2 "BITAND" "bitand"
scalar2 "REGEXP_COUNT" "regexpCount"
scalar2 "REGEXP_LIKE" "regexpLike"
scalar2 "TRUNC" "truncTo"
scalar3 "TRANSLATE" "translateOf"
scalar3 "DATEADD" "dateAdd"
scalar3 "TIMESTAMPADD" "dateAdd"
scalar3 "DATE_DIFF" "dateDiff"
scalar2 "SPLIT" "splitOf"
scalar1 "OBJECT_KEYS" "objectKeys"
scalar2 "GET_PATH" "getPath"
scalar2 "ARRAY_CONSTRUCT" "arrayConstruct"
-- Renamed from LEFT/RIGHT by the normalizer so those tokens stay join-only (see matchFnRename).
scalar2 "LEFTSTR" "leftOf"
scalar2 "RIGHTSTR" "rightOf"
scalar2 "CONTAINS" "containsOf"
scalar2 "STARTSWITH" "startsWithOf"
scalar2 "ENDSWITH" "endsWithOf"
scalar2 "CHARINDEX" "charIndexOf"
scalar2 "INSTR" "instrOf"
scalar2 "REPEAT" "repeatOf"
scalar1 "SPACE" "spaceOf"
scalar1 "HASH" "hashOf"
scalar1 "MD5" "md5Of"
scalar2 "TO_CHAR" "toChar2"
scalar2 "TO_VARCHAR" "toChar2"
scalar2 "ST_MAKEPOINT" "stMakePoint"
scalar2 "ST_DISTANCE" "stDistance"
scalar4 "HAVERSINE" "haversine"
scalar1 "SQRT" "sqrtOf"
scalar1 "EXP" "expOf"
scalar1 "LN" "lnOf"
scalar1 "TRUNC" "truncNum"
scalar1 "UPPER" "upperOf"
scalar1 "LOWER" "lowerOf"
scalar1 "TRIM" "trimOf"
scalar1 "LTRIM" "ltrimOf"
scalar1 "RTRIM" "rtrimOf"
scalar1 "INITCAP" "initcapOf"
scalar1 "REVERSE" "reverseOf"
scalar1 "LENGTH" "lengthOf"
scalar1 "CHAR_LENGTH" "lengthOf"
scalar1 "CHARACTER_LENGTH" "lengthOf"
scalar1 "YEAR" "yearOf"
scalar1 "MONTH" "monthOf"
scalar1 "DAY" "dayOf"
scalar1 "QUARTER" "quarterOf"
scalar1 "WEEK" "weekOf"
scalar1 "HOUR" "hourOf"
scalar1 "MINUTE" "minuteOf"
scalar1 "SECOND" "secondOf"
scalar1 "DAYOFWEEK" "dayOfWeek"
scalar1 "TO_DATE" "toDate"
scalar2 "TO_DATE" "toDate2"
scalar1 "DATE" "toDate"
scalar1 "TO_TIMESTAMP" "toTimestamp"
scalar1 "ARRAY_SIZE" "arraySize"
scalar1 "TO_GEOGRAPHY" "toGeography"
scalar2 "TO_TIMESTAMP" "toTimestamp2"
scalar1 "TO_TIMESTAMP_NTZ" "toTimestamp"
scalar2 "TO_TIMESTAMP_NTZ" "toTimestamp2"
scalar1 "TO_VARCHAR" "toChar"
scalar2 "ST_INTERSECTS" "stIntersects"
scalar2 "ST_WITHIN" "stWithin"
scalar1 "ST_AREA" "stArea"
scalar2 "ST_INTERSECTION" "stIntersection"
scalar3 "CONVERT_TIMEZONE" "convertTimezone"
scalar1 "ARRAY_SORT" "arraySort"
scalar2 "REGEXP_SUBSTR_ALL" "regexpSubstrAll"
scalar1 "PARSE_JSON" "parseJson"
scalar3 "ST_DWITHIN" "stDwithin"
scalar2 "ARRAYS_OVERLAP" "arraysOverlap"
scalar1 "DAYOFYEAR" "dayOfYear"
scalar2 "DIFFERENCE" "difference"
scalar1 "LOG10" "log10Of"
-- Broad common-function coverage (see Operators/Scalar.lean).
scalar1 "CBRT" "cbrtOf"
scalar1 "SQUARE" "squareOf"
scalar1 "FACTORIAL" "factorialOf"
scalar1 "ACOS" "acosOf"
scalar1 "ASIN" "asinOf"
scalar1 "ATAN" "atanOf"
scalar1 "COS" "cosOf"
scalar1 "SIN" "sinOf"
scalar1 "TAN" "tanOf"
scalar1 "COT" "cotOf"
scalar1 "DEGREES" "degreesOf"
scalar1 "RADIANS" "radiansOf"
scalar2 "ATAN2" "atan2Of"
scalar1 "SOUNDEX" "soundexOf"
scalar1 "ASCII" "asciiOf"
scalar1 "LEN" "lenOf"
scalar1 "OCTET_LENGTH" "octetLength"
scalar2 "EDITDISTANCE" "editDistance"
scalar2 "REGEXP_INSTR" "regexpInstr"
scalar1 "CHR" "chrOf"
scalar3 "SUBSTRING_INDEX" "substringIndex"
scalar2 "NVL" "nvlOf"
scalar2 "IFNULL" "nvlOf"
scalar2 "ISNULL" "nvlOf"
scalar3 "NVL2" "nvl2Of"
scalar1 "SHA1" "sha1Of"
scalar1 "SHA2" "sha2Of"
scalar1 "BASE64_ENCODE" "base64Encode"
scalar1 "HEX_ENCODE" "hexEncode"
scalar2 "ADD_MONTHS" "addMonths"
scalar2 "MONTHS_BETWEEN" "monthsBetween"
scalar2 "NEXT_DAY" "nextDay"
scalar1 "WEEKOFYEAR" "weekOfYear"
scalar1 "WEEKISO" "weekIso"
scalar1 "DAYOFMONTH" "dayOfMonth"
scalar1 "YEAROFWEEK" "yearOfWeek"
scalar1 "MONTHNAME" "monthName"
scalar1 "DAYNAME" "dayName"
scalar1 "TO_TIME" "toTime"
scalar2 "ARRAY_CONTAINS" "arrayContains"
scalar2 "ARRAY_POSITION" "arrayPosition"
scalar3 "ARRAY_SLICE" "arraySlice"
scalar2 "ARRAY_CAT" "arrayCat"
scalar2 "ARRAY_APPEND" "arrayAppend"
scalar1 "ARRAY_DISTINCT" "arrayDistinct"
scalar1 "ARRAY_COMPACT" "arrayCompact"
scalar2 "GET" "getOf"
scalar1 "TO_BOOLEAN" "toBoolean"
scalar1 "TO_ARRAY" "toArray"
scalar1 "TO_OBJECT" "toObject"
scalar1 "TO_VARIANT" "toVariant"
scalar1 "TO_BINARY" "toBinary"
scalar1 "ST_X" "stX"
scalar1 "ST_Y" "stY"
scalar1 "ST_LENGTH" "stLength"
scalar2 "ST_CONTAINS" "stContains"
scalar1 "ST_CENTROID" "stCentroid"
scalar3 "DATE_FROM_PARTS" "dateFromParts"
scalar1 "TO_CHAR" "toChar"
scalar1 "TO_VARCHAR" "toChar"
scalar1 "TO_NUMBER" "toNumber"
scalar1 "TO_DECIMAL" "toNumber"
scalar1 "TO_DOUBLE" "toNumber"
scalar1 "LAST_DAY" "lastDay"
scalar2 "MOD" "modOf"
scalar2 "POWER" "powerOf"
scalar2 "POW" "powerOf"
scalar2 "LOG" "logOf"
scalar2 "GREATEST" "greatestOf"
scalar2 "LEAST" "leastOf"
scalar2 "REGEXP_SUBSTR" "regexpSubstr"
scalar2 "REGEXP_EXTRACT" "regexpSubstr"
scalar2 "STRPOS" "strposOf"
scalar2 "POSITION" "strposOf"
scalar2 "DATE_TRUNC" "dateTrunc"
scalar2 "DATE_PART" "datePart"
scalar3 "SUBSTR" "substr"
scalar3 "SUBSTRING" "substr"
scalar2 "SUBSTR" "substr2"
scalar2 "SUBSTRING" "substr2"
scalar3 "SPLIT_PART" "splitPart"
scalar3 "REPLACE" "replaceOf"
scalar3 "REGEXP_REPLACE" "regexpReplace"
scalar3 "LPAD" "lpadOf"
scalar3 "RPAD" "rpadOf"
scalar3 "DATEDIFF" "dateDiff"
scalar3 "TIMESTAMPDIFF" "dateDiff"
scalar3 "DATE_ADD" "dateAdd"
scalar2 "ARRAY_TO_STRING" "arrayToString"
scalar2 "VARIANTGET" "variantGet"

/-! ### PostgreSQL canonical-dialect forms

Everything above is the Snowflake-oriented surface (kept for direct Snowflake input). Since the prover's
canonical dialect is now PostgreSQL — every source dialect is transpiled to it via sqlglot — the forms
below are what sqlglot *emits*, and must parse too. They reuse the same opaque scalar bodies. -/
scalar2 "ST_POINT" "stMakePoint"        -- PG spelling of Snowflake ST_MAKEPOINT
scalar1 "ST_ASTEXT" "stAsText"
scalar2 "JSON_EXTRACT_PATH" "getPath"   -- PG spelling of Snowflake GET_PATH
scalar3 "JSON_EXTRACT_PATH" "getPath3"  -- nested path `JSON_EXTRACT_PATH(v, 'a', 'b')`
scalar4 "JSON_EXTRACT_PATH" "getPath4"
scalar2 "ARRAY_LENGTH" "arrayLength"
scalar1 "DAY_OF_WEEK" "dayOfWeek"     -- sqlglot's underscored spellings of DAYOFWEEK / DAYOFYEAR
scalar1 "DAY_OF_YEAR" "dayOfYear"
scalar1 "DAYOFWEEKISO" "dayOfWeek"

-- `EXTRACT(field FROM x)` (PG) — opaque `extractOf "FIELD" x`; `field` is a bare keyword (YEAR/MONTH/…).
macro:max "EXTRACT" "(" f:ident "FROM" x:term ")" : term => do
  let fs := Syntax.mkStrLit f.getId.toString.toUpper
  `($(mkIdent `LeanDatabase.Scalar.extractOf) $fs $x)

-- `POSITION(sub IN s)` (ANSI) — 1-based index of `sub` in `s`; reuses the opaque `charIndexOf`. `sub`
-- is parsed above the `IN`-operator precedence (91) so `POSITION('x' IN s)` doesn't read `'x' IN …`.
macro:max "POSITION" "(" sub:term:91 "IN" s:term ")" : term =>
  `($(mkIdent `LeanDatabase.Scalar.charIndexOf) $sub $s)

-- `SUBSTRING(x FROM n [FOR m])` (PG/ANSI) — reuses the Snowflake `substr`/`substr2` bodies.
-- The two arities need named kinds: with both declared, the shorter pattern is ambiguous inside a
-- single `macro_rules` (`FOR m` could still be pending), so each rule names the syntax it expands.
syntax:max (name := substringFor) "SUBSTRING" "(" term "FROM" term "FOR" term ")" : term
syntax:max (name := substringFrom) "SUBSTRING" "(" term "FROM" term ")" : term
macro_rules (kind := substringFor)
  | `(SUBSTRING($x FROM $n FOR $m)) => `($(mkIdent `LeanDatabase.Scalar.substr) $x $n $m)
macro_rules (kind := substringFrom)
  | `(SUBSTRING($x FROM $n))        => `($(mkIdent `LeanDatabase.Scalar.substr2) $x $n)

/-! ## Window functions (order-dependent ⇒ opaque)

`ROW_NUMBER`/`RANK`/`DENSE_RANK`/`LAG`/`LEAD` over `(PARTITION BY … ORDER BY …)` elaborate to the opaque
`Scalar.winOf spec`, where `spec` is a tuple of a per-function marker plus the args and PARTITION/ORDER
key values. Identical windows cancel; different specs stay unprovable (sound — a `Finset` has no order). -/
declare_syntax_cat win_ord_item
syntax term (&"ASC" <|> &"DESC")? ("NULLS" ("FIRST" <|> "LAST"))? : win_ord_item
-- Optional frame clause `ROWS/RANGE/GROUPS [BETWEEN <bound> AND] <bound>`. The frame keywords are
-- RESERVED (plain-symbol) so `PARTITION BY term,+` stops before them instead of parsing `RANGE`/`UNBOUNDED`
-- as columns. The frame is reprinted into the opaque window spec (`elabWindow`) — never dropped — so
-- windows with different frames get different specs and are never equated (sound); identical frames cancel.
declare_syntax_cat win_bound
syntax "UNBOUNDED" "PRECEDING" : win_bound
syntax "UNBOUNDED" "FOLLOWING" : win_bound
syntax "CURRENT" "ROW" : win_bound
syntax num "PRECEDING" : win_bound
syntax num "FOLLOWING" : win_bound
declare_syntax_cat win_frame
syntax "ROWS" "BETWEEN" win_bound "AND" win_bound : win_frame
syntax "RANGE" "BETWEEN" win_bound "AND" win_bound : win_frame
syntax "GROUPS" "BETWEEN" win_bound "AND" win_bound : win_frame
syntax "ROWS" win_bound : win_frame
syntax "RANGE" win_bound : win_frame
syntax "GROUPS" win_bound : win_frame
declare_syntax_cat win_spec
syntax ("PARTITION" &"BY" term,+)? (&"ORDER" &"BY" win_ord_item,*)? (win_frame)? : win_spec

syntax:max "ROW_NUMBER" "(" ")" &"OVER" "(" win_spec ")" : term
syntax:max "RANK" "(" ")" &"OVER" "(" win_spec ")" : term
syntax:max "DENSE_RANK" "(" ")" &"OVER" "(" win_spec ")" : term
syntax:max "LAG" "(" term,+ ")" &"OVER" "(" win_spec ")" : term
syntax:max "LEAD" "(" term,+ ")" &"OVER" "(" win_spec ")" : term
syntax:max "NTILE" "(" term ")" &"OVER" "(" win_spec ")" : term
-- Windowed aggregates (`SUM(x) OVER (…)`, `COUNT(*) OVER (…)`, `FIRST_VALUE`, …) — opaque, like above.
syntax:max "SUM" "(" term ")" &"OVER" "(" win_spec ")" : term
syntax:max "AVG" "(" term ")" &"OVER" "(" win_spec ")" : term
syntax:max "MIN" "(" term ")" &"OVER" "(" win_spec ")" : term
syntax:max "MAX" "(" term ")" &"OVER" "(" win_spec ")" : term
syntax:max "COUNT" "(" "*" ")" &"OVER" "(" win_spec ")" : term
syntax:max "COUNT" "(" term ")" &"OVER" "(" win_spec ")" : term
syntax:max "FIRST_VALUE" "(" term ")" &"OVER" "(" win_spec ")" : term
syntax:max "LAST_VALUE" "(" term ")" &"OVER" "(" win_spec ")" : term
syntax:max "NTH_VALUE" "(" term "," term ")" &"OVER" "(" win_spec ")" : term

open Lean Elab Term in
/-- Build `Scalar.winOf (marker, k₁, k₂, …)` — the marker string tags the function, the rest are the
arg/PARTITION/ORDER key terms folded into a right-nested tuple (empty ⇒ just the marker). -/
def elabWindow (marker : String) (args : Array Syntax) (spec : Syntax) : TermElabM Expr := do
  let sa := spec.getArgs
  let keys := if sa.size < 1 || sa[0]!.getArgs.isEmpty then #[] else sa[0]!.getArgs[2]!.getSepArgs
  let ordKeys := if sa.size < 2 || sa[1]!.getArgs.isEmpty then #[]
                 else sa[1]!.getArgs[2]!.getSepArgs.map (·[0])
  -- Fold any explicit frame (`ROWS/RANGE … BETWEEN …`) into the marker so distinct frames don't collapse
  -- to the same opaque window (sound — the frame text is part of the spec's identity).
  let marker := if sa.size < 3 || sa[2]!.getArgs.isEmpty then marker
                else marker ++ "|frame:" ++ ((sa[2]!.reprint.getD "").trim)
  let terms := args ++ keys ++ ordKeys
  let mut tup : Term ← `(term| $(Syntax.mkStrLit marker))
  for t in terms.reverse do
    tup ← `(term| ($(⟨t⟩), $tup))
  elabTerm (← `($(mkIdent `LeanDatabase.Scalar.winOf) $tup)) none

elab_rules : term
  | `(ROW_NUMBER() OVER ($s:win_spec))   => elabWindow "row_number" #[] s
  | `(RANK() OVER ($s:win_spec))         => elabWindow "rank" #[] s
  | `(DENSE_RANK() OVER ($s:win_spec))   => elabWindow "dense_rank" #[] s
  | `(LAG($as,*) OVER ($s:win_spec))     => elabWindow "lag" as.getElems.raw s
  | `(LEAD($as,*) OVER ($s:win_spec))    => elabWindow "lead" as.getElems.raw s
  | `(NTILE($a) OVER ($s:win_spec))      => elabWindow "ntile" #[a] s
  | `(SUM($a) OVER ($s:win_spec))          => elabWindow "win_sum" #[a] s
  | `(AVG($a) OVER ($s:win_spec))          => elabWindow "win_avg" #[a] s
  | `(MIN($a) OVER ($s:win_spec))          => elabWindow "win_min" #[a] s
  | `(MAX($a) OVER ($s:win_spec))          => elabWindow "win_max" #[a] s
  | `(COUNT(*) OVER ($s:win_spec))         => elabWindow "win_count_star" #[] s
  | `(COUNT($a) OVER ($s:win_spec))        => elabWindow "win_count" #[a] s
  | `(FIRST_VALUE($a) OVER ($s:win_spec))  => elabWindow "win_first" #[a] s
  | `(LAST_VALUE($a) OVER ($s:win_spec))   => elabWindow "win_last" #[a] s
  | `(NTH_VALUE($a, $b) OVER ($s:win_spec)) => elabWindow "win_nth" #[a, b] s

-- Non-uniform scalars (special emission), as `macro` one-liners.
open Lean in
macro:max "ROUND" "(" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.round) $x 0)
open Lean in
macro:max "ROUND" "(" x:term "," n:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.round) $x $n)
open Lean in
macro:max "EXTRACT" "(" "YEAR" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.yearOf) $x)
open Lean in
macro:max "EXTRACT" "(" "MONTH" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.monthOf) $x)
open Lean in
macro:max "EXTRACT" "(" "DAY" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.dayOf) $x)
open Lean in
macro:max "EXTRACT" "(" "QUARTER" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.quarterOf) $x)
open Lean in
macro:max "EXTRACT" "(" "WEEK" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.weekOf) $x)
open Lean in
macro:max "EXTRACT" "(" "HOUR" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.hourOf) $x)
open Lean in
macro:max "EXTRACT" "(" "MINUTE" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.minuteOf) $x)
open Lean in
macro:max "EXTRACT" "(" "SECOND" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.secondOf) $x)
open Lean in
macro:max "EXTRACT" "(" "DAYOFWEEK" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.dayOfWeek) $x)
open Lean in
macro:max "EXTRACT" "(" "EPOCH" "FROM" x:term ")" : term => `($(mkIdent `LeanDatabase.Scalar.epochOf) $x)
-- 3-/4-arg GREATEST/LEAST fold to the 2-arg form; conditionals are genuine (not opaque).
macro:max "GREATEST" "(" a:term "," b:term "," c:term ")" : term => `(GREATEST(GREATEST($a, $b), $c))
macro:max "GREATEST" "(" a:term "," b:term "," c:term "," d:term ")" : term => `(GREATEST(GREATEST($a, $b, $c), $d))
macro:max "LEAST" "(" a:term "," b:term "," c:term ")" : term => `(LEAST(LEAST($a, $b), $c))
macro:max "LEAST" "(" a:term "," b:term "," c:term "," d:term ")" : term => `(LEAST(LEAST($a, $b, $c), $d))

-- `DECODE(e, k1, v1, …[, default])` → the searched `CASE WHEN e = kᵢ THEN vᵢ … [ELSE default] END`.
syntax:max "DECODE" "(" term,+ ")" : term
macro_rules
  | `(DECODE($e:term, $rest,*)) => do
      let a := rest.getElems
      let mut cs : Array Term := #[]
      let mut vs : Array Term := #[]
      let mut i := 0
      while i + 1 < a.size do
        cs := cs.push (← `($e == $(a[i]!)))
        vs := vs.push a[i+1]!
        i := i + 2
      if i < a.size then `(CASE $[WHEN $cs THEN $vs:term]* ELSE $(a[i]!):term END)
      else `(CASE $[WHEN $cs THEN $vs:term]* ELSE NULL END)
macro:max "NVL" "(" x:term "," d:term ")" : term => `(Option.getD $x $d)
macro:max "NVL2" "(" x:term "," a:term "," b:term ")" : term => `(bif Option.isSome $x then $a else $b)
macro:max "IFF" "(" c:term "," a:term "," b:term ")" : term => `(bif ($c : Bool) then $a else $b)
macro:max "IF" "(" c:term "," a:term "," b:term ")" : term => `(bif ($c : Bool) then $a else $b)

-- `CAST(x AS <type>)`. The `::` cast form is intentionally unsupported — overriding `::` would
-- clobber `List.cons` globally. Elaborated (type-directed) in `Parser/Context.lean`, NOT as a macro:
-- the coercion depends on the *source* type (int→float is a real coercion.
declare_syntax_cat sql_cast_type
syntax "INT" : sql_cast_type
syntax "INTEGER" : sql_cast_type
syntax "BIGINT" : sql_cast_type
syntax "NUMBER" : sql_cast_type
syntax "FLOAT" : sql_cast_type
syntax "DOUBLE" : sql_cast_type
syntax (priority := high) "DOUBLE" "PRECISION" : sql_cast_type   -- PostgreSQL's float spelling
syntax "REAL" : sql_cast_type
syntax "NUMERIC" : sql_cast_type
syntax "DECIMAL" : sql_cast_type
syntax "STRING" : sql_cast_type
syntax "TEXT" : sql_cast_type
syntax "VARCHAR" : sql_cast_type
syntax "DATE" : sql_cast_type
syntax "TIMESTAMP" : sql_cast_type
syntax "TIMESTAMPTZ" : sql_cast_type          -- timestamp-with-time-zone; `String`-valued like TIMESTAMP
syntax "DATETIME" : sql_cast_type
syntax "BOOLEAN" : sql_cast_type
syntax "VARIANT" : sql_cast_type
-- Semi-structured / spatial target types — `String`-valued in our model (like `VARIANT`).
syntax "GEOGRAPHY" : sql_cast_type
syntax "GEOMETRY" : sql_cast_type
syntax "JSON" : sql_cast_type
syntax "JSONB" : sql_cast_type
syntax "OBJECT" : sql_cast_type
syntax "ARRAY" : sql_cast_type
syntax "CHAR" : sql_cast_type
-- Sized variants `VARCHAR(n)` / `NUMBER(p,s)` / … (the size is discarded). Higher priority so the
-- bare forms don't win and leave `(n)` dangling.
syntax (priority := high) "VARCHAR(" num ")" : sql_cast_type   -- `VARCHAR(` is a glued DDL token
syntax (priority := high) "CHAR" "(" num ")" : sql_cast_type
syntax (priority := high) "TIMESTAMP" "(" num ")" : sql_cast_type      -- fractional-seconds precision (discarded)
syntax (priority := high) "TIMESTAMPTZ" "(" num ")" : sql_cast_type
syntax (priority := high) "NUMBER" "(" num,+ ")" : sql_cast_type
syntax (priority := high) "NUMERIC" "(" num,+ ")" : sql_cast_type
syntax (priority := high) "DECIMAL" "(" num,+ ")" : sql_cast_type
syntax:max "CAST" "(" term "AS" sql_cast_type ")" : term
-- `CAST(NULL AS τ)` — a typed SQL NULL (value position), elaborated to `(none : Option τ)` in `Context`.
-- NULL stays a non-term elsewhere (so `col = NULL` remains unwritable); this is the standard typed-null.
syntax:max "CAST" "(" "NULL" "AS" sql_cast_type ")" : term
-- `TRY_CAST(x AS ty)` — same coercion as `CAST` (failure semantics not modelled).
macro:max "TRY_CAST" "(" x:term "AS" ty:sql_cast_type ")" : term => `(CAST($x AS $ty))

/-!
## Aggregates (`SUM`/`COUNT`/`AVG`/`MIN`/`MAX`)

The `SUM(term)` / … syntaxes live in `Parser.Context`. Every aggregate — over a column or an
arbitrary expression — is lifted into a fresh column by `liftAggExprs` (`Parser.Query`) and built
uniformly by `groupAggExprsE` (`Parser.Context`), dispatched on `AggKind`.
-/

open Meta Elab Term
def expandStx (str: String) : TermElabM Format := do
  let .ok stx := Parser.runParserCategory (← getEnv) `sql_query str | throwError "Failed to parse SQL query: {str}"
  let stx ← escapeJoin stx
  PrettyPrinter.ppCategory `sql_query stx

-- #eval expandStx "SELECT * FROM table JOIN table2 ON table.age = table2.age WHERE table.age > 30 && table.isActive && table.height < 180"

end LeanDatabase
