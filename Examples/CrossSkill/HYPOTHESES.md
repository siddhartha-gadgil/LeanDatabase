# Hypotheses for crossskill equivalences

Flat list. Each entry: the hypothesis, why it's needed, where it applies.

---

`HYPOTHESIS h : T "col = ROUND(col, n)"`
- why: a variant rounds a stored column the other reads raw; equal only if already rounded to n places.
- where: records where one SQL has `ROUND(col, n)` on a base column and the other has bare `col`.

---

`HYPOTHESIS h : T "ROUND(expr, n1) = ROUND(expr, n2)"`
- why: two variants round the same expression to different precisions; equal only if the value carries ≤ min(n1,n2) significant places on this data.
- where: R158 (eq_0_2: round-6 vs round-2), R304 (eq_*: round-2 vs round-6). Percentage columns rounded differently.

---

`HYPOTHESIS h : T "expr = ROUND(expr, n)"`
- why: one variant rounds a computed expression, the other leaves it raw.
- where: R158 (eq_0_1: `100.0*SUM/COUNT` rounded-6 vs unrounded), R304 unrounded-vs-rounded percentage pairs.

---

`HYPOTHESIS h : T "col_a = <arithmetic expr over other cols>"`   e.g. `"total = qty * price"`
- why: one variant reads a stored column, the other recomputes it; equal only if the stored value equals the formula.
- where: records with a derived/stored column pair (CAST or expression differences between variants).

---

`HYPOTHESIS h : T "col >= k"`   /   `HYPOTHESIS h : T "col <= k"`
- why: a range filter present in one variant only; the equivalence holds if the bound drops no rows.
- where: proved `sf_bq432` (`date_started <= '2015-01-31'`); any variant pair differing by a range `WHERE`.

---

`HYPOTHESIS h : T "col = 'literal'"`
- why: an equality filter present in one variant only; holds if every row already satisfies it.
- where: proved `sf_bq232` (`major_category = 'Theft and Handling'`, redundant given the `minor_category` filter).

---

`HYPOTHESIS h : T "col IN ('a', 'b', ...)"`
- why: an `IN`-list filter present in one variant only; holds if every row's value is in the set.
- where: records where one variant restricts a category/status column the other does not.

---

`HYPOTHESIS h : T "col_a = col_b"`
- why: two differently-named columns carry the same data; a variant projects/filters on one, the other on its twin.
- where: records with duplicated or renamed columns (e.g. a code column and its label projected interchangeably).

---

`HYPOTHESIS fd : T FUNCDEP a -> b`   (elaborates to `FuncDepEq (·.a) (·.b) t`)
- why: `a` functionally determines `b`, so `GROUP BY a, b` and `GROUP BY a` induce the same partition (equal per-group `COUNT(*)`).
- where: proved in `Example_35`; records where variants group by different-granularity keys (`GROUP BY id` vs `GROUP BY id, name`).

---

`HYPOTHESIS u : T UNIQUE k`   (elaborates to `FuncDepEq (·.k) id t`)
- why: `k` is a key, so `COUNT(DISTINCT k) = COUNT(*)` and a `DISTINCT` over rows already keyed by `k` is a no-op.
- where: records where one variant adds `DISTINCT` / `COUNT(DISTINCT k)` the other omits.

---

`HYPOTHESIS fk : "SELECT COUNT(*) FROM A" = "SELECT COUNT(*) FROM A JOIN B ON A.k = B.k"`
- why: every `A` row has exactly one matching `B` row (foreign key), so the extra inner join is lossless.
- where: 24 records carry a DDL `FOREIGN KEY`; records where one variant joins a lookup table the other skips.
