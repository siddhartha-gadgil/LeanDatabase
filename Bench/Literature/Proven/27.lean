import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_27_eq

CREATE TABLE R («X» INT)

theorem eq :
    sql%([R_schema]) "SELECT * FROM (SELECT * FROM R AS X WHERE B(X)) AS Y WHERE B(Y)"
  = sql%([R_schema]) "SELECT * FROM R AS X WHERE B(X)"
  := by sql_equiv

end N_27_eq
