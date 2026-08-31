import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_21

CREATE TABLE R («A» INT, «B» INT)

theorem eq :
    sql%([R_schema]) "SELECT X.A, SUM(X.A + X.B) FROM R AS X GROUP BY X.A"
  = sql%([R_schema]) "SELECT Y.A, SUM(Y.A + Y.B) FROM R AS Y GROUP BY Y.A"
  := by first | sql_equiv | sorry

end Literature_21
