import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq123_eq_2_3

CREATE TABLE POSTS_ANSWERS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» STRING, «answer_count» STRING, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» STRING, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» INT, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» STRING)
CREATE TABLE POSTS_QUESTIONS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» INT, «answer_count» INT, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» INT, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» STRING, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» INT)

theorem eq (t0 : TableRel POSTS_ANSWERS_schema) (t1 : TableRel POSTS_QUESTIONS_schema) :
    (sql%([POSTS_ANSWERS_schema, POSTS_QUESTIONS_schema]) "WITH earliest_answer AS (SELECT \"parent_id\", MIN(\"creation_date\") AS first_answer_date FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" GROUP BY \"parent_id\"), question_with_answer AS (SELECT q.\"id\", q.\"creation_date\" AS q_date, ea.first_answer_date AS a_date, DAYNAME(TO_TIMESTAMP(CAST(q.\"creation_date\" AS DOUBLE PRECISION) / 1000000)) AS dow FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" AS q LEFT JOIN earliest_answer AS ea ON q.\"id\" = ea.\"parent_id\"), day_stats AS (SELECT dow AS DAY_OF_WEEK, ROUND(CAST(CAST(100.0 * SUM(CASE WHEN NOT a_date IS NULL AND (a_date - q_date) <= 3600000000 THEN 1 ELSE 0 END) AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 6) AS PCT_WITHIN_1H FROM question_with_answer GROUP BY dow), ranked AS (SELECT DAY_OF_WEEK, PCT_WITHIN_1H, ROW_NUMBER() OVER (ORDER BY PCT_WITHIN_1H DESC) AS rn FROM day_stats) SELECT DAY_OF_WEEK, PCT_WITHIN_1H FROM ranked WHERE rn = 3") t0 t1
  ~= (sql%([POSTS_ANSWERS_schema, POSTS_QUESTIONS_schema]) "WITH earliest_answers AS (SELECT \"parent_id\", MIN(\"creation_date\") AS earliest_answer_date FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" GROUP BY \"parent_id\"), question_answer AS (SELECT q.\"id\", q.\"creation_date\" AS question_date, ea.earliest_answer_date, DAYNAME(TO_TIMESTAMP(CAST(q.\"creation_date\" AS DOUBLE PRECISION) / 1000000)) AS day_of_week, CASE WHEN NOT ea.earliest_answer_date IS NULL AND (ea.earliest_answer_date - q.\"creation_date\") <= 3600000000 THEN 1 ELSE 0 END AS answered_within_1h FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" AS q LEFT JOIN earliest_answers AS ea ON q.\"id\" = ea.\"parent_id\"), day_stats AS (SELECT day_of_week, ROUND(CAST(CAST(100.0 * SUM(answered_within_1h) AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 6) AS pct_within_1h FROM question_answer GROUP BY day_of_week), ranked AS (SELECT day_of_week, pct_within_1h, ROW_NUMBER() OVER (ORDER BY pct_within_1h DESC) AS rn FROM day_stats) SELECT day_of_week, pct_within_1h FROM ranked WHERE rn = 3") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq123_eq_2_3
