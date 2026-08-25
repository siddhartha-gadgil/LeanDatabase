import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq300 — crossskill equivalence(s)

Question: What is the highest number of answers received for a single Python 2 specific question on Stack Overflow, excluding any discussions that involve Python 3?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq300

CREATE TABLE TAGS («id» INT, «tag_name» STRING, «count» INT, «excerpt_post_id» INT, «wiki_post_id» INT)
CREATE TABLE POSTS_QUESTIONS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» INT, «answer_count» INT, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» INT, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» STRING, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» INT)

theorem eq_0_1 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(CAST(\"answer_count\" AS INT)) AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE \"tags\" LIKE '%python-2%' AND NOT \"tags\" LIKE '%python-3%'" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(\"answer_count\") AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE \"tags\" LIKE '%python-2%' AND NOT \"tags\" LIKE '%python-3%'" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(CAST(\"answer_count\" AS INT)) AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE \"tags\" LIKE '%python-2%' AND NOT \"tags\" LIKE '%python-3%'" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(\"answer_count\") AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE (LOWER(\"tags\") LIKE '%python-2.%' OR LOWER(\"tags\") LIKE '%python-2.x%') AND NOT (LOWER(\"tags\") LIKE '%python-3.%' OR LOWER(\"tags\") LIKE '%python-3.x%')" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(\"answer_count\") AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE \"tags\" LIKE '%python-2%' AND NOT \"tags\" LIKE '%python-3%'" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(\"answer_count\") AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE (LOWER(\"tags\") LIKE '%python-2.%' OR LOWER(\"tags\") LIKE '%python-2.x%') AND NOT (LOWER(\"tags\") LIKE '%python-3.%' OR LOWER(\"tags\") LIKE '%python-3.x%')" := by
  first | sql_equiv | sorry

end Bench_sf_bq300
