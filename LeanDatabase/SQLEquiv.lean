import LeanDatabase.RelationalAlgebra
import LeanDatabase.Operators.Aggregate
import LeanDatabase.CurriedPredicates
import LeanDatabase.SQLToolbox
import LeanDatabase.Operators
import LeanDatabase.Constraints

open LeanDatabase LeanDatabase.TypedAgg

/-!
This file is meant to be imported by the examples, to give them access to the `sql_equiv` tactic.
This file would contain all dependencies imported, to give all theorems and definitions for `simp` and `grind` to work in `sql_equiv`.

## What `sql_equiv` proves — read this before trusting a green checkmark (ROADMAP 0.2)

`sql_equiv` proves **set-equivalence**: the two queries denote the *same result set*, over a
`TypedRelation` whose `rows` is a `Finset` and whose base tables are assumed to have distinct rows.
A proved `sql%(…) = sql%(…)` is therefore **not** a claim about bag (multiset) or ordered SQL:

* `ORDER BY` is the identity (row order is unobservable on a `Finset`) — so an `ORDER BY`
  difference is *erased*, never proved as an ordered-result equality.
* `UNION ALL` maps to set `union`; `SELECT a FROM t UNION ALL SELECT a FROM t = SELECT a FROM t`
  is **correct as sets** (the result *set* of a bag-union is its set-union) but would be false under
  bag semantics. This is by design, not a bug.
* `LIMIT k` is `opaque` — provably equal only to itself, never to the unlimited query — because
  "which k rows" needs an order a `Finset` does not have.

So the equality symbol here means "same set of rows for every possible input table", nothing more.
-/

namespace LeanDatabase.SQLEquiv

/-- `sql_simp` — the normalisation pass: unfold the `@[simp]` query/operator definitions and
fire the `@[simp]`-tagged database identities, using local hypotheses (`simp_all`) to discharge
side-conditions like `t ∈ table`. It puts a goal in a shape `grind` can finish. -/
macro "sql_simp" : tactic => `(tactic| simp_all [Finset.filter_filter, Finset.image_image])

/-!
Creating a `sql_equiv` tactic to prove equivalences between SQL queries, by doing `simp` and `grind` using definitions produced and grinding on locals.

Idea is to use JUST this tactic to prove equivalences between SQL queries.

Possible future work: extend this tactic to also be able to disprove using `plausible` (counterexample search).
-/

-- Outer-join reduction: `A LEFT JOIN B WHERE right IS NULL` ≡ the null-padded anti-join. The broad
-- `sql_simp` rewrites `Option.isNone` away from the pushdown lemma's LHS, so it can't fire there;
-- this branch unfolds *only* `restriction`/`isNull` and lets the tagged lemma reduce the join. It is
-- guarded by `done` so it backtracks (restoring the goal) whenever it does not fully close — hence
-- harmless to every non-outer-join proof.
macro "sql_outer_join" : tactic => `(tactic|
  (apply TypedRelation.ext (by rfl)
   simp only [restriction, isNull, leftOuterJoin_filter_isNull_eq_antijoin_pad]
   done))

macro "sql_equiv" : tactic => `(tactic|
  (
   repeat (first
     | refine limit_congr ?_
     | sql_outer_join
     | (apply TypedRelation.ext <;> try rfl)
     | refine Finset.filter_congr (fun _ _ => ?_)
     | refine Finset.image_congr (fun _ _ => ?_)
     | sql_simp
     | (apply funext; intro _))
   all_goals (first
     | grind +locals
     | (apply Finset.ext; sql_simp; grind +locals))))

end LeanDatabase.SQLEquiv
