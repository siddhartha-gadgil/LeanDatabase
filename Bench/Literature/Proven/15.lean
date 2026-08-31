import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_15_eq

CREATE TABLE A («X» INT, «YA» INT, «YX» STRING)

theorem eq :
    sql%([A_schema]) "SELECT X.X AS AX FROM A AS X WHERE X.YX = 'HELLO'"
  = sql%([A_schema]) "SELECT X.X AS AX FROM A AS X WHERE X.YX = 'HELLO HI'"
  := by sql_equiv

end N_15_eq
