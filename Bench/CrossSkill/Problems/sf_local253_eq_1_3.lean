import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local253_eq_1_3

CREATE TABLE SALARYDATASET («index» INT, «CompanyName» STRING, «JobTitle» STRING, «SalariesReported» FLOAT, «Location» STRING, «Salary» STRING)

theorem eq (t0 : TableRel SALARYDATASET_schema) :
    (sql%([SALARYDATASET_schema]) "WITH cleaned AS (SELECT \"Location\", \"CompanyName\", CASE WHEN \"Salary\" LIKE '%/mo' THEN CAST(REGEXP_REPLACE(\"Salary\", '[^0-9]', '', 'g') AS DOUBLE PRECISION) * 12 WHEN \"Salary\" LIKE '%/hr' THEN CAST(REGEXP_REPLACE(\"Salary\", '[^0-9]', '', 'g') AS DOUBLE PRECISION) * 2080 ELSE CAST(REGEXP_REPLACE(\"Salary\", '[^0-9]', '', 'g') AS DOUBLE PRECISION) END AS salary_numeric FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"SALARYDATASET\"), country_avg AS (SELECT AVG(salary_numeric) AS avg_country FROM cleaned), company_location_avg AS (SELECT \"Location\", \"CompanyName\", AVG(salary_numeric) AS avg_salary_state, ROW_NUMBER() OVER (PARTITION BY \"Location\" ORDER BY AVG(salary_numeric) DESC, \"CompanyName\" ASC) AS rn FROM cleaned WHERE \"Location\" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad') GROUP BY \"Location\", \"CompanyName\") SELECT c.\"Location\" AS \"Location\", c.\"CompanyName\" AS \"Company Name\", c.avg_salary_state AS \"Average Salary in State\", ca.avg_country AS \"Average Salary in Country\" FROM company_location_avg AS c CROSS JOIN country_avg AS ca WHERE c.rn <= 5 ORDER BY c.\"Location\" ASC, c.avg_salary_state DESC, c.\"CompanyName\" ASC") t0
  ~= (sql%([SALARYDATASET_schema]) "WITH parsed AS (SELECT \"Location\", \"CompanyName\", CASE WHEN \"Salary\" LIKE '%/yr' THEN CAST(REGEXP_REPLACE(REPLACE(\"Salary\", ',', ''), '[^0-9.]', '', 'g') AS DOUBLE PRECISION) WHEN \"Salary\" LIKE '%/mo' THEN CAST(REGEXP_REPLACE(REPLACE(\"Salary\", ',', ''), '[^0-9.]', '', 'g') AS DOUBLE PRECISION) * 12 WHEN \"Salary\" LIKE '%/hr' THEN CAST(REGEXP_REPLACE(REPLACE(\"Salary\", ',', ''), '[^0-9.]', '', 'g') AS DOUBLE PRECISION) * 2080 ELSE NULL END AS salary_num FROM \"EDUCATION_BUSINESS\".\"EDUCATION_BUSINESS\".\"SALARYDATASET\"), country_avg AS (SELECT AVG(salary_num) AS avg_salary_country FROM parsed), company_avg AS (SELECT \"Location\", \"CompanyName\", AVG(salary_num) AS avg_salary_state FROM parsed WHERE \"Location\" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad') GROUP BY \"Location\", \"CompanyName\"), ranked AS (SELECT \"Location\", \"CompanyName\", avg_salary_state, ROW_NUMBER() OVER (PARTITION BY \"Location\" ORDER BY avg_salary_state DESC) AS rn FROM company_avg) SELECT r.\"Location\" AS \"Location\", r.\"CompanyName\" AS \"Company Name\", r.avg_salary_state AS \"Average Salary in State\", c.avg_salary_country AS \"Average Salary in Country\" FROM ranked AS r CROSS JOIN country_avg AS c WHERE r.rn <= 5 ORDER BY r.\"Location\", r.avg_salary_state DESC") t0
  := by first | sql_equiv | sorry

end N_sf_local253_eq_1_3
