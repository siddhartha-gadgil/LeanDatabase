import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq284 — crossskill equivalence(s)

Question: Can you provide a breakdown of the total number of articles into different categories and the percentage of those articles that mention "education" within each category from the BBC News?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq284

CREATE TABLE FULLTEXT («body» STRING, «title» STRING, «filename» STRING, «category» STRING)

theorem eq_0_1 :
    sql%([FULLTEXT_schema]) "SELECT \n    \"category\",\n    COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n    ROUND(\n        SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n        6\n    ) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" = sql%([FULLTEXT_schema]) "SELECT\n    \"category\" AS category,\n    COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n    100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([FULLTEXT_schema]) "SELECT \n    \"category\",\n    COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n    ROUND(\n        SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n        6\n    ) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" = sql%([FULLTEXT_schema]) "SELECT\n    \"category\",\n    COUNT(*) AS \"NUMBER_TOTAL_BY_CATEGORY\",\n    ROUND(\n        100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*),\n        2\n    ) AS \"PERCENT_EDUCATION\"\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([FULLTEXT_schema]) "SELECT \n    \"category\",\n    COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n    ROUND(\n        SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n        6\n    ) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" = sql%([FULLTEXT_schema]) "SELECT\n  \"category\",\n  COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n  ROUND(100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*), 6) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([FULLTEXT_schema]) "SELECT\n    \"category\" AS category,\n    COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n    100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" = sql%([FULLTEXT_schema]) "SELECT\n    \"category\",\n    COUNT(*) AS \"NUMBER_TOTAL_BY_CATEGORY\",\n    ROUND(\n        100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*),\n        2\n    ) AS \"PERCENT_EDUCATION\"\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" := by
  first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([FULLTEXT_schema]) "SELECT\n    \"category\" AS category,\n    COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n    100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" = sql%([FULLTEXT_schema]) "SELECT\n  \"category\",\n  COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n  ROUND(100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*), 6) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" := by
  first | sql_equiv | sorry

theorem eq_2_3 :
    sql%([FULLTEXT_schema]) "SELECT\n    \"category\",\n    COUNT(*) AS \"NUMBER_TOTAL_BY_CATEGORY\",\n    ROUND(\n        100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*),\n        2\n    ) AS \"PERCENT_EDUCATION\"\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" = sql%([FULLTEXT_schema]) "SELECT\n  \"category\",\n  COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n  ROUND(100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*), 6) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";" := by
  first | sql_equiv | sorry

end Bench_sf_bq284
