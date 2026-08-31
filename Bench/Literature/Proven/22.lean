import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_22_eq

CREATE TABLE R («X» INT)

theorem eq :
    sql%([R_schema]) "SELECT * FROM (SELECT * FROM R AS X WHERE B1(X)) AS Y WHERE B2(Y)"
  = sql%([R_schema]) "SELECT * FROM (SELECT * FROM R AS X WHERE B2(X)) AS Y WHERE B1(Y)"
  := by sql_equiv

end N_22_eq
