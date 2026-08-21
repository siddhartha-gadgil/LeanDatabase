import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq303 — a proven cross-skill equivalence

Question: From July 1, 2019 through December 31, 2019, for all users with IDs between 16712208 and 18712208 on Stack Overflow, retrieve the user ID and the tags of the relevant question for each of their contributions, including comments on both questions and answers, any answers they posted, and any questions they authored, making sure to correctly associate the comment or answer with its parent question’s tags.

Two independently-written SQL answers to the same question, proved equivalent for *all*
table contents by `sql_equiv` (not just on one instance).
-/

namespace P_sf_bq303

CREATE TABLE COMMENTS («id» INT, «creation_date» INT, «post_id» INT, «user_id» INT)
CREATE TABLE TAGS («id» INT)
CREATE TABLE USERS («id» INT, «creation_date» INT)
CREATE TABLE POSTS_ANSWERS («id» INT, «creation_date» INT, «owner_user_id» INT, «parent_id» INT, «tags» STRING)
CREATE TABLE POSTS_QUESTIONS («id» INT, «creation_date» INT, «owner_user_id» INT, «parent_id» STRING, «tags» STRING)

/-- Variant A:  -- sf_bq303: Retrieve user_id and tags for all contributions (questions, answers, comments) -- from July 1, 2019 through December 31, 2019 for users with IDs be
    Variant B:  -- Contributions from July 1, 2019 through December 31, 2019 -- Users with IDs between 16712208 and 18712208 -- 4 types: comments on questions, comments on answ -/
theorem equivalent :
    sql%([COMMENTS_schema, TAGS_schema, USERS_schema, POSTS_ANSWERS_schema, POSTS_QUESTIONS_schema]) "-- sf_bq303: Retrieve user_id and tags for all contributions (questions, answers, comments)\n-- from July 1, 2019 through December 31, 2019 for users with IDs between 16712208 and 18712208\n\n-- Date boundaries (microseconds since epoch):\n-- July 1, 2019 00:00:00 UTC = 1561939200 * 1000000 = 1561939200000000\n-- Jan 1, 2020 00:00:00 UTC = 1577836800 * 1000000 = 1577836800000000\n\n-- 1. Comments on questions: user_id from comment, tags from question\nSELECT c.\"user_id\" AS U_ID, pq.\"tags\" AS TAGS\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"COMMENTS\" c\nINNER JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" pq ON c.\"post_id\" = pq.\"id\"\nWHERE c.\"user_id\" BETWEEN 16712208 AND 18712208\n  AND c.\"creation_date\" >= 1561939200000000\n  AND c.\"creation_date\" < 1577836800000000\n\nUNION ALL\n\n-- 2. Comments on answers: user_id from comment, tags from parent question of the answer\nSELECT c.\"user_id\" AS U_ID, pq.\"tags\" AS TAGS\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"COMMENTS\" c\nINNER JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" pa ON c.\"post_id\" = pa.\"id\"\nINNER JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" pq ON pa.\"parent_id\" = pq.\"id\"\nWHERE c.\"user_id\" BETWEEN 16712208 AND 18712208\n  AND c.\"creation_date\" >= 1561939200000000\n  AND c.\"creation_date\" < 1577836800000000\n\nUNION ALL\n\n-- 3. Answers posted: owner_user_id from answer, tags from parent question\nSELECT pa.\"owner_user_id\" AS U_ID, pq.\"tags\" AS TAGS\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" pa\nINNER JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" pq ON pa.\"parent_id\" = pq.\"id\"\nWHERE pa.\"owner_user_id\" BETWEEN 16712208 AND 18712208\n  AND pa.\"creation_date\" >= 1561939200000000\n  AND pa.\"creation_date\" < 1577836800000000\n\nUNION ALL\n\n-- 4. Questions authored: owner_user_id and tags directly from question\nSELECT pq.\"owner_user_id\" AS U_ID, pq.\"tags\" AS TAGS\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" pq\nWHERE pq.\"owner_user_id\" BETWEEN 16712208 AND 18712208\n  AND pq.\"creation_date\" >= 1561939200000000\n  AND pq.\"creation_date\" < 1577836800000000\n;"
      = sql%([COMMENTS_schema, TAGS_schema, USERS_schema, POSTS_ANSWERS_schema, POSTS_QUESTIONS_schema]) "-- Contributions from July 1, 2019 through December 31, 2019\n-- Users with IDs between 16712208 and 18712208\n-- 4 types: comments on questions, comments on answers, answers, questions\n-- Always associate with parent question's tags\n\n-- 1. Comments on questions (direct: comment -> question)\nSELECT \n  c.\"user_id\" AS U_ID,\n  q.\"tags\" AS TAGS\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"COMMENTS\" c\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" q ON c.\"post_id\" = q.\"id\"\nWHERE c.\"user_id\" BETWEEN 16712208 AND 18712208\n  AND c.\"creation_date\" >= 1561939200000000\n  AND c.\"creation_date\" < 1577836800000000\n\nUNION ALL\n\n-- 2. Comments on answers (two-hop: comment -> answer -> question)\nSELECT \n  c.\"user_id\" AS U_ID,\n  q.\"tags\" AS TAGS\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"COMMENTS\" c\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" a ON c.\"post_id\" = a.\"id\"\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" q ON a.\"parent_id\" = q.\"id\"\nWHERE c.\"user_id\" BETWEEN 16712208 AND 18712208\n  AND c.\"creation_date\" >= 1561939200000000\n  AND c.\"creation_date\" < 1577836800000000\n\nUNION ALL\n\n-- 3. Answers posted (answer -> question for tags)\nSELECT \n  a.\"owner_user_id\" AS U_ID,\n  q.\"tags\" AS TAGS\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_ANSWERS\" a\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" q ON a.\"parent_id\" = q.\"id\"\nWHERE a.\"owner_user_id\" BETWEEN 16712208 AND 18712208\n  AND a.\"creation_date\" >= 1561939200000000\n  AND a.\"creation_date\" < 1577836800000000\n\nUNION ALL\n\n-- 4. Questions authored (question has tags directly)\nSELECT \n  q.\"owner_user_id\" AS U_ID,\n  q.\"tags\" AS TAGS\nFROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"POSTS_QUESTIONS\" q\nWHERE q.\"owner_user_id\" BETWEEN 16712208 AND 18712208\n  AND q.\"creation_date\" >= 1561939200000000\n  AND q.\"creation_date\" < 1577836800000000" := by sql_equiv

end P_sf_bq303
