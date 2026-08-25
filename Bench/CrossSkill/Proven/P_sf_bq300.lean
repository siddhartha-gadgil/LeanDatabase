import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq300 — proven cross-skill equivalence(s)

Question: What is the highest number of answers received for a single Python 2 specific question on Stack Overflow, excluding any discussions that involve Python 3?

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` fact, that data assumption is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_bq300

CREATE TABLE TAGS («id» INT, «tag_name» STRING, «count» INT, «excerpt_post_id» INT, «wiki_post_id» INT)
CREATE TABLE POSTS_QUESTIONS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» INT, «answer_count» INT, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» INT, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» STRING, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» INT)

theorem eq_0_1 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(CAST(\"answer_count\" AS INT)) AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE \"tags\" LIKE '%python-2%' AND NOT \"tags\" LIKE '%python-3%'" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(\"answer_count\") AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE \"tags\" LIKE '%python-2%' AND NOT \"tags\" LIKE '%python-3%'" := by sql_equiv

end P_sf_bq300
