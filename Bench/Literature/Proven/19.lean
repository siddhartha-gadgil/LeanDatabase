import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_19_eq

CREATE TABLE R («A» INT)

theorem eq (t0 : TableRel R_schema) :
    (sql%([R_schema]) "SELECT DISTINCT Y.A AS A FROM R AS X, R AS Y WHERE X.A = Y.A") t0
  ~= (sql%([R_schema]) "SELECT DISTINCT X.A AS A FROM R AS X") t0
  := by sql_equiv

end N_19_eq
