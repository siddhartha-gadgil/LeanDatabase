import LeanDatabase.Parser.Syntax

/-!
# Table aliases

A `FROM` item can be renamed: `FROM employees AS e` (or bare `FROM employees e`) lets the rest of the
query write `e.salary` instead of `employees.salary`. Aliases are also what make a **self-join**
expressible — `FROM emp a JOIN emp b ON a.manager = b.id` needs two distinct names for one table.

We normalise aliases away before elaborating, so an aliased query and its un-aliased twin denote the
*same* relation (and CTE resolution, which keys on base-qualified names, keeps working):

    SELECT e.salary FROM employees AS e   ≡   SELECT salary FROM employees

`collectAliases` gathers the `(alias, baseTable)` pairs from a parsed query; `baseifyName` /
`baseifyIdents` rewrite an `alias.col` reference back to `base.col`.
-/

open Lean

namespace LeanDatabase

/-- Collect `(alias, baseTable)` pairs from every `t AS x` anywhere in a query, so `expandNames` can
rewrite `x.col → base.col`. A dotted base (`"DB"."SC"."T"` → `DB.SC.T`) is reduced to its last
component `T`, since that is the declared table its columns are qualified under. -/
partial def collectAliases : Syntax → List (Name × Name) :=
  let baseOf : Syntax → Name := fun t => let n := t.getId; (n.components.getLast?).getD n
  fun stx =>
    let here := match stx with
      | `(sql_from| $t:ident AS $x:ident) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from JOIN $t:ident AS $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from CROSS JOIN $t:ident AS $x:ident) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from LEFT JOIN $t:ident AS $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from LEFT OUTER JOIN $t:ident AS $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from RIGHT JOIN $t:ident AS $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from RIGHT OUTER JOIN $t:ident AS $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from FULL JOIN $t:ident AS $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from FULL OUTER JOIN $t:ident AS $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $t:ident $x:ident) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from JOIN $t:ident $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from CROSS JOIN $t:ident $x:ident) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from LEFT JOIN $t:ident $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from LEFT OUTER JOIN $t:ident $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from RIGHT JOIN $t:ident $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from RIGHT OUTER JOIN $t:ident $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from FULL JOIN $t:ident $x:ident ON $_) => [(x.getId, baseOf t)]
      | `(sql_from| $_:sql_from FULL OUTER JOIN $t:ident $x:ident ON $_) => [(x.getId, baseOf t)]
      | _ => []
    stx.getArgs.foldl (fun acc s => acc ++ collectAliases s) here

/-- Subquery/derived-table aliases (`(…) AS x` / `(…) x`). Unlike base-table/CTE aliases these have
no base table to re-qualify to; `expandNames` strips a `x.col` reference to bare `col` so the per-scope
column binding resolves it against the subquery's own output. -/
partial def collectSubqueryAliases : Syntax → List Name :=
  fun stx =>
    let here := match stx with
      | `(sql_from| ( $_:sql_query ) AS $x:ident) => [x.getId]
      | `(sql_from| ( $_:sql_query ) $x:ident)    => [x.getId]
      | _ => []
    stx.getArgs.foldl (fun acc s => acc ++ collectSubqueryAliases s) here

/-- CTE names bound by a `WITH`/`WITH RECURSIVE`. A `cte.col` reference (CTE used without a fresh
alias) is stripped to `col` like a subquery alias, since a CTE's columns keep their own bare names. -/
partial def collectCteNames : Syntax → List Name :=
  fun stx =>
    let here := match stx with
      | `(sql_cte| $name:ident AS ( $_:sql_query ))          => [name.getId]
      | `(sql_cte| $name:ident ( $_,* ) AS ( $_:sql_query )) => [name.getId]
      | _ => []
    stx.getArgs.foldl (fun acc s => acc ++ collectCteNames s) here

/-- Map an alias prefix back to its base table (`e1.col → emp.col`), so a projected column's *output*
label is base-qualified regardless of aliasing — an aliased and non-aliased query then agree, and CTE
column resolution (which relies on base-qualified names) keeps working. -/
def baseifyName (aliasMap : List (Name × Name)) (n : Name) : Name :=
  aliasMap.foldl (fun acc (al, base) =>
    if al != acc && al.isPrefixOf acc then acc.replacePrefix al base else acc) n

/-- Rewrite every `ident` in a syntax tree by `baseifyName` — used to point `ORDER BY` refs at the
base-qualified output labels. -/
def baseifyIdents (aliasMap : List (Name × Name)) (stx : Syntax) : Syntax :=
  stx.replaceM (m := Id) fun s => match s with
    | .ident info raw val pre =>
      let val' := baseifyName aliasMap val
      -- Rewrite the raw substring too, so a name derived from the *source text* (`autoColName` for an
      -- unaliased computed column) is alias-independent as well.
      let raw' := if val' == val then raw else (toString val').toRawSubstring
      some (.ident info raw' val' pre)
    | _ => none

end LeanDatabase
