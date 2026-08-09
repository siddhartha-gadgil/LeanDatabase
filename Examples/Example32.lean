import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean

/-!
# Example 32 — semi-structured (VARIANT) path access

Path access `v:key` and `v['key']` extract a sub-field of a semi-structured column. Modelled as an
opaque `VARIANTGET` (the sub-field has no value we interpret), so it cancels identically on both sides
and a following `::TYPE` cast is the real coercion. Rewritten at the string level (`normalizeSqlLiterals`)
so the `:` operator never clashes with Lean's type ascription.
-/

namespace Example32

CREATE TABLE events (id INT, payload STRING)

/-- Colon and bracket path access, a `::` cast on a path, and a commuted `WHERE`. -/
theorem path_access :
    sql%([events_schema])
        "SELECT payload:user AS u, payload['device'] AS d, payload:amount::INT AS a FROM events WHERE id > 1 AND id < 9"
      = sql%([events_schema])
        "SELECT payload:user AS u, payload['device'] AS d, payload:amount::INT AS a FROM events WHERE id < 9 AND id > 1" := by
  sql_equiv

end Example32
