
LeanDatabase: what it is, why it's built this way, and what's actually broken

1. The system in one paragraph

Two SQL query strings + a schema go in; a machine-checked Lean proof of equivalence (or a failure) comes out. Queries are parsed at elaboration time into relational-algebra terms over TypedRelation (a dependently-typed record of labels : Fin n → String and rows : Finset (TypedTuple colType)), and the goal q₁ = q₂ is closed by one tactic, sql_equiv. A green proof quantifies over all input tables — it's not row-testing. Two front doors: sql%(schema) "…" as a term elaborator for .lean files, and checkEquiv : Json → TermElabM Bool driven by the sql_process executable behind sql_server.py (HTTP on 6767).

lake build is green (8607 jobs, exit 0, warnings only) on main @ 662aa28.

2. The layer cake

Parser.Syntax     surface grammar (sql_query/sql_from/sql_col/sql_cte cats, AND/OR/IN/BETWEEN/
                  LIKE/CASE/IS NULL/scalar-fn macros).  Depends only on `Lean` — deliberately.
Parser.Types      SQLTypeProxy (int|bool|float|string|timestamp|nullable) → Lean types;
                  colTypeOfList / TypedTupleOfList / TypedRelationOfList = the canonical
                  *list-indexed* schema every query targets.
Parser.Context    the join of the two: withSchemasTupleVars binds each column as a `let`-fvar so
                  the emitted term reads like SQL; AggKind dispatcher; CAST elaborator;
                  TypedRelation.mapByList (the projection primitive) + its fusion lemma.
Parser.Query      elabSqlQueryCore: the shape dispatcher (CTE / set-op / SELECT / SELECT+GROUP BY),
                  productPair (FROM), elabWhere/elabExists, ofOuter{Left,Right,Full} reindexers.
Operators/*       the algebra: CrossProduct (Fin.append plumbing, splitTuple/combineTuple/
                  swapAppend/assocAppend), Join (θ/semi/anti/left/right/full outer),
                  Aggregate (group*/rel*), Select, Predicates, Like, Scalar (opaque), OrderLimit.
SQLToolbox + Constraints    curated @[grind]/@[simp] rewrite set; FD/bijection hypothesis vocabulary.
SQLEquiv          `sql_simp` = simp_all[filter_filter,image_image]; `sql_equiv` = a `repeat first`
                  peeling loop (limit_congr | sql_outer_joilter_congr |
                  image_congr | sql_simp | funext) then `grind +locals`.

The let-binding trick in Parser.Context is the nicest piece of engineering here: the elaborated term literally shows let t.age := coords 0;
decide (t.age > 30) && t.isActive, so proof states are rea-order goals.

3. Why set semantics (and where the boundary really is)

ROADMAP.md §"chosen semantics" commits to rows : Finset +  rows", final, with the Multiset phases struck out. Thereasoning is sound and the consequences are honestly tabulated: DISTINCT and ORDER BY become identities, UNION ALL = UNION, window functions are
out of scope (hence the ~73% ceiling, not 100%). The distit makes SUM/COUNT honest at the leaves — it's theload-bearing premise, and ROADMAP 0.3 (make it real via PRIMARY KEY → injectivity hypothesis) is not done; the DDL even declares a constraints
syntax (PRIMARY KEY/NOT NULL/UNIQUE) that elabCreateTableC

The Phase-2.4 CAST decision is the best example of the pro AS FLOAT) is a real Int → Rat coercion, not opaque,precisely so a/b (integer division) can't be laundered into CAST(a)/CAST(b) (real division) — and the two even have different result types, so
the false claim is a type error, not merely unprovable. Thx.

4. Findings

S1 — sql_equiv still proves false top-N equalities. ROADMA of Bug 0.B. (highest severity)

limit was made opaque (correct), but orderBy remains @[simrderBy key rel = rel. The key is erased underneath theopaque limit, so the two sides become literally the same term:

pre-simp #1:  fun t => limit 10 (orderBy (fun coords => … coords 0 …) t)
pre-simp #2:  fun t => limit 10 (orderBy (fun coords => …
                                          ^^ erased by orderBy_eq → limit 10 t  on both sides

Both of these are proved by a bare sql_equiv (verified: no error from lake env lean):

- SELECT * FROM t ORDER BY a LIMIT 10 = SELECT * FROM t ORDER BY b LIMIT 10
- SELECT a FROM t ORDER BY a ASC LIMIT 1 = SELECT a FROM t

These are false in every real SQL engine. The limit-opaque shapes it targeted (LIMIT 1 vs no limit → correctly fails;LIMIT 1 vs LIMIT 2 → correctly fails), and the same false answer comes out of the server API: checkEquiv returns true for the ORDER BY age LIMIT
1 vs ORDER BY isActive LIMIT 1 pair.

This is not hypothetical — the project's own ledger has res. result.json/sf_bq020: "identical (… same LIMIT 1) exceptfor the ORDER BY key: CAST(COUNT() AS FLOAT)/CAST(r."length" AS FLOAT) vs COUNT()/r."length". Under set semantics ORDER BY (and LIMIT) is
identity on the row-set…" — that justification is verbatim 0.B declares false. Same for sf_bq027 (extrapublication_number DESC tiebreak + LIMIT). 32.5% of corpus records (114/351) have variants whose ORDER BY … LIMIT keys differ, so this is the
dominant false-positive class, not an edge case.

Fix: limit must be opaque in the order key too — opaque li) (rel : …), with orderBy erasure only permitted when noLIMIT sits above it. Emit limit k key rel in Parser/Query.lean instead of limit k (orderBy key rel). The roadmap's own closing line ("an
automated prover that proves false things is worse than noieved") applies unchanged.

S2 — AVG is truncating integer division, contradicting the

groupAvg = groupSum / Int.ofNat groupCount over Int. So bo

- SELECT AVG(b) FROM t GROUP BY a = SELECT SUM(b)/COUNT(*)
- SELECT AVG(b) FROM t GROUP BY a = SELECT SUM(b)/COUNT(b) FROM t GROUP BY a

In Snowflake/Postgres AVG(int) is exact numeric — AVG of {1,2} is 1.5, the model says 1. This is the same int-vs-real division laundering that
2.4 went to real trouble to close for CAST, left open in taxInt/groupMinInt/groupAvg return 0 on an empty group whereSQL returns NULL (only reachable through HAVING, but reachable), and relMax/relMin are Nat-only while groupMaxInt is Int — the aggregate layer
isn't type-uniform.

S3 — Correlated subqueries over the same table silently dr

elabExists calls elabTypedTupleFilter [(.anonymous, outerSa)]. When outer and inner are the same table,schemaWithFullNames is idempotent (its isPrefixOf guard stops re-prefixing), so both binder groups bind the identical names and the inner
shadows the outer. Confirmed:

lean
-- SELECT a FROM t WHERE EXISTS (SELECT b FROM t WHERE t.a = t.b)
fun t => (semijoin t t fun coords t.coords =>      -- `cooused
    let t.a := t.coords 0;                          -- resolves to the INNER tuple
    let t.b := t.coords 1;
    decide (t.a = t.b)) …

The outer binder is dead. Self-correlated EXISTS — the canonical "rows with a greater value in the same table" idiom — elaborates to a row-local
predicate. It doesn't error; it quietly means something eliases, so you can't even write the correct query — see C2.)

S4 — Ambiguous unqualified columns resolve silently to the

expandNames builds (shortName, prefix) pairs from all labe hit. SELECT a FROM t, u where both have a elaborates to t.a with no diagnostic (SQL requires an ambiguity error). Both sides of an equivalence resolve the same way so it rarely produces a false positive
directly — but it does produce confusing failures: SELECT OM u ORDER BY a fails with Failed to parse type in ASclause: t.a, because the ORDER BY key over the right query's schema got rewritten to t.a.

I1 — The "VERIFIED / ground truth" coverage number is not verified by anything

coverage.py prints verified today (machine-checked, from result.json): encoded 20 / pass 15 / files on disk now 9. In fact:

- Examples/CrossSkill/*.lean — none exist, and git log --diff-filter=A shows they were never committed (.gitignore: **/CrossSkill/Sf*.lean "not
pushed").
- on_disk_now: 9 is a hardcoded JSON field, not a stat(). The 10 instances marked "on_disk": true are all false in this checkout. Sf_bq060.lean
exists but at Examples/, not the recorded path.
- So lake build cannot and does not check any of the 20 encoded records, while the script's footer says "lake build must pass for VERIFIED to be
trustworthy."

Combined with S1, the ledger is both unverifiable and cont(sf_bq020, sf_bq027) that are false w.r.t. real SQL. Minimum fix: make on_disk a live filesystem check, refuse to print a VERIFIED tally for missing files, and either commit the encodings or stop calling
the number machine-checked.

I2 — CI does not run the coverage guard

ROADMAP 0.8 states the guard is "wired after lake build in_action_ci.yml is 12 lines: checkout +leanprover/lean-action@v1. No coverage.py step, and it couldn't work anyway (the 109 MB .jsonl is gitignored).

C1 — Grammar and elaborator disagree: the clause-combination matrix is full of holes

sql_query is one production with optional DISTINCT/WHERE/GROUP BY/HAVING/ORDER BY/LIMIT, but elabSqlQueryCore has exactly two SELECT patterns —
one without GROUP BY, one without DISTINCT/ORDER BY/LIMIT.e omitted optional slots to be absent, so everycross-combination dies at | _ => throwError "Unexpected syntax for SQL query". Same for escapeJoin, whose JOIN→comma desugaring patterns also
require no GROUP BY/ORDER BY/LIMIT — so an inner JOIN reacd and hits Unsupported FROM clause. Measured on the corpus:

┌───────────────────────────────────┬───────────────────────────────────┬────────────────┐
│               shape               │                           status                            │ corpus queries │
├───────────────────────────────────┼───────────────────────────────────┼────────────────┤
│ GROUP BY … ORDER BY               │ FAIL Unexpected syntax                                      │ 882 (69.7%)    │
├───────────────────────────────────┼───────────────────────────────────┼────────────────┤
│ inner JOIN … GROUP BY             │ FAIL Unsupported FROM clause                                │ 673 (53.2%)    │
├───────────────────────────────────┼───────────────────────────────────┼────────────────┤
│ GROUP BY … LIMIT                  │ FAIL                                                        │ 419 (33.1%)    │
├───────────────────────────────────┼───────────────────────────────────┼────────────────┤
│ DISTINCT … GROUP BY               │ FAIL                                                        │ 295 (23.3%)    │
├───────────────────────────────────┼───────────────────────────────────┼────────────────┤
│ aggregate with no GROUP BY        │ FAIL Failed to parse type in AS clause: SUM(t.b)            │ 122 (9.6%)     │
├───────────────────────────────────┼───────────────────────────────────┼────────────────┤
│ JOIN … ORDER BY / JOIN … LIMIT    │ FAIL                                                        │ —              │
├───────────────────────────────────┼───────────────────────────────────┼────────────────┤
│ SELECT alias … GROUP BY alias     │ FAIL                                                        │ —              │
├───────────────────────────────────┼───────────────────────────────────┼────────────────┤
│ EXISTS in WHERE with GROUP BY     │ FAIL elaboration function … not implemented                 │ —              │
├───────────────────────────────────┼───────────────────────────────────┼────────────────┤
│ LEFT JOIN … GROUP BY / … ORDER BY │ OK (outer joins are handled in productPair, not escapeJoin) │ —              │
└───────────────────────────────────┴───────────────────────────────────┴────────────────┘

Note the irony: LEFT JOIN + GROUP BY works and plain JOIN  because inner joins go through the escapeJoin rewrite path. elabWhere (which routes EXISTS/IN to semi/anti-joins) is only called from the non-GROUP BY arm; the GROUP BY arm calls elabTypedTupleFilter
directly, so subquery predicates hit the unimplemented EXIwhole class is cheap to fix — one merged SELECT arm thatreads all optional slots — and it is nowhere in the roadmap.

C2 — No table aliases at all

sql_from has ident and (sql_query) AS ident. There is no table AS alias or bare table alias. FROM t AS x and FROM t x both fail at parse. 76.9%
of corpus queries alias their tables; the very first recor"FHFA_…_TIMESERIES" t JOIN "…"."…"."…_ATTRIBUTES" a ONt."VARIABLE" = a."VARIABLE". Aliases are also the only way to write a correct self-join or self-correlated subquery, so C2 and S3 are the same
hole from two sides.

C3 — No dialect front-end: 0 of 1266 corpus queries can beten

This is the biggest strategic gap and it is invisible in ter explicitly measures semantic-feature reachability"assuming surface normalization". Measured on the real .jsonl:

┌────────────────────────────────┬──────────────┬───────────────────────────────────────────────────────────────────────────────────────────┐
│        surface feature         │   corpus     │                parser                                           │
│                                │   queries    │                                                                                           │
├────────────────────────────────┼──────────────┼─────────────────────────────────────────────────────────────────┤
│ double-quoted identifiers      │ 1266 (100%)  │ parse error — and "DATE" is grammatically a string literal, so it's ambiguous, not just   │
│ (t."DATE")                     │              │ missing                                                         │
├────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
│ 3-part dotted names            │ 1266 (100%)  │ parse erwn table)                                               │
│ ("DB"."SCH"."T")               │              │                                                                                           │
├────────────────────────────────┼──────────────┼─────────────────────────────────────────────────────────────────┤
│ single-quoted string literals  │ 975 (77.0%)  │ Lean reads 'x' as Char; a type mismatch is logged. Literals must be double-quoted         │
├────────────────────────────────┼──────────────┼─────────────────────────────────────────────────────────────────┤
│ :: cast                        │ 330 (26.1%)  │ intentionally unsupported (would clobber List.cons)                                       │
├────────────────────────────────┼──────────────┼─────────────────────────────────────────────────────────────────┤
│ scalar fns outside the         │ 451 (35.6%)  │ TO_TIMESTAMP 412, TO_DATE 329, EXTRACT 268, REGEXP_SUBSTR 85, DATE_TRUNC 84, SPLIT_PART   │
│ registry                       │              │ 72, DATE                                                        │
├────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
│ EXTRACT(YEAR FROM d)           │ 268          │ parse er form isn't in the grammar)                             │
└────────────────────────────────┴──────────────┴───────────────────────────────────────────────────────────────────────────────────────────┘

queries clear of every surface blocker: 0 (0.0%). So "P0 baseline = 33 queries (2.6%)" cannot be a parse-level measurement of corpus SQL — it
must count hand-transcribed encodings. Nothing in Phases 0 yet no amount of Phase 3/4/5 work moves the automatedpipeline off zero without one. This, not CTE, is the real "if you do only one feature". It's also cheap relative to the proof work: a
quoted-identifier token, AS-alias grammar, a dotted-name-tgle-quoted strings, EXTRACT, and ~10 more opaque scalars.

Minor / hygiene

- Dead, uncompiled code with 16 sorrys. ListRelationalAlgeationalAlgebraList}.lean (416 lines, 16 sorrys),CrossProductGeneral.lean, CurryParser.lean — imported by nobody, and since lean_lib LeanDatabase uses default globs (root module only), they are
never compiled, so the sorrys never even surface as warninde: finish that file, or fold it in… Do not leave a thirdparallel algebra." It's still there. Given the Multiset decision is final, delete it.
- SQLSyntax.lean leaks a global table. CREATE TABLE Producope defineLeanDatabase.Products/Products_types/Products_schema in the shipped library and print an info on every build. elabSelectCmd below it is labelled
/-incomplete and incorrect-/ and is ~60 lines of logInfo d
- crossProductRel computes hasCollision and never uses it, under a comment claiming "we rename labels if they are same". No renaming happens.
- sqlProxy maps decimal/numeric/number → .int. A NUMBER(10 price/2 is integer division — the exact hazard 2.4 closedfor CAST, reopened at the DDL. Schema.lean's legacy SQLType.FLOAT → Float also disagrees with SQLTypeProxy.float → Rat.
- checkEquiv is inconsistent about failure. A parse error  (the server turns it into status: error — acceptable,fail-loud) while a proof failure returns false. The hasSorry branch's early-return inside the match is confusing enough that I'd rewrite it for
clarity even though observed behaviour is correct.
- Lowercase keywords fail (select a from t) — 0% of this corpus, but a real gap for other inputs.
- Build warnings: 3 overlapping-instance-parameter warningne unused section variable onleftOuterJoin_filter_isNull_eq_antijoin_pad.

5. Roadmap accuracy audit — deltas to write in

The roadmap is unusually good: honest about its ceiling, records negative results (7.2: "the blanket sql_simp unfold broke 7 proofs — do not
retry globally"), and marks deferrals as deliberate ratherons needed:

┌─────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────┐
│              claim              │                                                 reality                                                 │
├─────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ 0.1 "LIMIT opaque — the fix. ✅ │ half-done. limit k R = R is gone, but limit k (orderBy k₁ R) = limit k (orderBy k₂ R) is provable.      │
│  DONE… Example18 fixed"         │ Reopen 0.B.                                                                   │
├─────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 0.8 "wired after lake build in  │ not wired; CI is check                                                        │
│ lean_action_ci.yml"             │                                                                                                         │
├─────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ 0.8 "VERIFIED — the             │ a hand-maintained JSON; 0 of 20 proof files present, on_disk_now stale                                  │
│ machine-checked proof tally"    │                                                                               │
├─────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 0.4 "Decide: finish that file   │ still orphaned, 16 sor                                                        │
│ or fold it in"                  │                                                                                                         │
├─────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ 0.3 distinct-rows discipline    │ not started; DDL constraints syntax exists but is ignored                                               │
├─────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ "P0 baseline 33 queries (2.6%)" │ not achievable on raw corpus SQL (0% parse). Label it "hand-transcribed"                                │
├─────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│                                 │ add rows: AVG = truncating Int division ≠ SQL AVG; any projection dedupes, so SUM over a subquery/CTE   │
│ semantics table                 │ that projects differs le (this one is safe — it fails rather than             │
│                                 │ false-proving — but it's a real model divergence and isn't listed)                                      │
├─────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ Phases 1–5 framing              │ add a Phase 0.9 "surface/dialect front-end" and a Phase 1.4 "clause-combination matrix"; both gate      │
│                                 │ everything else and ne                                                        │
└─────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Two things the roadmap under-weights: ORDER BY erasure is a separate soundness surface from LIMIT, and 7.3 (plausible counterexample search) is
the standing guard that would have caught S1, S2 and S4 au says so about 0.A/0.B. It's still unstarted, and it's nowthe cheapest high-value item on the list.

6. What I'd do, in order

1. limit takes the order key (S1). Small diff: opaque limit (k) (key) (rel), emit it in Parser/Query.lean, keep orderBy_eq only where no limit
is above. Then re-adjudicate sf_bq020/sf_bq027 in the ledg
2. Wire 7.3 (plausible) into sql_equiv so a false equivalence fails with a witness. This is the regression guard for classes 1, 2 and 4.
3. Make the ledger honest (I1/I2): live on_disk check, ref absent files, add the coverage step to CI, commit theencodings (or a redacted form).
4. One merged SELECT arm (C1). Highest coverage-per-line cs 70% of corpus queries' clause shapes, plus routingelabWhere from the GROUP BY arm.
5. Surface/dialect front-end (C2/C3): quoted identifiers, s, single-quoted strings, EXTRACT, the missing scalars.Without this the automated pipeline stays at zero regardless of Phases 3–5.                                                                   6. Fix AVG (S2) — either Rat division, or keep Int and ren to be SQL AVG.
7. Delete the orphans (ListRelationalAlgebra/*, CrossProductGeneral, CurryParser, the Products/elabSelectCmd leftovers) and add ROADMAP 0.3's PRIMARY KEY hypothesis, since it's the premise everything
                                                                                                                                            The proof engineering is the strong part of this repo — thon, the @[grind] orientation notes, the dependent-Fin.append plumbing. The weak part is the boundary: what the parser accepts, and whether the reported coverage means anything. Items 1, 3, 4 and 5 all live on that boundary. 
