import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq171_eq_1_3

CREATE TABLE FORUMMESSAGEVOTES («Id» INT, «ForumMessageId» INT, «FromUserId» INT, «ToUserId» INT, «VoteDate» STRING)
CREATE TABLE USERS («Id» INT, «UserName» STRING, «DisplayName» STRING, «RegisterDate» STRING, «PerformanceTier» INT, «Country» STRING)

theorem eq (t0 : TableRel FORUMMESSAGEVOTES_schema) (t1 : TableRel USERS_schema) :
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema]) "WITH user_upvotes AS (SELECT fm.\"PostUserId\", COUNT(*) AS upvote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" AS fm ON fmv.\"ForumMessageId\" = fm.\"Id\" WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019 GROUP BY fm.\"PostUserId\"), avg_calc AS (SELECT AVG(upvote_count) AS avg_upvotes FROM user_upvotes) SELECT u.\"UserName\" AS \"Username\" FROM user_upvotes AS uu JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uu.\"PostUserId\" = u.\"Id\" CROSS JOIN avg_calc AS ac ORDER BY ABS(uu.upvote_count - ac.avg_upvotes) ASC, u.\"UserName\" ASC LIMIT 1") t0 t1
  ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema]) "WITH user_upvotes AS (SELECT v.\"ToUserId\" AS user_id, COUNT(*) AS upvote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS v WHERE EXTRACT(YEAR FROM v.\"VoteDate\") = 2019 GROUP BY v.\"ToUserId\"), avg_upvotes AS (SELECT AVG(upvote_count) AS avg_count FROM user_upvotes) SELECT u.\"UserName\" FROM user_upvotes AS uu JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uu.user_id = u.\"Id\" CROSS JOIN avg_upvotes AS a ORDER BY ABS(uu.upvote_count - a.avg_count) ASC, u.\"UserName\" ASC LIMIT 1") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq171_eq_1_3
