import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_37

CREATE TABLE A («X» INT)

theorem eq :
    sql%([A_schema]) "SELECT * FROM A AS X UNION ALL SELECT * FROM A AS X WHERE FALSE"
  = sql%([A_schema]) "SELECT * FROM A AS X"
  := by sql_equiv

end Literature_37
