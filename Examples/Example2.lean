import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 2 — Cascading selection (the "Index Merge" rewrite)

Two `WHERE` filters applied one after another equal a single filter testing both conditions
at once. A planner uses this to collapse a multi-pass scan into one pass (or a single
composite index seek).

## The two SQL queries being proved equivalent

```sql
-- query_MultiPass: filter for active, then filter that result for high value (two passes)
SELECT * FROM (
  SELECT * FROM r WHERE is_active
) WHERE is_high_value;

-- query_SinglePass: test both conditions in one pass
SELECT * FROM r WHERE is_high_value AND is_active;
```

The **new** `WITH` (CTE) form (Phase 3) expresses the same first pass as a named binding rather than
an inline derived table — and proves equal to the same single-pass query. Old (derived table) and
new (CTE) sit side by side below.
-/

namespace Example2

CREATE TABLE table (is_active BOOL, is_high_value BOOL)

/-- Original form: the first pass as an inline derived table `(…) AS r`. -/
theorem query_equivalence :
    sql%([table_schema])
        "SELECT * FROM (SELECT * FROM table WHERE is_active) AS r WHERE is_high_value"
      = sql%([table_schema]) "SELECT * FROM table WHERE is_high_value AND is_active" := by
  sql_equiv

/-- Same rewrite, first pass written as a CTE (`WITH r AS (…)`). -/
theorem query_equivalence_cte :
    sql%([table_schema])
        "WITH r AS (SELECT * FROM table WHERE is_active) SELECT * FROM r WHERE is_high_value"
      = sql%([table_schema]) "SELECT * FROM table WHERE is_high_value AND is_active" := by
  sql_equiv

end Example2
