import LeanDatabase.SQLEquiv
import LeanDatabase.LlmTactic.SQLEquivLLMPrompt
import Lean.Meta.Tactic.TryThis

/-!
# `sql_equiv_llm` — LLM-assisted fallback (Gemini / Claude / OpenAI)

Not imported by the `LeanDatabase` umbrella; lives under `LeanDatabase/LlmTactic/` (gitignored).
Runs an iterative AI↔elaborator loop: ask the model for a tactic, try it, and on failure feed the
elaboration error back for up to `maxRounds` rounds. Reports round-by-round status to the infoview.
On success applies the tactic; otherwise falls back to `sql_equiv`, and failing that leaves a `sorry`.
No axiom check — a `sorry`-writing candidate is accepted; treat results as provisional.
-/

open Lean Meta Elab Tactic Parser

namespace LeanDatabase.SQLEquivLLM

/-! ## Repo context -/

def coreModules : Array Name := #[
  `LeanDatabase.TypedRelation, `LeanDatabase.RelationalAlgebra, `LeanDatabase.SQLToolbox,
  `LeanDatabase.CurriedPredicates, `LeanDatabase.Constraints, `LeanDatabase.Operators]

def inCoreScope (mod : Name) : Bool := coreModules.any (fun m => m == mod || m.isPrefixOf mod)

/-- Auto-generated equation/congruence lemmas (`foo.eq_def`, `foo.eq_1`, `foo.congr_simp`, `foo.match_1`)
— noise for premise selection; the model has the def itself. -/
def isNoiseLemma (n : Name) : Bool :=
  match n.components.getLast? with
  | some c => let s := c.toString
    s == "eq_def" || s == "congr_simp" || s.startsWith "eq_" || s.startsWith "match_" ||
      s.startsWith "proof_"
  | none => false

def isAuxDecl (declName : Name) : CoreM Bool := do
  let env ← getEnv
  pure <| declName.isInternalDetail || isNoiseLemma declName || isAuxRecursor env declName
    || isNoConfusion env declName <||> isRec declName <||> isMatcher declName

/-- In-scope declaration names, scanned via the imported-module list (fast; avoids walking all consts). -/
def coreDeclsByModule : CoreM (Std.HashMap Name (Array Name)) := do
  let env ← getEnv
  let mut acc : Std.HashMap Name (Array Name) := {}
  for i in [0:env.header.moduleNames.size] do
    let modName := env.header.moduleNames[i]!
    if inCoreScope modName then
      let names ← env.header.moduleData[i]!.constNames.filterM (fun n => return !(← isAuxDecl n))
      acc := acc.insert modName names
  pure acc

def ppDeclEntry (n : Name) : MetaM String := do
  let env ← getEnv
  let some info := env.find? n | return ""
  let kind := if info.isTheorem then "theorem" else "def"
  let ty ← ppExpr info.type
  match ← findDocString? env n with
  | some doc =>
    -- first line of the docstring only (the gist), capped — full multi-line rationale is just bulk
    let line := ((doc.replace "\n" " ").take 140).toString
    pure s!"{kind} {n} : {ty}  -- {line}"
  | none => pure s!"{kind} {n} : {ty}"

/-- Modules whose `def`s are dropped: the opaque, uninterpreted scalar/string functions (~160). Their
theorems are still kept; opaque values are reasoned about by congruence, and the concrete scalar terms
appear in the goal anyway. -/
def noisyDefModules : Array Name := #[`LeanDatabase.Operators.Scalar, `LeanDatabase.Operators.Like]

/-- Essential relational decls that live in `Parser` (excluded as a module) but drive the standard
proof shape, plus structural lemmas — always kept regardless of goal relevance. -/
def alwaysInclude : Array Name := #[
  `LeanDatabase.TypedRelation.mapByList, `LeanDatabase.restriction, `LeanDatabase.dataEq,
  `LeanDatabase.TypedTupleOfList.cons_inj, `LeanDatabase.TypedTupleOfList.cons_nil_inj,
  `LeanDatabase.TypedTupleOfList.cons_succ]

/-- Whole modules always kept regardless of goal relevance: the cross-cutting proof-lemma library
`Constraints` (FD / partition / bijection lemmas). These connect to a goal only through definitional
unfolding (e.g. `COUNT(DISTINCT)` ⇝ `card (image …)`), which surface name-overlap can't see, so
premise selection would wrongly drop them. It is small, so always including it is cheap. -/
def alwaysIncludeModules : Array Name := #[`LeanDatabase.Constraints]

/-- Candidate decls (with the constants their type mentions) and the always-keep name set, cached
once. Candidates: all in-scope theorems + relational `def`s (opaque scalar/string `def`s excluded).
Always-keep: `alwaysInclude` names plus every decl in `alwaysIncludeModules`. -/
initialize candCache : IO.Ref (Option (Array (Name × Array Name) × Std.HashSet Name)) ← IO.mkRef none

def candidateDecls : MetaM (Array (Name × Array Name) × Std.HashSet Name) := do
  if let some c := ← candCache.get then return c
  let byModule ← coreDeclsByModule
  let env ← getEnv
  let mut cands : Array Name := alwaysInclude
  let mut always : Std.HashSet Name := Std.HashSet.ofArray alwaysInclude
  for (m, ns) in byModule.toList do
    for n in ns do
      if (env.find? n).any (·.isTheorem) || !noisyDefModules.contains m then cands := cands.push n
      if alwaysIncludeModules.contains m then always := always.insert n
  let out ← cands.filterMapM fun n => do
    match env.find? n with
    | some info => pure (some (n, info.type.getUsedConstants))
    | none => pure none
  candCache.set (some (out, always))
  pure (out, always)

/-- Constants that appear in more than a third of candidate types (`TypedRelation`, `TypedTupleOfList`,
`SQLTypeProxy`, `Finset`, …): ubiquitous, so they carry no relevance signal — matching on them would
select almost everything. Computed from the candidate set, not hard-coded. Cached. -/
initialize ubiqCache : IO.Ref (Option (Std.HashSet Name)) ← IO.mkRef none

def ubiquitousConsts : MetaM (Std.HashSet Name) := do
  if let some c := ← ubiqCache.get then return c
  let (cands, _) ← candidateDecls
  let mut df : Std.HashMap Name Nat := {}
  for (_, tc) in cands do
    for c in tc do df := df.insert c (df.getD c 0 + 1)
  let thresh := cands.size / 5
  let ubiq := Std.HashSet.ofArray (df.toArray.filterMap (fun (c, k) => if k > thresh then some c else none))
  ubiqCache.set (some ubiq)
  pure ubiq

/-- **Premise selection.** Repo-context filtered to what's relevant to THIS goal (like the harness's
column pruning, but for lemmas): keep a decl if it is named in the goal, if its type shares a
*discriminative* (non-ubiquitous) constant with the goal — a lemma about an operator the goal actually
uses — or if it is structurally essential (`alwaysInclude`). Sound (the candidate proof is still
elaborator-checked) and far leaner than dumping every decl. Theorems first, then defs. -/
def buildRepoContextFor (goalExpr : Expr) : MetaM String := do
  let (cands, always) ← candidateDecls
  let ubiq ← ubiquitousConsts
  let env ← getEnv
  let goalKeys := Std.HashSet.ofArray
    (goalExpr.getUsedConstants.filter (fun c => !ubiq.contains c))
  let goalConsts := Std.HashSet.ofArray goalExpr.getUsedConstants
  let relevant := cands.filter fun (n, tc) =>
    always.contains n || goalConsts.contains n || tc.any goalKeys.contains
  let isThm (n : Name) : Bool := (env.find? n).any (·.isTheorem)
  let names := (relevant.map (·.1)).qsort (fun a b => isThm a && !isThm b)
  let entries ← names.mapM ppDeclEntry
  pure (String.intercalate "\n" entries.toList)

/-! ## Providers -/

inductive Provider where | gemini | anthropic | openai
deriving DecidableEq, Repr

def Provider.name : Provider → String
  | .gemini => "Gemini" | .anthropic => "Claude" | .openai => "OpenAI"

def Provider.keyName : Provider → String
  | .gemini => "GEMINI_API_KEY" | .anthropic => "ANTHROPIC_API_KEY" | .openai => "OPENAI_API_KEY"

def Provider.defaultModel : Provider → String
  | .gemini => "gemini-3.0-pro"
  | .anthropic => "claude-5-sonnet"
  | .openai => "gpt-5.4"

/-- `KEY=value` lookup in a `.env` file at the project root. -/
def readDotEnv (key : String) : IO (Option String) := do
  let path : System.FilePath := ".env"
  unless ← path.pathExists do return none
  for raw in (← IO.FS.readFile path).splitOn "\n" do
    let line := raw.trimAscii.toString
    if line.startsWith s!"{key}=" then
      let v := (line.drop (key.length + 1)).trimAscii.toString
      if !v.isEmpty then return some v
  return none

/-- Provider key: env var, else `.env`. -/
def getKey (p : Provider) : IO String := do
  match ← IO.getEnv p.keyName with
  | some k => let k := k.trimAscii.toString; if !k.isEmpty then return k
  | none => pure ()
  match ← readDotEnv p.keyName with
  | some k => return k
  | none => throw <| IO.userError s!"{p.keyName} not set (checked env var and .env)"

/-- POST JSON to `url` via `curl` (temp file to dodge arg-length limits). -/
def curlPostJson (url : String) (headers : Array String) (body : Json) : IO Json := do
  IO.FS.withTempFile fun handle path => do
    handle.putStr body.pretty; handle.flush
    let hdrArgs := headers.foldl (fun acc h => acc ++ #["-H", h]) #[]
    let out ← IO.Process.output {
      cmd := "curl",
      args := #["-sS", "-X", "POST", url] ++ hdrArgs ++ #["--data", s!"@{path}"] }
    match Json.parse out.stdout with
    | .ok j => pure j
    | .error _ => throw (IO.userError s!"non-JSON response (curl exit {out.exitCode}): {out.stdout}")

def callOpenAI (key prompt model : String) (maxTokens : Nat) : IO String := do
  let body := Json.mkObj [("model", model),
    ("messages", Json.arr #[Json.mkObj [("role", "user"), ("content", prompt)]]),
    ("max_tokens", maxTokens)]
  let json ← curlPostJson "https://api.openai.com/v1/chat/completions"
    #[s!"Authorization: Bearer {key}", "Content-Type: application/json"] body
  if let .ok err := json.getObjVal? "error" then throw (IO.userError s!"OpenAI error: {err}")
  match json.getObjValAs? (Array Json) "choices" with
  | .error e => throw (IO.userError s!"OpenAI: no choices ({e})")
  | .ok cs => match cs[0]? >>= (·.getObjVal? "message" |>.toOption) >>=
      (·.getObjValAs? String "content" |>.toOption) with
    | some t => pure t | none => throw (IO.userError "OpenAI: no message.content")

def callAnthropic (key prompt model : String) (maxTokens : Nat) : IO String := do
  let body := Json.mkObj [("model", model), ("max_tokens", maxTokens),
    ("messages", Json.arr #[Json.mkObj [("role", "user"), ("content", prompt)]])]
  let json ← curlPostJson "https://api.anthropic.com/v1/messages"
    #[s!"x-api-key: {key}", "anthropic-version: 2023-06-01", "Content-Type: application/json"] body
  if let .ok err := json.getObjVal? "error" then throw (IO.userError s!"Anthropic error: {err}")
  match json.getObjValAs? (Array Json) "content" with
  | .error e => throw (IO.userError s!"Anthropic: no content ({e})")
  | .ok bs => match bs[0]? >>= (·.getObjValAs? String "text" |>.toOption) with
    | some t => pure t | none => throw (IO.userError "Anthropic: no text block")

def callGemini (key prompt model : String) (maxTokens : Nat) : IO String := do
  let body := Json.mkObj [
    ("contents", Json.arr #[Json.mkObj [("parts", Json.arr #[Json.mkObj [("text", prompt)]])]]),
    ("generationConfig", Json.mkObj [("maxOutputTokens", maxTokens)])]
  let url := s!"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
  let json ← curlPostJson url #["Content-Type: application/json"] body
  if let .ok err := json.getObjVal? "error" then throw (IO.userError s!"Gemini error: {err}")
  match json.getObjValAs? (Array Json) "candidates" with
  | .error e => throw (IO.userError s!"Gemini: no candidates ({e})")
  | .ok cs => match cs[0]? >>= (·.getObjVal? "content" |>.toOption) >>=
      (·.getObjValAs? (Array Json) "parts" |>.toOption) >>= (·[0]?) >>=
      (·.getObjValAs? String "text" |>.toOption) with
    | some t => pure t | none => throw (IO.userError "Gemini: no candidate text")

/-- One completion from `p`. -/
def callLLM (p : Provider) (prompt model : String) (maxTokens : Nat := 2048) : IO String := do
  let key ← getKey p
  match p with
  | .openai => callOpenAI key prompt model maxTokens
  | .anthropic => callAnthropic key prompt model maxTokens
  | .gemini => callGemini key prompt model maxTokens

/-! ## Parse / trial (prompt assembly is in `SQLEquivLLMPrompt.lean`) -/

/-- Drop a leading/trailing markdown code fence if present. -/
def stripFence (s : String) : String := Id.run do
  let s := s.trimAscii.toString
  if s.startsWith "```" then
    let s := (s.dropWhile (· != '\n')).trimAscii.toString
    return if s.endsWith "```" then (s.dropEnd 3).trimAscii.toString else s
  return s

/-- One-line, length-capped summary of an error, for the concise status line. -/
def shortErr (s : String) (length : Nat := 100) : String :=
  let s1 := ((s.replace "\n" " ").take length).toString
  s1 ++ (if s.length > length then "…" else "")

private def sHas (s sub : String) : Bool := (s.splitOn sub).length > 1

/-- Whether an error reads like an auth/key failure — retrying an invalid key is pointless, so the
loop stops after the first such call rather than burning all `maxRounds`. -/
def isAuthError (s : String) : Bool :=
  sHas s "API_KEY_INVALID" || sHas s "API key not valid" || sHas s "UNAUTHENTICATED" ||
  sHas s "PERMISSION_DENIED" || sHas s "invalid_api_key" || sHas s "Incorrect API key" ||
  sHas s "authentication" || sHas s "Unauthorized" || sHas s "not set (checked env var"

def parseCandidate (t : String) : CoreM (Option Syntax) := do
  match Parser.runParserCategory (← getEnv) `tactic s!"({stripFence t})" with
  | .ok stx => pure (some stx) | .error _ => pure none

/-- Trial `tac` on `goal`, state reverted; `.ok` if it closes it, else the error/left-goals message. -/
def trialCapture (goal : MVarId) (tac : Syntax) : TermElabM (Except String Unit) :=
  withoutModifyingState do
    try
      let (goals, _) ← Term.withoutErrToSorry do Elab.runTactic goal tac (← read) (← get)
      pure (if goals.isEmpty then .ok () else .error "tactic ran but left open goals")
    catch e => pure (.error (← e.toMessageData.toString))

/-! ## The tactic -/

def maxRounds : Nat := 5
def defaultProvider : Provider := .gemini

/-- LLM-assisted fallback. Order: (0) try the deterministic `sql_equiv`; (1) if that fails, run the
LLM refinement loop (up to `maxRounds`, stopping after the first call on an auth/key error); (2) if no
candidate closes it, try the LLM's last code with `sql_equiv` appended (`… <;> sql_equiv`) in case the
model got partway; (3) else leave a `sorry`. Concise status to the infoview; code to `Try this:`. -/
elab "sql_equiv_llm" : tactic => do
  let goal ← getMainGoal
  -- Step 0: deterministic `sql_equiv` first.
  let sqlEq ← `(tactic| sql_equiv)
  if let .ok _ ← trialCapture goal sqlEq then
    evalTactic sqlEq
    logInfo "LlmTactic: sql_equiv tactic PROVED the goal."
    TryThis.addSuggestion (← getRef) { suggestion := "sql_equiv" }
    return
  -- Step 1: LLM refinement loop.
  let goalText := (← Meta.ppGoal goal).pretty
  let context ← buildRepoContextFor (← goal.getType)
  let p := defaultProvider
  let model := p.defaultModel
  let mut feedback := ""
  let mut lastCode := ""
  let mut status : Array String := #["sql_equiv: failed"]
  let mut winner : Option Syntax := none
  let mut stop := false
  for round in [1:maxRounds+1] do
    if stop then break
    let resp ← (do try pure (.ok (← callLLM p (buildPrompt goalText context feedback) model))
                   catch e => pure (.error (← e.toMessageData.toString)) :
                   TacticM (Except String String))
    match resp with
    | .error e =>
      status := status.push s!"call{round}: NET-ERR ({shortErr e})"; feedback := ""
      if isAuthError e then status := status.push "auth error → stopping"; stop := true
    | .ok raw =>
      lastCode := stripFence raw
      match ← parseCandidate raw with
      | none => status := status.push s!"call{round}: 200 OK, parse-fail"
                feedback := "Your response did not parse as a Lean 4 tactic."
      | some stx =>
        match ← trialCapture goal stx with
        | .ok _ => status := status.push s!"call{round}: 200 OK, PROVED"; winner := some stx; break
        | .error e =>
          status := status.push s!"call{round}: 200 OK, failed"
          feedback := s!"Tactic:\n{lastCode}\nfailed with:\n{e.take 400}"
  let hdr := s!"LlmTactic: {p.name} ({model}) | " ++ String.intercalate " | " status.toList
  match winner with
  | some stx =>
    evalTactic stx
    logInfo s!"{hdr} → PROVED"
    TryThis.addSuggestion (← getRef) { suggestion := lastCode }
  | none =>
    -- Step 2: append `sql_equiv` to whatever the LLM last produced (in case it got partway).
    unless lastCode.isEmpty do
      if let some cstx ← parseCandidate s!"({lastCode}) <;> sql_equiv" then
        if let .ok _ ← trialCapture goal cstx then
          evalTactic cstx
          logInfo s!"{hdr} → PROVED by LLM code `<;> sql_equiv`"
          TryThis.addSuggestion (← getRef) { suggestion := s!"{lastCode} <;> sql_equiv" }
          return
    -- Step 3: give up cleanly with a `sorry`.
    evalTactic (← `(tactic| sorry))
    logInfo s!"{hdr} → FAILED; left `sorry`"
    unless lastCode.isEmpty do TryThis.addSuggestion (← getRef) { suggestion := lastCode }

end LeanDatabase.SQLEquivLLM
