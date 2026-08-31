import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_27_eq

CREATE TABLE R («X» INT)

theorem eq (t0 : TableRel R_schema) :
    (sql%([R_schema]) "SELECT * FROM (SELECT * FROM R AS X WHERE B(X)) AS Y WHERE B(Y)") t0
  ~= (sql%([R_schema]) "SELECT * FROM R AS X WHERE B(X)") t0
  := by first | sql_equiv | sorry

end N_27_eq
