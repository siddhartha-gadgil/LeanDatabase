import Lean.Meta
import LeanDatabase.Refute
open Lean LeanDatabase

set_option maxHeartbeats 10000000
set_option maxRecDepth 1000000

/-!
# `refute` — bounded counterexample search over a dataset

`lake exe refute <dataset> [bound] [tries]` runs `refutePair` over `Bench/<dataset>/pairs.json` and
writes `refute_results.json`. A hit means the pair is **not** an equivalence, so the proving census
should not be chasing it; silence means only that no small counterexample was found.
-/

unsafe def main (args : List String) : IO UInt32 := do
  enableInitializersExecution
  initSearchPath (← findSysroot)
  -- `LeanDatabase.Refute` explicitly: the root module does not import it, and the evaluated term
  -- mentions `rowsEqB`, which must exist in the *runtime* environment.
  let env ← importModules (loadExts := true)
    #[{module := `Mathlib}, {module := `LeanDatabase}, {module := `LeanDatabase.Refute}] {}
  let ds := args.headD "Literature"
  let bound := (args[1]?).bind (·.toNat?) |>.getD 2
  let tries := (args[2]?).bind (·.toNat?) |>.getD 24
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
    let v ← ((refutePairCore r bound tries).run' ctx { env := env }).toIO'
    let j := v.toOption.getD (Json.mkObj [("refuted", Json.bool false)])
    let hit := (j.getObjValAs? Bool "refuted").toOption.getD false
    if hit then refuted := refuted + 1
    let err := (j.getObjValAs? String "error").toOption
    IO.println (if hit then s!"[{ds}] refute {i + 1}/{recs.size} NOT-EQUIVALENT {id}"
                else s!"[{ds}] refute {i + 1}/{recs.size} no counterexample {id}"
                     ++ (match err with | some e => s!": {(e.splitOn "\n").headD e}" | none => ""))
    (← IO.getStdout).flush
    results := results.push (Json.mkObj [("id", Json.str id), ("refuted", Json.bool hit),
      ("error", match err with | some e => Json.str e | none => Json.null)])
  IO.FS.writeFile s!"Bench/{ds}/refute_results.json"
    (Json.mkObj [("refuted", Json.num refuted), ("total", Json.num recs.size),
                 ("results", Json.arr results)]).pretty
  IO.println s!"[{ds}] REFUTED: {refuted}/{recs.size} (bound {bound}, {tries} tries)"
  return 0
