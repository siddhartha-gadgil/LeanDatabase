import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_28_eq

CREATE TABLE A («C» INT)

theorem eq (t0 : TableRel A_schema) :
    (sql%([A_schema]) "SELECT * FROM A AS X WHERE EXISTS(SELECT * FROM A AS Y WHERE X.C = Y.C)") t0
  ~= (sql%([A_schema]) "SELECT * FROM A AS X") t0
  := by first | sql_equiv | sorry

end N_28_eq
