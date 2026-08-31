import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_36

CREATE TABLE R («A» INT, «B» INT)

theorem eq :
    sql%([R_schema]) "SELECT X.A + X.B, CAST(X.A AS DOUBLE PRECISION) / NULLIF(X.B, 0) AS A FROM R AS X"
  = sql%([R_schema]) "SELECT Y.A + Y.B, CAST(Y.A AS DOUBLE PRECISION) / NULLIF(Y.B, 0) AS A FROM R AS Y"
  := by first | sql_equiv | sorry

end Literature_36
