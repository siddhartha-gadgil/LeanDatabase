import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq300 — a proven cross-skill equivalence

Question: What is the highest number of answers received for a single Python 2 specific question on Stack Overflow, excluding any discussions that involve Python 3?

Two independently-written SQL answers to the same question, proved equivalent for *all*
table contents by `sql_equiv` (not just on one instance).
-/

namespace P_sf_bq300

CREATE TABLE TAGS («id» INT, «tag_name» STRING, «count» INT, «excerpt_post_id» INT, «wiki_post_id» INT)
CREATE TABLE POSTS_QUESTIONS («answer_count» INT, «tags» STRING)

/-- Variant A:  SELECT MAX(CAST("answer_count" AS INTEGER)) AS output FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" WHERE "tags" LIKE '%python-2%' AND "tags" NOT LIKE 
    Variant B:  SELECT MAX("answer_count") AS output FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" WHERE "tags" LIKE '%python-2%' AND "tags" NOT LIKE '%python-3%'; -/
theorem equivalent :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(CAST(\"answer_count\" AS INTEGER)) AS output\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE \"tags\" LIKE '%python-2%'\n  AND \"tags\" NOT LIKE '%python-3%';"
      = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(\"answer_count\") AS output\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE \"tags\" LIKE '%python-2%'\n  AND \"tags\" NOT LIKE '%python-3%';" := by sql_equiv

end P_sf_bq300
