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

/-- First line of a (possibly multi-line) error, truncated — the per-record progress lines stay one
line each. -/
def firstLine (s : String) : String :=
  let l := (s.splitOn "\n").headD s
  if l.length ≤ 120 then l else (l.take 120).toString ++ "…"

/-- Resolve a dataset name against the directories under `Bench/`, ignoring case, so `literature`
finds `Bench/Literature`. -/
def resolveDataset (ds : String) : IO (Option String) := do
  let root : System.FilePath := "Bench"
  unless ← root.pathExists do return none
  for e in (← root.readDir) do
    let name := e.fileName
    if name.toLower == ds.toLower && (← (root / name).isDir) then return some name
  return none

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
  let s := if s.endsWith ":eq" then (s.dropEnd 3).toString else s
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
  -- The theorem is stated **applied to table binders** (`(t0 : TableRel A_schema) … : q₁ t0 ~= q₂ t0`),
  -- the same goal the census proves: `~=` compares rows only, and it is not defined on the *function*
  -- `sql%` returns, so a bare `q₁ ~= q₂` would not even typecheck. A non-`dataEq` pair keeps `=`.
  let binders := String.join ((refs.zipIdx).map fun (schemaName, i) =>
    s!" (t{i} : TableRel {schemaName})")
  let args := String.join ((refs.zipIdx).map fun (_, i) => s!" t{i}")
  let op := if (rec.getObjValAs? Bool "dataEq").toOption.getD true then "~=" else "="
  "import LeanDatabase.Parser\nimport LeanDatabase.SQLSyntax\nopen LeanDatabase Lean\n" ++
  "set_option maxHeartbeats 1000000\nset_option maxRecDepth 1000000\n\n" ++
  s!"namespace {ns}\n\n{creates}\n" ++
  s!"theorem eq{binders} :\n    (sql%([{reflist}]) \"{escapeSql first}\"){args}\n" ++
  s!"  {op} (sql%([{reflist}]) \"{escapeSql second}\"){args}\n  := by {tactic}\n\n" ++
  s!"end {ns}\n"

unsafe def runElabCensus (env : Environment) (ctx : Core.Context) (ds : String) : IO Unit := do
  let path : System.FilePath := s!"Bench/{ds}/corpus_pg.json"
  unless ← path.pathExists do IO.println s!"[{ds}] no corpus_pg.json, skipping elab"; return
  let .ok (.arr recs) := Json.parse (← IO.FS.readFile path) | return
  let mut ok : Nat := 0
  let mut results : Array Json := #[]
  for h : i in [0 : recs.size] do
    let r := recs[i]
    let id := (r.getObjValAs? String "id").toOption.getD "?"
    let ctx := { ctx with initHeartbeats := (← IO.getNumHeartbeats) }
    let v ← ((elabCheckCore r).run' ctx { env := env }).toIO'
    let status := match v with
      | .ok j => (j.getObjValAs? String "status").toOption.getD "fail"
      | .error _ => "fail"
    let err := match v with | .ok j => (j.getObjValAs? String "error").toOption.getD "?" | .error _ => "exn"
    if status == "ok" then ok := ok + 1
    -- One line per query, flushed, so a long census shows progress instead of going silent.
    IO.println (if status == "ok" then s!"[{ds}] elab {i + 1}/{recs.size} ok    {id}"
                else s!"[{ds}] elab {i + 1}/{recs.size} FAIL  {id}: {firstLine err}")
    (← IO.getStdout).flush
    results := results.push (Json.mkObj [("id", Json.str id), ("status", Json.str status),
      ("error", if status == "ok" then Json.null else Json.str err)])
  IO.FS.writeFile s!"Bench/{ds}/elab_results.json"
    (Json.mkObj [("elaborates", Json.num ok), ("total", Json.num recs.size),
                 ("results", Json.arr results)]).pretty
  IO.println s!"[{ds}] ELABORATES: {ok}/{recs.size}"

/-- Fast pass: clear both dirs and write EVERY pair to `Problems/` (the complete set). `Proven/` (a
subset) is filled later by proving. Runs for all datasets before any slow census so files appear at once. -/
def populateProblems (ds : String) : IO Unit := do
  let path : System.FilePath := s!"Bench/{ds}/pairs.json"
  unless ← path.pathExists do IO.println s!"[{ds}] no pairs.json"; return
  let .ok (.arr recs) := Json.parse (← IO.FS.readFile path) | return
  for dir in [s!"Bench/{ds}/Proven", s!"Bench/{ds}/Problems"] do
    let d : System.FilePath := dir
    if ← d.pathExists then
      for e in (← d.readDir) do
        if e.path.extension == some "lean" then IO.FS.removeFile e.path
    IO.FS.createDirAll dir
  for rec in recs do
    let base := fileBase ((rec.getObjValAs? String "id").toOption.getD "?")
    IO.FS.writeFile s!"Bench/{ds}/Problems/{base}.lean" (genTheorem rec "first | sql_equiv | sorry")
  IO.println s!"[{ds}] Problems: {recs.size} (all pairs)"

unsafe def runProveSync (env : Environment) (ctx : Core.Context) (ds : String) : IO Unit := do
  let path : System.FilePath := s!"Bench/{ds}/pairs.json"
  unless ← path.pathExists do return
  let .ok (.arr recs) := Json.parse (← IO.FS.readFile path) | return
  let mut proved : Nat := 0
  let mut elaborated : Nat := 0
  let mut refuted : Nat := 0
  let mut timeouts : Nat := 0
  let mut results : Array Json := #[]
  -- One pass per pair (file-wise): `provePair` parses + elaborates both queries, THEN runs `sql_equiv`
  -- — so a single call gives us both statuses. An exception (`err`) means it never elaborated; no error
  -- + `proved` false means it elaborated but the tactic couldn't close it.
  for h : i in [0 : recs.size] do
    let r := recs[i]
    let id := (r.getObjValAs? String "id").toOption.getD "?"
    let base := fileBase id
    let ctx := { ctx with initHeartbeats := (← IO.getNumHeartbeats) }
    let v ← ((provePairCore r).run' ctx { env := env }).toIO'
    let (ok, err, cex, didElab) ← match v with
      | .ok j => pure ((j.getObjValAs? Bool "proved").toOption.getD false,
                       (j.getObjValAs? String "error").toOption,
                       (j.getObjValAs? String "counterexample").toOption,
                       -- Reported by `provePair`, not inferred: a proof that ran out of budget
                       -- elaborated perfectly well, and used to be miscounted as ELAB-FAIL.
                       (j.getObjValAs? Bool "elaborated").toOption.getD false)
      | .error e => do pure (false, some s!"exception: {← e.toMessageData.toString}", none, false)
    let timedOut : Bool := match err with | some e => (e.splitOn "heartbeats").length ≥ 2 | none => false
    -- A timeout escapes `provePair` before it can report anything, but only the *tactic* raises one:
    -- a query that fails to elaborate comes back as a clean error instead. So it did elaborate.
    let didElab := didElab || timedOut
    if timedOut then timeouts := timeouts + 1
    if didElab then elaborated := elaborated + 1
    if ok then
      proved := proved + 1
      IO.FS.writeFile s!"Bench/{ds}/Proven/{base}.lean" (genTheorem r "sql_equiv")
    if cex.isSome then refuted := refuted + 1
    -- One line per pair, flushed. Status: PROVED | COUNTEREX (the search found a database where the
    -- two queries differ — not an equivalence at all) | TIMEOUT | UNPROVED | ELAB-FAIL.
    let tag := if ok then "PROVED   " else if cex.isSome then "COUNTEREX"
               else if timedOut then "TIMEOUT  "
               else if didElab then "UNPROVED " else "ELAB-FAIL"
    -- For a counterexample the database itself is the useful part of the message.
    let note := match cex, err with
      | some c, _ => " | " ++ " ".intercalate ((c.splitOn "\n").filter (fun l => (l.splitOn ":=").length ≥ 2))
      | none, some e => s!": {firstLine e}"
      | none, none => ""
    IO.println s!"[{ds}] {i + 1}/{recs.size} {tag} {id}{note}"
    (← IO.getStdout).flush
    results := results.push (Json.mkObj [("id", Json.str id), ("proved", Json.bool ok),
      ("elaborated", Json.bool didElab),
      ("counterexample", match cex with | some c => Json.str c | none => Json.null),
      ("error", match err with | some e => Json.str e | none => Json.null)])
  IO.FS.writeFile s!"Bench/{ds}/prove_results.json"
    (Json.mkObj [("proved", Json.num proved), ("elaborated", Json.num elaborated),
                 ("counterexamples", Json.num refuted), ("timeouts", Json.num timeouts),
                 ("total", Json.num recs.size), ("results", Json.arr results)]).pretty
  -- Timeouts are counted apart from elaboration: when the budget runs out the exception escapes
  -- before we learn how far it got, so those pairs are "unknown", not "did not elaborate".
  IO.println s!"[{ds}] elaborated {elaborated}/{recs.size}, PROVED {proved}/{recs.size}, \
    NOT-EQUIVALENT {refuted}/{recs.size}, TIMEOUT {timeouts}/{recs.size} (Proven ⊆ Problems)"

unsafe def main (args : List String) : IO UInt32 := do
  enableInitializersExecution
  initSearchPath (← findSysroot)
  IO.println "runall: loading Mathlib + LeanDatabase environment (~1 min)…"
  (← IO.getStdout).flush
  let env ← importModules (loadExts := true) #[{module := `Mathlib}, {module := `LeanDatabase}] {}
  IO.println "runall: environment loaded."; (← IO.getStdout).flush
  -- Heartbeats: the `Core.Context.maxHeartbeats` FIELD is in raw units = 1000× the `maxHeartbeats`
  -- *option*, whose default is 200000 (field 200_000_000). We use 4× the default (~30 s of work) so
  -- proofs that need a bit longer succeed while failures still trip in bounded time.
  -- `maxRecDepth` is kept MODERATE (not ~1M): a runaway recursion (e.g. a malformed query) must hit the
  -- Lean recursion-depth *error* — which `provePairCore` catches — before it overflows the OS stack.
  let opts := Lean.maxRecDepth.set (Lean.maxHeartbeats.set {} 800000) 8000
  let ctx : Core.Context :=
    { fileName := "", fileMap := { source := "", positions := #[] },
      -- Wide-schema pairs (the seven-table university queries) elaborate to very large terms; at
      -- 800M the *proof* ran out of budget on six of them and the census reported them as if the SQL
      -- were unsupported. Proving is the expensive half, so give it room.
      options := opts, maxHeartbeats := 3000000000, maxRecDepth := 8000 }
  let requested := if args.isEmpty then ["CrossSkill", "Calcite", "Literature"] else args
  let mut datasets := []
  for ds in requested do
    match ← resolveDataset ds with
    | some real => datasets := datasets ++ [real]
    | none => IO.eprintln s!"unknown dataset `{ds}` — no directory Bench/{ds}"
  if datasets.isEmpty then return 1
  -- First, populate every dataset's Problems/ (fast) so all appear immediately.
  for ds in datasets do populateProblems ds
  -- Then the slow work: one file-wise pass per dataset that elaborates + proves each pair (proving
  -- subsumes elaboration, so there is no separate elab census here — use `elabcheck` for the
  -- per-query corpus_pg.json coverage metric, which is a different granularity).
  for ds in datasets do
    IO.println s!"=== {ds} ==="
    runProveSync env ctx ds
  return 0
