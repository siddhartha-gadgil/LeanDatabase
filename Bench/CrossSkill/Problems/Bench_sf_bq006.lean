import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq006 — crossskill equivalence(s)

Question: What is the date with the second highest Z-score for daily counts of 'PUBLIC INTOXICATION' incidents in Austin for the year 2016? List the date in the format of '2016-xx-xx'.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq006

CREATE TABLE INCIDENTS_2016 («unique_key» INT, «descript» STRING, «date» STRING, «time» STRING, «address» STRING, «longitude» FLOAT, «latitude» FLOAT, «location» STRING, «timestamp» INT)

theorem eq_0_1 : ∀ t,
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\", COUNT(*) AS cnt FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(cnt) AS mean_cnt, STDDEV_POP(cnt) AS stddev_cnt FROM daily_counts), z_scores AS (SELECT dc.\"date\", CAST((dc.cnt - s.mean_cnt) AS DOUBLE PRECISION) / s.stddev_cnt AS z_score FROM daily_counts AS dc CROSS JOIN stats AS s) SELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\" AS dt, COUNT(*) AS cnt FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(cnt) AS mean_val, STDDEV_POP(cnt) AS stddev_val FROM daily_counts), z_scores AS (SELECT d.dt AS date, ROUND(CAST((d.cnt - s.mean_val) AS DOUBLE PRECISION) / s.stddev_val, 2) AS z_score FROM daily_counts AS d, stats AS s) SELECT TO_CHAR(date, 'YYYY-MM-DD') AS date FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : INCIDENTS_2016 "\"date\" = CAST(\"date\" AS DATE)"
theorem eq_0_2 (t : TableRel INCIDENTS_2016_schema) (h0 : hyp0_2_0 t) :
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\", COUNT(*) AS cnt FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(cnt) AS mean_cnt, STDDEV_POP(cnt) AS stddev_cnt FROM daily_counts), z_scores AS (SELECT dc.\"date\", CAST((dc.cnt - s.mean_cnt) AS DOUBLE PRECISION) / s.stddev_cnt AS z_score FROM daily_counts AS dc CROSS JOIN stats AS s) SELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT CAST(\"date\" AS DATE) AS \"date\", COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY CAST(\"date\" AS DATE)), stats AS (SELECT AVG(daily_count) AS mean_count, STDDEV(daily_count) AS stddev_count FROM daily_counts), z_scores AS (SELECT d.\"date\", CAST((d.daily_count - s.mean_count) AS DOUBLE PRECISION) / s.stddev_count AS z_score FROM daily_counts AS d CROSS JOIN stats AS s) SELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t := by
  first | sql_equiv | sorry

theorem eq_0_3 : ∀ t,
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\", COUNT(*) AS cnt FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(cnt) AS mean_cnt, STDDEV_POP(cnt) AS stddev_cnt FROM daily_counts), z_scores AS (SELECT dc.\"date\", CAST((dc.cnt - s.mean_cnt) AS DOUBLE PRECISION) / s.stddev_cnt AS z_score FROM daily_counts AS dc CROSS JOIN stats AS s) SELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\", COUNT(*) AS incident_count FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(incident_count) AS mean_count, STDDEV_POP(incident_count) AS stddev_count FROM daily_counts), z_scores AS (SELECT d.\"date\", d.incident_count, ROUND(CAST((d.incident_count - s.mean_count) AS DOUBLE PRECISION) / s.stddev_count, 4) AS z_score FROM daily_counts AS d CROSS JOIN stats AS s) SELECT \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\" AS dt, COUNT(*) AS cnt FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(cnt) AS mean_val, STDDEV_POP(cnt) AS stddev_val FROM daily_counts), z_scores AS (SELECT d.dt AS date, ROUND(CAST((d.cnt - s.mean_val) AS DOUBLE PRECISION) / s.stddev_val, 2) AS z_score FROM daily_counts AS d, stats AS s) SELECT TO_CHAR(date, 'YYYY-MM-DD') AS date FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT CAST(\"date\" AS DATE) AS \"date\", COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY CAST(\"date\" AS DATE)), stats AS (SELECT AVG(daily_count) AS mean_count, STDDEV(daily_count) AS stddev_count FROM daily_counts), z_scores AS (SELECT d.\"date\", CAST((d.daily_count - s.mean_count) AS DOUBLE PRECISION) / s.stddev_count AS z_score FROM daily_counts AS d CROSS JOIN stats AS s) SELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_3 : ∀ t,
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\" AS dt, COUNT(*) AS cnt FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(cnt) AS mean_val, STDDEV_POP(cnt) AS stddev_val FROM daily_counts), z_scores AS (SELECT d.dt AS date, ROUND(CAST((d.cnt - s.mean_val) AS DOUBLE PRECISION) / s.stddev_val, 2) AS z_score FROM daily_counts AS d, stats AS s) SELECT TO_CHAR(date, 'YYYY-MM-DD') AS date FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\", COUNT(*) AS incident_count FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(incident_count) AS mean_count, STDDEV_POP(incident_count) AS stddev_count FROM daily_counts), z_scores AS (SELECT d.\"date\", d.incident_count, ROUND(CAST((d.incident_count - s.mean_count) AS DOUBLE PRECISION) / s.stddev_count, 4) AS z_score FROM daily_counts AS d CROSS JOIN stats AS s) SELECT \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : INCIDENTS_2016 "CAST(\"date\" AS DATE) = \"date\""
theorem eq_2_3 (t : TableRel INCIDENTS_2016_schema) (h0 : hyp2_3_0 t) :
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT CAST(\"date\" AS DATE) AS \"date\", COUNT(*) AS daily_count FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY CAST(\"date\" AS DATE)), stats AS (SELECT AVG(daily_count) AS mean_count, STDDEV(daily_count) AS stddev_count FROM daily_counts), z_scores AS (SELECT d.\"date\", CAST((d.daily_count - s.mean_count) AS DOUBLE PRECISION) / s.stddev_count AS z_score FROM daily_counts AS d CROSS JOIN stats AS s) SELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (SELECT \"date\", COUNT(*) AS incident_count FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\" WHERE \"descript\" = 'PUBLIC INTOXICATION' GROUP BY \"date\"), stats AS (SELECT AVG(incident_count) AS mean_count, STDDEV_POP(incident_count) AS stddev_count FROM daily_counts), z_scores AS (SELECT d.\"date\", d.incident_count, ROUND(CAST((d.incident_count - s.mean_count) AS DOUBLE PRECISION) / s.stddev_count, 4) AS z_score FROM daily_counts AS d CROSS JOIN stats AS s) SELECT \"date\" FROM z_scores ORDER BY z_score DESC LIMIT 1 OFFSET 1") t := by
  first | sql_equiv | sorry

end Bench_sf_bq006
