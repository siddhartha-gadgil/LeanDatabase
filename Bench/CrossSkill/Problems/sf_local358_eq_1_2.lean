import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local358_eq_1_2

CREATE TABLE MST_USERS («user_id» STRING, «sex» STRING, «birth_date» STRING, «register_date» STRING, «register_device» STRING, «withdraw_date» STRING)

theorem eq (t0 : TableRel MST_USERS_schema) :
    (sql%([MST_USERS_schema]) "SELECT CASE WHEN FLOOR(CAST((CAST(CURRENT_DATE AS DATE) - CAST(CAST(\"birth_date\" AS DATE) AS DATE)) AS DOUBLE PRECISION) / 365.25) BETWEEN 20 AND 29 THEN '20s' WHEN FLOOR(CAST((CAST(CURRENT_DATE AS DATE) - CAST(CAST(\"birth_date\" AS DATE) AS DATE)) AS DOUBLE PRECISION) / 365.25) BETWEEN 30 AND 39 THEN '30s' WHEN FLOOR(CAST((CAST(CURRENT_DATE AS DATE) - CAST(CAST(\"birth_date\" AS DATE) AS DATE)) AS DOUBLE PRECISION) / 365.25) BETWEEN 40 AND 49 THEN '40s' WHEN FLOOR(CAST((CAST(CURRENT_DATE AS DATE) - CAST(CAST(\"birth_date\" AS DATE) AS DATE)) AS DOUBLE PRECISION) / 365.25) BETWEEN 50 AND 59 THEN '50s' ELSE 'others' END AS category, COUNT(*) AS user_count FROM \"LOG\".\"LOG\".\"MST_USERS\" GROUP BY category ORDER BY category") t0
  ~= (sql%([MST_USERS_schema]) "WITH user_ages AS (SELECT \"user_id\", FLOOR(CAST((CAST(CURRENT_DATE AS DATE) - CAST(CAST(\"birth_date\" AS DATE) AS DATE)) AS DOUBLE PRECISION) / 365.25) AS age FROM \"LOG\".\"LOG\".\"MST_USERS\") SELECT CASE WHEN FLOOR(CAST(age AS DOUBLE PRECISION) / 10) = 2 THEN '20s' WHEN FLOOR(CAST(age AS DOUBLE PRECISION) / 10) = 3 THEN '30s' WHEN FLOOR(CAST(age AS DOUBLE PRECISION) / 10) = 4 THEN '40s' WHEN FLOOR(CAST(age AS DOUBLE PRECISION) / 10) = 5 THEN '50s' ELSE 'others' END AS \"category\", COUNT(*) AS \"user_count\" FROM user_ages GROUP BY \"category\" ORDER BY CASE \"category\" WHEN '20s' THEN 1 WHEN '30s' THEN 2 WHEN '40s' THEN 3 WHEN '50s' THEN 4 ELSE 5 END") t0
  := by first | sql_equiv | sorry

end N_sf_local358_eq_1_2
