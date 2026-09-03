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

-- Name + type only (no docstring): the signature is what the model reasons from, and dropping the
-- per-entry prose cuts ~20% of the prompt's input tokens (the dominant cost) with no loss on the
-- standard proof shapes.
def ppDeclEntry (n : Name) : MetaM String := do
  let env ← getEnv
  let some info := env.find? n | return ""
  let kind := if info.isTheorem then "theorem" else "def"
  let ty ← ppExpr info.type
  pure s!"{kind} {n} : {ty}"

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
  -- Cap the block: input tokens dominate the per-call cost, and the context is almost all of them.
  -- Keep every structurally-essential (`always`) entry, then fill to `cap` with the goal-relevant rest
  -- (theorems first). Beyond this the extra lemmas rarely change the proof but keep growing the prompt.
  let cap := 45
  let names := (relevant.map (·.1)).qsort (fun a b => isThm a && !isThm b)
  let keep := names.filter (fun n => always.contains n)
  let rest := names.filter (fun n => !always.contains n)
  let fill := if keep.size ≥ cap then #[] else rest.take (cap - keep.size)
  let entries ← (keep ++ fill).mapM ppDeclEntry
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
    "The repo's own automation `sql_equiv` (its full reduction + `grind` pipeline) has ALREADY been run",
    "on this goal and did NOT close it. So do NOT call `sql_equiv`, `sql_equiv_safe`, `sql_equiv_llm`,",
    "`sql_membership`, or `sql_big_goal` — a script that does is rejected. Write a PRIMITIVE proof.",
    "",
    "You may use any Mathlib lemma or standard tactic (simp, grind, ring, omega, Finset lemmas) and the",
    "repo's *component* lemmas/defs from the REPO CONTEXT below — its **theorems** are lemmas you can",
    "`apply` or feed to `simp`; its **defs** are the operators the goal is built from.",
    "",
    "REDUCE FIRST (recommended): you may begin your script with `sql_normalize` — the repo's reduction",
    "(a congruence + rewrite loop; it is ALLOWED — it is NOT `sql_equiv`/`sql_safe`/`sql_membership`). It",
    "collapses BOTH queries to a small per-row / arithmetic RESIDUAL, which is far easier to close than the",
    "raw elaborated goal. Then finish the residual. Note: `sql_normalize` followed by a blind `grind` is",
    "exactly what already failed (that IS `sql_equiv_safe`), so after it use a TARGETED move — `aesop` for",
    "join/∃ witnesses, a `groupSum_*` / `*_congr` lemma for aggregates, `ring`/`omega` for arithmetic, or a",
    "specific component lemma. On a retry, the feedback shows you the exact residual, so target THAT. If",
    "you prefer, the raw-goal recipes below still work verbatim.",
    "",
    "PICK THE RECIPE BY GOAL SHAPE (these are the moves the repo's own tactic uses; they are reliable):",
    "",
    "(A) JOIN / SUBQUERY / FLATTENING — a multi-table FROM, a derived table or subquery in FROM, EXISTS,",
    "  IN, or a correlated scalar subquery. Push membership through the algebra, then let `aesop` match",
    "  the `∃` witnesses. Emit exactly:",
    "      apply Finset.ext",
    "      intro x",
    "      simp only [dataEq, List.cons_append, List.nil_append, sql_mem, Finset.mem_image,",
    "        Finset.mem_filter, Finset.mem_product, Finset.mem_union, Finset.mem_inter, Finset.mem_sdiff,",
    "        Prod.exists, decide_eq_true_eq, Bool.and_eq_true, Bool.or_eq_true, Bool.not_eq_true,",
    "        exists_and_left, exists_and_right, exists_eq_left, exists_eq_right, exists_eq_left',",
    "        exists_eq_right']",
    "      aesop",
    "  `sql_mem` is the repo's row-membership simp SET (allowed — NOT `sql_membership`): it turns",
    "  `x ∈ σ/π/×/∪` into first-order `∧`/`∨`/`∃` over base-table membership and splits row equalities",
    "  into per-column scalars; the `exists_*` laws collapse the intermediate row a derived table adds",
    "  (`∃ v, … ∧ cons(…) = v`). **Use `aesop`, NOT `grind`** — `grind` cannot chain the join witnesses.",
    "  If `aesop` leaves a residual, retry as `aesop` after `constructor`, or `<;> omega` / `<;> grind`.",
    "",
    "(B) AGGREGATE — SELECT with SUM / AVG / COUNT / MIN / MAX (usually + GROUP BY), where the two sides",
    "  differ only in a dropped/constant GROUP-BY key or in aggregate arithmetic. Reduce to the per-group",
    "  equality then apply the matching congruence:",
    "      simp only [TypedRelation.mapByList_rows]",
    "      apply Finset.image_congr; intro x hx",
    "      simp only [TypedTupleOfList.cons_inj, TypedTupleOfList.cons_nil_inj, true_and, and_true,",
    "        Nat.cast_inj, Int.ofNat.injEq]",
    "      first",
    "        | simp only [groupSum_add, groupSum_sub, groupSum_mul_left, groupSum_neg, groupSum_zero]",
    "        | (first | apply groupSum_congr | apply groupCount_congr | apply groupAvg_congr",
    "             | apply groupMaxInt_congr | apply groupMinInt_congr",
    "           apply group_congr; intro _ _; grind +locals)",
    "  `SUM(a+b)=SUM(a)+SUM(b)` etc. are the `groupSum_*` simp laws; a dropped key uses `group_congr`",
    "  (same partition). COUNT is `Nat` cast to `Int` — peel with `Nat.cast_inj`/`Int.ofNat.injEq`.",
    "",
    "(C) PROJECTION / WHERE ONLY — one table (or same FROM), differing by a rearranged SELECT expression",
    "  or an equivalent WHERE. For a WHERE difference: `refine restriction_congr _ _ _ (fun _ _ => ?_)`",
    "  then `grind +locals` (this closes the per-row predicate `p t = q t`; good for arithmetic/CASE). For",
    "  a SELECT difference: `apply TypedRelation.ext (by rfl); simp only [TypedRelation.mapByList,",
    "  restriction]; apply Finset.image_congr; intro x hx; simp only [TypedTupleOfList.cons_inj,",
    "  TypedTupleOfList.cons_nil_inj, true_and, and_true]; grind +locals` (or `ring`/`omega` per column).",
    "",
    "PER-CONSTRUCT TIPS:",
    "- NULL / CASE: `CASE WHEN NOT c IS NULL THEN a ELSE b` elaborates to `if !SqlNullable.isNull (t i)",
    "  then a else b`; `simp [SqlNullable.isNull]` reduces it (a non-nullable INT column is never null).",
    "- ORDER BY / LIMIT: order is irrelevant under SET semantics — ignore `ORDER BY`; a `LIMIT` difference",
    "  reduces with `refine limit_congr ?_`.",
    "- COUNT(col) on a NON-nullable column equals COUNT(*) = the group size (`groupCount`).",
    "- CONSTRAINT-DEPENDENT (IMPORTANT): some equivalences hold ONLY given an integrity constraint — e.g.",
    "  `COUNT GROUP BY key ~= per-row value` needs `key` to be UNIQUE; `WHERE EXISTS(subquery) ~= no filter`",
    "  needs a FOREIGN KEY. If the theorem's binder has NO such hypothesis (`FuncDepEq …`, a `UNIQUE`/`∀ a b,",
    "  … → a = b` fact, or a `HYPOTHESIS`), the goal is UNPROVABLE and actually FALSE — do not invent a proof.",
    "  Reply with just `skip` so the tool records a clean `sorry`; that is the correct outcome, and it saves",
    "  the wasted rounds. Only attempt such a pair when the needed constraint IS a hypothesis you can use.",
    "  To signal this, reply with the single word `UNPROVABLE` (nothing else) — the tool then stops and",
    "  records a clean `sorry` without burning more rounds.",
    "- GENERAL: `UNION`/`INTERSECT`/`EXCEPT` are SET ops (arm order & duplicates do not matter); for `A ~= B`",
    "  output labels are already ignored, so alias-only differences need NO work. If two queries differ in an",
    "  output VALUE (different literal, column, filter) they are NOT equal — reply `UNPROVABLE`. When unsure",
    "  which recipe fits, try (A) first — its membership reduction + `aesop` is the most general."
  ]

/-- Delimits the repo-context block so it reads as reference material, not instructions or the goal. -/
def contextBeginMarker : String := "=== BEGIN REPO CONTEXT (theorems first, then operator defs) ==="

/-- @see `contextBeginMarker`. -/
def contextEndMarker : String := "=== END REPO CONTEXT ==="

/-- The one instruction parsing depends on: the reply is parsed directly as tactic syntax. Restated
after the context block and goal, not just up front. -/
def outputFormatInstruction : String :=
  String.intercalate "\n" [
    "OUTPUT: the raw Lean 4 tactic script and NOTHING else. Your entire reply is parsed directly as",
    "tactic syntax, so any prose, heading, restatement, or trailing remark makes it fail to parse.",
    "- No markdown, no ``` fences, no `by`, no comments, no blank explanation lines.",
    "- Nothing before the first tactic and nothing after the last; do not echo the goal.",
    "- One tactic per line (or separated by `;`); e.g. `apply Finset.ext; intro x` then `aesop`.",
    "- Never `sorry`/`admit`/`sorryAx`, and never `sql_equiv`/`sql_membership` — such replies are rejected."
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
