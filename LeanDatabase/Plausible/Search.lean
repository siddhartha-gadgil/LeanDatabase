import LeanDatabase.Check
import LeanDatabase.Plausible.Tactic

/-!
# Driving the search over a benchmark pair

`sql_equiv` can only ever *prove*; when it fails, nothing distinguishes "the tactic is too weak" from
"these queries are not equivalent". This is the other half: build the goal `∀ tables, first ~= second`
straight from a `{schemas, first, second}` record and hand it to `plausible`, which reports a database
the two queries disagree on — already shrunk.

`sql_plausible` is `plausible` tuned for this domain. The default configuration grows databases to a
hundred rows of arbitrarily large values, which is slow and yields unreadable reports; a query pair
that differs at all almost always differs on a handful of small rows, so it is better to try many
small databases than a few big ones. (VeriEQL report the same — most of their benchmarks are refuted
at bound 2.)
-/

open Lean Meta Elab Term

namespace LeanDatabase

-- (`sql_plausible` and `sql_disprove` live in `Plausible/Tactic.lean`, which `SQLEquiv` can import
-- without a cycle.)

/-- Search for a database on which the pair's two queries differ. Returns
`{refuted, counterexample?}`; the counterexample is the tester's report, already shrunk.

A hit is a **disproof**: `Plausible.TestResult.failure` is constructible only from a proof that the
property fails on that database, so nothing here is heuristic. Silence is inconclusive — it means no
small counterexample was found, never that the pair is an equivalence. -/
def counterexamplePair (data : Json) : TermElabM Json := do
  let run : TermElabM Json := do
    let .ok schemas := data.getObjValAs? (List Json) "schemas" | return json% {"refuted": false}
    let .ok first := data.getObjValAs? String "first" | return json% {"refuted": false}
    let .ok second := data.getObjValAs? String "second" | return json% {"refuted": false}
    let schemasStr ← schemas.mapM parseSchema
    -- Feed the samplers the literals these two queries mention: a predicate like `SIZE > 100000` or
    -- `YX = 'HELLO'` is false on essentially every random value, so without this the search never
    -- gets past it (`Plausible/Constants.lean`).
    LeanDatabase.Plausible.setPoolFrom first second
    let (firstExpr, _) ← parseSqlQuery schemasStr first
    let (secondExpr, _) ← parseSqlQuery schemasStr second
    lambdaTelescope (← instantiateMVars firstExpr) fun tvars body1 => do
      let body2 ← instantiateLambda (← instantiateMVars secondExpr) tvars
      -- `~=`, not `=`: relation equality includes the `labels` function, which is not decidable —
      -- and row equality is the benchmark's own notion of "same answer".
      let goal ← mkForallFVars tvars (← mkAppM ``LeanDatabase.dataEq #[body1, body2])
      let mvar ← mkFreshExprMVar goal
      let tac ← `(tacticSeq| sql_plausible)
      try
        let _ ← Elab.runTactic mvar.mvarId! tac
        return json% {"refuted": false}
      catch ex =>
        let msg ← ex.toMessageData.toString
        -- The tactic reports *both* outcomes as errors; only one of them is a counterexample.
        if (msg.splitOn "Found a counter-example").length ≥ 2 then
          return Json.mkObj [("refuted", true), ("counterexample", Json.str msg)]
        else
          return Json.mkObj [("refuted", false), ("error", Json.str msg)]
  try run
  catch ex => return Json.mkObj [("refuted", false), ("error", Json.str (← ex.toMessageData.toString))]

def counterexamplePairCore (data : Json) : CoreM Json :=
  Core.withCurrHeartbeats (counterexamplePair data |>.run' {} |>.run' {})

end LeanDatabase
