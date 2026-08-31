import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local049_eq_1_2

CREATE TABLE COMPANIES_DATES («company_id» INT, «date_joined» STRING, «year_founded» INT)
CREATE TABLE COMPANIES_INDUSTRIES («company_id» INT, «industry» STRING)

theorem eq (t0 : TableRel COMPANIES_DATES_schema) (t1 : TableRel COMPANIES_INDUSTRIES_schema) :
    (sql%([COMPANIES_DATES_schema, COMPANIES_INDUSTRIES_schema]) "WITH top_industry AS (SELECT i.\"industry\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_DATES\" AS d JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_INDUSTRIES\" AS i ON d.\"company_id\" = i.\"company_id\" WHERE EXTRACT(YEAR FROM CAST(d.\"date_joined\" AS TIMESTAMP)) BETWEEN 2019 AND 2021 GROUP BY i.\"industry\" ORDER BY COUNT(DISTINCT d.\"company_id\") DESC LIMIT 1), yearly_counts AS (SELECT EXTRACT(YEAR FROM CAST(d.\"date_joined\" AS TIMESTAMP)) AS yr, COUNT(DISTINCT d.\"company_id\") AS cnt FROM \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_DATES\" AS d JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_INDUSTRIES\" AS i ON d.\"company_id\" = i.\"company_id\" WHERE EXTRACT(YEAR FROM CAST(d.\"date_joined\" AS TIMESTAMP)) BETWEEN 2019 AND 2021 AND i.\"industry\" = (SELECT \"industry\" FROM top_industry) GROUP BY yr) SELECT ROUND(CAST(AVG(cnt) AS DECIMAL), 6) AS AVG_NEW_UNICORNS_PER_YEAR FROM yearly_counts") t0 t1
  = (sql%([COMPANIES_DATES_schema, COMPANIES_INDUSTRIES_schema]) "WITH top_industry AS (SELECT ci.\"industry\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_DATES\" AS cd JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_INDUSTRIES\" AS ci ON cd.\"company_id\" = ci.\"company_id\" WHERE EXTRACT(YEAR FROM CAST(cd.\"date_joined\" AS TIMESTAMP)) BETWEEN 2019 AND 2021 GROUP BY ci.\"industry\" ORDER BY COUNT(DISTINCT cd.\"company_id\") DESC LIMIT 1), yearly_counts AS (SELECT EXTRACT(YEAR FROM CAST(cd.\"date_joined\" AS TIMESTAMP)) AS yr, COUNT(DISTINCT cd.\"company_id\") AS num_new FROM \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_DATES\" AS cd JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_INDUSTRIES\" AS ci ON cd.\"company_id\" = ci.\"company_id\" WHERE EXTRACT(YEAR FROM CAST(cd.\"date_joined\" AS TIMESTAMP)) BETWEEN 2019 AND 2021 AND ci.\"industry\" = (SELECT \"industry\" FROM top_industry) GROUP BY yr) SELECT AVG(num_new) AS \"AVG_NEW_UNICORNS_PER_YEAR\" FROM yearly_counts") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local049_eq_1_2
