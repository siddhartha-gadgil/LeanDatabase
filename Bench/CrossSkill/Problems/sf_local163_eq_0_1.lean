import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local163_eq_0_1

CREATE TABLE UNIVERSITY_FACULTY («FacNo» INT, «FacFirstName» STRING, «FacLastName» STRING, «FacCity» STRING, «FacState» STRING, «FacDept» STRING, «FacRank» STRING, «FacSalary» INT, «FacSupervisor» FLOAT, «FacHireDate» STRING, «FacZipCode» STRING)

theorem eq (t0 : TableRel UNIVERSITY_FACULTY_schema) :
    (sql%([UNIVERSITY_FACULTY_schema]) "WITH rank_avg AS (SELECT \"FacRank\", AVG(\"FacSalary\") AS avg_salary FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"UNIVERSITY_FACULTY\" GROUP BY \"FacRank\"), ranked AS (SELECT f.\"FacRank\", f.\"FacFirstName\", f.\"FacLastName\", f.\"FacSalary\" AS SALARY, RANK() OVER (PARTITION BY f.\"FacRank\" ORDER BY ABS(f.\"FacSalary\" - ra.avg_salary)) AS rk FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"UNIVERSITY_FACULTY\" AS f JOIN rank_avg AS ra ON f.\"FacRank\" = ra.\"FacRank\") SELECT \"FacRank\", \"FacFirstName\", \"FacLastName\", SALARY FROM ranked WHERE rk = 1 ORDER BY \"FacRank\", SALARY DESC") t0
  = (sql%([UNIVERSITY_FACULTY_schema]) "WITH rank_avg AS (SELECT \"FacRank\", AVG(\"FacSalary\") AS avg_salary FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"UNIVERSITY_FACULTY\" GROUP BY \"FacRank\"), ranked AS (SELECT f.\"FacRank\", f.\"FacFirstName\", f.\"FacLastName\", f.\"FacSalary\" AS SALARY, RANK() OVER (PARTITION BY f.\"FacRank\" ORDER BY ABS(f.\"FacSalary\" - ra.avg_salary)) AS rnk FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"UNIVERSITY_FACULTY\" AS f JOIN rank_avg AS ra ON f.\"FacRank\" = ra.\"FacRank\") SELECT \"FacRank\", \"FacFirstName\", \"FacLastName\", SALARY FROM ranked WHERE rnk = 1 ORDER BY \"FacRank\", SALARY DESC") t0
  := by first | sql_equiv | sorry

end N_sf_local163_eq_0_1
