import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_24_eq

CREATE TABLE R («A» INT, «B» INT)

theorem eq (t0 : TableRel R_schema) :
    (sql%([R_schema]) "SELECT COUNT(*) AS A FROM R AS X") t0
  ~= (sql%([R_schema]) "SELECT COUNT(Y.B) FROM R AS Y") t0
  := by first | sql_equiv | sorry

end N_24_eq
