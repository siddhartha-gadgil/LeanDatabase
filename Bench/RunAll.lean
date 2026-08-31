import Lean.Meta
import LeanDatabase.Check
import LeanDatabase.SQLEquiv
open Lean LeanDatabase

set_option maxHeartbeats 10000000
set_option maxRecDepth 1000000

/-!
# `runall` — one runner for every benchmark dataset

For each dataset under `Bench/` (default: CrossSkill, Calcite, Literature) this:
1. runs the **elaboration census** over `corpus_pg.json` → `elab_results.json`;
2. runs the **proving census** over `pairs.json`, and **syncs** each pair's `.lean` file — a proving
   pair lands in `Proven/` (`by sql_equiv`), a non-proving one in `Problems/` (`first | sql_equiv |
   sorry`), moving files across as verdicts flip → `prove_results.json` (with per-pair errors).

`lake exe runall [dataset …]`. There is no separate regression build: the sync keeps `Proven/` exactly
the set that proves right now, so a regression just moves a file back to `Problems/` and is recorded.
-/

/-- Map a JSON column type to the DDL keyword our `CREATE TABLE` macro accepts. -/
def ddlType (t : String) : String :=
  match t.toUpper with
  | "INT" | "INTEGER" | "BIGINT" => "INT"
  | "FLOAT" | "DOUBLE" | "DECIMAL" | "REAL" | "NUMERIC" => "FLOAT"
  | "BOOL" | "BOOLEAN" => "BOOL"
  | "TIMESTAMP" | "DATE" | "DATETIME" => "TIMESTAMP"
  | _ => "STRING"

/-- Sanitise an id into a valid identifier component (for the namespace). -/
def sanitizeIdent (s : String) : String :=
  let cs := s.toList.map fun c => if c.isAlphanum then c else '_'
  "N_" ++ String.ofList cs

/-- Filename base for a pair id (`1:eq` → `1`; `sf035:eq_0_1` → `sf035_eq_0_1`). -/
def fileBase (s : String) : String :=
  let s := if s.endsWith ":eq" then s.dropRight 3 else s
  String.ofList (s.toList.map fun c => if c.isAlphanum then c else '_')

def escapeSql (s : String) : String := (s.replace "\\" "\\\\").replace "\"" "\\\""

/-- Build the `.lean` content for one pair: `CREATE TABLE`s + a `sql%A = sql%B := by <tactic>`. -/
def genTheorem (rec : Json) (tactic : String) : String := Id.run do
  let id := (rec.getObjValAs? String "id").toOption.getD "?"
  let first := (rec.getObjValAs? String "first").toOption.getD ""
  let second := (rec.getObjValAs? String "second").toOption.getD ""
  let schemas := (rec.getObjValAs? (List Json) "schemas").toOption.getD []
  let mut creates := ""
  let mut refs : List String := []
  for s in schemas do
    let name := (s.getObjValAs? String "name").toOption.getD "T"
    let cols := (s.getObjValAs? (List Json) "columns").toOption.getD []
    let colDdl := ", ".intercalate (cols.map fun c =>
      let cn := (c.getObjValAs? String "name").toOption.getD "c"
      let ct := ddlType ((c.getObjValAs? String "type").toOption.getD "STRING")
      s!"«{cn}» {ct}")
    creates := creates ++ s!"CREATE TABLE {name} ({colDdl})\n"
    refs := refs ++ [s!"{name}_schema"]
  let ns := sanitizeIdent id
  let reflist := ", ".intercalate refs
  "import LeanDatabase.Parser\nimport LeanDatabase.SQLSyntax\nopen LeanDatabase Lean\n" ++
  "set_option maxHeartbeats 1000000\nset_option maxRecDepth 1000000\n\n" ++
  s!"namespace {ns}\n\n{creates}\n" ++
  s!"theorem eq :\n    sql%([{reflist}]) \"{escapeSql first}\"\n" ++
  s!"  = sql%([{reflist}]) \"{escapeSql second}\"\n  := by {tactic}\n\n" ++
  s!"end {ns}\n"

/-- Remove a pair's file from a directory if present. -/
def rmIfExists (dir base : String) : IO Unit := do
  let p : System.FilePath := s!"{dir}/{base}.lean"
  if ← p.pathExists then IO.FS.removeFile p

unsafe def runElabCensus (env : Environment) (ctx : Core.Context) (ds : String) : IO Unit := do
  let path : System.FilePath := s!"Bench/{ds}/corpus_pg.json"
  unless ← path.pathExists do IO.println s!"[{ds}] no corpus_pg.json, skipping elab"; return
  let .ok (.arr recs) := Json.parse (← IO.FS.readFile path) | return
  let mut ok : Nat := 0
  let mut results : Array Json := #[]
  for rec in recs do
    let id := (rec.getObjValAs? String "id").toOption.getD "?"
    let ctx := { ctx with initHeartbeats := (← IO.getNumHeartbeats) }
    let v ← ((elabCheckCore rec).run' ctx { env := env }).toIO'
    let status := match v with
      | .ok j => (j.getObjValAs? String "status").toOption.getD "fail"
      | .error _ => "fail"
    let err := match v with | .ok j => (j.getObjValAs? String "error").toOption.getD "?" | .error _ => "exn"
    if status == "ok" then ok := ok + 1
    results := results.push (Json.mkObj [("id", Json.str id), ("status", Json.str status),
      ("error", if status == "ok" then Json.null else Json.str err)])
  IO.FS.writeFile s!"Bench/{ds}/elab_results.json"
    (Json.mkObj [("elaborates", Json.num ok), ("total", Json.num recs.size),
                 ("results", Json.arr results)]).pretty
  IO.println s!"[{ds}] ELABORATES: {ok}/{recs.size}"

unsafe def runProveSync (env : Environment) (ctx : Core.Context) (ds : String) : IO Unit := do
  let path : System.FilePath := s!"Bench/{ds}/pairs.json"
  unless ← path.pathExists do IO.println s!"[{ds}] no pairs.json, skipping prove"; return
  let .ok (.arr recs) := Json.parse (← IO.FS.readFile path) | return
  -- Authoritative: clear both dirs, then regenerate every pair into exactly one of them.
  for dir in [s!"Bench/{ds}/Proven", s!"Bench/{ds}/Problems"] do
    let d : System.FilePath := dir
    if ← d.pathExists then
      for e in (← d.readDir) do
        if e.path.extension == some "lean" then IO.FS.removeFile e.path
    IO.FS.createDirAll dir
  let mut proved : Nat := 0
  let mut results : Array Json := #[]
  for rec in recs do
    let id := (rec.getObjValAs? String "id").toOption.getD "?"
    let base := fileBase id
    let ctx := { ctx with initHeartbeats := (← IO.getNumHeartbeats) }
    let v ← ((provePairCore rec).run' ctx { env := env }).toIO'
    let (ok, err) ← match v with
      | .ok j => pure ((j.getObjValAs? Bool "proved").toOption.getD false,
                       (j.getObjValAs? String "error").toOption)
      | .error e => do pure (false, some s!"exception: {← e.toMessageData.toString}")
    -- Sync: proving → Proven/, else → Problems/. Remove the stale counterpart.
    if ok then
      proved := proved + 1
      rmIfExists s!"Bench/{ds}/Problems" base
      IO.FS.writeFile s!"Bench/{ds}/Proven/{base}.lean" (genTheorem rec "sql_equiv")
    else
      rmIfExists s!"Bench/{ds}/Proven" base
      IO.FS.writeFile s!"Bench/{ds}/Problems/{base}.lean" (genTheorem rec "first | sql_equiv | sorry")
    results := results.push (Json.mkObj [("id", Json.str id), ("proved", Json.bool ok),
      ("error", match err with | some e => Json.str e | none => Json.null)])
  IO.FS.writeFile s!"Bench/{ds}/prove_results.json"
    (Json.mkObj [("proved", Json.num proved), ("total", Json.num recs.size),
                 ("results", Json.arr results)]).pretty
  IO.println s!"[{ds}] PROVED: {proved}/{recs.size}"

unsafe def main (args : List String) : IO UInt32 := do
  enableInitializersExecution
  initSearchPath (← findSysroot)
  let env ← importModules (loadExts := true) #[{module := `Mathlib}, {module := `LeanDatabase}] {}
  let ctx : Core.Context :=
    { fileName := "", fileMap := { source := "", positions := #[] },
      options := Lean.maxRecDepth.set {} 1000000, maxHeartbeats := 100000000, maxRecDepth := 1000000 }
  let datasets := if args.isEmpty then ["CrossSkill", "Calcite", "Literature"] else args
  for ds in datasets do
    IO.println s!"=== {ds} ==="
    runElabCensus env ctx ds
    runProveSync env ctx ds
  return 0
