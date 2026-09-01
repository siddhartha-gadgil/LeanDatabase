import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_20_eq

CREATE TABLE R («A1» INT, «A2» INT)

theorem eq (t0 : TableRel R_schema) :
    (sql%([R_schema]) "SELECT DISTINCT Y.A1 AS A1, Y.A2 AS A2 FROM R AS X, R AS Y WHERE X.A1 = Y.A1 AND X.A2 = Y.A2") t0
  ~= (sql%([R_schema]) "SELECT DISTINCT X.A1 AS A1, X.A2 AS A2 FROM R AS X") t0
  := by sql_equiv

end N_20_eq
