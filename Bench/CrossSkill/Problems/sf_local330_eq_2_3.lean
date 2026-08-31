import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local330_eq_2_3

CREATE TABLE ACTIVITY_LOG («stamp» STRING, «session» STRING, «action» STRING, «option» STRING, «path» STRING, «search_type» STRING)

theorem eq (t0 : TableRel ACTIVITY_LOG_schema) :
    (sql%([ACTIVITY_LOG_schema]) "WITH landing_pages AS (SELECT \"session\", \"path\" FROM (SELECT \"session\", \"path\", ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\" ASC) AS rn FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\") WHERE rn = 1), exit_pages AS (SELECT \"session\", \"path\" FROM (SELECT \"session\", \"path\", ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\" DESC) AS rn FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\") WHERE rn = 1), combined AS (SELECT \"session\", \"path\" FROM landing_pages UNION SELECT \"session\", \"path\" FROM exit_pages) SELECT \"path\" AS \"PATH\", COUNT(DISTINCT \"session\") AS \"SESSION_COUNT\" FROM combined GROUP BY \"path\" ORDER BY \"SESSION_COUNT\" DESC") t0
  ~= (sql%([ACTIVITY_LOG_schema]) "WITH landing_pages AS (SELECT \"session\", page FROM (SELECT \"session\", TRIM(TRAILING '/' FROM \"path\") AS page, ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\" ASC) AS _w, \"stamp\" FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\") AS _t WHERE _w = 1), exit_pages AS (SELECT \"session\", page FROM (SELECT \"session\", TRIM(TRAILING '/' FROM \"path\") AS page, ROW_NUMBER() OVER (PARTITION BY \"session\" ORDER BY \"stamp\" DESC) AS _w, \"stamp\" FROM \"LOG\".\"LOG\".\"ACTIVITY_LOG\") AS _t WHERE _w = 1), combined AS (SELECT \"session\", page FROM landing_pages UNION SELECT \"session\", page FROM exit_pages) SELECT page AS PATH, COUNT(DISTINCT \"session\") AS SESSION_COUNT FROM combined GROUP BY page ORDER BY SESSION_COUNT DESC, PATH ASC") t0
  := by first | sql_equiv | sorry

end N_sf_local330_eq_2_3
