import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_29

CREATE TABLE A («A1» INT, «A2» INT)
CREATE TABLE B («B1» INT, «B2» INT)

theorem eq :
    sql%([A_schema, B_schema]) "SELECT X.A1 AS A1, X.A2 AS A2, Y.B1 AS B1, Y.B2 AS B2 FROM A AS X, B AS Y WHERE X.A1 = Y.B1"
  = sql%([A_schema, B_schema]) "SELECT Y.A1 AS A1, Y.A2 AS A2, X.B1 AS B1, X.B2 AS B2 FROM B AS X, A AS Y WHERE Y.A1 = X.B1"
  := by first | sql_equiv | sorry

end Literature_29
