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
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n    SELECT \n        \"date\",\n        COUNT(*) AS cnt\n    FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n    WHERE \"descript\" = 'PUBLIC INTOXICATION'\n    GROUP BY \"date\"\n),\nstats AS (\n    SELECT \n        AVG(cnt) AS mean_cnt,\n        STDDEV_POP(cnt) AS stddev_cnt\n    FROM daily_counts\n),\nz_scores AS (\n    SELECT \n        dc.\"date\",\n        (dc.cnt - s.mean_cnt) / s.stddev_cnt AS z_score\n    FROM daily_counts dc\n    CROSS JOIN stats s\n)\nSELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\"\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n  SELECT \n    \"date\" AS dt,\n    COUNT(*) AS cnt\n  FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n  WHERE \"descript\" = 'PUBLIC INTOXICATION'\n  GROUP BY \"date\"\n),\nstats AS (\n  SELECT AVG(cnt) AS mean_val, STDDEV_POP(cnt) AS stddev_val\n  FROM daily_counts\n),\nz_scores AS (\n  SELECT \n    d.dt AS date,\n    ROUND((d.cnt - s.mean_val) / s.stddev_val, 2) AS z_score\n  FROM daily_counts d, stats s\n)\nSELECT TO_CHAR(date, 'YYYY-MM-DD') AS date\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : INCIDENTS_2016 "\"date\" = CAST(\"date\" AS DATE)"
theorem eq_0_2 (t : TableRel INCIDENTS_2016_schema) (h0 : hyp0_2_0 t) :
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n    SELECT \n        \"date\",\n        COUNT(*) AS cnt\n    FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n    WHERE \"descript\" = 'PUBLIC INTOXICATION'\n    GROUP BY \"date\"\n),\nstats AS (\n    SELECT \n        AVG(cnt) AS mean_cnt,\n        STDDEV_POP(cnt) AS stddev_cnt\n    FROM daily_counts\n),\nz_scores AS (\n    SELECT \n        dc.\"date\",\n        (dc.cnt - s.mean_cnt) / s.stddev_cnt AS z_score\n    FROM daily_counts dc\n    CROSS JOIN stats s\n)\nSELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\"\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n  SELECT\n    CAST(\"date\" AS DATE) AS \"date\",\n    COUNT(*) AS daily_count\n  FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n  WHERE \"descript\" = 'PUBLIC INTOXICATION'\n  GROUP BY CAST(\"date\" AS DATE)\n),\nstats AS (\n  SELECT\n    AVG(daily_count) AS mean_count,\n    STDDEV(daily_count) AS stddev_count\n  FROM daily_counts\n),\nz_scores AS (\n  SELECT\n    d.\"date\",\n    (d.daily_count - s.mean_count) / s.stddev_count AS z_score\n  FROM daily_counts d\n  CROSS JOIN stats s\n)\nSELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\"\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t := by
  first | sql_equiv | sorry

theorem eq_0_3 : ∀ t,
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n    SELECT \n        \"date\",\n        COUNT(*) AS cnt\n    FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n    WHERE \"descript\" = 'PUBLIC INTOXICATION'\n    GROUP BY \"date\"\n),\nstats AS (\n    SELECT \n        AVG(cnt) AS mean_cnt,\n        STDDEV_POP(cnt) AS stddev_cnt\n    FROM daily_counts\n),\nz_scores AS (\n    SELECT \n        dc.\"date\",\n        (dc.cnt - s.mean_cnt) / s.stddev_cnt AS z_score\n    FROM daily_counts dc\n    CROSS JOIN stats s\n)\nSELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\"\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n    SELECT\n        \"date\",\n        COUNT(*) AS incident_count\n    FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n    WHERE \"descript\" = 'PUBLIC INTOXICATION'\n    GROUP BY \"date\"\n),\nstats AS (\n    SELECT\n        AVG(incident_count) AS mean_count,\n        STDDEV_POP(incident_count) AS stddev_count\n    FROM daily_counts\n),\nz_scores AS (\n    SELECT\n        d.\"date\",\n        d.incident_count,\n        ROUND((d.incident_count - s.mean_count) / s.stddev_count, 4) AS z_score\n    FROM daily_counts d\n    CROSS JOIN stats s\n)\nSELECT \"date\"\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n  SELECT \n    \"date\" AS dt,\n    COUNT(*) AS cnt\n  FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n  WHERE \"descript\" = 'PUBLIC INTOXICATION'\n  GROUP BY \"date\"\n),\nstats AS (\n  SELECT AVG(cnt) AS mean_val, STDDEV_POP(cnt) AS stddev_val\n  FROM daily_counts\n),\nz_scores AS (\n  SELECT \n    d.dt AS date,\n    ROUND((d.cnt - s.mean_val) / s.stddev_val, 2) AS z_score\n  FROM daily_counts d, stats s\n)\nSELECT TO_CHAR(date, 'YYYY-MM-DD') AS date\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n  SELECT\n    CAST(\"date\" AS DATE) AS \"date\",\n    COUNT(*) AS daily_count\n  FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n  WHERE \"descript\" = 'PUBLIC INTOXICATION'\n  GROUP BY CAST(\"date\" AS DATE)\n),\nstats AS (\n  SELECT\n    AVG(daily_count) AS mean_count,\n    STDDEV(daily_count) AS stddev_count\n  FROM daily_counts\n),\nz_scores AS (\n  SELECT\n    d.\"date\",\n    (d.daily_count - s.mean_count) / s.stddev_count AS z_score\n  FROM daily_counts d\n  CROSS JOIN stats s\n)\nSELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\"\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_3 : ∀ t,
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n  SELECT \n    \"date\" AS dt,\n    COUNT(*) AS cnt\n  FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n  WHERE \"descript\" = 'PUBLIC INTOXICATION'\n  GROUP BY \"date\"\n),\nstats AS (\n  SELECT AVG(cnt) AS mean_val, STDDEV_POP(cnt) AS stddev_val\n  FROM daily_counts\n),\nz_scores AS (\n  SELECT \n    d.dt AS date,\n    ROUND((d.cnt - s.mean_val) / s.stddev_val, 2) AS z_score\n  FROM daily_counts d, stats s\n)\nSELECT TO_CHAR(date, 'YYYY-MM-DD') AS date\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n    SELECT\n        \"date\",\n        COUNT(*) AS incident_count\n    FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n    WHERE \"descript\" = 'PUBLIC INTOXICATION'\n    GROUP BY \"date\"\n),\nstats AS (\n    SELECT\n        AVG(incident_count) AS mean_count,\n        STDDEV_POP(incident_count) AS stddev_count\n    FROM daily_counts\n),\nz_scores AS (\n    SELECT\n        d.\"date\",\n        d.incident_count,\n        ROUND((d.incident_count - s.mean_count) / s.stddev_count, 4) AS z_score\n    FROM daily_counts d\n    CROSS JOIN stats s\n)\nSELECT \"date\"\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : INCIDENTS_2016 "CAST(\"date\" AS DATE) = \"date\""
theorem eq_2_3 (t : TableRel INCIDENTS_2016_schema) (h0 : hyp2_3_0 t) :
    (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n  SELECT\n    CAST(\"date\" AS DATE) AS \"date\",\n    COUNT(*) AS daily_count\n  FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n  WHERE \"descript\" = 'PUBLIC INTOXICATION'\n  GROUP BY CAST(\"date\" AS DATE)\n),\nstats AS (\n  SELECT\n    AVG(daily_count) AS mean_count,\n    STDDEV(daily_count) AS stddev_count\n  FROM daily_counts\n),\nz_scores AS (\n  SELECT\n    d.\"date\",\n    (d.daily_count - s.mean_count) / s.stddev_count AS z_score\n  FROM daily_counts d\n  CROSS JOIN stats s\n)\nSELECT TO_CHAR(\"date\", 'YYYY-MM-DD') AS \"date\"\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t ~= (sql%([INCIDENTS_2016_schema]) "WITH daily_counts AS (\n    SELECT\n        \"date\",\n        COUNT(*) AS incident_count\n    FROM \"AUSTIN\".\"AUSTIN_INCIDENTS\".\"INCIDENTS_2016\"\n    WHERE \"descript\" = 'PUBLIC INTOXICATION'\n    GROUP BY \"date\"\n),\nstats AS (\n    SELECT\n        AVG(incident_count) AS mean_count,\n        STDDEV_POP(incident_count) AS stddev_count\n    FROM daily_counts\n),\nz_scores AS (\n    SELECT\n        d.\"date\",\n        d.incident_count,\n        ROUND((d.incident_count - s.mean_count) / s.stddev_count, 4) AS z_score\n    FROM daily_counts d\n    CROSS JOIN stats s\n)\nSELECT \"date\"\nFROM z_scores\nORDER BY z_score DESC\nLIMIT 1 OFFSET 1;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq006
