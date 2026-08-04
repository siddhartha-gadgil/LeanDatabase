import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 31 — breadth of scalar functions

A wide mix of scalar functions across a query. Each is `opaque` (or a genuine conditional), so it
cancels identically on both sides of an equivalence and never launders an unsound rewrite — here the
two `WHERE` conjuncts commute while a numeric, string, date, and conditional function each ride along.
-/

namespace Example31

CREATE TABLE events (id INT, qty INT, name STRING, ts STRING, amt INT NULL)

/-- Numeric (`MOD`, `POWER`, `GREATEST`), string (`INITCAP`, `LPAD`), date (`DATEDIFF`, `QUARTER`),
and conditional (`IFF`, `NVL`) functions together; the `WHERE` conjuncts commute. -/
theorem many_functions :
    sql%([events_schema])
        "SELECT MOD(qty, 2) AS parity, GREATEST(qty, 10) AS g, INITCAP(name) AS nm, QUARTER(ts) AS q, IFF(qty > 5, qty, 0) AS capped, NVL(amt, 0) AS a FROM events WHERE qty > 1 AND id < 100"
      = sql%([events_schema])
        "SELECT MOD(qty, 2) AS parity, GREATEST(qty, 10) AS g, INITCAP(name) AS nm, QUARTER(ts) AS q, IFF(qty > 5, qty, 0) AS capped, NVL(amt, 0) AS a FROM events WHERE id < 100 AND qty > 1" := by
  sql_equiv

/-- Nested functions compose: `POWER(SIGN(qty), 2)` cancels with itself over a commuted `WHERE`. -/
theorem nested_functions :
    sql%([events_schema]) "SELECT POWER(SIGN(qty), 2) AS x FROM events WHERE qty > 1 AND qty < 9"
      = sql%([events_schema]) "SELECT POWER(SIGN(qty), 2) AS x FROM events WHERE qty < 9 AND qty > 1" := by
  sql_equiv

end Example31
