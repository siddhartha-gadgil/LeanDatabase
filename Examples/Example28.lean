import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 28 — the audit-unlock features, combined (C1/C2/C3)

One realistic optimizer rewrite that only elaborates because of the `report.md` follow-ups:
**table aliases** (`FROM sales AS s`), **inner `JOIN` composing with `GROUP BY`/`ORDER BY`** (the
clause-combination matrix, C1), a **single-quoted** string literal (C3), and an opaque **scalar**
over the aggregate. The rewrite commutes the two `WHERE` conjuncts and the two `AND`s in the join's
`ON`-derived filter — same result set, so a bare `sql_equiv` closes it.

Also pins the S1 soundness boundary: `ORDER BY … LIMIT` keeps its sort key (`limit` is opaque in it),
so the two ordered-limited sides prove equal *only* because they share the same key.
-/

namespace Example28

CREATE TABLE sales (region STRING, dept INT, amt INT, d STRING)
CREATE TABLE depts (dept INT, active BOOL)

/-- Aliased inner join + `GROUP BY` + `ORDER BY`, single-quoted literal, `ROUND` over the `SUM`:
the `WHERE` conjuncts commute. -/
theorem aliased_join_group_order :
    sql%([sales_schema, depts_schema])
        "SELECT s.dept, ROUND(SUM(s.amt), 2) AS total FROM sales AS s JOIN depts AS dd ON s.dept = dd.dept WHERE s.region = 'US' AND dd.active GROUP BY s.dept ORDER BY s.dept"
      = sql%([sales_schema, depts_schema])
        "SELECT s.dept, ROUND(SUM(s.amt), 2) AS total FROM sales AS s JOIN depts AS dd ON s.dept = dd.dept WHERE dd.active AND s.region = 'US' GROUP BY s.dept ORDER BY s.dept" := by
  sql_equiv

/-- `GROUP BY … ORDER BY … LIMIT` with the same sort key on both sides: closes by `limit_congr`
over the commuted `WHERE`. Dropping the `ORDER BY` on one side would *not* prove equal (S1). -/
theorem grouped_order_limit :
    sql%([sales_schema])
        "SELECT dept, SUM(amt) AS s FROM sales WHERE region = 'US' AND dept > 2 GROUP BY dept ORDER BY dept LIMIT 10"
      = sql%([sales_schema])
        "SELECT dept, SUM(amt) AS s FROM sales WHERE dept > 2 AND region = 'US' GROUP BY dept ORDER BY dept LIMIT 10" := by
  sql_equiv

/-- A **self-join**: the same base table under two aliases gets distinct columns (`s1.*` vs `s2.*`),
so `sales AS s1 JOIN sales AS s2` is a genuine self cross-product — the canonical idiom that used to
be rejected (S3). Here the `ON` and `WHERE` conjuncts commute. -/
theorem self_join :
    sql%([sales_schema])
        "SELECT s1.amt FROM sales AS s1 JOIN sales AS s2 ON s1.dept = s2.dept WHERE s2.amt > s1.amt AND s1.region = 'US'"
      = sql%([sales_schema])
        "SELECT s1.amt FROM sales AS s1 JOIN sales AS s2 ON s1.dept = s2.dept WHERE s1.region = 'US' AND s2.amt > s1.amt" := by
  sql_equiv

end Example28
