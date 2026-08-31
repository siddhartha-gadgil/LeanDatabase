import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local049_eq_0_1

CREATE TABLE COMPANIES_DATES («company_id» INT, «date_joined» STRING, «year_founded» INT)
CREATE TABLE COMPANIES_INDUSTRIES («company_id» INT, «industry» STRING)

theorem eq (t0 : TableRel COMPANIES_DATES_schema) (t1 : TableRel COMPANIES_INDUSTRIES_schema) :
    (sql%([COMPANIES_DATES_schema, COMPANIES_INDUSTRIES_schema]) "/* Calculate average number of new unicorn companies per year in the top industry from 2019 to 2021 */ WITH top_industry AS (/* Find the top industry by count of distinct companies in 2019-2021 */ SELECT i.\"industry\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_DATES\" AS d JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_INDUSTRIES\" AS i ON d.\"company_id\" = i.\"company_id\" WHERE EXTRACT(YEAR FROM TRY_TO_TIMESTAMP(d.\"date_joined\")) BETWEEN 2019 AND 2021 GROUP BY i.\"industry\" ORDER BY COUNT(DISTINCT d.\"company_id\") DESC LIMIT 1), yearly_counts AS (/* Count distinct new unicorn companies per year in the top industry */ SELECT EXTRACT(YEAR FROM TRY_TO_TIMESTAMP(d.\"date_joined\")) AS join_year, COUNT(DISTINCT d.\"company_id\") AS new_unicorns FROM \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_DATES\" AS d JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_INDUSTRIES\" AS i ON d.\"company_id\" = i.\"company_id\" WHERE EXTRACT(YEAR FROM TRY_TO_TIMESTAMP(d.\"date_joined\")) BETWEEN 2019 AND 2021 AND i.\"industry\" = (SELECT \"industry\" FROM top_industry) GROUP BY join_year) SELECT AVG(new_unicorns) AS AVG_NEW_UNICORNS_PER_YEAR FROM yearly_counts") t0 t1
  = (sql%([COMPANIES_DATES_schema, COMPANIES_INDUSTRIES_schema]) "WITH top_industry AS (SELECT i.\"industry\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_DATES\" AS d JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_INDUSTRIES\" AS i ON d.\"company_id\" = i.\"company_id\" WHERE EXTRACT(YEAR FROM CAST(d.\"date_joined\" AS TIMESTAMP)) BETWEEN 2019 AND 2021 GROUP BY i.\"industry\" ORDER BY COUNT(DISTINCT d.\"company_id\") DESC LIMIT 1), yearly_counts AS (SELECT EXTRACT(YEAR FROM CAST(d.\"date_joined\" AS TIMESTAMP)) AS yr, COUNT(DISTINCT d.\"company_id\") AS cnt FROM \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_DATES\" AS d JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"COMPANIES_INDUSTRIES\" AS i ON d.\"company_id\" = i.\"company_id\" WHERE EXTRACT(YEAR FROM CAST(d.\"date_joined\" AS TIMESTAMP)) BETWEEN 2019 AND 2021 AND i.\"industry\" = (SELECT \"industry\" FROM top_industry) GROUP BY yr) SELECT ROUND(CAST(AVG(cnt) AS DECIMAL), 6) AS AVG_NEW_UNICORNS_PER_YEAR FROM yearly_counts") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local049_eq_0_1
