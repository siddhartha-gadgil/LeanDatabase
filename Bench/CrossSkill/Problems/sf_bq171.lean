import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq171 — crossskill equivalence(s)

Question: Whose Forum message upvotes are closest to the average in 2019? If there’s a tie, tell me the one with the alphabetically first username.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq171

CREATE TABLE FORUMMESSAGEVOTES («Id» INT, «ForumMessageId» INT, «FromUserId» INT, «ToUserId» INT, «VoteDate» STRING)
CREATE TABLE USERS («Id» INT, «UserName» STRING, «DisplayName» STRING, «RegisterDate» STRING, «PerformanceTier» INT, «Country» STRING)
CREATE TABLE FORUMMESSAGES («Id» INT, «ForumTopicId» INT, «PostUserId» INT, «PostDate» STRING, «ReplyToForumMessageId» FLOAT, «Message» STRING, «RawMarkdown» STRING, «Medal» FLOAT, «MedalAwardDate» STRING)

theorem eq_0_1 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (SELECT fmv.\"ToUserId\" AS user_id, COUNT(*) AS total_upvotes FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019 GROUP BY fmv.\"ToUserId\"), avg_upvotes AS (SELECT AVG(total_upvotes) AS avg_val FROM user_upvotes) SELECT COALESCE(usr.\"UserName\", usr.\"DisplayName\") AS Username FROM user_upvotes AS u CROSS JOIN avg_upvotes AS a JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS usr ON u.user_id = usr.\"Id\" ORDER BY ABS(u.total_upvotes - a.avg_val) ASC, COALESCE(usr.\"UserName\", usr.\"DisplayName\") ASC LIMIT 1") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (SELECT fm.\"PostUserId\", COUNT(*) AS upvote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" AS fm ON fmv.\"ForumMessageId\" = fm.\"Id\" WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019 GROUP BY fm.\"PostUserId\"), avg_calc AS (SELECT AVG(upvote_count) AS avg_upvotes FROM user_upvotes) SELECT u.\"UserName\" AS \"Username\" FROM user_upvotes AS uu JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uu.\"PostUserId\" = u.\"Id\" CROSS JOIN avg_calc AS ac ORDER BY ABS(uu.upvote_count - ac.avg_upvotes) ASC, u.\"UserName\" ASC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (SELECT fmv.\"ToUserId\" AS user_id, COUNT(*) AS total_upvotes FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019 GROUP BY fmv.\"ToUserId\"), avg_upvotes AS (SELECT AVG(total_upvotes) AS avg_val FROM user_upvotes) SELECT COALESCE(usr.\"UserName\", usr.\"DisplayName\") AS Username FROM user_upvotes AS u CROSS JOIN avg_upvotes AS a JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS usr ON u.user_id = usr.\"Id\" ORDER BY ABS(u.total_upvotes - a.avg_val) ASC, COALESCE(usr.\"UserName\", usr.\"DisplayName\") ASC LIMIT 1") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH upvote_counts AS (SELECT v.\"ToUserId\" AS user_id, COUNT(*) AS vote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS v WHERE EXTRACT(YEAR FROM CAST(v.\"VoteDate\" AS DATE)) = 2019 GROUP BY v.\"ToUserId\"), avg_votes AS (SELECT AVG(vote_count) AS avg_count FROM upvote_counts) SELECT u.\"UserName\" AS \"Username\" FROM upvote_counts AS uc CROSS JOIN avg_votes AS av JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uc.user_id = u.\"Id\" ORDER BY ABS(uc.vote_count - av.avg_count), u.\"UserName\" LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_3 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (SELECT fmv.\"ToUserId\" AS user_id, COUNT(*) AS total_upvotes FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019 GROUP BY fmv.\"ToUserId\"), avg_upvotes AS (SELECT AVG(total_upvotes) AS avg_val FROM user_upvotes) SELECT COALESCE(usr.\"UserName\", usr.\"DisplayName\") AS Username FROM user_upvotes AS u CROSS JOIN avg_upvotes AS a JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS usr ON u.user_id = usr.\"Id\" ORDER BY ABS(u.total_upvotes - a.avg_val) ASC, COALESCE(usr.\"UserName\", usr.\"DisplayName\") ASC LIMIT 1") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (SELECT v.\"ToUserId\" AS user_id, COUNT(*) AS upvote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS v WHERE EXTRACT(YEAR FROM v.\"VoteDate\") = 2019 GROUP BY v.\"ToUserId\"), avg_upvotes AS (SELECT AVG(upvote_count) AS avg_count FROM user_upvotes) SELECT u.\"UserName\" FROM user_upvotes AS uu JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uu.user_id = u.\"Id\" CROSS JOIN avg_upvotes AS a ORDER BY ABS(uu.upvote_count - a.avg_count) ASC, u.\"UserName\" ASC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (SELECT fm.\"PostUserId\", COUNT(*) AS upvote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" AS fm ON fmv.\"ForumMessageId\" = fm.\"Id\" WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019 GROUP BY fm.\"PostUserId\"), avg_calc AS (SELECT AVG(upvote_count) AS avg_upvotes FROM user_upvotes) SELECT u.\"UserName\" AS \"Username\" FROM user_upvotes AS uu JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uu.\"PostUserId\" = u.\"Id\" CROSS JOIN avg_calc AS ac ORDER BY ABS(uu.upvote_count - ac.avg_upvotes) ASC, u.\"UserName\" ASC LIMIT 1") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH upvote_counts AS (SELECT v.\"ToUserId\" AS user_id, COUNT(*) AS vote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS v WHERE EXTRACT(YEAR FROM CAST(v.\"VoteDate\" AS DATE)) = 2019 GROUP BY v.\"ToUserId\"), avg_votes AS (SELECT AVG(vote_count) AS avg_count FROM upvote_counts) SELECT u.\"UserName\" AS \"Username\" FROM upvote_counts AS uc CROSS JOIN avg_votes AS av JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uc.user_id = u.\"Id\" ORDER BY ABS(uc.vote_count - av.avg_count), u.\"UserName\" LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_1_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_3 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (SELECT fm.\"PostUserId\", COUNT(*) AS upvote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS fmv JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" AS fm ON fmv.\"ForumMessageId\" = fm.\"Id\" WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019 GROUP BY fm.\"PostUserId\"), avg_calc AS (SELECT AVG(upvote_count) AS avg_upvotes FROM user_upvotes) SELECT u.\"UserName\" AS \"Username\" FROM user_upvotes AS uu JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uu.\"PostUserId\" = u.\"Id\" CROSS JOIN avg_calc AS ac ORDER BY ABS(uu.upvote_count - ac.avg_upvotes) ASC, u.\"UserName\" ASC LIMIT 1") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (SELECT v.\"ToUserId\" AS user_id, COUNT(*) AS upvote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS v WHERE EXTRACT(YEAR FROM v.\"VoteDate\") = 2019 GROUP BY v.\"ToUserId\"), avg_upvotes AS (SELECT AVG(upvote_count) AS avg_count FROM user_upvotes) SELECT u.\"UserName\" FROM user_upvotes AS uu JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uu.user_id = u.\"Id\" CROSS JOIN avg_upvotes AS a ORDER BY ABS(uu.upvote_count - a.avg_count) ASC, u.\"UserName\" ASC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_2_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_2_3 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH upvote_counts AS (SELECT v.\"ToUserId\" AS user_id, COUNT(*) AS vote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS v WHERE EXTRACT(YEAR FROM CAST(v.\"VoteDate\" AS DATE)) = 2019 GROUP BY v.\"ToUserId\"), avg_votes AS (SELECT AVG(vote_count) AS avg_count FROM upvote_counts) SELECT u.\"UserName\" AS \"Username\" FROM upvote_counts AS uc CROSS JOIN avg_votes AS av JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uc.user_id = u.\"Id\" ORDER BY ABS(uc.vote_count - av.avg_count), u.\"UserName\" LIMIT 1") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (SELECT v.\"ToUserId\" AS user_id, COUNT(*) AS upvote_count FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" AS v WHERE EXTRACT(YEAR FROM v.\"VoteDate\") = 2019 GROUP BY v.\"ToUserId\"), avg_upvotes AS (SELECT AVG(upvote_count) AS avg_count FROM user_upvotes) SELECT u.\"UserName\" FROM user_upvotes AS uu JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" AS u ON uu.user_id = u.\"Id\" CROSS JOIN avg_upvotes AS a ORDER BY ABS(uu.upvote_count - a.avg_count) ASC, u.\"UserName\" ASC LIMIT 1") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq171
