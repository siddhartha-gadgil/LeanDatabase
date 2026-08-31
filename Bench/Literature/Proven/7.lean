import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_7_eq

CREATE TABLE EMP («NAME» INT, «DEPT» INT, «EMP» INT)
CREATE TABLE DEPT («DEPT» INT, «LOC» INT, «MGR» INT)

theorem eq :
    sql%([EMP_schema, DEPT_schema]) "SELECT X.NAME AS XN FROM EMP AS X WHERE EXISTS(SELECT * FROM DEPT AS Y WHERE Y.LOC = 3 AND X.EMP = Y.MGR AND X.DEPT = Y.DEPT)"
  = sql%([EMP_schema, DEPT_schema]) "SELECT X.NAME AS XN FROM EMP AS X, DEPT AS Y WHERE X.DEPT = Y.DEPT AND Y.LOC = 3 AND X.EMP = Y.MGR"
  := by sql_equiv

end N_7_eq
