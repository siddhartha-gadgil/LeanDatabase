import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_23_eq

CREATE TABLE R («X» INT)

theorem eq (t0 : TableRel R_schema) :
    (sql%([R_schema]) "SELECT * FROM R AS X WHERE B1(X) AND B2(X)") t0
  ~= (sql%([R_schema]) "SELECT * FROM (SELECT * FROM R AS X WHERE B1(X)) AS Y WHERE B2(Y)") t0
  := by sql_equiv

end N_23_eq
