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

theorem eq_0_1 : ∀ t,
    (sql%([ACTIVITY_LOG_schema]) "WITH ordered_visits AS (SELECT \"session\", \"stamp\", CASE WHEN \"path\" IN ('/detail', '/detail/') THEN '/detail' WHEN \"path\" IN ('/search_list', '/search_list/') THEN '/search_list' WHEN \"path\" IN ('/search_input', '/search_input/') THEN '/search_input' WHEN \"path\" = '/' THEN '/' ELSE TRIM(TRAILING '/' FROM \"path\") END AS normalized_path, ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\") AS rn FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\"), with_leads AS (SELECT normalized_path, LEAD(normalized_path, 1) OVER (PARTITION BY \"session\" ORDER BY rn) AS next_path, LEAD(normalized_path, 2) OVER (PARTITION BY \"session\" ORDER BY rn) AS third_path FROM ordered_visits) SELECT third_path AS THIRD_PAGE, COUNT(*) AS OCCURRENCES FROM with_leads WHERE normalized_path = '/detail' AND next_path = '/detail' AND NOT third_path IS NULL GROUP BY third_path ORDER BY OCCURRENCES DESC LIMIT 3") t ~= (sql%([ACTIVITY_LOG_schema]) "WITH ordered AS (SELECT ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\") AS rn, \"session\", \"stamp\", CASE WHEN \"path\" LIKE '%/' AND LENGTH(\"path\") > 1 THEN TRIM(TRAILING '/' FROM \"path\") ELSE \"path\" END AS normalized_path FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\"), with_leads AS (SELECT \"session\", \"stamp\", normalized_path, rn, LEAD(normalized_path, 1) OVER (PARTITION BY \"session\" ORDER BY rn) AS next1, LEAD(normalized_path, 2) OVER (PARTITION BY \"session\" ORDER BY rn) AS next2 FROM ordered) SELECT next2 AS THIRD_PAGE, COUNT(*) AS OCCURRENCES FROM with_leads WHERE normalized_path = '/detail' AND next1 = '/detail' AND NOT next2 IS NULL GROUP BY next2 ORDER BY OCCURRENCES DESC LIMIT 3") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_local331
