import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local262_eq_1_2

CREATE TABLE PROBLEM («name» STRING, «path» STRING, «type» STRING, «target» STRING)
CREATE TABLE SOLUTION («name» STRING, «version» INT, «correlation» FLOAT, «nb_model» INT, «nb_feature» INT, «score» FLOAT, «test_size» FLOAT, «resampling» INT)
CREATE TABLE MODEL («name» STRING, «version» INT, «step» INT, «L1_model» STRING)
CREATE TABLE MODEL_SCORE («name» STRING, «version» INT, «step» INT, «model» STRING, «train_score» FLOAT, «test_score» FLOAT)

theorem eq (t0 : TableRel PROBLEM_schema) (t1 : TableRel SOLUTION_schema) (t2 : TableRel MODEL_schema) (t3 : TableRel MODEL_SCORE_schema) :
    (sql%([PROBLEM_schema, SOLUTION_schema, MODEL_schema, MODEL_SCORE_schema]) "WITH solution_counts AS (SELECT \"name\", COUNT(*) AS solution_count FROM \"STACKING\".\"STACKING\".\"SOLUTION\" GROUP BY \"name\"), beat_counts AS (SELECT ms_stack.\"name\", COUNT(*) AS beat_count FROM \"STACKING\".\"STACKING\".\"MODEL_SCORE\" AS ms_stack JOIN (SELECT \"name\", \"version\", \"step\", MAX(\"test_score\") AS max_non_stack FROM \"STACKING\".\"STACKING\".\"MODEL_SCORE\" WHERE \"model\" <> 'Stack' GROUP BY \"name\", \"version\", \"step\") AS ms_non ON ms_stack.\"name\" = ms_non.\"name\" AND ms_stack.\"version\" = ms_non.\"version\" AND ms_stack.\"step\" = ms_non.\"step\" WHERE ms_stack.\"model\" = 'Stack' AND ms_non.max_non_stack < ms_stack.\"test_score\" AND ms_stack.\"step\" IN (1, 2, 3) GROUP BY ms_stack.\"name\") SELECT b.\"name\" AS \"problem\" FROM beat_counts AS b JOIN solution_counts AS s ON b.\"name\" = s.\"name\" WHERE b.beat_count > s.solution_count ORDER BY b.\"name\"") t0 t1 t2 t3
  ~= (sql%([PROBLEM_schema, SOLUTION_schema, MODEL_schema, MODEL_SCORE_schema]) "WITH stack_scores AS (SELECT \"name\", \"version\", \"step\", \"test_score\" AS stack_test_score FROM \"STACKING\".\"STACKING\".\"MODEL_SCORE\" WHERE \"model\" = 'Stack'), non_stack_max AS (SELECT \"name\", \"version\", \"step\", MAX(\"test_score\") AS max_non_stack_test_score FROM \"STACKING\".\"STACKING\".\"MODEL_SCORE\" WHERE \"model\" <> 'Stack' GROUP BY \"name\", \"version\", \"step\"), qualifying AS (SELECT s.\"name\", s.\"version\", s.\"step\" FROM stack_scores AS s JOIN non_stack_max AS ns ON s.\"name\" = ns.\"name\" AND s.\"version\" = ns.\"version\" AND s.\"step\" = ns.\"step\" WHERE ns.max_non_stack_test_score < s.stack_test_score), problem_counts AS (SELECT \"name\" AS problem, COUNT(*) AS qualifying_count FROM qualifying WHERE \"step\" IN (1, 2, 3) GROUP BY \"name\"), solution_counts AS (SELECT \"name\", COUNT(*) AS solution_count FROM \"STACKING\".\"STACKING\".\"SOLUTION\" GROUP BY \"name\") SELECT pc.problem FROM problem_counts AS pc JOIN solution_counts AS sc ON pc.problem = sc.\"name\" WHERE pc.qualifying_count > sc.solution_count ORDER BY pc.problem") t0 t1 t2 t3
  := by first | sql_equiv | sorry

end N_sf_local262_eq_1_2
