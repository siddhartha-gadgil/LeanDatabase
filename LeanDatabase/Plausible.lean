import LeanDatabase.Plausible.Sampling
import LeanDatabase.Plausible.Lemmas
import LeanDatabase.Plausible.Search

/-!
# Counterexample search for query equivalence

`sql_equiv` proves; this half *disproves*. Of the 61 Literature benchmark pairs, 29 are genuinely
inequivalent — time spent trying to prove those is wasted, and a failed proof never says which case
you are in. `plausible` (Lean's property-based tester) answers it directly: it samples databases,
evaluates both queries, and reports one they disagree on, shrunk to something a person can read.

    example (t : TypedRelationOfList [.int, .int, .int]) :
        (sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A = 5 AND X.C < 1") t
      ~= (sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A < 10") t := by
      sql_plausible
    -- Found a counter-example!  t := [(0, 0, 0)]

Three modules:

* `Plausible/Sampling.lean` — how a database is generated and shrunk (`SampleableExt` for a relation,
  via a printable `RowProxy`). Sampled rows go through `List.toFinset`, so a database is always a
  **set** and no verdict can be a multiplicity artefact.
* `Plausible/Lemmas.lean` — what the tester needs (`Decidable`) and what makes its answers
  trustworthy (`Testable`, which carries a `¬p` proof, so a hit is a disproof), plus the lemmas
  pinning the set semantics.
* `Plausible/Search.lean` — `sql_plausible`, and driving the search over a benchmark pair.
-/
