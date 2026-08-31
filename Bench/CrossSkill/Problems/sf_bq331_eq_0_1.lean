import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq331_eq_0_1

CREATE TABLE FORUMMESSAGEVOTES («Id» INT, «ForumMessageId» INT, «FromUserId» INT, «ToUserId» INT, «VoteDate» STRING)
CREATE TABLE FORUMTOPICS («TotalReplies» INT, «LastCommentDate» INT, «FirstForumMessageId» FLOAT, «IsSticky» BOOL, «ForumId» INT, «Title» STRING, «TotalMessages» INT, «Id» INT, «LastForumMessageId» FLOAT, «CreationDate» INT, «TotalViews» INT, «KernelId» FLOAT, «Score» INT)
CREATE TABLE USERS («Id» INT, «UserName» STRING, «DisplayName» STRING, «RegisterDate» STRING, «PerformanceTier» INT, «Country» STRING)
CREATE TABLE FORUMMESSAGES («Id» INT, «ForumTopicId» INT, «PostUserId» INT, «PostDate» STRING, «ReplyToForumMessageId» FLOAT, «Message» STRING, «RawMarkdown» STRING, «Medal» FLOAT, «MedalAwardDate» STRING)

theorem eq (t0 : TableRel FORUMMESSAGEVOTES_schema) (t1 : TableRel FORUMTOPICS_schema) (t2 : TableRel USERS_schema) (t3 : TableRel FORUMMESSAGES_schema) :
    (sql%([FORUMMESSAGEVOTES_schema, FORUMTOPICS_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH first_messages AS (SELECT fm.\"Id\" AS message_id, fm.\"PostUserId\", COUNT(DISTINCT fmv.\"FromUserId\") AS message_score FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMTOPICS\" AS ft JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" AS fm ON ft.\"FirstForumMessageId\" = fm.\"Id\" LEFT JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv ON fm.\"Id\" = fmv.\"ForumMessageId\" GROUP BY fm.\"Id\", fm.\"PostUserId\"), avg_score AS (SELECT AVG(message_score) AS avg_msg_score FROM first_messages) SELECT u.\"UserName\", ABS(fm.message_score - a.avg_msg_score) AS ABS_DIFF FROM first_messages AS fm JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON fm.\"PostUserId\" = u.\"Id\" CROSS JOIN avg_score AS a ORDER BY fm.message_score DESC LIMIT 3") t0 t1 t2 t3
  ~= (sql%([FORUMMESSAGEVOTES_schema, FORUMTOPICS_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH first_msgs AS (SELECT fm.\"Id\" AS msg_id, fm.\"PostUserId\" FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMTOPICS\" AS ft JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" AS fm ON ft.\"FirstForumMessageId\" = fm.\"Id\"), msg_scores AS (SELECT fm.msg_id, fm.\"PostUserId\", COUNT(DISTINCT fmv.\"FromUserId\") AS msg_score FROM first_msgs AS fm LEFT JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv ON fm.msg_id = fmv.\"ForumMessageId\" GROUP BY fm.msg_id, fm.\"PostUserId\"), avg_score AS (SELECT AVG(msg_score) AS avg_msg_score FROM msg_scores) SELECT u.\"UserName\", ABS(ms.msg_score - a.avg_msg_score) AS ABS_DIFF FROM msg_scores AS ms JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON ms.\"PostUserId\" = u.\"Id\" CROSS JOIN avg_score AS a ORDER BY ms.msg_score DESC LIMIT 3") t0 t1 t2 t3
  := by first | sql_equiv | sorry

end N_sf_bq331_eq_0_1
