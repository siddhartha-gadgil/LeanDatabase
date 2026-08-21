import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local358 — crossskill equivalence(s)

Question: How many users are there in each age category (20s, 30s, 40s, 50s, and others)?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local358

CREATE TABLE MST_USERS («user_id» STRING, «sex» STRING, «birth_date» STRING, «register_date» STRING, «register_device» STRING, «withdraw_date» STRING)

theorem eq_0_1 :
    sql%([MST_USERS_schema]) "SELECT \n  CASE \n    WHEN age >= 20 AND age < 30 THEN '20s'\n    WHEN age >= 30 AND age < 40 THEN '30s'\n    WHEN age >= 40 AND age < 50 THEN '40s'\n    WHEN age >= 50 AND age < 60 THEN '50s'\n    ELSE 'others'\n  END AS category,\n  COUNT(*) AS user_count\nFROM (\n  SELECT \n    FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\", 'YYYY-MM-DD'), CURRENT_DATE()) / 365.25) AS age\n  FROM \"LOG\".\"LOG\".\"MST_USERS\"\n) sub\nGROUP BY category\nORDER BY \n  CASE category \n    WHEN '20s' THEN 1 \n    WHEN '30s' THEN 2 \n    WHEN '40s' THEN 3 \n    WHEN '50s' THEN 4 \n    ELSE 5 \n  END;" = sql%([MST_USERS_schema]) "SELECT \n  CASE \n    WHEN FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) BETWEEN 20 AND 29 THEN '20s'\n    WHEN FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) BETWEEN 30 AND 39 THEN '30s'\n    WHEN FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) BETWEEN 40 AND 49 THEN '40s'\n    WHEN FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) BETWEEN 50 AND 59 THEN '50s'\n    ELSE 'others'\n  END AS category,\n  COUNT(*) AS user_count\nFROM \"LOG\".\"LOG\".\"MST_USERS\"\nGROUP BY category\nORDER BY category" := by
  first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([MST_USERS_schema]) "SELECT \n  CASE \n    WHEN age >= 20 AND age < 30 THEN '20s'\n    WHEN age >= 30 AND age < 40 THEN '30s'\n    WHEN age >= 40 AND age < 50 THEN '40s'\n    WHEN age >= 50 AND age < 60 THEN '50s'\n    ELSE 'others'\n  END AS category,\n  COUNT(*) AS user_count\nFROM (\n  SELECT \n    FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\", 'YYYY-MM-DD'), CURRENT_DATE()) / 365.25) AS age\n  FROM \"LOG\".\"LOG\".\"MST_USERS\"\n) sub\nGROUP BY category\nORDER BY \n  CASE category \n    WHEN '20s' THEN 1 \n    WHEN '30s' THEN 2 \n    WHEN '40s' THEN 3 \n    WHEN '50s' THEN 4 \n    ELSE 5 \n  END;") t ~= (sql%([MST_USERS_schema]) "WITH user_ages AS (\n  SELECT\n    \"user_id\",\n    FLOOR(DATEDIFF('DAY', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) AS age\n  FROM \"LOG\".\"LOG\".\"MST_USERS\"\n)\nSELECT\n  CASE\n    WHEN FLOOR(age / 10) = 2 THEN '20s'\n    WHEN FLOOR(age / 10) = 3 THEN '30s'\n    WHEN FLOOR(age / 10) = 4 THEN '40s'\n    WHEN FLOOR(age / 10) = 5 THEN '50s'\n    ELSE 'others'\n  END AS \"category\",\n  COUNT(*) AS \"user_count\"\nFROM user_ages\nGROUP BY \"category\"\nORDER BY\n  CASE \"category\"\n    WHEN '20s' THEN 1\n    WHEN '30s' THEN 2\n    WHEN '40s' THEN 3\n    WHEN '50s' THEN 4\n    ELSE 5\n  END;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([MST_USERS_schema]) "SELECT \n  CASE \n    WHEN FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) BETWEEN 20 AND 29 THEN '20s'\n    WHEN FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) BETWEEN 30 AND 39 THEN '30s'\n    WHEN FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) BETWEEN 40 AND 49 THEN '40s'\n    WHEN FLOOR(DATEDIFF('day', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) BETWEEN 50 AND 59 THEN '50s'\n    ELSE 'others'\n  END AS category,\n  COUNT(*) AS user_count\nFROM \"LOG\".\"LOG\".\"MST_USERS\"\nGROUP BY category\nORDER BY category") t ~= (sql%([MST_USERS_schema]) "WITH user_ages AS (\n  SELECT\n    \"user_id\",\n    FLOOR(DATEDIFF('DAY', TO_DATE(\"birth_date\"), CURRENT_DATE()) / 365.25) AS age\n  FROM \"LOG\".\"LOG\".\"MST_USERS\"\n)\nSELECT\n  CASE\n    WHEN FLOOR(age / 10) = 2 THEN '20s'\n    WHEN FLOOR(age / 10) = 3 THEN '30s'\n    WHEN FLOOR(age / 10) = 4 THEN '40s'\n    WHEN FLOOR(age / 10) = 5 THEN '50s'\n    ELSE 'others'\n  END AS \"category\",\n  COUNT(*) AS \"user_count\"\nFROM user_ages\nGROUP BY \"category\"\nORDER BY\n  CASE \"category\"\n    WHEN '20s' THEN 1\n    WHEN '30s' THEN 2\n    WHEN '40s' THEN 3\n    WHEN '50s' THEN 4\n    ELSE 5\n  END;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_local358
