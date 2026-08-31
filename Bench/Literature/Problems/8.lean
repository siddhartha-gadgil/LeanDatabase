import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_8

CREATE TABLE R («A» INT, «B» INT, «C» INT)

theorem eq :
    sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A = 5 AND X.C < 1"
  = sql%([R_schema]) "SELECT X.B AS XB FROM R AS X WHERE X.A < 10"
  := by first | sql_equiv | sorry

end Literature_8
