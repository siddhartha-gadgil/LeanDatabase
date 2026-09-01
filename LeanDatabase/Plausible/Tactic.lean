import LeanDatabase.Plausible.Lemmas

/-!
# The tactics

`sql_plausible` searches for a counterexample database and reports it; `sql_disprove` is the
*pre-check* that `sql_equiv` runs before it tries to prove anything.

This module deliberately depends only on the sampling instances, not on the parser or the census
(`Plausible/Search.lean` does), so that `SQLEquiv` can use `sql_disprove` without an import cycle.
-/

open Lean Meta Elab

namespace LeanDatabase

/-- `plausible`, tuned for query equivalence: many small databases rather than a few large ones. The
default grows databases to a hundred rows of arbitrarily large values, which is slow and yields
unreadable reports; a pair that differs at all almost always differs on a handful of small rows. -/
macro "sql_plausible" : tactic =>
  `(tactic| plausible (config := { maxSize := 6, numInst := 300 }))

/-- **Look for a counterexample before trying to prove.** A quick pass, so a pair that simply is not
an equivalence fails fast and *says so*, instead of burning the whole proving pipeline on it.

It is deliberately not an alternative inside `first`: `plausible` never closes a goal, so as a branch
it could only ever fall through — and a found counterexample would then be swallowed by the next
branch. Instead this is a **no-op that aborts**: on a hit it throws the counterexample, so the proof
stops on a message saying the queries differ rather than on "tactic failed"; on anything else — no
counterexample found, or a goal the tester cannot build an instance for, such as one carrying
integrity constraints — it succeeds silently and the proving pipeline runs exactly as before.

It never closes a goal, so it cannot report a proof that does not exist. -/
elab "sql_disprove" : tactic => do
  -- An earlier step may already have closed the goal; there is then nothing to disprove. Without
  -- this the tactic errors on the empty goal list and takes the whole pipeline down with it.
  if (← Elab.Tactic.getGoals).isEmpty then return
  let goal ← Elab.Tactic.getMainGoal
  -- Back off on very large goals. Sampling a database means *evaluating both queries on it*, and on a
  -- seven-table join that costs more than the proof attempt it is supposed to save; those goals were
  -- timing out with the budget spent on testing rather than proving.
  if (← goal.getType).approxDepth > 96 then return
  -- A fixed seed keeps the check (and therefore every build that runs it) reproducible. The size
  -- guard above already excludes the goals where sampling is expensive, so on everything that
  -- reaches here the search should be *generous* — cutting it back to 40 instances lost two
  -- counterexamples that need a specific mined value in the row.
  let tac ← `(tacticSeq| plausible (config := { maxSize := 6, numInst := 120, randomSeed := some 271828 }))
  -- Anything the probe logs ("Unable to find a counter-example") is its own business, not the
  -- user's: remember where the log ends and drop whatever it added.
  let log ← Core.getMessageLog
  let found ← try
      -- A copy of the goal: whatever the tester does to it must not touch the real one.
      let probe ← mkFreshExprMVar (← goal.getType)
      let _ ← Elab.runTactic probe.mvarId! tac
      pure none
    catch ex =>
      let msg ← ex.toMessageData.toString
      pure (if (msg.splitOn "Found a counter-example").length ≥ 2 then some msg else none)
  Core.setMessageLog log
  match found with
  | some msg =>
    throwError "these queries are not equivalent — `plausible` found a database where they differ:\n{msg}"
  | none => pure ()

end LeanDatabase
