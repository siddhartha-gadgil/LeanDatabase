import Lean.Meta
import LeanDatabase.Plausible.Search
open Lean LeanDatabase

set_option maxHeartbeats 10000000
set_option maxRecDepth 1000000

/-!
# `counterexample` — search a dataset for pairs that are *not* equivalences

`lake exe counterexample <dataset>` runs the `plausible` search (`LeanDatabase/Counterexample.lean`)
over `Bench/<dataset>/pairs.json`, prints the shrunk counterexample database for every hit, and writes
`counterexample_results.json`.

A hit means the proving census should not be chasing that pair at all. Silence means only that no
small counterexample was found.
-/

unsafe def main (args : List String) : IO UInt32 := do
  enableInitializersExecution
  initSearchPath (← findSysroot)
  let env ← importModules (loadExts := true)
    #[{module := `Mathlib}, {module := `LeanDatabase}, {module := `LeanDatabase.Plausible}] {}
  let ds := args.headD "Literature"
  let path : System.FilePath := s!"Bench/{ds}/pairs.json"
  let .ok (.arr recs) := Json.parse (← IO.FS.readFile path)
    | do IO.eprintln s!"could not read {path}"; return 1
  let ctx : Core.Context :=
    { fileName := "", fileMap := { source := "", positions := #[] },
      options := Lean.maxRecDepth.set {} 1000000, maxHeartbeats := 100000000, maxRecDepth := 1000000 }
  let mut refuted : Nat := 0
  let mut results : Array Json := #[]
  for h : i in [0 : recs.size] do
    let r := recs[i]
    let id := (r.getObjValAs? String "id").toOption.getD "?"
    let ctx := { ctx with initHeartbeats := (← IO.getNumHeartbeats) }
    let v ← ((counterexamplePairCore r).run' ctx { env := env }).toIO'
    let j := v.toOption.getD (Json.mkObj [("refuted", Json.bool false)])
    let hit := (j.getObjValAs? Bool "refuted").toOption.getD false
    let cex := (j.getObjValAs? String "counterexample").toOption
    let err := (j.getObjValAs? String "error").toOption
    if hit then refuted := refuted + 1
    -- The witness line of the tester's report ("t := [(0, 0, 0)]") is the database itself.
    let witness := match cex with
      | some c => " | " ++ " ".intercalate ((c.splitOn "\n").filter (fun l => (l.splitOn ":=").length ≥ 2))
      | none => match err with
        | some e => ": " ++ (e.splitOn "\n").headD e
        | none => ""
    IO.println (if hit then s!"[{ds}] {i + 1}/{recs.size} NOT-EQUIVALENT {id}{witness}"
                else s!"[{ds}] {i + 1}/{recs.size} no counterexample {id}{witness}")
    (← IO.getStdout).flush
    results := results.push (Json.mkObj [("id", Json.str id), ("refuted", Json.bool hit),
      ("counterexample", match cex with | some c => Json.str c | none => Json.null),
      ("error", match err with | some e => Json.str e | none => Json.null)])
  IO.FS.writeFile s!"Bench/{ds}/counterexample_results.json"
    (Json.mkObj [("refuted", Json.num refuted), ("total", Json.num recs.size),
                 ("results", Json.arr results)]).pretty
  IO.println s!"[{ds}] NOT-EQUIVALENT: {refuted}/{recs.size}"
  return 0
