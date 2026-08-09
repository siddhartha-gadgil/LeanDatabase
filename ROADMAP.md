# Roadmap: from 2.6% to 100% of `crossskill_equivalent_sql.jsonl`

Target corpus: **351 records / 1266 queries**. A record counts as *covered* only when **every** variant
in it parses and elaborates, since equivalence is proved per variant-pair.

Baseline today: **33 / 1266 queries (2.6%)**, **2 / 351 records (0.6%)**.

---

## The chosen semantics (decided)

**We commit to set semantics: `TypedRelation.rows : Finset`, and we assume every base table has
distinct rows.** Equivalence therefore means *"the two queries denote the same result set."* We are
**not** building the `Multiset` (bag) or `List` (ordered) layers — that decision is final, and the
Multiset phases below (0.4–0.6) are struck out accordingly.

This is a real spec, not a fudge, but it draws a hard boundary. Under "same result set":

| construct | status under our spec | why |
|---|---|---|
| `DISTINCT` | **identity** (sound) | every relation is already a set |
| `ORDER BY` | **identity** (sound) | row order is not observable on a `Finset` |
| `UNION ALL` | **= `UNION`** (sound *as sets*) | the result *set* of a bag-union is its set-union |
| `WHERE` / `JOIN` / `GROUP BY` / scalar aggregates | faithful | set-relational algebra |
| `LIMIT k` | **cannot be modelled** (see Bug 0.B) | picking *which* k rows needs an order we don't have |
| window fns (`ROW_NUMBER`, `RANK`) | **out of scope by design** | meaningless without row order |
| `COUNT(*)` / `SUM` over duplicates | approximated (set-count) | duplicates are gone; the distinct-rows assumption covers base tables, not derived ones |

So the honest coverage ceiling is **not 100%**. Window functions (27% of the corpus) and true
top-N-by-`LIMIT` semantics are permanently out of scope. The reachable target is **the Phase 5 line
— ~73% of queries / ~68% of records** (see the curve below). Everything past that needs a semantics
we've chosen not to build.

Dependency spine: `Phase 0 (soundness)` → `Phase 4 (NULL)` → `Phase 5 (outer joins)`. Phases 1–3 are
independent and can proceed in parallel. Phase 6 (windows) is **dropped**.

---

## Coverage unlock curve (measured, not estimated)

| after phase | queries OK | records fully OK |
|---|---|---|
| P0 baseline (today) | 33 (2.6%) | 2 (0.6%) |
| P1 cheap syntax | 95 (7.5%) | 13 (3.7%) |
| P2 opaque scalars | 213 (16.8%) | 34 (9.7%) |
| P3 CTE | 557 (44.0%) | 112 (31.9%) |
| P4 NULL + 3VL | 782 (61.8%) | 184 (52.4%) |
| P5 outer joins | 926 (73.1%) | 238 (67.8%) |
| ~~P6 window functions~~ | ~~1266 (100%)~~ | **out of scope (needs row order)** |

**P5 (73.1% / 67.8%) is the ceiling under set semantics**, not a waypoint to 100%. The last ~27% of
queries use window functions, which cannot be modelled on a `Finset`.

**P3 (CTE) is the single biggest unlock: +27.2 points of queries.** It is also cheap relative to
P4. If only one phase ships, ship P3.

> Note on `LIMIT`: queries with `ORDER BY … LIMIT k` still *parse* and count toward the curve, and an
> equivalence closes when both sides carry the *same* `LIMIT k` over congruent subqueries (via
> `limit_congr`, Phase 0). What is out of scope is a *top-N semantic* equivalence — two variants that
> differ in how `LIMIT` selects rows. Those need the ordered layer we chose not to build.

---

# Audit follow-ups (`report.md`, 2026-08)

An external review (`report.md`) found soundness bugs, coverage gaps, and stale scaffolding. Status:

| id | issue | status |
|---|---|---|
| S1 | `ORDER BY` erased under `LIMIT` → false top-N equalities | **fixed.** `limit` is now opaque in the order key too (`Operators/OrderLimit.lean`); `ORDER BY a LIMIT k ≠ ORDER BY b LIMIT k`. Emitted at `Parser/Query.lean` (`applyOrderLimit`). |
| S2 | `AVG` = truncating `Int` division | **fixed.** `groupAvg`/`groupAvgDistinct` return exact `Rat`; `AVG = SUM/COUNT` is now a *type error* (like `CAST`). |
| S3 | self-correlated / self-join silently drops the outer binder | **fixed.** An aliased table's columns are renamed to the alias prefix (`productPair`), so two aliases of the same base table get distinct columns and a self-join is a genuine self cross-product. Output labels are mapped back to base (`baseifyName`) so aliased/non-aliased queries still agree and CTEs keep resolving. See Example 28 `self_join`. |
| S4 | ambiguous unqualified column resolves silently to the first | **open (needs scoped resolution).** A global ambiguity check false-errors on UNION-branch/subquery queries where each scope sees one table; a correct diagnostic needs per-FROM-scope name resolution, which `expandNames` (flat, whole-query) doesn't have. Both sides resolve identically today, so no false positive. |
| C1 | clause-combination matrix holes (`GROUP BY … ORDER BY`, inner `JOIN … GROUP BY`, ungrouped aggregates, …) | **fixed — one unified SELECT arm.** The two SELECT elaborators (plain / GROUP BY) are merged into a single arm reading every optional slot once (`elabSelect`), so all clause combinations compose and a new clause is added in one place. Inner `JOIN`/`CROSS JOIN` in `productPair`; ungrouped aggregates = group over the empty key; `EXISTS`/`IN` in `WHERE` now work with GROUP BY too (the merged arm routes WHERE through `elabWhere` uniformly). |
| C2 | no table aliases | **done.** `FROM t AS x` and aliased-RHS joins (`… JOIN u AS y ON …`, inner + all outer). Aliased columns are renamed to the alias prefix (`productPair`), so self-joins work (see S3); output labels are mapped back to base (`baseifyName`) so aliased/non-aliased queries agree and CTEs keep resolving. |
| C3 | dialect front-end (0 raw corpus queries parse) | **done (surface).** Committed to the SQL-standard convention: single-quote = string, double-quote = identifier. `normalizeSqlLiterals` unquotes `"…"` identifiers, resolves 3-part dotted table names (`"DB"."SC"."T"` → declared `T`), and normalizes `'…'` strings; examples migrated off `"…"`-string literals (transparent). `X::TYPE` postfix casts rewrite to `CAST(X AS TYPE)` (size dropped) reusing the sound cast; case-insensitive identifiers (fold to lowercase); **quoted identifiers unquote into guillemet idents `«…»`** so columns named like keywords (`YEAR`/`COUNT`/`END`, 44% of records) parse; **bare table aliases `FROM t x`** (53% of records, vs 0% using `AS`); **simple `CASE e WHEN v`**; ~40 scalars. **Many-column `CREATE TABLE`** fixed (30-70 cols) via `colTypeOfList` + generic instances. **Semi-structured path access** `v:key` / `v['key']` → opaque `VARIANTGET` (rewritten at the string level so `:` doesn't clash with type ascription; `CAST(str AS INT/FLOAT)` opaque). Measured (`probe.py`): **89/258 non-window first-queries parse** end-to-end. Remaining blockers: **derived-table subqueries in `FROM`** (`FROM (SELECT …)`), deep nesting, and long-tail functions. See Examples 29, 32. |
| I1/I2 | coverage ledger unverified; CI doesn't run the guard | **improved.** `coverage.py` VERIFIED is now a live filesystem check (a recorded pass whose file is absent is *not* counted and is named); the guard is wired into CI and runs VERIFIED-only when the corpus is absent. Root cause remains: `Sf*.lean` proofs are gitignored, so `lake build`/CI never checks them — commit them (or drop the "machine-checked" claim) to close fully. |
| — | dead scaffolding (orphaned `sorry` files, `elabSelectCmd`, `Products` build leak) | **removed.** |

### Shipped in this pass

- [x] **S1** — `LIMIT` opaque in the order key; `ORDER BY … LIMIT` no longer erases the sort key.
- [x] **S2** — `AVG` is exact `Rat` division; `AVG = SUM/COUNT` is now a type error.
- [x] **C1** — clause-combination matrix: GROUP BY composes with `DISTINCT`/`ORDER BY`/`LIMIT`; inner `JOIN`/`CROSS JOIN` in `productPair`.
- [x] **C2** — table aliases `FROM t AS x` + aliased-RHS joins (inner + all outer); self-joins fail loud.
- [x] **C3** — SQL-standard quoting: single-quoted strings normalized, **double-quoted identifiers + 3-part dotted names** (the raw-corpus parse blocker); `EXTRACT` + `TO_DATE`/`TO_TIMESTAMP`/`DATE_TRUNC`/`CONCAT`/`SUBSTR`. See Example 29.
- [x] **I1/I2** — `coverage.py` VERIFIED is a live filesystem check; wired into CI.
- [x] **Hygiene** — deleted orphaned `sorry`-files + `elabSelectCmd` + `Products` leak; `NUMBER/NUMERIC/DECIMAL → Rat`; dead `crossProductRel` collision code; legacy `SQLType.FLOAT → Rat`; unused-section-var warning.
- [x] **`::` casts + more scalars** — `X::TYPE → CAST(X AS TYPE)` (sound); `SPLIT_PART`/`REGEXP_SUBSTR`/`REPLACE`.
- [x] **Case-insensitive identifiers** — schema + query idents fold to lowercase; ungrouped aggregates (`SELECT COUNT(*)`).
- [x] **S3 (self-joins)** — aliased columns renamed per-alias; **3.4 correlated scalar subqueries** — deferred/stash elaboration in projection context.
- [x] **Keyword-collision idents** — quoted `"YEAR"`/`"COUNT"`/`"END"` unquote into guillemet idents `«…»`, immune to keyword tokens (44% of records had such columns).
- [x] **Many-column `CREATE TABLE`** — `colTypeOfList` + generic instances (30-70-col corpus tables no longer fail exhaustiveness).
- [x] **Bare table aliases** `FROM t x`; **semi-structured path access** `v:key`/`v['key']` → opaque `VARIANTGET`.
- [x] **Broad surface/function coverage** — `NOT BETWEEN`, `IS [NOT] TRUE/FALSE/DISTINCT FROM`, `LIMIT…OFFSET`, `NULLS FIRST/LAST`, `USING`, bare-alias derived tables, sized casts, `DECODE`, variadic `COALESCE`/`CONCAT`/`GREATEST`/`LEAST`, and ~40 more functions (see `Parser/Syntax.lean`).
- [ ] **S4 (ambiguous-column diagnostic)** — open (needs scoped resolution).

---

# Phase 0 — Soundness (BLOCKING; do not add features on a broken base)

Under the set-semantics decision, the two items from the audit split apart: one dissolves, one is a
genuine bug even in our own model.

### 0.A — `UNION ALL` aliased to set `union` — **SOUND under our spec; scoping only**
`Parser/Query.lean:85` maps both `UNION` and `UNION ALL` to `` `union ``. Under bag semantics this
would be wrong (`t UNION ALL t` doubles rows). **But we chose set semantics**, where a query denotes
its *result set*, and the result set of `t UNION ALL t` genuinely *is* `t`. So `sql_equiv` proving
`SELECT a FROM t UNION ALL SELECT a FROM t = SELECT a FROM t` is **correct w.r.t. our spec** — not a
bug. The only residual risk is a reader mistaking `=` for bag-equality. Fix is documentation +
naming (0.2), not behaviour. (Known scope limit: a `COUNT(*)` over a `UNION ALL` counts distinct,
not bag — accepted, listed in the semantics table.)

### 0.B — `LIMIT k` is the identity — **GENUINE BUG, even in set semantics**
`Operators/OrderLimit.lean:38-44`: `limit k rel = rel`, `@[simp, grind =]`. This is false *as sets*:
`LIMIT 1` on a 2-row table is a 1-row set ≠ the 2-row set. `sql_equiv` proves
`SELECT * FROM t LIMIT 1 ≡ SELECT * FROM t`. **`Example18` is a live instance** — it asserts
`… ORDER BY age LIMIT 10 = SELECT * FROM table`. `LIMIT` genuinely cannot be modelled on a `Finset`
(no order to pick "first k"), so the honest move is to make it **opaque** — provably equal only to
itself — never the identity.

Contrast with `orderBy`: identity **is** sound under set semantics (order unobservable), so
`orderBy_eq` stays tagged. 0.B touches `limit` only.

### Tasks

- [x] **0.1 Make `limit` opaque (S) — the fix. ✅ DONE.** `Operators/OrderLimit.lean`: `def limit`
      → `opaque limit`, deleted `limit_eq` / `limit_card` / `limit_noop_of_card_le`, added
      `limit_congr : r1 = r2 → limit k r1 = limit k r2`. `SQLEquiv.lean`: added
      `| refine limit_congr ?_` as the first alternative in `sql_equiv`. `Example18` fixed (both
      sides carry `LIMIT 10`; now a true theorem). `limit k t = t` is no longer provable. `orderBy`
      left as sound identity.
- [x] **0.2 Name the claim honestly (S). ✅ DONE.** A module doc-block on `sql_equiv` in
      `SQLEquiv.lean` spells out that it proves **set-equivalence** ("same result set for every input
      table"), not bag/ordered SQL: `ORDER BY` erased, `UNION ALL` = set `union` (with the 0.A note
      discharged here), `LIMIT` opaque. The README "What it does" section mirrors it for readers.
- [ ] **0.3 Distinct-rows discipline (M).** The blanket "base tables have distinct rows" assumption
      makes set = bag *at the leaves* (so `SUM`/`COUNT` over a base table are honest). Make it
      real, not just prose: an optional `PRIMARY KEY` on `CREATE TABLE` emitting
      `hkey : Function.Injective (key)`, available as a hypothesis where a proof needs it (e.g. to
      justify `SUM` not double-counting). Does **not** extend to derived tables — a `UNION ALL`
      feeding an aggregate is still set-count.
<!-- - [ ] **0.4 Multiset core (XL — the real fix).** Change `TypedRelation.rows` to `Multiset`.
      `LeanDatabase/ListRelationalAlgebra/TypedListRelation.lean` is already a half-built version of
      this: `List` + `List.Perm` setoid + `toFinsetRelation`, and it carries `LinearOrder` on columns
      (which Phase 6 needs). **It is orphaned — nothing imports it — and `RelationalAlgebraList.lean`
      has 16 `sorry`s.** Decide: finish that file, or fold it into the main tower and delete it. Do
      not leave a third parallel algebra.
      Blast radius: 136 `Finset` occurrences, 201 theorems, 140 `@[grind]`/`@[simp]` lemmas,
      30 example files to re-prove.
- [ ] **0.5 Re-tag the automation (L).** `Finset.filter_filter` / `Finset.image_image` in `sql_simp`
      become `Multiset` analogues. Re-audit all 140 tagged lemmas: **every lemma that assumed dedup
      is now either false or needs a `Nodup` hypothesis.** This is where the real work is.
- [ ] **0.6 `DISTINCT` becomes the only route to `Finset` (M).** `distinct` (`Operators/Select.lean`)
      is the coercion `Multiset → Finset`. Re-derive the set-level lemmas as
      `distinct`-conditioned corollaries so existing proofs survive as special cases. -->
<!-- - [ ] **0.7 Ordered top layer (M).** DROPPED — requires the `List` layer we chose not to build.
      `ORDER BY` stays identity (sound); `LIMIT` stays opaque (0.1). -->
- [x] **0.8 Regression guard (S). ✅ DONE.** `Examples/CrossSkill/coverage.py` prints two tracked
      numbers on every run (and in CI, wired after `lake build` in `lean_action_ci.yml`):
      **POTENTIAL** — a transparent regex feature-classifier over all 1266 queries that assigns each
      the earliest roadmap phase unlocking it, reproducing the unlock curve as a measured number; and
      **VERIFIED** — the machine-checked proof tally from `result.json`. The classifier independently
      lands within ~1% of this file's hand-estimated curve (P3 43.8% vs 44.0%, P4 61.5% vs 61.8%,
      P5 72.9% vs 73.1%; window 26.9%, CTE 76%, CAST 33.3% all match), cross-validating both. Note:
      POTENTIAL measures *semantic-feature* reachability (assuming surface normalization), so it
      aligns with the P1+ lines, not the surface-syntax-gated "P0 today = 33". `--json` for CI
      consumption. This is the standing guard 7.3 (`plausible`) will complement.

---

# Phase 1 — Cheap syntax (2.6% → 7.5%)

- [x] **1.1 `ORDER BY … ASC|DESC` (S). ✅ DONE.** Added `sql_order_dir` (`ASC`/`DESC`) and
      `sql_order_item` (= `sql_col` + optional dir) categories in `Parser/Syntax.lean`; `ORDER BY`
      now takes `sql_order_item,*`; `Parser/Query.lean` strips the direction via `sqlOrderCol` and
      elaborates to the existing identity `orderBy`. Direction is provably erased
      (`ORDER BY a DESC = ORDER BY a ASC = unordered`, verified). Unblocks the **60.1%** of queries
      that were dying at parse time on a direction token.
- [x] **1.2 Qualified star `t.*` (S). ✅ DONE.** Added `syntax ident "." "*" : sql_cols` in
      `Parser/Syntax.lean`; the SELECT arm in `Parser/Query.lean` filters `combinedSchema` to the
      columns whose full name has prefix `t` and reuses the explicit-column projection path. Verified:
      `t.* = a, b` (single table) and, across `t, u`, `t.* = t.a, t.b` (picks only `t`'s columns).
- [x] **1.3 `CASE … END` without `ELSE` (S, partial). ✅ DONE (aggregate-argument slice).** Added
      `syntax:90 "CASE" ("WHEN" term "THEN" term)+ "END"` in `Parser/Syntax.lean` with **no** general
      term macro — so a bare CASE-without-ELSE in an ordinary scalar position is *rejected*, never
      silently `ELSE 0`. `liftAggExprs` (`Parser/Query.lean`) intercepts the dominant idiom
      `COUNT(CASE WHEN p THEN _ END)` and rewrites it to the indicator sum
      `SUM(CASE WHEN p THEN 1 … ELSE 0 END)`, folded by `groupSum_case_eq_groupSum_where`. Verified:
      `COUNT(CASE WHEN p THEN 1 END) = SUM(CASE WHEN p THEN 1 ELSE 0 END)`, THEN-value irrelevant to
      the count, and scalar-position CASE-no-ELSE errors. Full `ELSE NULL` semantics still deferred
      to Phase 4.7.

---

# Phase 2 — Opaque scalar functions (7.5% → 16.8%)

`ROUND` 22.2%, `CAST`/`::` 33.3%, date fns 17.1%, string fns 13.4%. These almost always appear
*identically on both sides* of an equivalence, so they cancel and need no axioms.

- [x] **2.1 Scalar registry (M). ✅ DONE (as a shared file + convention, not an enum dispatcher).**
      A uniform `AggKind`-style dispatcher turned out **not** to typecheck for scalars: result types
      differ per function (`YEAR : String → Int`, `ROUND : α → α`, `UPPER : String → String`), so no
      single signature fits. Instead `Operators/Scalar.lean` holds one `opaque` constant per function
      with a documented "add a scalar = one opaque + one macro line" convention, and `Parser/Syntax.lean`
      has the matching syntax/macro table (idents emitted via `mkIdent`, like `LIKE`, since Syntax
      doesn't import Scalar). Shipped: `ROUND` (1&2-arg), `ABS`/`CEIL`/`FLOOR`, `YEAR`/`MONTH`/`DAY`,
      `UPPER`/`LOWER`/`TRIM`/`LENGTH`.
- [x] **2.2 Uninterpreted-by-default (S). ✅ DONE.** Each scalar is an `opaque` constant, so
      `ROUND(x,n) = x` is **unprovable** (soundness: verified `sql_equiv` *fails* to prove
      `SELECT ROUND(v,2) = SELECT v`) while identical calls cancel by congruence — verified
      `ROUND(v,2)` cancels over a commuted `WHERE`, `YEAR(d)=2023` elaborates as an `Int` predicate,
      and `ROUND(SUM(v),3)` composes with the aggregate-lifting path in `GROUP BY`.
- [ ] **2.3 Targeted axioms only where variants differ (M). DEFERRED (by discipline).** `ABS(a-b) =
      ABS(b-a)`, `ROUND` idempotence, etc. would each be an *axiom over an opaque constant* — i.e.
      trust surface. Per this phase's own rule ("only where variants differ"), not adding them
      speculatively: they go in the moment a concrete corpus pair is shown to need one, not before.
- [x] **2.4 `CAST` is not free (M). ✅ DONE.** `CAST(x AS <type>)` is a *type-directed elaborator*
      (`Parser/Context.lean`), not an opaque macro: it inspects the source type. `Int → FLOAT` is the
      genuine `Int → Rat` coercion `Scalar.castIntToFloat` (so downstream division is real, not
      integer — the `sf_bq030` hazard); `Int → INT` is the identity; lossy directions (`FLOAT → INT`,
      casts to string) stay opaque (no laundering risk). Verified: `CAST(a AS FLOAT)` cancels with
      itself, `CAST(a AS INT) = a` on an int, and `SELECT CAST(a AS FLOAT) = SELECT a` is **rejected
      as a type mismatch** (Rat ≠ Int) — the integer/real split is structurally enforced, not merely
      unprovable. The `::` cast form is intentionally unsupported (it would clobber `List.cons`).

---

# Phase 3 — CTE (16.8% → 44.0%) ← **biggest unlock, do this first after Phase 1**

`WITH` appears in **76.6%** of queries. Only **3 queries (0.2%) use `WITH RECURSIVE`** — so the
recursive fixpoint, the genuinely hard part, is almost pure ignorable tail.

- [x] **3.1 Grammar (S). ✅ DONE.** `sql_cte` category + `WITH x AS (q), … SELECT …` in
      `Parser/Syntax.lean`, comma-separated, non-recursive (`WITH RECURSIVE` is not accepted).
- [x] **3.2 Elaborate as a binding (M). ✅ DONE (via inlining, not `let`).** `elabSqlQueryCore` gains
      a threaded `ctes` list; each CTE body is elaborated to a relation over the base vars (`.beta`)
      and looked up by `productPair`, shadowing base tables. Later CTEs may reference earlier ones.
      Chose **inlining** over `withLetDecl` (3.3) — simpler and the shared base fvars are captured by
      the one outer lambda. Column names are kept as the body produced them so `expandNames`
      (base-label-only) resolves outer references.
- [x] **3.3 Make `grind` see through it (M). ✅ DONE.** Added `@[simp, grind =]
      TypedRelation.mapByList_mapByList` — projection fusion via `Finset.image_image`, so a projecting
      CTE (`SELECT a FROM (SELECT a,b …)`) collapses to one `mapByList`. Verified passthrough,
      `WHERE`-carrying, projected-through, and chained (`y` references `x`) CTEs all prove; full build
      green (the global lemma broke nothing).
- [x] **3.4 Scalar subquery in `SELECT` (L). ✅ DONE (uncorrelated + correlated).**
      `(SELECT AGG(x) FROM t [WHERE p])` in a select-list → the whole-relation aggregate
      (`relSum`/`relCount`/`relCountDistinct`). `preprocessScalarSubqueries` (`Parser/Query.lean`) builds
      the inner relation and stashes a `DeferredSubq`, emitting a `sqlDeferredSubq%` placeholder; the
      term elaborator builds the aggregate *inside the projection context*, so a **correlated** inner
      `WHERE` (referencing the outer row) resolves against the outer let-vars and the value is computed
      per outer row. A bare-term `sql_col` production (auto-named) lets the inner aggregate go unaliased.
      See Example 30. (Corpus note: scalar-subquery-in-SELECT is ~2.2%, not the roadmap's earlier 71.2%.)
- [ ] **3.5 `WITH RECURSIVE` (XL).** 3 queries. **Out of scope** — the grammar rejects it.

---

# Phase 4 — `NULL` and three-valued logic (44.0% → 61.8%)

`NULL` appears in **31.3%** of queries; `IS [NOT] NULL` in **29.9%**. This is the second-hardest
phase and it cannot be faked.

**Scope decision:** we shipped the **sound 2-valued slice** (opt-in nullable columns + the constructs
that reduce NULL to `Bool`/a non-null value), *not* full Kleene 3VL. NULL never enters through a bare
literal, so the `WHERE NOT(x = NULL)` trap is unwriteable and a raw `Option` column in a comparison
fails to typecheck. Full 3VL (4.2) and NULL-aware aggregates (4.5) remain deliberately deferred.

- [x] **4.1 Nullable types (M). ✅ DONE (opt-in).** `SQLTypeProxy.nullable` constructor →
      `.type = Option _`; `.type`/`typeExpr`/`DecidableEq`/the probe `.list` extended; a
      `LinearOrder (Option α)` (NULLS-FIRST, via `WithBot`) satisfies the DDL's per-column order.
      DDL: a trailing `NULL` (`amt INT NULL`) marks a column nullable; unmarked columns stay
      non-nullable, so all existing schemas/examples are unchanged.
- [ ] **4.2 Predicates become Kleene (L). DEFERRED (by the scope decision).** The full 3VL rewrite of
      `pAnd`/`pOr`/`pNot` with every predicate lemma re-proved. Not attempted; instead the surface is
      restricted so nothing unsound can be *written* (see scope note). This is the main remaining
      Phase-4 work and stays an explicit, large follow-up.
- [x] **4.3 `IS NULL` / `IS NOT NULL` (S). ✅ DONE.** `Option.isNone`/`isSome` — 2-valued Bool even on
      NULL input. Verified they compose with ordinary `Bool` predicates and commute under `AND`.
- [x] **4.4 `COALESCE`/`IFNULL`/`NULLIF` (S). ✅ DONE.** `COALESCE(x,d)`/`IFNULL(x,d) = x.getD d`
      (non-null result); `NULLIF(a,b) = if a==b then none else some a` (nullable result). Verified
      `COALESCE` projects and cancels by congruence.
- [ ] **4.5 Aggregates skip `NULL` (M). DEFERRED.** Needs the nullable values to flow through the
      aggregate builders (`COUNT(x)` skips nulls, `SUM` of all-nulls is NULL, `AVG` divides by
      non-null count). Pairs with 4.2; not in the 2-valued slice.
- [ ] **4.6 The `NULL` equality quirk (M).** `GROUP BY`/`DISTINCT` treat nulls as equal, `WHERE` as
      unknown. Encode explicitly. Deferred with 4.2/4.5.
- [x] **4.7 `CASE … ELSE NULL END` (S). ✅ DONE (sound slice).** Dedicated syntax with `NULL` bound
      *inside* the `CASE` (never a standalone term, so `col = NULL` stays unwriteable): the scalar
      form yields an `Option` column (`some v` / `none`), and `COUNT(CASE … ELSE NULL END)` is
      intercepted like the no-`ELSE` form → indicator sum (COUNT skips the NULLs). Verified
      `COUNT(… ELSE NULL) = COUNT(… no-ELSE)` and a nullable scalar projection through `IS NULL`. The
      general 3VL semantics of an unrestricted `CASE`/NULL still awaits 4.2.

---

# Phase 5 — Outer joins (61.8% → 73.1%) — depends on Phase 4

`LEFT JOIN` 14.9%; `RIGHT`/`FULL` only 1.4%.

- [x] **5.1 `LEFT`/`RIGHT`/`FULL OUTER JOIN` — operator + grammar + schema reconciliation (L). ✅ DONE.**
      Operators `leftOuterJoin`/`rightOuterJoin`/`fullOuterJoin` (`Operators/Join.lean`) null-pad the
      unmatched side (`liftNullable`/`nullRow`, that side's columns become `Option`), built on the same
      `Fin.append` machinery as the inner join. **Grammar**: `sql_from` gains
      `LEFT|RIGHT|FULL [OUTER] JOIN t ON cond` (6 productions, `Parser/Syntax.lean`); `productPair`
      elaborates each to the operator with a two-tuple `ON` predicate (reusing `elabTypedTupleFilter`,
      like the semi/anti-join correlations) and a nullable output schema (`Inhabited` instances added
      in `Parser/Types.lean` for the null pad). **Schema reconciliation**:
      `ofOuterLeft`/`ofOuterRight`/`ofOuterFull` (`Parser/Query.lean`) convert the operator's
      `Fin.append (colTypeOfList l1) (fun i => Option (colTypeOfList l2 i))` result back to the canonical
      `colTypeOfList (l1 ++ l2.map .nullable)` by rebuilding each row (`splitTuple` +
      `TypedTupleOfList.append` + a new `ofOption`, whose recursion on the list sidesteps the
      heterogeneous `List.length_map` domains a plain cast couldn't bridge). So **projection and `WHERE`
      over an outer join now elaborate**. Verified in **Example 26**: LEFT/RIGHT/FULL, `OUTER` synonym,
      qualified/unqualified `ON`, `ON`-commute, `WHERE amount IS NULL AND …` commute over a LEFT JOIN,
      and `COALESCE(amount,0)` projected out of one — all by `sql_equiv`.
      **Follow-up:** bridge the *parsed* form (which passes through the `ofOuter*` reindex) to the
      operator-level pushdown lemma, so a parsed `LEFT JOIN … WHERE key IS NULL` proves ≡ `NOT EXISTS`
      by `sql_equiv` (operator-level version is Example 26).
- [x] **5.2 The anti-join pushdown (M). ✅ DONE (the `IS NULL` case).**
      `leftOuterJoin_filter_isNull_eq_antijoin_pad`: `A LEFT JOIN B ON cond` keeping only rows where a right
      column `IS NULL` = the null-padded **anti-join** of the unmatched `A` rows — the
      `LEFT JOIN … WHERE b.key IS NULL` ≡ `NOT EXISTS` rewrite, proved and demonstrated (Example 26).
      The complementary `WHERE right IS NOT NULL ≡ INNER JOIN` direction is the remaining half.
- [ ] **5.3 Join commutativity/associativity (M). Mostly present; wiring pending.** `swapAppend`,
      `join_comm`, `join_comm_image`, `crossProduct_comm` are all **proved** in
      `Operators/{Join,CrossProduct}.lean`. What remains is reaching them from `sql_equiv`
      automatically (so `sf_bq060`-style inner-join reordering closes without a manual `rw`).

---

# Phase 6 — Window functions — **OUT OF SCOPE (dropped with the `List` layer)**

`OVER(…)` 26.9%; `PARTITION BY` 17.6%; `ROW_NUMBER` 17.8%; `RANK`/`DENSE_RANK` 2.1%.

`ROW_NUMBER()`/`RANK()` are **meaningless on a `Finset`** — they need row order, which set semantics
discards. These are permanently out of scope under the chosen spec and are why the ceiling is ~73%,
not 100%. A query containing a window function is logged as *out-of-scope-by-design*, not attempted.

**Exception worth a second look — aggregate windows without `ORDER BY` (4.3%).** `SUM(x) OVER
(PARTITION BY k)` has no row-order dependence: it is a per-group aggregate broadcast back onto every
row. It *is* expressible on a `Finset` (reuse the `groupBy` machinery + a join back to rows). If any
window support is ever added, it is only this slice — and it belongs in Phase 4/5 territory, not a
revived Phase 6.

---

# Phase 7 — Proof automation (cross-cutting, continuous)

- [ ] **7.1 Parser emits clean group keys (M).** ("Fix 4" from earlier.) Emit
      `groupByRel key labels mkRow base` with `fun t => t 0` instead of opaque
      `TypedTupleOfList.cons` keys. This shrinks `Example12`'s `hpres` from ~10 lines to one.
- [ ] **7.2 Opt-in `group_equiv` tactic (M).** The blanket `sql_simp` unfold of `mapByList`/`map` was
      tried and **broke 7 previously-passing proofs** (`Sf010`, `Sf_bq398`, `Example6`, `Example11`,
      `Example18`, `Example20`). Do not retry it globally. A dedicated whole-relation `GROUP BY`
      tactic is the right home. Note `SQLEquiv.lean` does not import `Parser.Context`, so it cannot
      name `mapByList` — the tactic must live above the parser.
- [ ] **7.3 Counterexample search (M).** Wire `plausible` into `sql_equiv` so a *false* equivalence
      fails fast with a witness instead of timing out. This is the direct defense against Bugs 0.A/
      0.B ever recurring: a bag-semantics counterexample generator would have caught both.
- [ ] **7.4 Normal-form pass (L).** Push `WHERE` through joins/unions, fold `SUM(CASE)`→`WHERE`+`SUM`,
      canonicalize `IN`→`OR`-chain, before `grind`. Turns many equivalences into `rfl`.

---

# Phase 8 — Data-dependent hypotheses (orthogonal; user-deferred)

Some corpus pairs are equal **only under assumptions absent from the SQL and DDL**, e.g. `sf_bq327`
(`COUNT(DISTINCT indicator_name)` vs `COUNT(DISTINCT indicator_code)` — needs a name↔code bijection),
`sf_bq232` (dropping `major_category` — needs a functional dependency), `state='FL'` vs
`state_name='Florida'`. These are **not** provable by any amount of the above and must not be.

- [ ] **8.1 Hypothesis vocabulary (M).** intra-column (`0 ≤ age ≤ 100`), inter-column
      (`salary = months * wage`), functional dependency (`minor → major`), bijection (`name ↔ code`).
- [ ] **8.2 Surface them in `CREATE TABLE` (M)** so they become theorem hypotheses, not axioms.
- [ ] **8.3 Feed them to `grind` (M).**
- [ ] **8.4 Ledger (S).** Classify every corpus record: *pure-algebra* / *needs-hypothesis* /
      *genuinely-not-equivalent*. Nobody should be scored against pairs in the third bucket.

---

# Suggested execution order

Coverage per unit of effort, respecting the dependency spine:

1. **0.1, 0.2, 0.8** — stop the bleed, rename the claim, start measuring. Days, not weeks.
2. **1.1–1.3** — cheap parse wins (2.6% → 7.5%). Unblocks the 60% of queries dying on `DESC`.
3. **3.1–3.4** — CTE + scalar subquery (**→ 44%**). Best return in the entire roadmap.
4. **2.1–2.4** — scalar registry (→ ~50% combined with P3).
5. **0.3** — key hypothesis; retro-legitimizes existing examples cheaply.
6. **7.1, 7.3** — clean keys + counterexample search. 7.3 (`plausible`) is the standing guard that
   would have caught Bug 0.B automatically — wire it in early.
7. **4.x** → **5.x** — NULL, then outer joins. This is the ceiling (~73% / 68%).
8. **8.x** — data-dependent hypotheses, for the pairs inside that ceiling that need them.

Window functions (old Phase 6) and top-N-`LIMIT` semantics are **not on this list** — out of scope
by the set-semantics decision.

**If you do only one thing:** 0.1 (make `limit` opaque). It is the one place `sql_equiv` proves
something false *in our own model*, and `Example18` is currently that false thing wearing a green
checkmark. An automated prover that proves false things is worse than no prover, because it is
believed.

**If you do only one *feature*:** Phase 3 (CTE). +27 points, no semantic prerequisites.
