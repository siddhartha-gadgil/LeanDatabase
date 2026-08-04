import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 29 — the dialect front-end: quoted identifiers & 3-part names (C3)

The corpus writes `"…"` for **identifiers** (`t."VARIABLE"`, `"DATE"`) and 3-part table names
(`"DB"."SCHEMA"."TABLE"`), and `'…'` for **string literals** — the SQL standard. Both are now
normalized before parsing (`normalizeSqlLiterals`): double-quoted identifiers are unquoted, dotted
table names resolve to the declared table by their last component, single-quoted strings become the
grammar's string form. This is what lets a raw corpus query parse at all.
-/

namespace Example29

CREATE TABLE TIMESERIES (VARIABLE INT, val INT, DATE STRING)
CREATE TABLE ATTRIBUTES (VARIABLE INT, name STRING)

/-- Quoted column identifiers and a quoted keyword-name column (`"DATE"`), with a single-quoted
string literal on both sides — the two quoting conventions side by side. -/
theorem quoted_columns :
    sql%([TIMESERIES_schema]) "SELECT t.\"VARIABLE\" FROM TIMESERIES AS t WHERE t.\"DATE\" = 'x'"
      = sql%([TIMESERIES_schema]) "SELECT VARIABLE FROM TIMESERIES WHERE DATE = 'x'" := by
  sql_equiv

/-- A 3-part dotted table name resolves to the declared table by its last component. -/
theorem three_part_name :
    sql%([TIMESERIES_schema]) "SELECT val FROM \"MYDB\".\"PUBLIC\".\"TIMESERIES\" WHERE val > 1"
      = sql%([TIMESERIES_schema]) "SELECT val FROM TIMESERIES WHERE val > 1" := by
  sql_equiv

/-- The whole corpus shape at once: 3-part quoted tables, aliases, quoted `ON` columns, and an
`IN`-list rewritten as an `OR`-chain — the first `crossskill` record's difference. -/
theorem corpus_join :
    sql%([TIMESERIES_schema, ATTRIBUTES_schema])
      "SELECT t.val FROM \"DB\".\"SC\".\"TIMESERIES\" AS t JOIN \"DB\".\"SC\".\"ATTRIBUTES\" AS a ON t.\"VARIABLE\" = a.\"VARIABLE\" WHERE t.val IN (1, 2)"
      = sql%([TIMESERIES_schema, ATTRIBUTES_schema])
      "SELECT t.val FROM TIMESERIES AS t JOIN ATTRIBUTES AS a ON t.VARIABLE = a.VARIABLE WHERE t.val = 1 OR t.val = 2" := by
  sql_equiv

end Example29
