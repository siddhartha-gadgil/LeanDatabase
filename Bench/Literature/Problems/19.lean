import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_19

CREATE TABLE R («A» INT)

theorem eq :
    sql%([R_schema]) "SELECT DISTINCT Y.A AS A FROM R AS X, R AS Y WHERE X.A = Y.A"
  = sql%([R_schema]) "SELECT DISTINCT X.A AS A FROM R AS X"
  := by first | sql_equiv | sorry

end Literature_19
