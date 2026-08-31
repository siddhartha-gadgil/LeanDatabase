import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_35

CREATE TABLE R1 («X» INT)
CREATE TABLE R2 («X» INT)

theorem eq :
    sql%([R1_schema, R2_schema]) "SELECT * FROM R1 AS X, (SELECT * FROM R2 AS Y WHERE B(Y)) AS Z"
  = sql%([R1_schema, R2_schema]) "SELECT * FROM R1 AS X, R2 AS Y WHERE B(Y)"
  := by first | sql_equiv | sorry

end Literature_35
