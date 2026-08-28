import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq034 — crossskill equivalence(s)

Question: I want to know the IDs, names of weather stations within a 50 km straight-line distance from the center of Chicago (41.8319°N, 87.6847°W)

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq034

CREATE TABLE GHCND_STATIONS («id» STRING, «latitude» FLOAT, «longitude» FLOAT, «elevation» FLOAT, «state» STRING, «name» STRING, «gsn_flag» STRING, «hcn_crn_flag» STRING, «wmoid» INT, «source_url» STRING, «etl_timestamp» INT)

HYPOTHESIS hyp0_1_0 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) <= 50000"
HYPOTHESIS hyp0_1_1 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) < 50000"
theorem eq_0_1 (t : TableRel GHCND_STATIONS_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) :
    (sql%([GHCND_STATIONS_schema]) "SELECT \"id\", \"name\", \"state\", ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) AS LOC, ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) AS DIST_METERS, RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) AS RANK FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) <= 50000 ORDER BY DIST_METERS") t = (sql%([GHCND_STATIONS_schema]) "SELECT \"id\", \"name\", \"state\", ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) AS LOC, ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) AS DIST_METERS, RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) AS RANK FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) < 50000 ORDER BY DIST_METERS") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) <= 50000"
HYPOTHESIS hyp0_2_1 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) <= 50000"
HYPOTHESIS hyp0_2_2 : GHCND_STATIONS "ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) = 'POINT(' || \"longitude\" || ' ' || \"latitude\" || ')'"
HYPOTHESIS hyp0_2_3 : GHCND_STATIONS "RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) = RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)))"
HYPOTHESIS hyp0_2_4 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) = ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319))"
theorem eq_0_2 (t : TableRel GHCND_STATIONS_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) (h2 : hyp0_2_2 t) (h3 : hyp0_2_3 t) (h4 : hyp0_2_4 t) :
    (sql%([GHCND_STATIONS_schema]) "SELECT \"id\", \"name\", \"state\", ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) AS LOC, ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) AS DIST_METERS, RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) AS RANK FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) <= 50000 ORDER BY DIST_METERS") t = (sql%([GHCND_STATIONS_schema]) "SELECT \"id\" AS \"id\", \"name\" AS \"name\", \"state\" AS \"state\", 'POINT(' || \"longitude\" || ' ' || \"latitude\" || ')' AS \"LOC\", ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) AS \"DIST_METERS\", RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319))) AS \"RANK\" FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) <= 50000 ORDER BY \"DIST_METERS\", \"id\"") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) <= 50000"
HYPOTHESIS hyp0_3_1 : GHCND_STATIONS "ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)) < 50000"
HYPOTHESIS hyp0_3_2 : GHCND_STATIONS "RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) = ROW_NUMBER() OVER (ORDER BY ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)))"
HYPOTHESIS hyp0_3_3 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) = ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY))"
theorem eq_0_3 (t : TableRel GHCND_STATIONS_schema) (h0 : hyp0_3_0 t) (h1 : hyp0_3_1 t) (h2 : hyp0_3_2 t) (h3 : hyp0_3_3 t) :
    (sql%([GHCND_STATIONS_schema]) "SELECT \"id\", \"name\", \"state\", ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) AS LOC, ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) AS DIST_METERS, RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) AS RANK FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) <= 50000 ORDER BY DIST_METERS") t = (sql%([GHCND_STATIONS_schema]) "SELECT \"id\", \"name\", \"state\", ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) AS LOC, ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)) AS DIST_METERS, ROW_NUMBER() OVER (ORDER BY ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY))) AS RANK FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)) < 50000 ORDER BY DIST_METERS") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) < 50000"
HYPOTHESIS hyp1_2_1 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) <= 50000"
HYPOTHESIS hyp1_2_2 : GHCND_STATIONS "ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) = 'POINT(' || \"longitude\" || ' ' || \"latitude\" || ')'"
HYPOTHESIS hyp1_2_3 : GHCND_STATIONS "RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) = RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)))"
HYPOTHESIS hyp1_2_4 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) = ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319))"
theorem eq_1_2 (t : TableRel GHCND_STATIONS_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) (h2 : hyp1_2_2 t) (h3 : hyp1_2_3 t) (h4 : hyp1_2_4 t) :
    (sql%([GHCND_STATIONS_schema]) "SELECT \"id\", \"name\", \"state\", ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) AS LOC, ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) AS DIST_METERS, RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) AS RANK FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) < 50000 ORDER BY DIST_METERS") t = (sql%([GHCND_STATIONS_schema]) "SELECT \"id\" AS \"id\", \"name\" AS \"name\", \"state\" AS \"state\", 'POINT(' || \"longitude\" || ' ' || \"latitude\" || ')' AS \"LOC\", ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) AS \"DIST_METERS\", RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319))) AS \"RANK\" FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) <= 50000 ORDER BY \"DIST_METERS\", \"id\"") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) < 50000"
HYPOTHESIS hyp1_3_1 : GHCND_STATIONS "ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)) < 50000"
HYPOTHESIS hyp1_3_2 : GHCND_STATIONS "RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) = ROW_NUMBER() OVER (ORDER BY ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)))"
HYPOTHESIS hyp1_3_3 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) = ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY))"
theorem eq_1_3 (t : TableRel GHCND_STATIONS_schema) (h0 : hyp1_3_0 t) (h1 : hyp1_3_1 t) (h2 : hyp1_3_2 t) (h3 : hyp1_3_3 t) :
    (sql%([GHCND_STATIONS_schema]) "SELECT \"id\", \"name\", \"state\", ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) AS LOC, ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) AS DIST_METERS, RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\"))) AS RANK FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(ST_POINT(-87.6847, 41.8319), ST_POINT(\"longitude\", \"latitude\")) < 50000 ORDER BY DIST_METERS") t = (sql%([GHCND_STATIONS_schema]) "SELECT \"id\", \"name\", \"state\", ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) AS LOC, ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)) AS DIST_METERS, ROW_NUMBER() OVER (ORDER BY ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY))) AS RANK FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)) < 50000 ORDER BY DIST_METERS") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) <= 50000"
HYPOTHESIS hyp2_3_1 : GHCND_STATIONS "ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)) < 50000"
HYPOTHESIS hyp2_3_2 : GHCND_STATIONS "'POINT(' || \"longitude\" || ' ' || \"latitude\" || ')' = ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\"))"
HYPOTHESIS hyp2_3_3 : GHCND_STATIONS "RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319))) = ROW_NUMBER() OVER (ORDER BY ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)))"
HYPOTHESIS hyp2_3_4 : GHCND_STATIONS "ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) = ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY))"
theorem eq_2_3 (t : TableRel GHCND_STATIONS_schema) (h0 : hyp2_3_0 t) (h1 : hyp2_3_1 t) (h2 : hyp2_3_2 t) (h3 : hyp2_3_3 t) (h4 : hyp2_3_4 t) :
    (sql%([GHCND_STATIONS_schema]) "SELECT \"id\" AS \"id\", \"name\" AS \"name\", \"state\" AS \"state\", 'POINT(' || \"longitude\" || ' ' || \"latitude\" || ')' AS \"LOC\", ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) AS \"DIST_METERS\", RANK() OVER (ORDER BY ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319))) AS \"RANK\" FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(ST_POINT(\"longitude\", \"latitude\"), ST_POINT(-87.6847, 41.8319)) <= 50000 ORDER BY \"DIST_METERS\", \"id\"") t = (sql%([GHCND_STATIONS_schema]) "SELECT \"id\", \"name\", \"state\", ST_ASTEXT(ST_POINT(\"longitude\", \"latitude\")) AS LOC, ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)) AS DIST_METERS, ROW_NUMBER() OVER (ORDER BY ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY))) AS RANK FROM \"GHCN_D\".\"GHCN_D\".\"GHCND_STATIONS\" WHERE ST_DISTANCE(CAST(ST_POINT(\"longitude\", \"latitude\") AS GEOGRAPHY), CAST(ST_POINT(-87.6847, 41.8319) AS GEOGRAPHY)) < 50000 ORDER BY DIST_METERS") t := by
  first | sql_equiv | sorry

end Bench_sf_bq034
