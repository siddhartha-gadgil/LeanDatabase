import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq310 — crossskill equivalence(s)

Question: What is the title of the most viewed "how" question related to Android development on StackOverflow, across specified tags such as 'android-layout', 'android-activity', 'android-intent', and others

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq310

CREATE TABLE TAGS («id» INT, «tag_name» STRING, «count» INT, «excerpt_post_id» INT, «wiki_post_id» INT)
CREATE TABLE POSTS_QUESTIONS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» INT, «answer_count» INT, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» INT, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» STRING, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» INT)

theorem eq_0_1 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS OUTPUT\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE 'how%'\n  AND \"tags\" LIKE '%android-%'\nORDER BY \"view_count\" DESC\nLIMIT 1;" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS OUTPUT\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE 'how %'\n  AND \"tags\" LIKE '%android-%'\nORDER BY \"view_count\" DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS OUTPUT\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE 'how%'\n  AND \"tags\" LIKE '%android-%'\nORDER BY \"view_count\" DESC\nLIMIT 1;" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS \"OUTPUT\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE '%how%'\n  AND \"tags\" LIKE '%android-%'\nORDER BY \"view_count\" DESC NULLS LAST\nLIMIT 1;" := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS OUTPUT\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE 'how%'\n  AND \"tags\" LIKE '%android-%'\nORDER BY \"view_count\" DESC\nLIMIT 1;" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS \"OUTPUT\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE 'how%'\n  AND \"tags\" LIKE '%android%'\nORDER BY \"view_count\" DESC NULLS LAST\nLIMIT 1;" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS OUTPUT\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE 'how %'\n  AND \"tags\" LIKE '%android-%'\nORDER BY \"view_count\" DESC\nLIMIT 1;" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS \"OUTPUT\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE '%how%'\n  AND \"tags\" LIKE '%android-%'\nORDER BY \"view_count\" DESC NULLS LAST\nLIMIT 1;" := by
  first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS OUTPUT\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE 'how %'\n  AND \"tags\" LIKE '%android-%'\nORDER BY \"view_count\" DESC\nLIMIT 1;" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS \"OUTPUT\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE 'how%'\n  AND \"tags\" LIKE '%android%'\nORDER BY \"view_count\" DESC NULLS LAST\nLIMIT 1;" := by
  first | sql_equiv | sorry

theorem eq_2_3 :
    sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS \"OUTPUT\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE '%how%'\n  AND \"tags\" LIKE '%android-%'\nORDER BY \"view_count\" DESC NULLS LAST\nLIMIT 1;" = sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT \"title\" AS \"OUTPUT\"\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\"\nWHERE LOWER(\"title\") LIKE 'how%'\n  AND \"tags\" LIKE '%android%'\nORDER BY \"view_count\" DESC NULLS LAST\nLIMIT 1;" := by
  first | sql_equiv | sorry

end Bench_sf_bq310
