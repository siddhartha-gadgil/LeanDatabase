import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local262_eq_0_3

CREATE TABLE PROBLEM («name» STRING, «path» STRING, «type» STRING, «target» STRING)
CREATE TABLE SOLUTION («name» STRING, «version» INT, «correlation» FLOAT, «nb_model» INT, «nb_feature» INT, «score» FLOAT, «test_size» FLOAT, «resampling» INT)
CREATE TABLE MODEL («name» STRING, «version» INT, «step» INT, «L1_model» STRING)
CREATE TABLE MODEL_SCORE («name» STRING, «version» INT, «step» INT, «model» STRING, «train_score» FLOAT, «test_score» FLOAT)

theorem eq (t0 : TableRel PROBLEM_schema) (t1 : TableRel SOLUTION_schema) (t2 : TableRel MODEL_schema) (t3 : TableRel MODEL_SCORE_schema) :
    (sql%([PROBLEM_schema, SOLUTION_schema, MODEL_schema, MODEL_SCORE_schema]) "WITH stack_scores AS (SELECT \"name\", \"step\", \"version\", \"test_score\" AS stack_score FROM \"STACKING\".\"STACKING\".\"MODEL_SCORE\" WHERE \"model\" = 'Stack' AND \"step\" IN (1, 2, 3)), non_stack_max AS (SELECT \"name\", \"step\", \"version\", MAX(\"test_score\") AS max_non_stack_score FROM \"STACKING\".\"STACKING\".\"MODEL_SCORE\" WHERE \"model\" <> 'Stack' AND \"step\" IN (1, 2, 3) GROUP BY \"name\", \"step\", \"version\"), stack_wins AS (SELECT s.\"name\", COUNT(*) AS win_count FROM stack_scores AS s JOIN non_stack_max AS ns ON s.\"name\" = ns.\"name\" AND s.\"step\" = ns.\"step\" AND s.\"version\" = ns.\"version\" WHERE s.stack_score > ns.max_non_stack_score GROUP BY s.\"name\"), solution_counts AS (SELECT \"name\", COUNT(*) AS sol_count FROM \"STACKING\".\"STACKING\".\"SOLUTION\" GROUP BY \"name\") SELECT sw.\"name\" AS \"problem\" FROM stack_wins AS sw JOIN solution_counts AS sc ON sw.\"name\" = sc.\"name\" WHERE sw.win_count > sc.sol_count ORDER BY sw.\"name\"") t0 t1 t2 t3
  ~= (sql%([PROBLEM_schema, SOLUTION_schema, MODEL_schema, MODEL_SCORE_schema]) "WITH stack_wins AS (SELECT \"name\", \"version\", \"step\", MAX(CASE WHEN \"model\" = 'Stack' THEN \"test_score\" END) AS stack_score, MAX(CASE WHEN \"model\" <> 'Stack' THEN \"test_score\" END) AS max_non_stack_score FROM \"STACKING\".\"STACKING\".\"MODEL_SCORE\" WHERE \"step\" IN (1, 2, 3) GROUP BY \"name\", \"version\", \"step\" HAVING max_non_stack_score < stack_score), win_counts AS (SELECT \"name\", COUNT(*) AS win_count FROM stack_wins GROUP BY \"name\"), solution_counts AS (SELECT \"name\", COUNT(*) AS sol_count FROM \"STACKING\".\"STACKING\".\"SOLUTION\" GROUP BY \"name\") SELECT w.\"name\" AS problem FROM win_counts AS w JOIN solution_counts AS s ON w.\"name\" = s.\"name\" WHERE w.win_count > s.sol_count ORDER BY w.\"name\"") t0 t1 t2 t3
  := by first | sql_equiv | sorry

end N_sf_local262_eq_0_3
