import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq280_eq_0_1

CREATE TABLE USERS («id» INT, «display_name» STRING, «about_me» STRING, «age» STRING, «creation_date» INT, «last_access_date» INT, «location» STRING, «reputation» INT, «up_votes» INT, «down_votes» INT, «views» INT, «profile_image_url» STRING, «website_url» STRING)
CREATE TABLE POSTS_ANSWERS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» STRING, «answer_count» STRING, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» STRING, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» INT, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» STRING)

theorem eq (t0 : TableRel USERS_schema) (t1 : TableRel POSTS_ANSWERS_schema) :
    (sql%([USERS_schema, POSTS_ANSWERS_schema]) "SELECT u.\"display_name\" AS output FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" AS a JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" AS u ON a.\"owner_user_id\" = u.\"id\" WHERE u.\"reputation\" > 10 GROUP BY u.\"display_name\" ORDER BY COUNT(*) DESC LIMIT 1") t0 t1
  = (sql%([USERS_schema, POSTS_ANSWERS_schema]) "SELECT u.\"display_name\" AS \"output\" FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" AS a JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" AS u ON a.\"owner_user_id\" = u.\"id\" WHERE u.\"reputation\" > 10 GROUP BY u.\"id\", u.\"display_name\" ORDER BY COUNT(*) DESC LIMIT 1") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq280_eq_0_1
