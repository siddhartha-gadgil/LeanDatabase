/-!
# `sql_equiv_llm`'s prompt template + assembly

The static framing text plus `buildPrompt`, kept separate from `SQLEquivLLM.lean`'s plumbing. The two
things that change call to call — the repo-context block and the goal (+ any feedback from a failed
prior attempt) — are supplied by the caller; everything else lives here.

Assembled as a **sandwich**: framing, then the (large) repo-context block, then the goal, then the
output-format instruction restated — a long input biases attention toward its start and end, so the
one instruction the pipeline depends on (respond with *only* the tactic) is stated at both ends.
-/

namespace LeanDatabase.SQLEquivLLM

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
    "information, not a restriction."
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
    "No markdown code fences. No explanation. Nothing before or after the script."
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
