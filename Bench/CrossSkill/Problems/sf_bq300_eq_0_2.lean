import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq300_eq_0_2

CREATE TABLE TAGS («id» INT, «tag_name» STRING, «count» INT, «excerpt_post_id» INT, «wiki_post_id» INT)
CREATE TABLE POSTS_QUESTIONS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» INT, «answer_count» INT, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» INT, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» STRING, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» INT)

theorem eq (t0 : TableRel TAGS_schema) (t1 : TableRel POSTS_QUESTIONS_schema) :
    (sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(CAST(\"answer_count\" AS INT)) AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE \"tags\" LIKE '%python-2%' AND NOT \"tags\" LIKE '%python-3%'") t0 t1
  = (sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT MAX(\"answer_count\") AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE (LOWER(\"tags\") LIKE '%python-2.%' OR LOWER(\"tags\") LIKE '%python-2.x%') AND NOT (LOWER(\"tags\") LIKE '%python-3.%' OR LOWER(\"tags\") LIKE '%python-3.x%')") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq300_eq_0_2
