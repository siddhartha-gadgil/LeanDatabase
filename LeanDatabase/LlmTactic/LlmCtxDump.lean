import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean LeanDatabase.TypedAgg Elab Tactic Meta

namespace LlmCtxDump

open LeanDatabase.SQLEquivLLM in
/-- Dump the premise-selected context (names only, theorem/def counts) for the current goal. -/
elab "dump_llm_ctx" : tactic => do
  let goal ← getMainGoal
  let ctx ← buildRepoContextFor (← goal.getType)
  let lines := ctx.splitOn "\n"
  let nThm := lines.filter (·.startsWith "theorem") |>.length
  let nDef := lines.filter (·.startsWith "def") |>.length
  logInfo s!"CTX: {ctx.length} chars, {nThm} theorems, {nDef} defs\n\n{ctx}"

CREATE TABLE orders (customer_id INT, status STRING, total_amount INT)

-- GROUP BY / FUNCDEP-shaped goal (Example12)
example :
    sql%([orders_schema])
        "SELECT customer_id, SUM(CASE WHEN status = 'completed' THEN total_amount ELSE 0 END) AS completed_total FROM orders GROUP BY customer_id HAVING SUM(CASE WHEN status = 'completed' THEN total_amount ELSE 0 END) > 1000"
      = sql%([orders_schema])
        "SELECT customer_id, SUM(total_amount) AS completed_total FROM orders WHERE status = 'completed' GROUP BY customer_id HAVING SUM(total_amount) > 1000" := by
  funext orders
  dump_llm_ctx
  sorry

-- Plain WHERE-reordering goal
example :
    sql%([orders_schema]) "SELECT * FROM orders WHERE total_amount > 30 AND customer_id > 1"
      = sql%([orders_schema]) "SELECT * FROM orders WHERE customer_id > 1 AND total_amount > 30" := by
  dump_llm_ctx
  sorry

end LlmCtxDump
