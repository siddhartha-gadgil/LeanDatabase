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
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (\n  SELECT\n    fmv.\"ToUserId\" AS user_id,\n    COUNT(*) AS total_upvotes\n  FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" fmv\n  WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019\n  GROUP BY fmv.\"ToUserId\"\n),\navg_upvotes AS (\n  SELECT AVG(total_upvotes) AS avg_val FROM user_upvotes\n)\nSELECT\n  COALESCE(usr.\"UserName\", usr.\"DisplayName\") AS Username\nFROM user_upvotes u\nCROSS JOIN avg_upvotes a\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" usr\n  ON u.user_id = usr.\"Id\"\nORDER BY ABS(u.total_upvotes - a.avg_val) ASC,\n         COALESCE(usr.\"UserName\", usr.\"DisplayName\") ASC\nLIMIT 1;") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (\n  SELECT fm.\"PostUserId\", COUNT(*) AS upvote_count\n  FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" fmv\n  JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" fm \n    ON fmv.\"ForumMessageId\" = fm.\"Id\"\n  WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019\n  GROUP BY fm.\"PostUserId\"\n),\navg_calc AS (\n  SELECT AVG(upvote_count) AS avg_upvotes FROM user_upvotes\n)\nSELECT u.\"UserName\" AS \"Username\"\nFROM user_upvotes uu\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" u ON uu.\"PostUserId\" = u.\"Id\"\nCROSS JOIN avg_calc ac\nORDER BY ABS(uu.upvote_count - ac.avg_upvotes) ASC, u.\"UserName\" ASC\nLIMIT 1") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (\n  SELECT\n    fmv.\"ToUserId\" AS user_id,\n    COUNT(*) AS total_upvotes\n  FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" fmv\n  WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019\n  GROUP BY fmv.\"ToUserId\"\n),\navg_upvotes AS (\n  SELECT AVG(total_upvotes) AS avg_val FROM user_upvotes\n)\nSELECT\n  COALESCE(usr.\"UserName\", usr.\"DisplayName\") AS Username\nFROM user_upvotes u\nCROSS JOIN avg_upvotes a\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" usr\n  ON u.user_id = usr.\"Id\"\nORDER BY ABS(u.total_upvotes - a.avg_val) ASC,\n         COALESCE(usr.\"UserName\", usr.\"DisplayName\") ASC\nLIMIT 1;") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH upvote_counts AS (\n    SELECT\n        v.\"ToUserId\" AS user_id,\n        COUNT(*) AS vote_count\n    FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" v\n    WHERE YEAR(TO_DATE(v.\"VoteDate\")) = 2019\n    GROUP BY v.\"ToUserId\"\n),\navg_votes AS (\n    SELECT AVG(vote_count) AS avg_count\n    FROM upvote_counts\n)\nSELECT u.\"UserName\" AS \"Username\"\nFROM upvote_counts uc\nCROSS JOIN avg_votes av\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" u\n    ON uc.user_id = u.\"Id\"\nORDER BY ABS(uc.vote_count - av.avg_count), u.\"UserName\"\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_3 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (\n  SELECT\n    fmv.\"ToUserId\" AS user_id,\n    COUNT(*) AS total_upvotes\n  FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" fmv\n  WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019\n  GROUP BY fmv.\"ToUserId\"\n),\navg_upvotes AS (\n  SELECT AVG(total_upvotes) AS avg_val FROM user_upvotes\n)\nSELECT\n  COALESCE(usr.\"UserName\", usr.\"DisplayName\") AS Username\nFROM user_upvotes u\nCROSS JOIN avg_upvotes a\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" usr\n  ON u.user_id = usr.\"Id\"\nORDER BY ABS(u.total_upvotes - a.avg_val) ASC,\n         COALESCE(usr.\"UserName\", usr.\"DisplayName\") ASC\nLIMIT 1;") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (\n    SELECT\n        v.\"ToUserId\" AS user_id,\n        COUNT(*) AS upvote_count\n    FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" v\n    WHERE YEAR(v.\"VoteDate\") = 2019\n    GROUP BY v.\"ToUserId\"\n),\navg_upvotes AS (\n    SELECT AVG(upvote_count) AS avg_count\n    FROM user_upvotes\n)\nSELECT u.\"UserName\"\nFROM user_upvotes uu\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" u\n    ON uu.user_id = u.\"Id\"\nCROSS JOIN avg_upvotes a\nORDER BY ABS(uu.upvote_count - a.avg_count) ASC, u.\"UserName\" ASC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

-- eq_1_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_2 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (\n  SELECT fm.\"PostUserId\", COUNT(*) AS upvote_count\n  FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" fmv\n  JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" fm \n    ON fmv.\"ForumMessageId\" = fm.\"Id\"\n  WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019\n  GROUP BY fm.\"PostUserId\"\n),\navg_calc AS (\n  SELECT AVG(upvote_count) AS avg_upvotes FROM user_upvotes\n)\nSELECT u.\"UserName\" AS \"Username\"\nFROM user_upvotes uu\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" u ON uu.\"PostUserId\" = u.\"Id\"\nCROSS JOIN avg_calc ac\nORDER BY ABS(uu.upvote_count - ac.avg_upvotes) ASC, u.\"UserName\" ASC\nLIMIT 1") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH upvote_counts AS (\n    SELECT\n        v.\"ToUserId\" AS user_id,\n        COUNT(*) AS vote_count\n    FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" v\n    WHERE YEAR(TO_DATE(v.\"VoteDate\")) = 2019\n    GROUP BY v.\"ToUserId\"\n),\navg_votes AS (\n    SELECT AVG(vote_count) AS avg_count\n    FROM upvote_counts\n)\nSELECT u.\"UserName\" AS \"Username\"\nFROM upvote_counts uc\nCROSS JOIN avg_votes av\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" u\n    ON uc.user_id = u.\"Id\"\nORDER BY ABS(uc.vote_count - av.avg_count), u.\"UserName\"\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

-- eq_1_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_1_3 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (\n  SELECT fm.\"PostUserId\", COUNT(*) AS upvote_count\n  FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" fmv\n  JOIN \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGES\" fm \n    ON fmv.\"ForumMessageId\" = fm.\"Id\"\n  WHERE EXTRACT(YEAR FROM fmv.\"VoteDate\") = 2019\n  GROUP BY fm.\"PostUserId\"\n),\navg_calc AS (\n  SELECT AVG(upvote_count) AS avg_upvotes FROM user_upvotes\n)\nSELECT u.\"UserName\" AS \"Username\"\nFROM user_upvotes uu\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" u ON uu.\"PostUserId\" = u.\"Id\"\nCROSS JOIN avg_calc ac\nORDER BY ABS(uu.upvote_count - ac.avg_upvotes) ASC, u.\"UserName\" ASC\nLIMIT 1") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (\n    SELECT\n        v.\"ToUserId\" AS user_id,\n        COUNT(*) AS upvote_count\n    FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" v\n    WHERE YEAR(v.\"VoteDate\") = 2019\n    GROUP BY v.\"ToUserId\"\n),\navg_upvotes AS (\n    SELECT AVG(upvote_count) AS avg_count\n    FROM user_upvotes\n)\nSELECT u.\"UserName\"\nFROM user_upvotes uu\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" u\n    ON uu.user_id = u.\"Id\"\nCROSS JOIN avg_upvotes a\nORDER BY ABS(uu.upvote_count - a.avg_count) ASC, u.\"UserName\" ASC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

-- eq_2_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_2_3 : ∀ t,
    (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH upvote_counts AS (\n    SELECT\n        v.\"ToUserId\" AS user_id,\n        COUNT(*) AS vote_count\n    FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" v\n    WHERE YEAR(TO_DATE(v.\"VoteDate\")) = 2019\n    GROUP BY v.\"ToUserId\"\n),\navg_votes AS (\n    SELECT AVG(vote_count) AS avg_count\n    FROM upvote_counts\n)\nSELECT u.\"UserName\" AS \"Username\"\nFROM upvote_counts uc\nCROSS JOIN avg_votes av\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" u\n    ON uc.user_id = u.\"Id\"\nORDER BY ABS(uc.vote_count - av.avg_count), u.\"UserName\"\nLIMIT 1;") t ~= (sql%([FORUMMESSAGEVOTES_schema, USERS_schema, FORUMMESSAGES_schema]) "WITH user_upvotes AS (\n    SELECT\n        v.\"ToUserId\" AS user_id,\n        COUNT(*) AS upvote_count\n    FROM \"META_KAGGLE\".\"META_KAGGLE\".\"FORUMMESSAGEVOTES\" v\n    WHERE YEAR(v.\"VoteDate\") = 2019\n    GROUP BY v.\"ToUserId\"\n),\navg_upvotes AS (\n    SELECT AVG(upvote_count) AS avg_count\n    FROM user_upvotes\n)\nSELECT u.\"UserName\"\nFROM user_upvotes uu\nJOIN \"META_KAGGLE\".\"META_KAGGLE\".\"USERS\" u\n    ON uu.user_id = u.\"Id\"\nCROSS JOIN avg_upvotes a\nORDER BY ABS(uu.upvote_count - a.avg_count) ASC, u.\"UserName\" ASC\nLIMIT 1;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq171
