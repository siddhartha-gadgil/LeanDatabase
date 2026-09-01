import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_32_eq

CREATE TABLE R («X» INT)
CREATE TABLE S («X» INT)

theorem eq (t0 : TableRel R_schema) (t1 : TableRel S_schema) :
    (sql%([R_schema, S_schema]) "SELECT * FROM (SELECT * FROM R UNION ALL SELECT * FROM S) AS X") t0 t1
  ~= (sql%([R_schema, S_schema]) "(SELECT * FROM R AS X) UNION ALL (SELECT * FROM S AS Y)") t0 t1
  := by first | sql_equiv | sorry

end N_32_eq
