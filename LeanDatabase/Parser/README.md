# Extending the SQL parser

The parser turns an SQL string into a `TypedRelation` term. Each kind of extension has **one home** —
add there and it composes with everything else.

| To add… | Do this |
|---|---|
| **Scalar function** (`ROUND`, `TO_DATE`, `CONCAT`, …) | one `opaque` in `Operators/Scalar.lean` + **one line** in the `scalarN` table in `Parser/Syntax.lean`: `scalar1 "SQRT" "sqrtOf"` (arity 1/2/3) declares the syntax and the rewrite together. Non-uniform ones (special emission, e.g. `NVL`, `IFF`) are `macro:max` one-liners just below the table. |
| **Aggregate** (`SUM`, `COUNT`, `MIN`, …) | an `AggKind` constructor + its `op` / `summand` / `wrapNat` / `resultType` lines in `Parser/Context.lean`, plus a match arm in `liftAggExprs` (`Parser/Query.lean`). To allow it as a scalar subquery, add a case to the `kind` match in `elabScalarSubquery`. |
| **Clause** (`DISTINCT` / `WHERE` / `GROUP BY` / `HAVING` / `ORDER BY` / `LIMIT`) | the single unified SELECT arm in `elabSqlQueryCore`: read the new optional slot once. It then applies to every query shape (grouped and ungrouped alike). |
| **FROM form** (a join kind, an alias form) | a `productPair` arm in `Parser/Query.lean`; if it binds an alias, also add it to `collectAliases` (`Parser/Syntax.lean`). |
| **Surface / dialect** (quoting, `::` casts, 3-part names, case) | `normalizeSqlLiterals` (a string pass) and `lowerIdents` (identifier case-folding) in `Parser/Query.lean`. |

## The elaboration pipeline

`normalizeSqlLiterals` (string) → parse → `lowerIdents` → `expandNames` (resolve bare/qualified column
refs) → `elabSqlQueryCore`, whose SELECT arm runs: **FROM → WHERE → (project / group + aggregate +
HAVING) → DISTINCT → ORDER BY / LIMIT**.

## Soundness discipline

New features must never let `sql_equiv` prove a false equivalence. Prefer making an unsound claim a
*type error* (e.g. `AVG`/`CAST` are real `Rat`, so `AVG = SUM/COUNT` doesn't typecheck) or *unprovable*
(opaque scalars) over silently equating things. When a construct can't be modelled, fail loudly rather
than approximate.
