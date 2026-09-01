import LeanDatabase.Plausible.Sampling
import LeanDatabase.DataEquiv

/-!
# Facts the tester needs, and the ones that make its answers trustworthy

`plausible` is not a proof search, but it does take help, in exactly two forms:

* **`Decidable` instances** — how it evaluates the property on a sampled database at all;
* **`Testable` instances** — how it *reports* a failure, and (crucially) what evidence it carries.

`TestResult.failure` is constructible only from a `¬p`, so every counterexample this module reports
comes with a machine-checked proof that the property fails on that database. A hit is a disproof, not
a heuristic; only *silence* is inconclusive.

The other job here is pinning down that our verdicts are about **sets**. Our semantics are set
semantics: a difference in row *multiplicity* is not a difference at all, and a tester that reported
one would be lying. `sample_toFinset_dedup` records that the sampler cannot produce such a case.
-/

open Plausible

namespace LeanDatabase

/-- `A ~= B` unfolds to equality of the row `Finset`s. Stated so `simp`/`decide` can see it. -/
@[simp] theorem dataEq_iff_rows {n : Nat} {ct : Fin n → Type} [∀ i, DecidableEq (ct i)]
    (a b : TypedRelation ct) : dataEq a b ↔ a.rows = b.rows := Iff.rfl

/-- `plausible` builds its `Testable` from a `Decidable` instance, and `dataEq` is a `def` that
instance search will not unfold on its own. Row-set equality *is* decidable, so hand it over. -/
instance instDecidableDataEq {n : Nat} {ct : Fin n → Type} [∀ i, DecidableEq (ct i)]
    (a b : TypedRelation ct) : Decidable (dataEq a b) := by
  unfold dataEq
  infer_instance

/-- **A sampled database is a set.** Repeating a row in the sample changes nothing about the database
it denotes, so no counterexample this module reports can be a multiplicity artefact — which would be
meaningless under our set semantics. -/
theorem sample_toFinset_dedup {l : List SQLTypeProxy} (r : RowProxy l) (rows : List (RowProxy l)) :
    ((r :: r :: rows).map RowProxy.interp).toFinset = ((r :: rows).map RowProxy.interp).toFinset := by
  simp [List.toFinset_cons, Finset.insert_idem]

/-- The order rows are sampled in is equally irrelevant. -/
theorem sample_toFinset_swap {l : List SQLTypeProxy} (r s : RowProxy l) (rows : List (RowProxy l)) :
    ((r :: s :: rows).map RowProxy.interp).toFinset = ((s :: r :: rows).map RowProxy.interp).toFinset := by
  simp [List.toFinset_cons, Finset.insert_comm]

/-! ## Reporting *why* a database is a counterexample -/

/-- How the two results differ, as counts: rows on each side, and how many are on one side only.
`Finset.card` and `\` are computable, unlike `Finset.toList`, so this can run inside the tester. -/
def rowDiffSummary {l : List SQLTypeProxy} (a b : TypedRelationOfList l) : String :=
  s!"first query: {a.rows.card} row(s), second: {b.rows.card}; " ++
    s!"{(a.rows.filter (· ∉ b.rows)).card} only in the first, " ++
    s!"{(b.rows.filter (· ∉ a.rows)).card} only in the second"

/-- A `Testable` for `~=` that says **how** the two results differ, not just which database was
sampled. `plausible` picks this up automatically for a row-equality goal, and the carried
`h : ¬ dataEq a b` is what makes the report a disproof rather than a guess. -/
instance instTestableDataEq {l : List SQLTypeProxy} (a b : TypedRelationOfList l) :
    Testable (dataEq a b) where
  run := fun _ _ => do
    if h : dataEq a b then
      return .success (.inr h)
    else
      return .failure h [rowDiffSummary a b] 0

end LeanDatabase
