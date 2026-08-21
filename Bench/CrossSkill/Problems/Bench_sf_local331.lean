import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local331 — crossskill equivalence(s)

Question: Which three distinct third-page visits are most frequently observed immediately after two consecutive visits to the '/detail' page, and how many times does each third-page visit occur?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local331

CREATE TABLE ACTIVITY_LOG («stamp» STRING, «session» STRING, «action» STRING, «option» STRING, «path» STRING, «search_type» STRING)

theorem eq_0_1 :
    sql%([ACTIVITY_LOG_schema]) "WITH ordered_visits AS (\n  SELECT\n    \"session\",\n    \"stamp\",\n    CASE \n      WHEN \"path\" IN ('/detail', '/detail/') THEN '/detail'\n      WHEN \"path\" IN ('/search_list', '/search_list/') THEN '/search_list'\n      WHEN \"path\" IN ('/search_input', '/search_input/') THEN '/search_input'\n      WHEN \"path\" = '/' THEN '/'\n      ELSE RTRIM(\"path\", '/')\n    END AS normalized_path,\n    ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\") AS rn\n  FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\"\n),\nwith_leads AS (\n  SELECT\n    normalized_path,\n    LEAD(normalized_path, 1) OVER (PARTITION BY \"session\" ORDER BY rn) AS next_path,\n    LEAD(normalized_path, 2) OVER (PARTITION BY \"session\" ORDER BY rn) AS third_path\n  FROM ordered_visits\n)\nSELECT\n  third_path AS THIRD_PAGE,\n  COUNT(*) AS OCCURRENCES\nFROM with_leads\nWHERE normalized_path = '/detail'\n  AND next_path = '/detail'\n  AND third_path IS NOT NULL\nGROUP BY third_path\nORDER BY OCCURRENCES DESC\nLIMIT 3;" = sql%([ACTIVITY_LOG_schema]) "WITH ordered AS (\n  SELECT \n    ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\") AS rn,\n    \"session\",\n    \"stamp\",\n    CASE \n      WHEN \"path\" LIKE '%/' AND LENGTH(\"path\") > 1 \n      THEN RTRIM(\"path\", '/') \n      ELSE \"path\" \n    END AS normalized_path\n  FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\"\n),\nwith_leads AS (\n  SELECT\n    \"session\",\n    \"stamp\",\n    normalized_path,\n    rn,\n    LEAD(normalized_path, 1) OVER (PARTITION BY \"session\" ORDER BY rn) AS next1,\n    LEAD(normalized_path, 2) OVER (PARTITION BY \"session\" ORDER BY rn) AS next2\n  FROM ordered\n)\nSELECT \n  next2 AS THIRD_PAGE, \n  COUNT(*) AS OCCURRENCES\nFROM with_leads\nWHERE normalized_path = '/detail'\n  AND next1 = '/detail'\n  AND next2 IS NOT NULL\nGROUP BY next2\nORDER BY OCCURRENCES DESC\nLIMIT 3;" := by
  first | sql_equiv | sorry

end Bench_sf_local331
