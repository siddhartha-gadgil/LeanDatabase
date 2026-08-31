import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local163_eq_2_3

CREATE TABLE UNIVERSITY_FACULTY («FacNo» INT, «FacFirstName» STRING, «FacLastName» STRING, «FacCity» STRING, «FacState» STRING, «FacDept» STRING, «FacRank» STRING, «FacSalary» INT, «FacSupervisor» FLOAT, «FacHireDate» STRING, «FacZipCode» STRING)

theorem eq (t0 : TableRel UNIVERSITY_FACULTY_schema) :
    (sql%([UNIVERSITY_FACULTY_schema]) "WITH avg_salary AS (SELECT \"FacRank\", AVG(\"FacSalary\") AS avg_sal FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"UNIVERSITY_FACULTY\" GROUP BY \"FacRank\"), salary_diff AS (SELECT f.\"FacRank\", f.\"FacFirstName\", f.\"FacLastName\", f.\"FacSalary\" AS SALARY, ABS(f.\"FacSalary\" - a.avg_sal) AS diff FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"UNIVERSITY_FACULTY\" AS f JOIN avg_salary AS a ON f.\"FacRank\" = a.\"FacRank\"), min_diff AS (SELECT \"FacRank\", MIN(diff) AS min_diff FROM salary_diff GROUP BY \"FacRank\") SELECT sd.\"FacRank\", sd.\"FacFirstName\", sd.\"FacLastName\", sd.SALARY FROM salary_diff AS sd JOIN min_diff AS md ON sd.\"FacRank\" = md.\"FacRank\" AND sd.diff = md.min_diff ORDER BY sd.\"FacRank\", sd.SALARY DESC") t0
  = (sql%([UNIVERSITY_FACULTY_schema]) "WITH avg_salary AS (SELECT \"FacRank\", AVG(\"FacSalary\") AS avg_sal FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"UNIVERSITY_FACULTY\" GROUP BY \"FacRank\"), with_diff AS (SELECT f.\"FacRank\", f.\"FacFirstName\", f.\"FacLastName\", f.\"FacSalary\", ABS(f.\"FacSalary\" - a.avg_sal) AS salary_diff FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"UNIVERSITY_FACULTY\" AS f JOIN avg_salary AS a ON f.\"FacRank\" = a.\"FacRank\"), min_diff AS (SELECT \"FacRank\", MIN(salary_diff) AS min_salary_diff FROM with_diff GROUP BY \"FacRank\") SELECT w.\"FacRank\", w.\"FacFirstName\", w.\"FacLastName\", w.\"FacSalary\" FROM with_diff AS w JOIN min_diff AS m ON w.\"FacRank\" = m.\"FacRank\" AND w.salary_diff = m.min_salary_diff ORDER BY w.\"FacRank\", w.\"FacLastName\"") t0
  := by first | sql_equiv | sorry

end N_sf_local163_eq_2_3
