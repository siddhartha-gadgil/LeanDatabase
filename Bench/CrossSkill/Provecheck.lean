import Lean.Meta
import LeanDatabase.Check
import LeanDatabase.SQLEquiv
open Lean LeanDatabase

set_option maxHeartbeats 10000000
set_option maxRecDepth 1000000

/-!
# Lean-native proving census

Reads `Bench/CrossSkill/pairs.json` (a JSON array of `{id, schemas, first, second, dataEq}`, extracted
from the Problems `eq_i_j` theorems) and asks `sql_equiv` to prove each pair via `LeanDatabase.provePairCore`.
A pair counts as PROVED only when `sql_equiv` closes it with no leftover goals and no `sorry`
(`proveMVar` enforces this). Prints `PROVED n/total` and writes `Bench/CrossSkill/prove_results.json`.
-/

unsafe def main (args : List String) : IO UInt32 := do
  enableInitializersExecution
  initSearchPath (← findSysroot)
  let env ← importModules (loadExts := true) #[{module := `Mathlib}, {module := `LeanDatabase}] {}
  let path := args.headD "Bench/CrossSkill/pairs.json"
  let content ← IO.FS.readFile path
  let .ok (.arr recs) := Json.parse content
    | do IO.eprintln s!"could not parse {path} as a JSON array"; return 1
  let ctx : Core.Context :=
    { fileName := "", fileMap := { source := "", positions := #[] },
      options := Lean.maxRecDepth.set {} 1000000, maxHeartbeats := 300000000, maxRecDepth := 1000000 }
  -- Debug mode (`provecheck <file> debug`): print sql_equiv's residual/failure for each pair.
  if args.length ≥ 2 then
    for rec in recs do
      let id := (rec.getObjValAs? String "id").toOption.getD "?"
      let ctx := { ctx with initHeartbeats := (← IO.getNumHeartbeats) }
      let msg ← ((debugPairCore rec).run' ctx { env := env }).toIO'
      let text := msg.toOption.getD "exception"
      IO.println s!"=== {id} ===\n{text}"
      (← IO.getStdout).flush
    return 0
  let mut proved : Nat := 0
  let mut results : Array Json := #[]
  for rec in recs do
    let id := (rec.getObjValAs? String "id").toOption.getD "?"
    let ctx := { ctx with initHeartbeats := (← IO.getNumHeartbeats) }
    let verdict ← ((provePairCore rec).run' ctx { env := env }).toIO'
    let ok := match verdict with
      | .ok j => (j.getObjValAs? Bool "proved").toOption.getD false
      | .error _ => false
    let tag := if ok then "PROVED" else "-----"
    IO.println s!"{tag} {id}"
    (← IO.getStdout).flush
    if ok then proved := proved + 1
    results := results.push (Json.mkObj [("id", Json.str id), ("proved", Json.bool ok)])
  IO.FS.writeFile "Bench/CrossSkill/prove_results.json"
    ((Json.mkObj [("proved", Json.num proved), ("total", Json.num recs.size),
                  ("results", Json.arr results)]).pretty)
  IO.println s!"\nPROVED: {proved}/{recs.size}"
  return 0
