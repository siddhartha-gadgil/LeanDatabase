import LeanDatabase.SQLEquiv
import LeanDatabase.LlmTactic.SQLEquivLLMPrompt
import LeanDatabase.LlmTactic.SQLEquivCounterex
import Lean.Meta.Tactic.TryThis

/-!
# `sql_equiv_llm` — LLM-assisted fallback (Gemini / Claude / OpenAI)

Not imported by the `LeanDatabase` umbrella; lives under `LeanDatabase/LlmTactic/`.
Order: try the deterministic `sql_equiv` first; if it fails, run an iterative AI↔elaborator loop —
ask the model for a tactic, try it, and on failure feed the elaboration error back for up to
`maxRounds` rounds; if none closes it, try the model's last code with `sql_equiv` appended; else leave
a `sorry`. Reports round-by-round status to the infoview. Candidates that close the goal via
`sorry` are **rejected** (that would "prove" anything), so an accepted proof is real.
-/

open Lean Meta Elab Tactic Parser

/-- Provider for `sql_equiv_llm`, settable per-file: `set_option sqlEquivLlm.provider "anthropic"`.
Accepts `gemini` | `anthropic` (`claude`) | `openai` (`gpt`); empty ⇒ the built-in default. -/
register_option sqlEquivLlm.provider : String := {
  defValue := ""
  descr := "LLM provider for sql_equiv_llm: gemini | anthropic | openai (empty = default)"
}

/-- Model for `sql_equiv_llm`, settable per-file: `set_option sqlEquivLlm.model "gemini-3.0-pro"`.
Empty ⇒ the chosen provider's default model. -/
register_option sqlEquivLlm.model : String := {
  defValue := ""
  descr := "Model name for sql_equiv_llm (empty = the provider's default)"
}

/-- Price of INPUT (prompt) tokens, in **cents per 1,000,000 tokens** (options can't be `Float`).
E.g. $0.25 / 1M input tokens ⇒ 25. Set to your model's real rate; default ≈ a cheap gpt-5.x tier. -/
register_option sqlEquivLlm.inputCentsPerMTok : Nat := {
  defValue := 25
  descr := "Input/prompt token price in cents per 1M tokens (for the cost estimate)"
}

/-- Price of OUTPUT (completion) tokens, in **cents per 1,000,000 tokens**. E.g. $2.00 / 1M ⇒ 200. -/
register_option sqlEquivLlm.outputCentsPerMTok : Nat := {
  defValue := 200
  descr := "Output/completion token price in cents per 1M tokens (for the cost estimate)"
}

namespace LeanDatabase.SQLEquivLLM

/-! ## Providers -/

inductive Provider where | gemini | anthropic | openai
deriving DecidableEq, Repr

def Provider.name : Provider → String
  | .gemini => "Gemini" | .anthropic => "Claude" | .openai => "OpenAI"

def Provider.keyName : Provider → String
  | .gemini => "GEMINI_API_KEY" | .anthropic => "ANTHROPIC_API_KEY" | .openai => "OPENAI_API_KEY"

def Provider.defaultModel : Provider → String
  | .gemini => "gemini-pro-latest"
  | .anthropic => "claude-5-sonnet"
  | .openai => "gpt-5.6"

/-- Parse the `sqlEquivLlm.provider` option string; unknown/empty ⇒ `dflt`. -/
def Provider.ofString? (s : String) (dflt : Provider) : Provider :=
  match s.trimAscii.toString.toLower with
  | "gemini" | "google" => .gemini
  | "anthropic" | "claude" => .anthropic
  | "openai" | "gpt" => .openai
  | _ => dflt

/-- Strip one layer of matching surrounding `"`/`'` quotes (as `.env` values are often written). -/
def unquote (s : String) : String :=
  if s.length ≥ 2 && ((s.startsWith "\"" && s.endsWith "\"") || (s.startsWith "'" && s.endsWith "'"))
  then (s.drop 1 |>.dropEnd 1).toString else s

/-- `KEY=value` lookup in a `.env` file at the project root. Handles an optional `export ` prefix and
surrounding quotes on the value (python-dotenv semantics), which the raw provider APIs reject. -/
def readDotEnv (key : String) : IO (Option String) := do
  let path : System.FilePath := ".env"
  unless ← path.pathExists do return none
  for raw in (← IO.FS.readFile path).splitOn "\n" do
    let line := raw.trimAscii.toString
    let line := if line.startsWith "export " then (line.drop 7).trimAscii.toString else line
    if line.startsWith s!"{key}=" then
      let v := unquote (line.drop (key.length + 1)).trimAscii.toString
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

/-- Token counts `(promptTokens, completionTokens)` from a response's `usage` object, under the given
key names (OpenAI/Gemini: `prompt_tokens`/`completion_tokens`; Anthropic: `input_tokens`/`output_tokens`).
Missing ⇒ `(0, 0)`. -/
def getUsage (json : Json) (pk ck : String) : Nat × Nat :=
  match json.getObjVal? "usage" with
  | .ok u => ((u.getObjValAs? Nat pk).toOption.getD 0, (u.getObjValAs? Nat ck).toOption.getD 0)
  | .error _ => (0, 0)

/-- A completion plus its `(promptTokens, completionTokens)` usage. -/
abbrev LLMResult := String × Nat × Nat

def callOpenAI (key prompt model : String) (maxTokens : Nat) : IO LLMResult := do
  -- Newer OpenAI models (gpt-5.x) reject `max_tokens` and require `max_completion_tokens`; reasoning
  -- tokens count against it, so the budget must comfortably cover reasoning *and* the emitted proof, or
  -- `content` comes back empty. `reasoning_effort: medium` keeps the reasoning spend bounded.
  let body := Json.mkObj [("model", model),
    ("messages", Json.arr #[Json.mkObj [("role", "user"), ("content", prompt)]]),
    ("reasoning_effort", "high"),
    ("max_completion_tokens", maxTokens)]
  let json ← curlPostJson "https://api.openai.com/v1/chat/completions"
    #[s!"Authorization: Bearer {key}", "Content-Type: application/json"] body
  if let .ok err := json.getObjVal? "error" then throw (IO.userError s!"OpenAI error: {err}")
  let (pt, ct) := getUsage json "prompt_tokens" "completion_tokens"
  match json.getObjValAs? (Array Json) "choices" with
  | .error e => throw (IO.userError s!"OpenAI: no choices ({e})")
  | .ok cs => match cs[0]? >>= (·.getObjVal? "message" |>.toOption) >>=
      (·.getObjValAs? String "content" |>.toOption) with
    | some t =>
      if t.trim.isEmpty then
        throw (IO.userError s!"OpenAI: empty content (finish/usage: {ct} completion tokens — likely the reasoning+output budget was exhausted)")
      else pure (t, pt, ct)
    | none => throw (IO.userError "OpenAI: no message.content")

def callAnthropic (key prompt model : String) (maxTokens : Nat) : IO LLMResult := do
  let body := Json.mkObj [("model", model), ("max_tokens", maxTokens),
    ("messages", Json.arr #[Json.mkObj [("role", "user"), ("content", prompt)]])]
  let json ← curlPostJson "https://api.anthropic.com/v1/messages"
    #[s!"x-api-key: {key}", "anthropic-version: 2023-06-01", "Content-Type: application/json"] body
  if let .ok err := json.getObjVal? "error" then throw (IO.userError s!"Anthropic error: {err}")
  let (pt, ct) := getUsage json "input_tokens" "output_tokens"
  match json.getObjValAs? (Array Json) "content" with
  | .error e => throw (IO.userError s!"Anthropic: no content ({e})")
  | .ok bs => match bs[0]? >>= (·.getObjValAs? String "text" |>.toOption) with
    | some t => pure (t, pt, ct) | none => throw (IO.userError "Anthropic: no text block")

-- Gemini via Google's OpenAI-compatible endpoint (Bearer auth + chat/completions) — the native
-- `generateContent?key=` route rejects OpenAI-style keys with "API key not valid". Matches the
-- proven-working `PyAstLean/src/transpile/llm.py` client.
def callGemini (key prompt model : String) (maxTokens : Nat) : IO LLMResult := do
  let body := Json.mkObj [("model", model),
    ("messages", Json.arr #[Json.mkObj [("role", "user"), ("content", prompt)]]),
    ("max_tokens", maxTokens)]
  let json ← curlPostJson "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
    #[s!"Authorization: Bearer {key}", "Content-Type: application/json"] body
  if let .ok err := json.getObjVal? "error" then throw (IO.userError s!"Gemini error: {err}")
  let (pt, ct) := getUsage json "prompt_tokens" "completion_tokens"
  match json.getObjValAs? (Array Json) "choices" with
  | .error e => throw (IO.userError s!"Gemini: no choices ({e})")
  | .ok cs => match cs[0]? >>= (·.getObjVal? "message" |>.toOption) >>=
      (·.getObjValAs? String "content" |>.toOption) with
    | some t => pure (t, pt, ct) | none => throw (IO.userError "Gemini: no message.content")

/-- One completion from `p`, with its token usage. Budget must cover a reasoning model's hidden
reasoning tokens plus the emitted proof. -/
def callLLM (p : Provider) (prompt model : String) (maxTokens : Nat := 32768) : IO LLMResult := do
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

/-- The repo's own high-level tactics, which a candidate must not call: `sql_equiv`/`sql_equiv_safe`
have already been run (Step 0) without closing the goal, and `sql_membership`/`sql_big_goal` can hit an
*uncatchable* deterministic timeout that would abort the whole tactic. Returns the offending name, if
any (`sql_equiv` also matches `sql_equiv_safe`/`sql_equiv_llm`). -/
def usesBannedTactic (code : String) : Option String :=
  ["sql_equiv", "sql_membership", "sql_big_goal"].find? (fun n => (code.splitOn n).length > 1)

/-- Estimated cost **in cents** for a problem from its accumulated token usage and the per-1M-token
cent prices: `(promptTok × inputCents + completionTok × outputCents) / 1e6`. -/
def estCostCents (promptTok completionTok inputCents outputCents : Nat) : Float :=
  (promptTok.toFloat * inputCents.toFloat + completionTok.toFloat * outputCents.toFloat) / 1000000.0

/-- Round a cent amount to 4 decimal places for display. -/
def fmtCents (cents : Float) : String :=
  s!"{(cents * 10000.0).round / 10000.0}¢"

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

-- Wrap the reply as a parenthesised tactic block on its OWN lines: `(\n<seq>\n)`. Models reply with
-- multi-line proofs using `·` focus bullets, `constructor`, `rcases … with ⟨…⟩`; the newline layout
-- keeps bullet columns aligned so the block parses (inline `(<seq>)` collapses the columns and fails).
def parseCandidate (t : String) : CoreM (Option Syntax) := do
  match Parser.runParserCategory (← getEnv) `tactic s!"(\n{stripFence t}\n)" with
  | .ok stx => pure (some stx) | .error _ => pure none

/-- Trial `tac` on `goal`, state reverted; `.ok` only if it closes it with a **`sorry`-free** proof,
else the error/left-goals message. Rejecting `sorry` is a soundness gate — a model that
replies `sorry` "closes" any goal, even a false one. Runs via `evalTactic` in `TacticM` (not
`Elab.runTactic`, which caps the trial at the default heartbeats and times a heavy proof out
uncatchably before it closes); the ambient budget is the file's. -/
def trialCapture (goal : MVarId) (tac : Syntax) : TacticM (Except String Unit) := do
  let saved ← saveState
  -- Delaborating the residual `~=`/join goal for the feedback message drives heavy instance search;
  -- the default `synthInstance.maxHeartbeats` (20000) trips there and its timeout is uncatchable, so
  -- raise it. (The candidate's own budget is the ambient one, already the file's.)
  let res ← withOptions (Lean.Meta.synthInstance.maxHeartbeats.set · 1000000) <| (try
      evalTactic tac
      let goals ← getUnsolvedGoals
      if !goals.isEmpty then
        -- Report the *residual* goal state, not just "left open goals" — that's what lets the model
        -- fix its next attempt.
        let states ← goals.mapM fun g => return (← Meta.ppGoal g).pretty
        pure (.error s!"tactic ran but left {goals.length} open goal(s):\n{String.intercalate "\n---\n" states}")
      else if (← instantiateMVars (mkMVar goal)).hasSorry then
        pure (.error "closed the goal with `sorry` — that is not a proof; prove it for real")
      else pure (.ok ())
    catch e => pure (.error (← e.toMessageData.toString)))
  saved.restore
  pure res

/-- Run `tac` on `goal` (the main goal); return `true` iff it fully closes it with a **`sorry`-free**
proof. On failure, a partial result, or a `sorry`-based closure the state is rolled back and no error
escapes — so the caller can safely try another tactic. (A bare `evalTactic` would let a failed
candidate's `grind`/`apply` error propagate to the call site, and a `sorry` reply would be accepted.) -/
def tryClose (goal : MVarId) (tac : Syntax) : TacticM Bool := do
  let saved ← saveState
  let ok ← (withOptions (Lean.Meta.synthInstance.maxHeartbeats.set · 1000000) <| try
      evalTactic tac
      if (← getUnsolvedGoals).isEmpty then
        pure !(← instantiateMVars (mkMVar goal)).hasSorry
      else pure false
    catch _ => pure false)
  unless ok do saved.restore
  pure ok

/-- Emit a `Try this:` suggestion whose continuation lines are indented to the call site's column.
`TryThis` inserts a *string* suggestion verbatim (it only re-indents `tsyntax` suggestions), so a
multi-line proof would otherwise land its 2nd+ lines at column 0. We shift them right by the column of
the `sql_equiv_llm` token so the applied block is correctly indented (no `;`-linearisation). -/
def suggestProof (code : String) : TacticM Unit := do
  let ref ← getRef
  let fileMap ← getFileMap
  let col := (ref.getPos?.map fun p => (fileMap.toPosition p).column).getD 0
  let pad := String.ofList (List.replicate col ' ')
  let indented := match code.splitOn "\n" with
    | [] => code
    | first :: rest => String.intercalate "\n" (first :: rest.map (fun l => pad ++ l))
  TryThis.addSuggestion ref { suggestion := indented }

/-! ## The tactic -/

def maxRounds : Nat := 3
def defaultProvider : Provider := .openai

/-- LLM-assisted fallback. Order: (0) try the deterministic `sql_equiv`; (1) if that fails, run the
LLM refinement loop (up to `maxRounds`, stopping after the first call on an auth/key error); (2) if no
candidate closes it, try the LLM's last code with `sql_equiv` appended (`… <;> sql_equiv`) in case the
model got partway; (3) else leave a `sorry`. Concise status to the infoview; code to `Try this:`. -/
elab "sql_equiv_llm" : tactic => do
  let goal ← getMainGoal
  -- Step 0: the deterministic prover first, but the membership-free `sql_equiv_safe` — its structural
  -- route can hit an *uncatchable* deterministic timeout, which no `tryClose` can roll back, so it
  -- would abort before the LLM ever runs. `sql_equiv_safe` only ever fails cleanly, so a hard pair
  -- reliably falls through to the model.
  let sqlEq ← `(tactic| sql_equiv_safe)
  if ← tryClose goal sqlEq then
    logInfo "LlmTactic: sql_equiv tactic PROVED the goal."
    logInfo "<<<SQLLLM>>>OUTCOME=PROVED;METHOD=sql_equiv"
    logInfo "<<<SQLLLM_PROOF_BEGIN>>>\nsql_equiv\n<<<SQLLLM_PROOF_END>>>"
    TryThis.addSuggestion (← getRef) { suggestion := "sql_equiv  -- generated by `sql_equiv_llm`" }
    return
  -- Step 1: LLM refinement loop.
  let goalText := (← Meta.ppGoal goal).pretty
  let context ← buildRepoContextFor (← goal.getType)
  let opts ← getOptions
  let p := Provider.ofString? (sqlEquivLlm.provider.get opts) defaultProvider
  let modelOpt := sqlEquivLlm.model.get opts
  let model := if modelOpt.isEmpty then p.defaultModel else modelOpt
  let mut feedback := ""
  let mut lastCode := ""
  let mut status : Array String := #["sql_equiv: failed"]
  let mut winner : Option Syntax := none
  let mut stop := false
  let mut unprovable := false
  -- Accumulated across ALL rounds for this problem, so the cost is per-problem (not per-send).
  let mut totPrompt : Nat := 0
  let mut totCompletion : Nat := 0
  for round in [1:maxRounds+1] do
    if stop then break
    let resp ← (do try pure (.ok (← callLLM p (buildPrompt goalText context feedback) model))
                   catch e => pure (.error (← e.toMessageData.toString)) :
                   TacticM (Except String LLMResult))
    match resp with
    | .error e =>
      status := status.push s!"call{round}: NET-ERR ({shortErr e})"; feedback := ""
      if isAuthError e then status := status.push "auth error → stopping"; stop := true
    | .ok (raw, pt, ct) =>
      totPrompt := totPrompt + pt; totCompletion := totCompletion + ct
      lastCode := stripFence raw
      if (lastCode.trim.replace "`" "").toUpper == "UNPROVABLE" then
        -- The model judged the goal unprovable as stated (needs an absent constraint, or the queries
        -- genuinely differ). Stop now and leave a clean `sorry` rather than burning the remaining rounds.
        status := status.push s!"call{round}: 200 OK, model reports UNPROVABLE"
        lastCode := ""; stop := true; unprovable := true
      else
      match ← parseCandidate raw with
      | none => status := status.push s!"call{round}: 200 OK, parse-fail"
                feedback := "Your response did not parse as a Lean 4 tactic."
      | some stx =>
        if let some bad := usesBannedTactic lastCode then
          -- Reject before running it: `sql_equiv` already failed in Step 0, and running it (or the
          -- membership tactics) again risks an uncatchable timeout that would abort everything.
          status := status.push s!"call{round}: 200 OK, used `{bad}` (rejected)"
          feedback := s!"Your script called `{bad}`, which is off-limits: `sql_equiv`/`sql_equiv_safe` \
            have ALREADY been run on this goal and did not close it, and `sql_membership`/`sql_big_goal` \
            can loop. Write a primitive proof from Mathlib and basic tactics only (e.g. `apply \
            TypedRelation.ext (by rfl)`, `apply Finset.ext`/`Finset.image_congr`, `refine \
            restriction_congr _ _ _ (fun _ _ => ?_)`, `simp only [...]`, `intro`, `rcases`, `grind`, \
            `ring`, `omega`, `decide`) — never call any `sql_*` tactic."
        else
          match ← trialCapture goal stx with
          | .ok _ => status := status.push s!"call{round}: 200 OK, PROVED"; winner := some stx; break
          | .error e =>
            status := status.push s!"call{round}: 200 OK, failed"
            -- Prove like a human would: feed back the FULL residual proof state (`trialCapture`
            -- reports the leftover goals), not just a one-line error, so the model can advance the
            -- proof step by step from where it actually got stuck rather than restarting blind.
            feedback := s!"Your tactic:\n{lastCode}\n\ndid not close the goal. Here is the resulting \
              Lean proof state (continue the proof from HERE — reuse the part of your script that \
              worked and only fix/extend the rest):\n{e.take 6000}"
  -- Per-problem token/cost summary (net over all rounds).
  let inC := sqlEquivLlm.inputCentsPerMTok.get opts
  let outC := sqlEquivLlm.outputCentsPerMTok.get opts
  let costLine := s!"tokens: {totPrompt} in + {totCompletion} out | " ++
    s!"cost: {fmtCents (estCostCents totPrompt totCompletion inC outC)}"
  let hdr := s!"LlmTactic: {p.name} ({model})\n" ++
    String.intercalate "\n" status.toList ++ "\n" ++ costLine
  -- If the model declared the goal UNPROVABLE, ask (a second prompt) for a concrete counterexample
  -- database and let Lean `decide` the negation. A verified counterexample is a real DISPROOF; the goal
  -- itself can't be closed (it's false), so we report it and leave a `sorry`.
  if unprovable then
    let binders ← getTableBinders
    let goalTy ← getMainTarget
    let mut cxFb := ""
    let mut cxJson : Option String := none
    for _ in [1:3] do
      match ← (do try pure (some (← callLLM p s!"{counterexPrompt}\n\nGOAL:\n{goalText}{cxFb}" model))
                  catch _ => pure none : TacticM (Option LLMResult)) with
      | none => break
      | some (raw, pt, ct) =>
        totPrompt := totPrompt + pt; totCompletion := totCompletion + ct
        match parseDb raw with
        | none => cxFb := "\nReturn ONLY a JSON array of tables (one row-list per table binder)."
        | some db => match ← checkCounterexample goalTy binders db with
          | some _ => cxJson := some ((raw.replace "\n" " ").replace "```json" "" |>.replace "```" ""); break
          | none => cxFb := "\nThat database did NOT make the queries differ (set semantics: rows dedup). Give a different one."
    match cxJson with
    | some j =>
      logInfo s!"{hdr}\n→ DISPROVED (not equivalent) — decide-verified counterexample\ncounterexample rows: {j.take 400}"
      logInfo "<<<SQLLLM>>>OUTCOME=DISPROVED;METHOD=plausible_sql"
      logInfo s!"<<<SQLLLM_CX_BEGIN>>>\n{j}\n<<<SQLLLM_CX_END>>>"
    | none =>
      logInfo s!"{hdr}\n→ model reported UNPROVABLE; no verified counterexample found (inconclusive)"
      logInfo "<<<SQLLLM>>>OUTCOME=INCONCLUSIVE;METHOD=unprovable-unverified"
    evalTactic (← `(tactic| sorry)); return
  -- Apply the winner if one closed the goal on trial (reapplied safely).
  if let some stx := winner then
    if ← tryClose goal stx then
      logInfo s!"{hdr} → PROVED"
      logInfo "<<<SQLLLM>>>OUTCOME=PROVED;METHOD=llm"
      logInfo s!"<<<SQLLLM_PROOF_BEGIN>>>\n{lastCode}\n<<<SQLLLM_PROOF_END>>>"
      suggestProof s!"{lastCode}\n-- generated by `sql_equiv_llm`"
      return
  -- Step 2: append `sql_equiv_safe` to whatever the LLM last produced (in case it got partway). Safe,
  -- not full `sql_equiv`, so a residual goal it cannot close fails cleanly rather than timing out.
  -- Skip when the last reply itself called a banned tactic (running it could loop uncatchably).
  unless lastCode.isEmpty || (usesBannedTactic lastCode).isSome do
    if let some cstx ← parseCandidate s!"(\n{lastCode}\n) <;> sql_equiv_safe" then
      if ← tryClose goal cstx then
        logInfo s!"{hdr} → PROVED by LLM code `<;> sql_equiv_safe`"
        logInfo "<<<SQLLLM>>>OUTCOME=PROVED;METHOD=llm+safe"
        logInfo s!"<<<SQLLLM_PROOF_BEGIN>>>\n({lastCode}) <;> sql_equiv_safe\n<<<SQLLLM_PROOF_END>>>"
        suggestProof s!"({lastCode}) <;> sql_equiv_safe\n-- generated by `sql_equiv_llm`"
        return
  -- Step 3: give up cleanly with a `sorry`.
  evalTactic (← `(tactic| sorry))
  logInfo s!"{hdr} → FAILED; left `sorry`"
  logInfo "<<<SQLLLM>>>OUTCOME=INCONCLUSIVE;METHOD=exhausted"
  unless lastCode.isEmpty do suggestProof lastCode

elab "dump_llm_ctx" : tactic => do
  let goal ← getMainGoal
  let ctx ← buildRepoContextFor (← goal.getType)
  let lines := ctx.splitOn "\n"
  let nThm := lines.filter (·.startsWith "theorem") |>.length
  let nDef := lines.filter (·.startsWith "def") |>.length
  logInfo s!"CTX: {ctx.length} chars, {nThm} theorems, {nDef} defs\n\n{ctx}"

end LeanDatabase.SQLEquivLLM
