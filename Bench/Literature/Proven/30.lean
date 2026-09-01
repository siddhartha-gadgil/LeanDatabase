import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_30_eq

CREATE TABLE R1 («X» INT)
CREATE TABLE R2 («X» INT)
CREATE TABLE R3 («X» INT)

theorem eq (t0 : TableRel R1_schema) (t1 : TableRel R2_schema) (t2 : TableRel R3_schema) :
    (sql%([R1_schema, R2_schema, R3_schema]) "SELECT * FROM R1 AS X, (SELECT * FROM R2 UNION ALL SELECT * FROM R3) AS Y") t0 t1 t2
  ~= (sql%([R1_schema, R2_schema, R3_schema]) "(SELECT * FROM R1 AS X, R2 AS Y) UNION ALL (SELECT * FROM R1 AS X, R3 AS Y)") t0 t1 t2
  := by sql_equiv

end N_30_eq
