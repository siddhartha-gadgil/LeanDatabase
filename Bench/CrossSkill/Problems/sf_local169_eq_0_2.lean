import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local169_eq_0_2

CREATE TABLE LEGISLATORS_TERMS («id_bioguide» STRING, «term_number» INT, «term_id» STRING, «term_type» STRING, «term_start» STRING, «term_end» STRING, «state» STRING, «district» FLOAT, «class» FLOAT, «party» STRING, «how» STRING, «url» STRING, «address» STRING, «phone» STRING, «fax» STRING, «contact_form» STRING, «office» STRING, «state_rank» STRING, «rss_url» STRING, «caucus» STRING)

theorem eq (t0 : TableRel LEGISLATORS_TERMS_schema) :
    (sql%([LEGISLATORS_TERMS_schema]) "WITH cohort AS (SELECT \"id_bioguide\", MIN(CAST(\"term_start\" AS DATE)) AS first_start FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"LEGISLATORS_TERMS\" GROUP BY \"id_bioguide\" HAVING first_start >= '1917-01-01' AND first_start <= '1999-12-31'), cohort_size AS (SELECT COUNT(*) AS total FROM cohort), periods AS (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS period FROM TABLE(GENERATOR(20))), retained AS (SELECT p.period, COUNT(DISTINCT c.\"id_bioguide\") AS cnt FROM cohort AS c CROSS JOIN periods AS p INNER JOIN \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"LEGISLATORS_TERMS\" AS t ON t.\"id_bioguide\" = c.\"id_bioguide\" AND DATE_FROM_PARTS(CAST(EXTRACT(YEAR FROM c.first_start) AS INT) + p.period, 12, 31) >= CAST(t.\"term_start\" AS DATE) AND DATE_FROM_PARTS(CAST(EXTRACT(YEAR FROM c.first_start) AS INT) + p.period, 12, 31) <= CAST(t.\"term_end\" AS DATE) GROUP BY p.period) SELECT p.period AS \"PERIOD\", ROUND(CAST(COALESCE(r.cnt, 0) * 1.0 AS DOUBLE PRECISION) / cs.total, 6) AS \"retention rate\" FROM periods AS p CROSS JOIN cohort_size AS cs LEFT JOIN retained AS r ON p.period = r.period ORDER BY p.period") t0
  ~= (sql%([LEGISLATORS_TERMS_schema]) "WITH cohort AS (SELECT \"id_bioguide\", MIN(\"term_start\") AS first_term_start FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"LEGISLATORS_TERMS\" WHERE \"term_number\" = 0 AND \"term_start\" >= '1917-01-01' AND \"term_start\" <= '1999-12-31' GROUP BY \"id_bioguide\"), cohort_count AS (SELECT COUNT(*) AS total FROM cohort), periods AS (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS \"PERIOD\" FROM TABLE(GENERATOR(20))), retention AS (SELECT p.\"PERIOD\", COUNT(DISTINCT CASE WHEN EXISTS(SELECT 1 FROM \"CITY_LEGISLATION\".\"CITY_LEGISLATION\".\"LEGISLATORS_TERMS\" AS t WHERE t.\"id_bioguide\" = c.\"id_bioguide\" AND CAST(t.\"term_start\" AS DATE) <= CAST(TO_TIMESTAMP(CAST(EXTRACT(YEAR FROM CAST(c.first_term_start AS DATE)) + p.\"PERIOD\" AS VARCHAR) || '-12-31', 'YYYY-MM-DD') AS DATE) AND CAST(t.\"term_end\" AS DATE) >= CAST(TO_TIMESTAMP(CAST(EXTRACT(YEAR FROM CAST(c.first_term_start AS DATE)) + p.\"PERIOD\" AS VARCHAR) || '-12-31', 'YYYY-MM-DD') AS DATE)) THEN c.\"id_bioguide\" END) AS retained FROM periods AS p CROSS JOIN cohort AS c GROUP BY p.\"PERIOD\") SELECT r.\"PERIOD\", ROUND(CAST(r.retained * 1.0 AS DOUBLE PRECISION) / cc.total, 6) AS \"retention rate\" FROM retention AS r CROSS JOIN cohort_count AS cc ORDER BY r.\"PERIOD\"") t0
  := by first | sql_equiv | sorry

end N_sf_local169_eq_0_2
