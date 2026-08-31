import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_20_eq

CREATE TABLE EMP («EMPNO» INT, «DEPTNO» INT, «ENAME» STRING, «JOB» STRING, «MGR» INT, «HIREDATE» INT, «SAL» INT, «COMM» INT, «SLACKER» BOOL)
CREATE TABLE DEPT («DEPTNO» INT, «NAME» STRING)
CREATE TABLE BONUS («ENAME» STRING, «JOB» STRING, «SAL» INT, «COMM» INT)
CREATE TABLE EMPNULLABLES («EMPNO» INT, «DEPTNO» INT, «ENAME» STRING, «JOB» STRING, «MGR» INT, «HIREDATE» INT, «SAL» INT, «COMM» INT, «SLACKER» BOOL)
CREATE TABLE EMPNULLABLES_20 («EMPNO» INT, «DEPTNO» INT, «ENAME» STRING, «JOB» STRING, «MGR» INT, «HIREDATE» INT, «SAL» INT, «COMM» INT, «SLACKER» BOOL)
CREATE TABLE EMP_B («EMPNO» INT, «DEPTNO» INT, «ENAME» STRING, «JOB» STRING, «MGR» INT, «HIREDATE» INT, «SAL» INT, «COMM» INT, «SLACKER» BOOL, «BIRTHDATE» INT)

theorem eq (t0 : TableRel EMP_schema) (t1 : TableRel DEPT_schema) (t2 : TableRel BONUS_schema) (t3 : TableRel EMPNULLABLES_schema) (t4 : TableRel EMPNULLABLES_20_schema) (t5 : TableRel EMP_B_schema) :
    (sql%([EMP_schema, DEPT_schema, BONUS_schema, EMPNULLABLES_schema, EMPNULLABLES_20_schema, EMP_B_schema]) "SELECT A + B AS X, B, A FROM (VALUES (10, 1), (30, 7), (20, 3)) AS t(A, B) WHERE A - B < 21") t0 t1 t2 t3 t4 t5
  ~= (sql%([EMP_schema, DEPT_schema, BONUS_schema, EMPNULLABLES_schema, EMPNULLABLES_20_schema, EMP_B_schema]) "SELECT * FROM (VALUES (11, 1, 10), (23, 3, 20)) AS t(X, B, A)") t0 t1 t2 t3 t4 t5
  := by sql_equiv

end N_20_eq
