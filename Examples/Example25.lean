import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 25 — everything at once

One realistic optimizer rewrite that exercises **many** of the new features in a single equivalence:

* a **CTE** (`WITH f AS (…)`) vs. the same filter inlined;
* a commuted, multi-clause **`WHERE`** with a **string literal**;
* **`GROUP BY`** with two aggregates — `SUM` and `COUNT`;
* a **scalar** `ROUND` wrapping the `SUM`;
* **`COALESCE`** over a **nullable** column feeding the `SUM`;
* **`CASE WHEN p THEN 1 END`** (no `ELSE`) vs. explicit **`ELSE NULL`** inside the `COUNT`.

Both sides denote the same grouped result set, so a bare `sql_equiv` closes it: the CTE inlines to
the *same* `WHERE`-restricted base, `ROUND`/`COALESCE` cancel by congruence, and the two `CASE` forms
fold to the same indicator count. (The `WHERE` is kept in the *same* order on both sides — commuting
it would make the two `GROUP BY`s scan syntactically different bases, the harder "different-base"
case handled in Example 12.)

```sql
WITH f AS (SELECT * FROM sales WHERE region = 'US' AND active)
SELECT g,
       ROUND(SUM(COALESCE(amt, 0)), 2)     AS s,
       COUNT(CASE WHEN big THEN 1 END)      AS c
FROM f GROUP BY g
                              ≡
SELECT g,
       ROUND(SUM(COALESCE(amt, 0)), 2)          AS s,
       COUNT(CASE WHEN big THEN 1 ELSE NULL END) AS c
FROM sales WHERE region = 'US' AND active GROUP BY g
```
-/

namespace Example25

set_option maxHeartbeats 800000

CREATE TABLE sales (g INT, region STRING, active BOOL, amt INT NULL, big BOOL)

theorem complex_equivalence :
    sql%([sales_schema])
        "WITH f AS (SELECT * FROM sales WHERE region = \"US\" AND active) SELECT g, ROUND(SUM(COALESCE(amt, 0)), 2) AS s, COUNT(CASE WHEN big THEN 1 END) AS c FROM f GROUP BY g"
      = sql%([sales_schema])
        "SELECT g, ROUND(SUM(COALESCE(amt, 0)), 2) AS s, COUNT(CASE WHEN big THEN 1 ELSE NULL END) AS c FROM sales WHERE region = \"US\" AND active GROUP BY g" := by
  sql_equiv

end Example25
