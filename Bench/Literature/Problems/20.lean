import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_20

CREATE TABLE R («A1» INT, «A2» INT)

theorem eq :
    sql%([R_schema]) "SELECT DISTINCT Y.A1 AS A1, Y.A2 AS A2 FROM R AS X, R AS Y WHERE X.A1 = Y.A1 AND X.A2 = Y.A2"
  = sql%([R_schema]) "SELECT DISTINCT X.A1 AS A1, X.A2 AS A2 FROM R AS X"
  := by first | sql_equiv | sorry

end Literature_20
