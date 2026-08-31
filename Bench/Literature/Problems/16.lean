import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_16

CREATE TABLE R1 («X» INT, «Y» INT)
CREATE TABLE R2 («Y» INT)

theorem eq :
    sql%([R1_schema, R2_schema]) "SELECT DISTINCT X.X AS X FROM R1 AS X, R2 AS Y WHERE X.Y = Y.Y AND X.X = 1"
  = sql%([R1_schema, R2_schema]) "SELECT DISTINCT X.X AS X FROM R1 AS X, R1 AS Y, R2 AS Z WHERE X.X = Y.X AND X.Y = Z.Y AND X.X = 1"
  := by first | sql_equiv | sorry

end Literature_16
