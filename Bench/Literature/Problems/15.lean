import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_15_eq

CREATE TABLE A («X» INT, «YA» INT, «YX» STRING)

theorem eq (t0 : TableRel A_schema) :
    (sql%([A_schema]) "SELECT X.X AS AX FROM A AS X WHERE X.YX = 'HELLO'") t0
  ~= (sql%([A_schema]) "SELECT X.X AS AX FROM A AS X WHERE X.YX = 'HELLO HI'") t0
  := by first | sql_equiv | sorry

end N_15_eq
