import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq286_eq_0_3

CREATE TABLE USA_1910_CURRENT («state» STRING, «gender» STRING, «year» INT, «name» STRING, «number» INT)

theorem eq (t0 : TableRel USA_1910_CURRENT_schema) :
    (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (SELECT \"name\", \"number\" AS wy_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021), all_states_names AS (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") SELECT w.\"name\" AS output FROM wy_names AS w JOIN all_states_names AS a ON w.\"name\" = a.\"name\" ORDER BY CAST(w.wy_count * 1.0 AS DOUBLE PRECISION) / a.total_count DESC LIMIT 1") t0
  = (sql%([USA_1910_CURRENT_schema]) "WITH wy_names AS (SELECT \"name\", SUM(\"number\") AS wy_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"state\" = 'WY' AND \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\"), all_names AS (SELECT \"name\", SUM(\"number\") AS total_count FROM \"USA_NAMES\".\"USA_NAMES\".\"USA_1910_CURRENT\" WHERE \"gender\" = 'F' AND \"year\" = 2021 GROUP BY \"name\") SELECT w.\"name\" FROM wy_names AS w JOIN all_names AS a ON w.\"name\" = a.\"name\" ORDER BY CAST(w.wy_count * 1.0 AS DOUBLE PRECISION) / a.total_count DESC LIMIT 1") t0
  := by first | sql_equiv | sorry

end N_sf_bq286_eq_0_3
