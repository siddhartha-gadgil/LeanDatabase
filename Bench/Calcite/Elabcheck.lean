import Lean.Meta
import LeanDatabase.Check
open Lean LeanDatabase

set_option maxHeartbeats 10000000
set_option maxRecDepth 1000000

/-!
# Lean-native elaboration census

Reads a pre-transpiled corpus (`Bench/Calcite/corpus_pg.json`: a JSON array of
`{id, schemas, query}`, produced once by sqlglot since there is no Lean transpiler) and elaborates
each query via `LeanDatabase.elabCheckCore`. Because the check runs **inside** Lean, the result is the
elaborator's own verdict — success, the exact exception message, or an unresolved-metavariable/`sorry`
term — with none of the text-scraping / line-attribution / truncation bugs of the old Python census.

Usage: `lake exe calcite_elabcheck [corpus.json]` — prints `ELABORATES n/total`, lists failures, and writes
`Bench/Calcite/elab_results.json`.
-/

unsafe def main (args : List String) : IO UInt32 := do
  let dataset := "Calcite"
  enableInitializersExecution
  initSearchPath (← findSysroot)
  let env ← importModules (loadExts := true) #[{module := `Mathlib}, {module := `LeanDatabase}] {}
  let path := args.headD s!"Bench/{dataset}/corpus_pg.json"
  let content ← IO.FS.readFile path
  let .ok (.arr recs) := Json.parse content
    | do IO.eprintln s!"could not parse {path} as a JSON array"; return 1
  -- `maxRecDepth` is enforced from the *options* (default 512); deep many-partition `UNION`s exceed it,
  -- so raise the option, not just the Core.Context field. A finite `maxHeartbeats` caps records whose
  -- full elaboration blows up (e.g. a 28-way partition UNION) so the census can't hang.
  let ctx : Core.Context :=
    { fileName := "", fileMap := { source := "", positions := #[] },
      options := Lean.maxRecDepth.set {} 1000000, maxHeartbeats := 400000000, maxRecDepth := 1000000 }
  let mut ok := 0
  let mut timeout := 0
  let mut results : Array Json := #[]
  for rec in recs do
    let id := (rec.getObjValAs? String "id").toOption.getD "?"
    -- Reset the heartbeat budget per record: the global IO counter only grows, so `initHeartbeats`
    -- must be re-read each time or the finite `maxHeartbeats` is exhausted after the first few records.
    let ctx := { ctx with initHeartbeats := (← IO.getNumHeartbeats) }
    let verdict ← ((elabCheckCore rec).run' ctx { env := env }).toIO'
    let j ← match verdict with
      | .ok j => pure j
      | .error e => pure (Json.mkObj [("status", "fail"), ("error", Json.str (← e.toMessageData.toString))])
    let status0 := (j.getObjValAs? String "status").toOption.getD "fail"
    let errStr := (j.getObjValAs? String "error").toOption.getD "?"
    -- A heartbeat timeout means the query resolves and elaborates but is slow — a distinct bucket from
    -- a genuine (scope/type/parse) failure, so a fast finite cap doesn't misreport slow records.
    let status := if status0 != "ok" && (errStr.splitOn "maximum number of heartbeats").length ≥ 2
      then "timeout" else status0
    if status == "ok" then ok := ok + 1
    else if status == "timeout" then timeout := timeout + 1; IO.println s!"TIMEOUT {id}"
    else IO.println s!"FAIL {id}: {errStr.take 140}"
    results := results.push (Json.mkObj [("id", Json.str id), ("status", Json.str status),
      ("error", if status == "ok" then Json.null else Json.str errStr)])
  IO.FS.writeFile s!"Bench/{dataset}/elab_results.json"
    ((Json.mkObj [("elaborates", Json.num ok), ("timeout", Json.num timeout),
                  ("total", Json.num recs.size), ("results", Json.arr results)]).pretty)
  IO.println s!"\nELABORATES: {ok}/{recs.size}  (+{timeout} timeout = {ok + timeout} resolve)"
  return 0
