import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_26_eq

CREATE TABLE DEPT («DEPTNO» INT, «NAME» INT)

theorem eq (t0 : TableRel DEPT_schema) :
    (sql%([DEPT_schema]) "SELECT DEPT.NAME AS DNAME, COUNT(*) AS C FROM DEPT AS DEPT GROUP BY DEPT.NAME HAVING DEPT.NAME = 10") t0
  ~= (sql%([DEPT_schema]) "SELECT T2.DNAME, T2.CNT AS C FROM (SELECT DEPT0.NAME AS DNAME, COUNT(*) AS CNT FROM DEPT AS DEPT0 GROUP BY DEPT0.NAME) AS T2 WHERE T2.DNAME = 10") t0
  := by first | sql_equiv | sorry

end N_26_eq
