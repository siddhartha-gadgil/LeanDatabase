# Verified AI with Lean

## Overview

* We can view the central problem we address (within an agentic workflow) as *program synthesis*.
* Rather than an LLM simply giving an answer, and LLM generates a program which we run to get the answer.
  * This approach has been used in `FunSearch` and [AlphaEvolve](https://arxiv.org/abs/2506.13131) and also solutions to the [ARG-AGI challenge](https://icml.cc/virtual/2025/poster/43499).
* Here a program ranges from **SQL queries** and synthesis in other DSLs, to full programs, to **proofs** and **programs with proofs** (as proofs in Lean are essentially function definitions).
* We start with programs that are either given or generated in natural language and then translated.
* In addition to the "program" to be translated, we consider *properties* of the program (including *specifications*, *tests*, *invariants*).
  * These are translated into Lean and we use automation to try to prove/disprove these.
  * If the properties are proved our confidence in the answer increases.
  * If a property is disproved, we get feedback to correct the result.
* (Novel feature) In addition to the properties given by the user (if any), we generate using AI additional properties based on general principles and examples.
  * Again, we try to prove/disprove these.
* (Possible extension) Besides properties that *need* to be satisfied, we can (as in `FunSearch`, `AlphaEvolve`, `PatternBoost`) we can have measures of how good a "program" is and have an evolutionary loop.

## Work-points

Work points split into those to be done by the Lean Prover Team and those based on domain expertise (with ideas from everyone). As examples I have sketched some points for *mathematics* as a domain.

### Domain work-points

* Model the domain, for example making a DSL.
* Collect and represent properties useful for checking correctness.
* Design principles and prompts to generate properties useful for checking correctness.

### Lean Prover work-points

* Model domains in Lean.
* Add Syntax to Lean for DSLs.
* Prove basic theorems for domains and configure automation like `grind` to use these.
* Work on improving `LeanAide`'s autoformalization.

## Mathematics as an example

Some of the following applies directly to other domains.

### Generating properties

Some general *sanity checks* that can be used in a mathematical context. Since proofs can be just checked by Lean, the following apply more to checking that definitions and statements are correct.

* State a definition or result in a different way and prove they are equivalent.
* Answer in an easier special case and check that the general case reduces to the special case.
* Show that we can deduce expected consequences.
* Rule out *too good to be true*
