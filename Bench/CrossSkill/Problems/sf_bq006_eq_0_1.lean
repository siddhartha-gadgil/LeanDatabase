import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq006_eq_0_1

CREATE TABLE INCIDENTS_2016 («unique_key» INT, «descript» STRING, «date» STRING, «time» STRING, «address» STRING, «longitude» FLOAT, «latitude» FLOAT, «location» STRING, «timestamp» INT)

theorem eq (t0 : TableRel INCIDENTS_2016_schema) :
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\", COUNT(*) AS cnt FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(cnt) AS mean_cnt, STDDEV_POP(cnt) AS stddev_cnt FROM daily_counts), z_scores AS (SELECT dc.\"date\", CAST((dc.cnt - s.mean_cnt) AS DOUBLE PRECISION) / s.stddev_cnt AS z_score FROM daily_counts AS dc CROSS JOIN stats AS s) SELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t0
  ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\" AS dt, COUNT(*) AS cnt FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(cnt) AS mean_val, STDDEV_POP(cnt) AS stddev_val FROM daily_counts), z_scores AS (SELECT d.dt AS date, ROUND(CAST((d.cnt - s.mean_val) AS DOUBLE PRECISION) / s.stddev_val, 2) AS z_score FROM daily_counts AS d, stats AS s) SELECT TO_CHAR(date, 'YYYY-MM-DD') AS date FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t0
  := by first | sql_equiv | sorry

end N_sf_bq006_eq_0_1
