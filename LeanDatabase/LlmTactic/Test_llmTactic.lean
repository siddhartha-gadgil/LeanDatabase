import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 2000000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# Subquery-projection cascade — a genuine `sql_equiv` gap that IS provable

`SELECT a FROM (SELECT a, b FROM t WHERE a = 1) s WHERE b = 2`  ≡  `SELECT a FROM t WHERE a = 1 AND b = 2`

Bare `sql_equiv` fails here (the inner `SELECT a,b` projection leaves an un-collapsed `image` that its
heuristic can't push the outer `WHERE`/projection through). But it is a true universal equivalence,
provable by pure Finset reasoning.

`sql_equiv_llm` PROVES it: `sql_equiv` fails, then Gemini (gemini-pro-latest) closes it on round 2
(after the round-1 failure fed back the residual goal state). The proof it found:

    funext t
    apply LeanDatabase.TypedRelation.ext
    · rfl
    · ext x
      simp [LeanDatabase.TypedRelation.mapByList, LeanDatabase.restriction]
      grind
-/

namespace Trial_subquery_cascade

CREATE TABLE t («a» INT, «b» INT)

theorem equivalent :
    sql%([t_schema]) "SELECT a FROM (SELECT a, b FROM t WHERE a = 1) s WHERE b = 2"
      = sql%([t_schema]) "SELECT a FROM t WHERE a = 1 AND b = 2" := by
  funext t
  apply TypedRelation.ext
  · rfl
  · ext x
    simp only [TypedRelation.mapByList, restriction, Finset.mem_image, Finset.mem_filter,
      Bool.and_eq_true, decide_eq_true_eq]
    grind

end Trial_subquery_cascade
