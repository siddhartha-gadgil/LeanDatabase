import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_17

CREATE TABLE R («A1» INT, «A2» INT, «A3» INT)

theorem eq :
    sql%([R_schema]) "SELECT DISTINCT * FROM R AS X WHERE X.A1 = X.A2 AND X.A2 = X.A3"
  = sql%([R_schema]) "SELECT DISTINCT * FROM R AS X WHERE X.A1 = X.A2 AND X.A1 = X.A3"
  := by first | sql_equiv | sorry

end Literature_17
