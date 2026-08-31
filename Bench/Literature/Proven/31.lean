import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_31_eq

CREATE TABLE R1 («A» INT, «B» INT)
CREATE TABLE R2 («A» INT, «B» INT)

theorem eq :
    sql%([R1_schema, R2_schema]) "SELECT X.B AS XB, Y.B AS YB FROM R1 AS X, R2 AS Y"
  = sql%([R1_schema, R2_schema]) "SELECT X1.XB AS XB, Y1.YB AS YB FROM (SELECT X.B AS XB FROM R1 AS X) AS X1, (SELECT Y.B AS YB FROM R2 AS Y) AS Y1"
  := by sql_equiv

end N_31_eq
