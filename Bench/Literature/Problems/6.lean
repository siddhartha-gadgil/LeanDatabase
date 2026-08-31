import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_6

CREATE TABLE PAYROLL («SSNO» INT, «DEPTNO» INT)
CREATE TABLE APPLICANT («SSNO» INT, «JOBTITILE» INT, «OFFICENO» INT)

theorem eq :
    sql%([PAYROLL_schema, APPLICANT_schema]) "SELECT Y.* FROM PAYROLL AS X, APPLICANT AS Y WHERE X.SSNO = Y.SSNO AND X.DEPTNO = 29"
  = sql%([PAYROLL_schema, APPLICANT_schema]) "SELECT C.* FROM PAYROLL AS A, (SELECT Y.SSNO, Y.DEPTNO FROM PAYROLL AS Y) AS B, APPLICANT AS C WHERE A.SSNO = B.SSNO AND C.SSNO = A.SSNO AND B.DEPTNO = 29"
  := by first | sql_equiv | sorry

end Literature_6
