import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_23

CREATE TABLE R («X» INT)

theorem eq :
    sql%([R_schema]) "SELECT * FROM R AS X WHERE B1(X) AND B2(X)"
  = sql%([R_schema]) "SELECT * FROM (SELECT * FROM R AS X WHERE B1(X)) AS Y WHERE B2(Y)"
  := by first | sql_equiv | sorry

end Literature_23
