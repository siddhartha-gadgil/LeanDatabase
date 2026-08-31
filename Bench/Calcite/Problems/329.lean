import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_329_eq

CREATE TABLE EMP («EMPNO» INT, «DEPTNO» INT, «ENAME» STRING, «JOB» STRING, «MGR» INT, «HIREDATE» INT, «SAL» INT, «COMM» INT, «SLACKER» BOOL)
CREATE TABLE DEPT («DEPTNO» INT, «NAME» STRING)
CREATE TABLE BONUS («ENAME» STRING, «JOB» STRING, «SAL» INT, «COMM» INT)
CREATE TABLE EMPNULLABLES («EMPNO» INT, «DEPTNO» INT, «ENAME» STRING, «JOB» STRING, «MGR» INT, «HIREDATE» INT, «SAL» INT, «COMM» INT, «SLACKER» BOOL)
CREATE TABLE EMPNULLABLES_20 («EMPNO» INT, «DEPTNO» INT, «ENAME» STRING, «JOB» STRING, «MGR» INT, «HIREDATE» INT, «SAL» INT, «COMM» INT, «SLACKER» BOOL)
CREATE TABLE EMP_B («EMPNO» INT, «DEPTNO» INT, «ENAME» STRING, «JOB» STRING, «MGR» INT, «HIREDATE» INT, «SAL» INT, «COMM» INT, «SLACKER» BOOL, «BIRTHDATE» INT)

theorem eq (t0 : TableRel EMP_schema) (t1 : TableRel DEPT_schema) (t2 : TableRel BONUS_schema) (t3 : TableRel EMPNULLABLES_schema) (t4 : TableRel EMPNULLABLES_20_schema) (t5 : TableRel EMP_B_schema) :
    (sql%([EMP_schema, DEPT_schema, BONUS_schema, EMPNULLABLES_schema, EMPNULLABLES_20_schema, EMP_B_schema]) "SELECT AVG(EMP.SAL) FROM EMP, (VALUES (FALSE, TRUE, 'ab', CAST('2022-01-01' AS DATE))) AS t($f0, $f2, $f4, $f5) GROUP BY t.$f0, EMP.DEPTNO, t.$f2, EMP.EMPNO, t.$f4, t.$f5") t0 t1 t2 t3 t4 t5
  ~= (sql%([EMP_schema, DEPT_schema, BONUS_schema, EMPNULLABLES_schema, EMPNULLABLES_20_schema, EMP_B_schema]) "SELECT AVG(EMP0.SAL) FROM EMP AS EMP0, (VALUES (FALSE, TRUE, 'ab', CAST('2022-01-01' AS DATE))) AS t3($f0, $f2, $f4, $f5) GROUP BY t3.$f0, EMP0.DEPTNO, t3.$f2, EMP0.EMPNO, t3.$f4, t3.$f5") t0 t1 t2 t3 t4 t5
  := by first | sql_equiv | sorry

end N_329_eq
