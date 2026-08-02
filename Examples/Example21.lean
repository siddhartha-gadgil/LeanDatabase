import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 21 — the new surface features, one identity each

A single reference file for the parser features added in Phases 1–4. Each is proved by a bare
`sql_equiv`. For the *same* features shown in context next to an older rewrite see Example 2 (CTE)
and Example 18 (scalar); for all of them mixed into one query see Example 25.

Sections: qualified star · `CASE` without `ELSE` · scalar functions · `CAST` · CTE · `NULL`.
-/

namespace Example21

/-! ## Qualified star `t.*` -/
CREATE TABLE sa (a INT, b STRING)
CREATE TABLE sb (c INT, d STRING)

/-- `SELECT t.*` is the full, in-order column list of `t`. -/
theorem star_eq_explicit :
    sql%([sa_schema]) "SELECT sa.* FROM sa" = sql%([sa_schema]) "SELECT a, b FROM sa" := by
  sql_equiv

/-- Across a join `t.*` keeps only `t`'s columns, not the other table's. -/
theorem star_join :
    sql%([sa_schema, sb_schema]) "SELECT sa.* FROM sa, sb"
      = sql%([sa_schema, sb_schema]) "SELECT sa.a, sa.b FROM sa, sb" := by
  sql_equiv

/-! ## `CASE … END` without `ELSE` (aggregate position) -/
CREATE TABLE evt (g INT, active BOOL, v INT)

/-- `COUNT(CASE WHEN p THEN 1 END)` == the explicit indicator sum (COUNT skips the NULLs). -/
theorem count_case_eq_sum_indicator :
    sql%([evt_schema]) "SELECT COUNT(CASE WHEN active THEN 1 END) AS c FROM evt GROUP BY g"
      = sql%([evt_schema]) "SELECT SUM(CASE WHEN active THEN 1 ELSE 0 END) AS c FROM evt GROUP BY g" := by
  sql_equiv

/-- The THEN value is irrelevant to the count; and explicit `ELSE NULL` matches the no-`ELSE` form. -/
theorem count_case_else_null :
    sql%([evt_schema]) "SELECT COUNT(CASE WHEN active THEN v ELSE NULL END) AS c FROM evt GROUP BY g"
      = sql%([evt_schema]) "SELECT COUNT(CASE WHEN active THEN 1 END) AS c FROM evt GROUP BY g" := by
  sql_equiv

/-! ## Scalar functions (opaque) and `CAST` (a real coercion) -/
CREATE TABLE sc (g INT, v INT, d STRING, active BOOL)

/-- `ROUND(v,2)` cancels by congruence while a commuted `WHERE` closes. -/
theorem round_cancels :
    sql%([sc_schema]) "SELECT ROUND(v, 2) AS r FROM sc WHERE active AND g > 3"
      = sql%([sc_schema]) "SELECT ROUND(v, 2) AS r FROM sc WHERE g > 3 AND active" := by
  sql_equiv

/-- `YEAR(d)` elaborates to an `Int` predicate. -/
theorem year_predicate :
    sql%([sc_schema]) "SELECT * FROM sc WHERE YEAR(d) = 2023 AND active"
      = sql%([sc_schema]) "SELECT * FROM sc WHERE active AND YEAR(d) = 2023" := by
  sql_equiv

/-- `CAST(g AS INT)` on an int column is the identity; `CAST(g AS FLOAT)` is a real `Int → Rat`
    coercion (so `SELECT CAST(g AS FLOAT)` is deliberately *not* provably `SELECT g`). -/
theorem cast_int_identity :
    sql%([sc_schema]) "SELECT CAST(g AS INT) AS x FROM sc"
      = sql%([sc_schema]) "SELECT g AS x FROM sc" := by
  sql_equiv

/-! ## Common table expressions (`WITH`) -/
CREATE TABLE ct (a INT, b INT)

/-- A projecting CTE collapses (the two `mapByList`s fuse). -/
theorem cte_projected :
    sql%([ct_schema]) "WITH x AS (SELECT a, b FROM ct) SELECT a FROM x"
      = sql%([ct_schema]) "SELECT a FROM ct" := by
  sql_equiv

/-- A chained CTE (`y` references `x`) flattens to one filtered scan. -/
theorem cte_chained :
    sql%([ct_schema]) "WITH x AS (SELECT * FROM ct WHERE a > 3), y AS (SELECT * FROM x WHERE b > 1) SELECT * FROM y"
      = sql%([ct_schema]) "SELECT * FROM ct WHERE a > 3 AND b > 1" := by
  sql_equiv

/-! ## `NULL` (sound 2-valued slice) -/
CREATE TABLE nu (id INT, note STRING NULL, amt INT NULL)

/-- `IS NULL` / `IS NOT NULL` are 2-valued `Bool` predicates that commute with ordinary ones. -/
theorem is_null_commutes :
    sql%([nu_schema]) "SELECT * FROM nu WHERE note IS NULL AND id > 3"
      = sql%([nu_schema]) "SELECT * FROM nu WHERE id > 3 AND note IS NULL" := by
  sql_equiv

/-- `COALESCE(amt, 0) : Int` projects and cancels by congruence over a commuted `WHERE`. -/
theorem coalesce_projects :
    sql%([nu_schema]) "SELECT COALESCE(amt, 0) AS a FROM nu WHERE id > 1 AND id < 9"
      = sql%([nu_schema]) "SELECT COALESCE(amt, 0) AS a FROM nu WHERE id < 9 AND id > 1" := by
  sql_equiv

end Example21
