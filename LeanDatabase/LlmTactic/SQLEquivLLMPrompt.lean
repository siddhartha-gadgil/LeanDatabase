import Lean
import LeanDatabase.SQLEquiv

/-!
# `sql_equiv_llm`'s prompt: repo-context (premise selection) + template assembly

Everything that decides *what to tell the model* lives here: the premise-selection that turns the
whole repo into a lean, goal-relevant context block (`buildRepoContextFor` and its `coreModules` /
`alwaysInclude` / ubiquity machinery), the static framing text, and `buildPrompt` that assembles them.
`SQLEquivLLM.lean` only *calls* `buildRepoContextFor` and `buildPrompt`.

The prompt is assembled as a **sandwich**: framing, then the (large) repo-context block, then the goal
(+ any feedback from a failed prior attempt), then the output-format instruction restated — a long
input biases attention toward its start and end, so the one instruction the pipeline depends on
(respond with *only* the tactic) is stated at both ends.
-/

open Lean Meta

namespace LeanDatabase.SQLEquivLLM

/-! ## Repo context (premise selection) -/

def coreModules : Array Name := #[
  `LeanDatabase.TypedRelation, `LeanDatabase.RelationalAlgebra, `LeanDatabase.SQLToolbox,
  `LeanDatabase.CurriedPredicates, `LeanDatabase.Constraints, `LeanDatabase.Operators]

def inCoreScope (mod : Name) : Bool := coreModules.any (fun m => m == mod || m.isPrefixOf mod)

/-- Auto-generated equation/congruence/structure lemmas (`foo.eq_def`, `foo.eq_1`, `foo.congr_simp`,
`foo.match_1`, `Foo.mk.sizeOf_spec`, `Foo.mk.injEq`) — noise for premise selection; the model has the
def itself. -/
def isNoiseLemma (n : Name) : Bool :=
  match n.components.getLast? with
  | some c => let s := c.toString
    s == "eq_def" || s == "congr_simp" || s == "sizeOf_spec" || s == "injEq" || s == "noConfusion" ||
      s.startsWith "eq_" || s.startsWith "match_" || s.startsWith "proof_"
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
  let mut seen : Std.HashSet Name := Std.HashSet.ofArray alwaysInclude
  let mut always : Std.HashSet Name := Std.HashSet.ofArray alwaysInclude
  for (m, ns) in byModule.toList do
    for n in ns do
      if !seen.contains n && ((env.find? n).any (·.isTheorem) || !noisyDefModules.contains m) then
        cands := cands.push n; seen := seen.insert n
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

/-! ## Prompt template + assembly -/

/-- Framing before the repo-context block. Gives the model the *domain* it needs, not just a wall of
signatures: what the goal is (a `TypedRelation` set-semantics equality, or `~=` data-equivalence
ignoring column labels), the standard proof shape, and the fact that the repo's own tactics already
failed — so the useful move is a *targeted* one, not re-running them. -/
def promptPreamble : String :=
  String.intercalate "\n" [
    "You are assisting a Lean 4 proof-automation tool for a project that formalizes SQL relational",
    "algebra over `TypedRelation` (rows are a `Finset` of `TypedTuple`s — SET semantics; base tables",
    "are assumed duplicate-free). The goal below is an equality of two elaborated queries, either",
    "`A = B` or `A ~= B` (`dataEq`: rows equal, ignoring output column *labels*).",
    "",
    "You may use any Mathlib lemma or standard tactic (simp, grind, ring, omega, Finset lemmas). The",
    "REPO CONTEXT below is this project's own vocabulary — its **theorems** are lemmas you can `apply`",
    "or feed to `simp`; its **defs** are the operators the goal is built from. It is additional",
    "information, not a restriction.",
    "",
    "Useful facts for this domain:",
    "- `UNION`/`INTERSECT`/`EXCEPT` are SET operations: arm ORDER and DUPLICATES do not matter, and",
    "  `sql_equiv` ALREADY normalizes arm order — so two queries differing only in the order of",
    "  `UNION [ALL]` arms are closed by `sql_equiv` alone. Do NOT hand-reorder with `union_comm`/",
    "  `union_assoc`; just call `sql_equiv`.",
    "- For an `A ~= B` goal, output column *labels* are already ignored, so alias-only differences",
    "  (a renamed column or CTE) need NO work — do not try to rewrite labels.",
    "- Try `sql_equiv` FIRST (it runs the repo's whole reduction+grind pipeline); only add a targeted",
    "  step when it leaves a specific residual goal it cannot discharge, then finish with `sql_equiv`.",
    "- If the two queries genuinely differ in an output VALUE (a different string/number literal, a",
    "  different column selected, a different filter), they are NOT equal — do not force a proof; a",
    "  `sorry`-free failure is the correct, sound outcome."
  ]

/-- Delimits the repo-context block so it reads as reference material, not instructions or the goal. -/
def contextBeginMarker : String := "=== BEGIN REPO CONTEXT (theorems first, then operator defs) ==="

/-- @see `contextBeginMarker`. -/
def contextEndMarker : String := "=== END REPO CONTEXT ==="

/-- The one instruction parsing depends on: the reply is parsed directly as tactic syntax. Restated
after the context block and goal, not just up front. -/
def outputFormatInstruction : String :=
  String.intercalate "\n" [
    "Respond with ONLY the tactic script — e.g. `simp only [restriction]; grind +locals` or",
    "`apply TypedRelation.ext (by rfl); apply Finset.image_congr; intro x hx; grind`.",
    "No markdown code fences. No explanation. Nothing before or after the script.",
    "Never use `sorry`, `admit`, or `sorryAx` — a script that leaves them is rejected as no proof."
  ]

/-- Assemble the full prompt (framing / context / goal[+feedback] / restated instruction). -/
def buildPrompt (goalText context : String) (feedback : String := "") : String :=
  let fb := if feedback.isEmpty then "" else
    s!"\n\nYOUR PREVIOUS ATTEMPT FAILED:\n{feedback}\nReturn a corrected tactic script."
  String.intercalate "\n\n" [
    promptPreamble,
    s!"{contextBeginMarker}\n{context}\n{contextEndMarker}",
    s!"GOAL:\n{goalText}{fb}",
    outputFormatInstruction]

end LeanDatabase.SQLEquivLLM
