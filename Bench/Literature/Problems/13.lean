import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_13_eq

CREATE TABLE EMP («NAME» INT, «DEPT» INT, «EMP» INT)
CREATE TABLE DEPT («DEPT» INT, «LOC» INT, «MGR» INT)

theorem eq (t0 : TableRel EMP_schema) (t1 : TableRel DEPT_schema) :
    (sql%([EMP_schema, DEPT_schema]) "SELECT X.NAME AS XN FROM EMP AS X WHERE EXISTS(SELECT * FROM DEPT AS Y WHERE Y.LOC = 3 AND X.EMP = Y.MGR AND X.DEPT = Y.DEPT)") t0 t1
  ~= (sql%([EMP_schema, DEPT_schema]) "SELECT X.NAME AS XN FROM EMP AS X") t0 t1
  := by first | sql_equiv | sorry

end N_13_eq
