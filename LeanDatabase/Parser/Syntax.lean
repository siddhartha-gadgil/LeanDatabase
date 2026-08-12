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

/-- Auto-name for a bare (unaliased) computed column: its source text with non-ident chars dropped,
so `SUM(amt)` → `SUMamt`. Deterministic, so both sides of an equivalence agree. -/
def autoColName (t : Syntax) : Name :=
  Name.mkSimple <| ((t.reprint.getD "col").toList.filter (fun c => c.isAlphanum || c == '_')).asString

-- Scalar-subquery columns are rewritten to `term AS ident` before this is called, so the subquery
-- case is unreachable here.
def sqlColTerm : TSyntax `sql_col → Syntax.Term
  | `(sql_col| $col:ident) => col
  | `(sql_col| $col:term AS $_:ident) => col
  | `(sql_col| $col:term) => col
  | _ => unreachable!

def sqlColName : TSyntax `sql_col → Name
  | `(sql_col| $col:ident) => col.getId
  | `(sql_col| $_:term AS $x:ident) => x.getId
  | `(sql_col| ( $_:sql_query ) AS $x:ident) => x.getId
  | `(sql_col| $col:term) => autoColName col.raw
  | _ => unreachable!

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
syntax "(" sql_query ")" "AS" ident : sql_from       -- 2. Subquery with alias (AS)
syntax "(" sql_query ")" ident : sql_from             -- 2b. Subquery with bare alias

-- Recursive Cases (Chaining joins from left to right)
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

-- `GROUP BY` items are full terms: a bare column, an expression (`UPPER(col)`, `ROUND(lat, 2)`), or a
-- positional `1` (nth SELECT column). See `Parser/GroupBy.lean` for how the group *key* is built.
syntax "SELECT " (" DISTINCT ")? sql_cols " FROM " sql_from (" WHERE " term)?  (" GROUP " " BY " term,* (" HAVING " term)?)? (" ORDER " " BY " sql_order_item,*)? (" LIMIT " num)? (" OFFSET " num)? (";")? : sql_query

-- Binary set operators on whole queries, as one keyword-parameterised production. Our relations
-- are `Finset`s (sets), so `UNION ALL` maps to set `union` too (no bag semantics).
declare_syntax_cat sql_setop
syntax " UNION " " ALL " : sql_setop
syntax " UNION " : sql_setop
syntax " INTERSECT " : sql_setop
syntax " EXCEPT " : sql_setop
syntax:40 sql_query:40 sql_setop sql_query:41 : sql_query

-- Parenthesised query, for grouping set-ops: `a UNION (a INTERSECT b)`.
syntax:max "(" sql_query ")" : sql_query

-- Common table expressions: `WITH x AS (q), y AS (q) SELECT …` (non-recursive). Each CTE is a local
-- relation binding, inlined at every reference (`Parser/Query.lean`). `WITH RECURSIVE` is out of
-- scope — it is not accepted by this grammar.
declare_syntax_cat sql_cte
syntax ident "AS" "(" sql_query ")" : sql_cte
syntax:max "WITH" sql_cte,+ sql_query : sql_query

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
-- `x IS NULL` / `x IS NOT NULL` — 2-valued even on NULL input (`Option.isNone`/`isSome`).
syntax:50 term:51 " IS " " NULL " : term
syntax:50 term:51 " IS " " NOT " " NULL " : term
-- `COALESCE(x, d)` / `IFNULL(x, d)` — first non-null; `NULLIF(a, b)` — NULL when equal, else `a`.
-- `COALESCE`/`CONCAT` are variadic (folded to the 2-arg forms).
syntax:max "COALESCE" "(" term,+ ")" : term
syntax:max "IFNULL" "(" term "," term ")" : term
syntax:max "NULLIF" "(" term "," term ")" : term
macro_rules
  | `($x IS NULL)      => `(Option.isNone $x)
  | `($x IS NOT NULL)  => `(Option.isSome $x)
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

-- `REGEXP_SUBSTR`/`REGEXP_REPLACE` accept extra positional args (position, occurrence, flags) — drop.
syntax:max "REGEXP_SUBSTR" "(" term "," term "," term,+ ")" : term
syntax:max "REGEXP_REPLACE" "(" term "," term "," term "," term,+ ")" : term
open Lean in
macro_rules
  | `(REGEXP_SUBSTR($s, $p, $_rest,*))       => `($(mkIdent `LeanDatabase.Scalar.regexpSubstr) $s $p)
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

-- SQL `CASE WHEN c1 THEN v1  WHEN c2 THEN v2 … ELSE d END` → nested `if _ then _ else _`.
-- The condition is forced to `Bool` (`($c : Bool)` coerces a `Decidable` `Prop` like `age > 30` to
-- `decide (…)`), so a `CASE` condition has the SAME shape as a `WHERE` predicate — one Bool lemma
-- (`groupSum_case_eq_groupSum_where`) then folds `SUM(CASE)` into the matching `WHERE`+`SUM`.
syntax:90 "CASE" ( "WHEN" term "THEN" term ) + "ELSE" term "END" : term
macro_rules
  | `(CASE $[WHEN $cs THEN $vs]* ELSE $d END) => do
      let mut acc : Term := d
      for (c, v) in (cs.zip vs).reverse do
        acc ← `(if ($c : Bool) then $v else $acc)
      return acc

-- `CASE WHEN … THEN … END` with an explicit `ELSE NULL` — the result is `Option`-typed
-- (`some v` on a match, `none` otherwise). `NULL` appears *only* bound here, never as a standalone
-- term, so `col = NULL` still cannot be written (the 3VL trap stays unwriteable).
syntax:90 "CASE" ( "WHEN" term "THEN" term ) + "ELSE" "NULL" "END" : term
macro_rules
  | `(CASE $[WHEN $cs THEN $vs]* ELSE NULL END) => do
      let mut acc : Term ← `(none)
      for (c, v) in (cs.zip vs).reverse do
        acc ← `(if ($c : Bool) then some $v else $acc)
      return acc

-- `CASE WHEN … THEN … END` *without* `ELSE`. Its full semantics is `ELSE NULL`, which needs the
-- Phase-4 NULL layer we don't have yet — so there is deliberately **no** general term macro, and it
-- errors in an ordinary scalar position rather than silently defaulting the missing branch to `0`
-- (which would be wrong for `SUM`/`AVG`/`MIN`). It is meaningful only in the aggregate-argument
-- position `COUNT(CASE WHEN p THEN _ END)`, where `COUNT` skips the NULLs; `liftAggExprs`
-- intercepts exactly that shape and rewrites it to the indicator sum.
syntax:90 "CASE" ( "WHEN" term "THEN" term ) + "END" : term

-- Simple `CASE e WHEN v1 THEN r1 … [ELSE d] END` → the searched form comparing `e == vᵢ`.
syntax:90 "CASE" term ( "WHEN" term "THEN" term ) + "ELSE" term "END" : term
syntax:90 "CASE" term ( "WHEN" term "THEN" term ) + "END" : term
macro_rules
  | `(CASE $e:term $[WHEN $vs THEN $rs]* ELSE $d END) => do
      let cs ← vs.mapM fun v => `($e == $v)
      `(CASE $[WHEN $cs THEN $rs]* ELSE $d END)
  | `(CASE $e:term $[WHEN $vs THEN $rs]* END) => do
      let cs ← vs.mapM fun v => `($e == $v)
      `(CASE $[WHEN $cs THEN $rs]* END)


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
      if i < a.size then `(CASE $[WHEN $cs THEN $vs]* ELSE $(a[i]!) END)
      else `(CASE $[WHEN $cs THEN $vs]* ELSE NULL END)
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
syntax "REAL" : sql_cast_type
syntax "NUMERIC" : sql_cast_type
syntax "DECIMAL" : sql_cast_type
syntax "STRING" : sql_cast_type
syntax "TEXT" : sql_cast_type
syntax "VARCHAR" : sql_cast_type
syntax "DATE" : sql_cast_type
syntax "TIMESTAMP" : sql_cast_type
syntax "DATETIME" : sql_cast_type
syntax "BOOLEAN" : sql_cast_type
syntax "VARIANT" : sql_cast_type
syntax "CHAR" : sql_cast_type
-- Sized variants `VARCHAR(n)` / `NUMBER(p,s)` / … (the size is discarded). Higher priority so the
-- bare forms don't win and leave `(n)` dangling.
syntax (priority := high) "VARCHAR(" num ")" : sql_cast_type   -- `VARCHAR(` is a glued DDL token
syntax (priority := high) "CHAR" "(" num ")" : sql_cast_type
syntax (priority := high) "NUMBER" "(" num,+ ")" : sql_cast_type
syntax (priority := high) "NUMERIC" "(" num,+ ")" : sql_cast_type
syntax (priority := high) "DECIMAL" "(" num,+ ")" : sql_cast_type
syntax:max "CAST" "(" term "AS" sql_cast_type ")" : term
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
