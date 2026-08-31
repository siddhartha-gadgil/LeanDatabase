import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_15

CREATE TABLE A («X» INT, «YA» INT, «YX» STRING)

theorem eq :
    sql%([A_schema]) "SELECT X.X AS AX FROM A AS X WHERE X.YX = 'HELLO'"
  = sql%([A_schema]) "SELECT X.X AS AX FROM A AS X WHERE X.YX = 'HELLO HI'"
  := by first | sql_equiv | sorry

end Literature_15
