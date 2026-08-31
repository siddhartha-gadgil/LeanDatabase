import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq380_eq_0_2

CREATE TABLE FORUMMESSAGEVOTES («Id» INT, «ForumMessageId» INT, «FromUserId» INT, «ToUserId» INT, «VoteDate» STRING)
CREATE TABLE USERS («Id» INT, «UserName» STRING, «DisplayName» STRING, «RegisterDate» STRING, «PerformanceTier» INT, «Country» STRING)

theorem eq (t0 : TableRel FORUMMESSAGEVOTES_schema) (t1 : TableRel USERS_schema) :
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema]) "WITH received AS (SELECT \"ToUserId\" AS user_id, COUNT(DISTINCT \"Id\") AS upvotes_received FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" GROUP BY \"ToUserId\" ORDER BY upvotes_received DESC LIMIT 3), given AS (SELECT \"FromUserId\" AS user_id, COUNT(DISTINCT \"Id\") AS upvotes_given FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" GROUP BY \"FromUserId\") SELECT u.\"UserName\" AS \"MostUpvotedUserName\", r.upvotes_received AS \"UpvotesReceived\", COALESCE(g.upvotes_given, 0) AS \"UpvotesGiven\" FROM received AS r JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON r.user_id = u.\"Id\" LEFT JOIN given AS g ON r.user_id = g.user_id ORDER BY r.upvotes_received DESC") t0 t1
  ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema]) "WITH received AS (SELECT \"ToUserId\", COUNT(DISTINCT \"Id\") AS \"UpvotesReceived\" FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" GROUP BY \"ToUserId\" ORDER BY \"UpvotesReceived\" DESC LIMIT 3), given AS (SELECT \"FromUserId\", COUNT(DISTINCT \"Id\") AS \"UpvotesGiven\" FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" GROUP BY \"FromUserId\") SELECT u.\"UserName\" AS \"MostUpvotedUserName\", r.\"UpvotesReceived\", COALESCE(g.\"UpvotesGiven\", 0) AS \"UpvotesGiven\" FROM received AS r JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON r.\"ToUserId\" = u.\"Id\" LEFT JOIN given AS g ON r.\"ToUserId\" = g.\"FromUserId\" ORDER BY r.\"UpvotesReceived\" DESC LIMIT 3") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq380_eq_0_2
