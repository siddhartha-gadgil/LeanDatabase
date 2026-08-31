import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local330_eq_0_2

CREATE TABLE ACTIVITY_LOG («stamp» STRING, «session» STRING, «action» STRING, «option» STRING, «path» STRING, «search_type» STRING)

theorem eq (t0 : TableRel ACTIVITY_LOG_schema) :
    (sql%([ACTIVITY_LOG_schema]) "WITH session_stamp_path_counts AS (SELECT \"session\", \"stamp\", \"path\", COUNT(*) AS cnt FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\" GROUP BY \"session\", \"stamp\", \"path\"), ranked AS (SELECT \"session\", \"stamp\", \"path\", cnt, ROW_NUMBER() OVER (PARTITION BY \"session\", \"stamp\" ORDER BY cnt DESC, \"path\" ASC) AS rn, MIN(\"stamp\") OVER (PARTITION BY \"session\") AS first_stamp, MAX(\"stamp\") OVER (PARTITION BY \"session\") AS last_stamp FROM session_stamp_path_counts), landing AS (SELECT \"session\", \"path\" FROM ranked WHERE rn = 1 AND \"stamp\" = first_stamp), exit_p AS (SELECT \"session\", \"path\" FROM ranked WHERE rn = 1 AND \"stamp\" = last_stamp), combined AS (SELECT \"session\", \"path\" FROM landing UNION SELECT \"session\", \"path\" FROM exit_p) SELECT \"path\", COUNT(DISTINCT \"session\") AS session_count FROM combined GROUP BY \"path\" ORDER BY session_count DESC") t0
  ~= (sql%([ACTIVITY_LOG_schema]) "WITH landing_pages AS (SELECT \"session\", \"path\" FROM (SELECT \"session\", \"path\", ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\" ASC) AS rn FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\") WHERE rn = 1), exit_pages AS (SELECT \"session\", \"path\" FROM (SELECT \"session\", \"path\", ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\" DESC) AS rn FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\") WHERE rn = 1), combined AS (SELECT \"session\", \"path\" FROM landing_pages UNION SELECT \"session\", \"path\" FROM exit_pages) SELECT \"path\" AS \"PATH\", COUNT(DISTINCT \"session\") AS \"SESSION_COUNT\" FROM combined GROUP BY \"path\" ORDER BY \"SESSION_COUNT\" DESC") t0
  := by first | sql_equiv | sorry

end N_sf_local330_eq_0_2
