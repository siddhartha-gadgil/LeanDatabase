import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq302_eq_0_2

CREATE TABLE TAGS («id» INT, «tag_name» STRING, «count» INT, «excerpt_post_id» INT, «wiki_post_id» INT)
CREATE TABLE POSTS_QUESTIONS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» INT, «answer_count» INT, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» INT, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» STRING, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» INT)

theorem eq (t0 : TableRel TAGS_schema) (t1 : TableRel POSTS_QUESTIONS_schema) :
    (sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT CAST(EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"creation_date\" AS DOUBLE PRECISION) / 1000000)) AS INT) * 100 + CAST(EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"creation_date\" AS DOUBLE PRECISION) / 1000000)) AS INT) AS MONTH_INDEX, ROUND(CAST(CAST(SUM(CASE WHEN \"tags\" = 'python' OR \"tags\" LIKE 'python|%' OR \"tags\" LIKE '%|python|%' OR \"tags\" LIKE '%|python' THEN 1 ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 6) AS PROPORTION FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"creation_date\" AS DOUBLE PRECISION) / 1000000)) = 2022 GROUP BY MONTH_INDEX ORDER BY MONTH_INDEX") t0 t1
  ~= (sql%([TAGS_schema, POSTS_QUESTIONS_schema]) "SELECT EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"creation_date\" AS DOUBLE PRECISION) / 1000000)) * 100 + EXTRACT(MONTH FROM TO_TIMESTAMP(CAST(\"creation_date\" AS DOUBLE PRECISION) / 1000000)) AS \"MONTH_INDEX\", ROUND(CAST(CAST(SUM(CASE WHEN \"tags\" = 'python' OR \"tags\" LIKE 'python|%' OR \"tags\" LIKE '%|python|%' OR \"tags\" LIKE '%|python' THEN 1 ELSE 0 END) AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 4) AS \"PROPORTION\" FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"creation_date\" AS DOUBLE PRECISION) / 1000000)) = 2022 GROUP BY \"MONTH_INDEX\" ORDER BY \"MONTH_INDEX\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq302_eq_0_2
