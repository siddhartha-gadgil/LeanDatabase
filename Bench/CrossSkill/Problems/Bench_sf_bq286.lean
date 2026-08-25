import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq286 — crossskill equivalence(s)

Question: Can you tell me the name of the most popular female baby in Wyoming for the year 2021, based on the proportion of female babies given that name compared to the total number of female babies given the same name across all states?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq286

CREATE TABLE USA_1910_CURRENT («state» STRING, «gender» STRING, «year» INT, «name» STRING, «number» INT)

HYPOTHESIS hyp0_1_0 : USA_1910_CURRENT "\"state\" = 'WY'"
theorem eq_0_1 (t : TableRel USA_1910_CURRENT_schema) (h0 : hyp0_1_0 t) :
    (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (SELECT \"name\", \"number\" AS wy_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021), all_states_names AS (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") SELECT w.\"name\" AS output FROM wy_names AS w JOIN all_states_names AS a ON w.\"name\" = a.\"name\" ORDER BY CAST(w.wy_count * 1.0 AS DOUBLE PRECISION) / a.total_count DESC LIMIT 1") t ~= (sql%([USA_1910_CURRENT_schema]) "SELECT wy.\"name\" AS output FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" AS wy JOIN (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"year\" = 2021 AND \"gender\" = 'F' GROUP BY \"name\") AS total ON wy.\"name\" = total.\"name\" WHERE wy.\"year\" = 2021 AND wy.\"gender\" = 'F' AND wy.\"state\" = 'WY' ORDER BY CAST(wy.\"number\" AS DOUBLE PRECISION) / total.total_count DESC LIMIT 1") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : USA_1910_CURRENT "\"state\" = 'WY'"
theorem eq_0_2 (t : TableRel USA_1910_CURRENT_schema) (h0 : hyp0_2_0 t) :
    (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (SELECT \"name\", \"number\" AS wy_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021), all_states_names AS (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") SELECT w.\"name\" AS output FROM wy_names AS w JOIN all_states_names AS a ON w.\"name\" = a.\"name\" ORDER BY CAST(w.wy_count * 1.0 AS DOUBLE PRECISION) / a.total_count DESC LIMIT 1") t ~= (sql%([USA_1910_CURRENT_schema]) "SELECT wy.\"name\" AS \"output\" FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" AS wy JOIN (SELECT \"name\", SUM(\"number\") AS \"total_number\" FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") AS total ON wy.\"name\" = total.\"name\" WHERE wy.\"state\" = 'WY' AND wy.\"gender\" = 'F' AND wy.\"year\" = 2021 ORDER BY CAST(wy.\"number\" AS DOUBLE PRECISION) / total.\"total_number\" DESC LIMIT 1") t := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (SELECT \"name\", \"number\" AS wy_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021), all_states_names AS (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") SELECT w.\"name\" AS output FROM wy_names AS w JOIN all_states_names AS a ON w.\"name\" = a.\"name\" ORDER BY CAST(w.wy_count * 1.0 AS DOUBLE PRECISION) / a.total_count DESC LIMIT 1" = sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (SELECT \"name\", SUM(\"number\") AS wy_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\"), all_names AS (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") SELECT w.\"name\" FROM wy_names AS w JOIN all_names AS a ON w.\"name\" = a.\"name\" ORDER BY CAST(w.wy_count * 1.0 AS DOUBLE PRECISION) / a.total_count DESC LIMIT 1" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([USA_1910_CURRENT_schema]) "SELECT wy.\"name\" AS output FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" AS wy JOIN (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"year\" = 2021 AND \"gender\" = 'F' GROUP BY \"name\") AS total ON wy.\"name\" = total.\"name\" WHERE wy.\"year\" = 2021 AND wy.\"gender\" = 'F' AND wy.\"state\" = 'WY' ORDER BY CAST(wy.\"number\" AS DOUBLE PRECISION) / total.total_count DESC LIMIT 1" = sql%([USA_1910_CURRENT_schema]) "SELECT wy.\"name\" AS \"output\" FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" AS wy JOIN (SELECT \"name\", SUM(\"number\") AS \"total_number\" FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") AS total ON wy.\"name\" = total.\"name\" WHERE wy.\"state\" = 'WY' AND wy.\"gender\" = 'F' AND wy.\"year\" = 2021 ORDER BY CAST(wy.\"number\" AS DOUBLE PRECISION) / total.\"total_number\" DESC LIMIT 1" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : USA_1910_CURRENT "\"state\" = 'WY'"
theorem eq_1_3 (t : TableRel USA_1910_CURRENT_schema) (h0 : hyp1_3_0 t) :
    (sql%([USA_1910_CURRENT_schema]) "SELECT wy.\"name\" AS output FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" AS wy JOIN (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"year\" = 2021 AND \"gender\" = 'F' GROUP BY \"name\") AS total ON wy.\"name\" = total.\"name\" WHERE wy.\"year\" = 2021 AND wy.\"gender\" = 'F' AND wy.\"state\" = 'WY' ORDER BY CAST(wy.\"number\" AS DOUBLE PRECISION) / total.total_count DESC LIMIT 1") t ~= (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (SELECT \"name\", SUM(\"number\") AS wy_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\"), all_names AS (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") SELECT w.\"name\" FROM wy_names AS w JOIN all_names AS a ON w.\"name\" = a.\"name\" ORDER BY CAST(w.wy_count * 1.0 AS DOUBLE PRECISION) / a.total_count DESC LIMIT 1") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : USA_1910_CURRENT "\"state\" = 'WY'"
theorem eq_2_3 (t : TableRel USA_1910_CURRENT_schema) (h0 : hyp2_3_0 t) :
    (sql%([USA_1910_CURRENT_schema]) "SELECT wy.\"name\" AS \"output\" FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" AS wy JOIN (SELECT \"name\", SUM(\"number\") AS \"total_number\" FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") AS total ON wy.\"name\" = total.\"name\" WHERE wy.\"state\" = 'WY' AND wy.\"gender\" = 'F' AND wy.\"year\" = 2021 ORDER BY CAST(wy.\"number\" AS DOUBLE PRECISION) / total.\"total_number\" DESC LIMIT 1") t ~= (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (SELECT \"name\", SUM(\"number\") AS wy_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\"), all_names AS (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") SELECT w.\"name\" FROM wy_names AS w JOIN all_names AS a ON w.\"name\" = a.\"name\" ORDER BY CAST(w.wy_count * 1.0 AS DOUBLE PRECISION) / a.total_count DESC LIMIT 1") t := by
  first | sql_equiv | sorry

end Bench_sf_bq286
