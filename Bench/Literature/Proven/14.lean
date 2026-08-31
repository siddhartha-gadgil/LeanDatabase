import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_14_eq

CREATE TABLE A («X» INT, «YA» INT)
CREATE TABLE B («YB» INT)

theorem eq :
    sql%([A_schema, B_schema]) "SELECT DISTINCT X.X AS AX FROM A AS X, B AS Y WHERE X.YA = Y.YB"
  = sql%([A_schema, B_schema]) "(SELECT X.X AS AX FROM A AS X, A AS Y, B AS Z WHERE X.X = Y.X AND X.YA = Z.YB) UNION ALL (SELECT 1 AS AX FROM A AS X WHERE 1 = 0)"
  := by sql_equiv

end N_14_eq
