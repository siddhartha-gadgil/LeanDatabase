import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_35_eq

CREATE TABLE R1 («X» INT)
CREATE TABLE R2 («X» INT)

theorem eq (t0 : TableRel R1_schema) (t1 : TableRel R2_schema) :
    (sql%([R1_schema, R2_schema]) "SELECT * FROM R1 AS X, (SELECT * FROM R2 AS Y WHERE B(Y)) AS Z") t0 t1
  ~= (sql%([R1_schema, R2_schema]) "SELECT * FROM R1 AS X, R2 AS Y WHERE B(Y)") t0 t1
  := by first | sql_equiv | sorry

end N_35_eq
