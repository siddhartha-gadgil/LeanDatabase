import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq280 — crossskill equivalence(s)

Question: Please provide the display name of the user who has answered the most questions on Stack Overflow, considering only users with a reputation greater than 10.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq280

CREATE TABLE USERS («id» INT, «display_name» STRING, «about_me» STRING, «age» STRING, «creation_date» INT, «last_access_date» INT, «location» STRING, «reputation» INT, «up_votes» INT, «down_votes» INT, «views» INT, «profile_image_url» STRING, «website_url» STRING)
CREATE TABLE POSTS_ANSWERS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» STRING, «answer_count» STRING, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» STRING, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» INT, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» STRING)

theorem eq_0_1 :
    sql%([USERS_schema, POSTS_ANSWERS_schema]) "SELECT u.\"display_name\" AS output\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" a\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON a.\"owner_user_id\" = u.\"id\"\nWHERE u.\"reputation\" > 10\nGROUP BY u.\"display_name\"\nORDER BY COUNT(*) DESC\nLIMIT 1;" = sql%([USERS_schema, POSTS_ANSWERS_schema]) "SELECT u.\"display_name\" AS \"output\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" a\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON a.\"owner_user_id\" = u.\"id\"\nWHERE u.\"reputation\" > 10\nGROUP BY u.\"id\", u.\"display_name\"\nORDER BY COUNT(*) DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([USERS_schema, POSTS_ANSWERS_schema]) "SELECT u.\"display_name\" AS output\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" a\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON a.\"owner_user_id\" = u.\"id\"\nWHERE u.\"reputation\" > 10\nGROUP BY u.\"display_name\"\nORDER BY COUNT(*) DESC\nLIMIT 1;") t ~= (sql%([USERS_schema, POSTS_ANSWERS_schema]) "SELECT u.\"display_name\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" a\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON a.\"owner_user_id\" = u.\"id\"\nWHERE u.\"reputation\" > 10\nGROUP BY u.\"id\", u.\"display_name\"\nORDER BY COUNT(*) DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([USERS_schema, POSTS_ANSWERS_schema]) "SELECT u.\"display_name\" AS \"output\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" a\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON a.\"owner_user_id\" = u.\"id\"\nWHERE u.\"reputation\" > 10\nGROUP BY u.\"id\", u.\"display_name\"\nORDER BY COUNT(*) DESC\nLIMIT 1;") t ~= (sql%([USERS_schema, POSTS_ANSWERS_schema]) "SELECT u.\"display_name\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" a\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON a.\"owner_user_id\" = u.\"id\"\nWHERE u.\"reputation\" > 10\nGROUP BY u.\"id\", u.\"display_name\"\nORDER BY COUNT(*) DESC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq280
