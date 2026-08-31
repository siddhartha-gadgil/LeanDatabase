import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_1_eq

CREATE TABLE R1 («A» INT, «B» INT)
CREATE TABLE R2 («A» INT, «B» INT)

theorem eq :
    sql%([R1_schema, R2_schema]) "SELECT Z.A, Z.B FROM R1 AS X, R2 AS Y, R2 AS Z WHERE X.A = Y.A AND Y.A = Z.A AND X.A = Z.A AND Y.B = Z.B"
  = sql%([R1_schema, R2_schema]) "SELECT Z.A, Z.B FROM R1 AS X, R2 AS Y, R2 AS Z WHERE X.A = Y.A AND Y.A = Z.A AND X.A = Z.A"
  := by sql_equiv

end N_1_eq
