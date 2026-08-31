import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_18_eq

CREATE TABLE R («X» INT)

theorem eq :
    sql%([R_schema]) "SELECT DISTINCT X.* FROM R AS X, R AS Y"
  = sql%([R_schema]) "SELECT DISTINCT X.* FROM R AS X"
  := by sql_equiv

end N_18_eq
