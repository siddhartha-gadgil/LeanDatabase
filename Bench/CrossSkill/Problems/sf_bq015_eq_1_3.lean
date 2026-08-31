import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq015_eq_1_3

CREATE TABLE COMMENTS («id» INT, «by» STRING, «author» STRING, «time» INT, «time_ts» INT, «text» STRING, «parent» INT, «deleted» BOOL, «dead» BOOL, «ranking» INT)
CREATE TABLE POSTS_QUESTIONS («id» INT, «title» STRING, «body» STRING, «accepted_answer_id» INT, «answer_count» INT, «comment_count» INT, «community_owned_date» INT, «creation_date» INT, «favorite_count» INT, «last_activity_date» INT, «last_edit_date» INT, «last_editor_display_name» STRING, «last_editor_user_id» INT, «owner_display_name» STRING, «owner_user_id» INT, «parent_id» STRING, «post_type_id» INT, «score» INT, «tags» STRING, «view_count» INT)
CREATE TABLE TAGS («id» INT, «tag_name» STRING, «count» INT, «excerpt_post_id» INT, «wiki_post_id» INT)

theorem eq (t0 : TableRel COMMENTS_schema) (t1 : TableRel POSTS_QUESTIONS_schema) (t2 : TableRel TAGS_schema) :
    (sql%([COMMENTS_schema, POSTS_QUESTIONS_schema, TAGS_schema]) "WITH question_mentions AS (SELECT CAST(REGEXP_EXTRACT(\"text\", 'stackoverflow\\.com/questions/([0-9]+)', 1, 1, 'e', 1) AS DECIMAL(38, 0)) AS so_id, COUNT(*) AS mention_count FROM \"STACKOVERFLOW_PLUS\".\"HACKERNEWS\".\"COMMENTS\" WHERE \"text\" LIKE '%stackoverflow.com/questions/%' AND EXTRACT(YEAR FROM TO_TIMESTAMP(\"time\")) >= 2014 GROUP BY so_id) SELECT CAST(t.VALUE AS TEXT) AS TAG, SUM(qm.mention_count) AS COUNT FROM question_mentions AS qm JOIN \"STACKOVERFLOW_PLUS\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" AS q ON qm.so_id = q.\"id\", LATERAL UNNEST(input => SPLIT(q.\"tags\", '|')) AS t(SEQ, KEY, PATH, INDEX, VALUE, THIS) GROUP BY CAST(t.VALUE AS TEXT) ORDER BY COUNT DESC LIMIT 10") t0 t1 t2
  ~= (sql%([COMMENTS_schema, POSTS_QUESTIONS_schema, TAGS_schema]) "WITH so_questions_in_hn AS (/* Extract SO question IDs from HN comments on or after 2014 */ SELECT CAST(REGEXP_EXTRACT(\"text\", 'stackoverflow\\.com/questions/([0-9]+)', 1, 1, 'e', 1) AS INT) AS so_question_id FROM \"STACKOVERFLOW_PLUS\".\"HACKERNEWS\".\"COMMENTS\" WHERE \"text\" LIKE '%stackoverflow.com/questions/%' AND \"time\" >= 1388534400 /* Jan 1, 2014 UTC */), question_mentions AS (/* Count how many times each question was mentioned */ SELECT so_question_id, COUNT(*) AS mention_count FROM so_questions_in_hn WHERE NOT so_question_id IS NULL GROUP BY so_question_id), question_tags AS (/* Join with SO questions and split tags */ SELECT TRIM(CAST(t.VALUE AS TEXT)) AS tag, qm.mention_count FROM question_mentions AS qm JOIN \"STACKOVERFLOW_PLUS\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" AS pq ON qm.so_question_id = pq.\"id\", LATERAL SPLIT_TO_TABLE(pq.\"tags\", '|') AS t) SELECT tag AS TAG, SUM(mention_count) AS COUNT FROM question_tags GROUP BY tag ORDER BY COUNT DESC LIMIT 10") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_bq015_eq_1_3
