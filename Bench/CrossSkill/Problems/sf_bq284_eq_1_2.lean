import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq284_eq_1_2

CREATE TABLE FULLTEXT («body» STRING, «title» STRING, «filename» STRING, «category» STRING)

theorem eq (t0 : TableRel FULLTEXT_schema) :
    (sql%([FULLTEXT_schema]) "SELECT \"category\" AS category, COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY, CAST(100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) AS DOUBLE PRECISION) / COUNT(*) AS PERCENT_EDUCATION FROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\" GROUP BY \"category\" ORDER BY \"category\"") t0
  = (sql%([FULLTEXT_schema]) "SELECT \"category\", COUNT(*) AS \"NUMBER_TOTAL_BY_CATEGORY\", ROUND(CAST(CAST(100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 2) AS \"PERCENT_EDUCATION\" FROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\" GROUP BY \"category\" ORDER BY \"category\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq284_eq_1_2
