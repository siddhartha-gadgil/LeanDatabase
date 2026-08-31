import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq331_eq_2_3

CREATE TABLE FORUMMESSAGEVOTES («Id» INT, «ForumMessageId» INT, «FromUserId» INT, «ToUserId» INT, «VoteDate» STRING)
CREATE TABLE FORUMTOPICS («TotalReplies» INT, «LastCommentDate» INT, «FirstForumMessageId» FLOAT, «IsSticky» BOOL, «ForumId» INT, «Title» STRING, «TotalMessages» INT, «Id» INT, «LastForumMessageId» FLOAT, «CreationDate» INT, «TotalViews» INT, «KernelId» FLOAT, «Score» INT)
CREATE TABLE USERS («Id» INT, «UserName» STRING, «DisplayName» STRING, «RegisterDate» STRING, «PerformanceTier» INT, «Country» STRING)
CREATE TABLE FORUMMESSAGES («Id» INT, «ForumTopicId» INT, «PostUserId» INT, «PostDate» STRING, «ReplyToForumMessageId» FLOAT, «Message» STRING, «RawMarkdown» STRING, «Medal» FLOAT, «MedalAwardDate» STRING)

theorem eq (t0 : TableRel FORUMMESSAGEVOTES_schema) (t1 : TableRel FORUMTOPICS_schema) (t2 : TableRel USERS_schema) (t3 : TableRel FORUMMESSAGES_schema) :
    (sql%([FORUMMESSAGEVOTES_schema, FORUMTOPICS_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH first_messages AS (/* Get the first message of each forum topic */ SELECT ft.\"FirstForumMessageId\" AS message_id FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMTOPICS\" AS ft WHERE NOT ft.\"FirstForumMessageId\" IS NULL), message_scores AS (/* For each first message, compute message score = count of distinct voters */ SELECT fm.\"Id\" AS message_id, fm.\"PostUserId\", COUNT(DISTINCT fmv.\"FromUserId\") AS message_score FROM first_messages AS fmsg JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" AS fm ON fm.\"Id\" = fmsg.message_id LEFT JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv ON fmv.\"ForumMessageId\" = fm.\"Id\" GROUP BY fm.\"Id\", fm.\"PostUserId\"), avg_score AS (SELECT AVG(message_score) AS avg_message_score FROM message_scores), ranked AS (SELECT ms.\"PostUserId\", ms.message_score, ROW_NUMBER() OVER (ORDER BY ms.message_score DESC) AS rn FROM message_scores AS ms) SELECT u.\"UserName\" AS \"UserName\", ABS(r.message_score - a.avg_message_score) AS \"ABS_DIFF\" FROM ranked AS r CROSS JOIN avg_score AS a JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON u.\"Id\" = r.\"PostUserId\" WHERE r.rn <= 3 ORDER BY r.rn") t0 t1 t2 t3
  ~= (sql%([FORUMMESSAGEVOTES_schema, FORUMTOPICS_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH first_messages AS (SELECT fm.\"Id\" AS message_id, fm.\"PostUserId\" AS user_id FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMTOPICS\" AS ft JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" AS fm ON ft.\"FirstForumMessageId\" = fm.\"Id\"), message_scores AS (SELECT fmsg.message_id, fmsg.user_id, COUNT(DISTINCT fmv.\"FromUserId\") AS message_score FROM first_messages AS fmsg LEFT JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv ON fmsg.message_id = fmv.\"ForumMessageId\" GROUP BY fmsg.message_id, fmsg.user_id), avg_score AS (SELECT AVG(message_score) AS avg_message_score FROM message_scores), user_max_scores AS (SELECT ms.user_id, MAX(ms.message_score) AS user_message_score FROM message_scores AS ms GROUP BY ms.user_id) SELECT u.\"UserName\" AS UserName, ABS(us.user_message_score - a.avg_message_score) AS ABS_DIFF FROM user_max_scores AS us CROSS JOIN avg_score AS a JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON us.user_id = u.\"Id\" ORDER BY us.user_message_score DESC LIMIT 3") t0 t1 t2 t3
  := by first | sql_equiv | sorry

end N_sf_bq331_eq_2_3
