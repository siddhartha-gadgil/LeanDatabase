import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_33

CREATE TABLE A («X» INT)
CREATE TABLE B («X» INT)

theorem eq :
    sql%([A_schema, B_schema]) "SELECT * FROM A AS X, (SELECT * FROM B AS Y WHERE B0(Y)) AS Z WHERE B1(X, Z)"
  = sql%([A_schema, B_schema]) "SELECT * FROM A AS X, B AS Y WHERE B1(X, Y) AND B0(Y)"
  := by first | sql_equiv | sorry

end Literature_33
