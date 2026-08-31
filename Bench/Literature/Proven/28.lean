import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_28_eq

CREATE TABLE A («C» INT)

theorem eq :
    sql%([A_schema]) "SELECT * FROM A AS X WHERE EXISTS(SELECT * FROM A AS Y WHERE X.C = Y.C)"
  = sql%([A_schema]) "SELECT * FROM A AS X"
  := by sql_equiv

end N_28_eq
