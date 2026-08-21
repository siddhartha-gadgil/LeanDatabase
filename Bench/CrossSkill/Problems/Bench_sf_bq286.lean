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
    (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (\n    SELECT \"name\", \"number\" AS wy_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021\n),\nall_states_names AS (\n    SELECT \"name\", SUM(\"number\") AS total_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"gender\" = 'F' AND \"year\" = 2021\n    GROUP BY \"name\"\n)\nSELECT w.\"name\" AS output\nFROM wy_names w\nJOIN all_states_names a ON w.\"name\" = a.\"name\"\nORDER BY w.wy_count * 1.0 / a.total_count DESC\nLIMIT 1;") t ~= (sql%([USA_1910_CURRENT_schema]) "SELECT\n  wy.\"name\" AS output\nFROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" wy\nJOIN (\n  SELECT \"name\", SUM(\"number\") AS total_count\n  FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n  WHERE \"year\" = 2021 AND \"gender\" = 'F'\n  GROUP BY \"name\"\n) total ON wy.\"name\" = total.\"name\"\nWHERE wy.\"year\" = 2021 AND wy.\"gender\" = 'F' AND wy.\"state\" = 'WY'\nORDER BY CAST(wy.\"number\" AS FLOAT) / total.total_count DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : USA_1910_CURRENT "\"state\" = 'WY'"
theorem eq_0_2 (t : TableRel USA_1910_CURRENT_schema) (h0 : hyp0_2_0 t) :
    (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (\n    SELECT \"name\", \"number\" AS wy_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021\n),\nall_states_names AS (\n    SELECT \"name\", SUM(\"number\") AS total_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"gender\" = 'F' AND \"year\" = 2021\n    GROUP BY \"name\"\n)\nSELECT w.\"name\" AS output\nFROM wy_names w\nJOIN all_states_names a ON w.\"name\" = a.\"name\"\nORDER BY w.wy_count * 1.0 / a.total_count DESC\nLIMIT 1;") t ~= (sql%([USA_1910_CURRENT_schema]) "SELECT wy.\"name\" AS \"output\"\nFROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" wy\nJOIN (\n  SELECT \"name\", SUM(\"number\") AS \"total_number\"\n  FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n  WHERE \"gender\" = 'F' AND \"year\" = 2021\n  GROUP BY \"name\"\n) total ON wy.\"name\" = total.\"name\"\nWHERE wy.\"state\" = 'WY' AND wy.\"gender\" = 'F' AND wy.\"year\" = 2021\nORDER BY wy.\"number\"::FLOAT / total.\"total_number\" DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (\n    SELECT \"name\", \"number\" AS wy_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021\n),\nall_states_names AS (\n    SELECT \"name\", SUM(\"number\") AS total_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"gender\" = 'F' AND \"year\" = 2021\n    GROUP BY \"name\"\n)\nSELECT w.\"name\" AS output\nFROM wy_names w\nJOIN all_states_names a ON w.\"name\" = a.\"name\"\nORDER BY w.wy_count * 1.0 / a.total_count DESC\nLIMIT 1;" = sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (\n    SELECT \"name\", SUM(\"number\") AS wy_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021\n    GROUP BY \"name\"\n),\nall_names AS (\n    SELECT \"name\", SUM(\"number\") AS total_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"gender\" = 'F' AND \"year\" = 2021\n    GROUP BY \"name\"\n)\nSELECT w.\"name\"\nFROM wy_names w\nJOIN all_names a ON w.\"name\" = a.\"name\"\nORDER BY w.wy_count * 1.0 / a.total_count DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([USA_1910_CURRENT_schema]) "SELECT\n  wy.\"name\" AS output\nFROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" wy\nJOIN (\n  SELECT \"name\", SUM(\"number\") AS total_count\n  FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n  WHERE \"year\" = 2021 AND \"gender\" = 'F'\n  GROUP BY \"name\"\n) total ON wy.\"name\" = total.\"name\"\nWHERE wy.\"year\" = 2021 AND wy.\"gender\" = 'F' AND wy.\"state\" = 'WY'\nORDER BY CAST(wy.\"number\" AS FLOAT) / total.total_count DESC\nLIMIT 1;" = sql%([USA_1910_CURRENT_schema]) "SELECT wy.\"name\" AS \"output\"\nFROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" wy\nJOIN (\n  SELECT \"name\", SUM(\"number\") AS \"total_number\"\n  FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n  WHERE \"gender\" = 'F' AND \"year\" = 2021\n  GROUP BY \"name\"\n) total ON wy.\"name\" = total.\"name\"\nWHERE wy.\"state\" = 'WY' AND wy.\"gender\" = 'F' AND wy.\"year\" = 2021\nORDER BY wy.\"number\"::FLOAT / total.\"total_number\" DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : USA_1910_CURRENT "\"state\" = 'WY'"
theorem eq_1_3 (t : TableRel USA_1910_CURRENT_schema) (h0 : hyp1_3_0 t) :
    (sql%([USA_1910_CURRENT_schema]) "SELECT\n  wy.\"name\" AS output\nFROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" wy\nJOIN (\n  SELECT \"name\", SUM(\"number\") AS total_count\n  FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n  WHERE \"year\" = 2021 AND \"gender\" = 'F'\n  GROUP BY \"name\"\n) total ON wy.\"name\" = total.\"name\"\nWHERE wy.\"year\" = 2021 AND wy.\"gender\" = 'F' AND wy.\"state\" = 'WY'\nORDER BY CAST(wy.\"number\" AS FLOAT) / total.total_count DESC\nLIMIT 1;") t ~= (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (\n    SELECT \"name\", SUM(\"number\") AS wy_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021\n    GROUP BY \"name\"\n),\nall_names AS (\n    SELECT \"name\", SUM(\"number\") AS total_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"gender\" = 'F' AND \"year\" = 2021\n    GROUP BY \"name\"\n)\nSELECT w.\"name\"\nFROM wy_names w\nJOIN all_names a ON w.\"name\" = a.\"name\"\nORDER BY w.wy_count * 1.0 / a.total_count DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : USA_1910_CURRENT "\"state\" = 'WY'"
theorem eq_2_3 (t : TableRel USA_1910_CURRENT_schema) (h0 : hyp2_3_0 t) :
    (sql%([USA_1910_CURRENT_schema]) "SELECT wy.\"name\" AS \"output\"\nFROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" wy\nJOIN (\n  SELECT \"name\", SUM(\"number\") AS \"total_number\"\n  FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n  WHERE \"gender\" = 'F' AND \"year\" = 2021\n  GROUP BY \"name\"\n) total ON wy.\"name\" = total.\"name\"\nWHERE wy.\"state\" = 'WY' AND wy.\"gender\" = 'F' AND wy.\"year\" = 2021\nORDER BY wy.\"number\"::FLOAT / total.\"total_number\" DESC\nLIMIT 1;") t ~= (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (\n    SELECT \"name\", SUM(\"number\") AS wy_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021\n    GROUP BY \"name\"\n),\nall_names AS (\n    SELECT \"name\", SUM(\"number\") AS total_count\n    FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\"\n    WHERE \"gender\" = 'F' AND \"year\" = 2021\n    GROUP BY \"name\"\n)\nSELECT w.\"name\"\nFROM wy_names w\nJOIN all_names a ON w.\"name\" = a.\"name\"\nORDER BY w.wy_count * 1.0 / a.total_count DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq286
