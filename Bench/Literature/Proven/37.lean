import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_37_eq

CREATE TABLE A («X» INT)

theorem eq (t0 : TableRel A_schema) :
    (sql%([A_schema]) "SELECT * FROM A AS X UNION ALL SELECT * FROM A AS X WHERE FALSE") t0
  ~= (sql%([A_schema]) "SELECT * FROM A AS X") t0
  := by sql_equiv

end N_37_eq
