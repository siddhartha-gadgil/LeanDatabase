import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 4000000
set_option maxRecDepth 1000000

namespace Gen_sf_bq027

CREATE TABLE PUBLICATIONS («publication_number» STRING, «application_number» STRING, «country_code» STRING, «kind_code» STRING, «application_kind» STRING, «application_number_formatted» STRING, «pct_number» STRING, «family_id» STRING, «spif_publication_number» STRING, «spif_application_number» STRING, «title_localized» STRING, «abstract_localized» STRING, «claims_localized» STRING, «claims_localized_html» STRING, «description_localized» STRING, «description_localized_html» STRING, «publication_date» INT, «filing_date» INT, «grant_date» INT, «priority_date» INT, «priority_claim» STRING, «inventor» STRING, «inventor_harmonized» STRING, «assignee» STRING, «assignee_harmonized» STRING, «examiner» STRING, «uspc» STRING, «ipc» STRING, «cpc» STRING, «fi» STRING, «fterm» STRING, «locarno» STRING, «citation» STRING, «parent» STRING, «child» STRING, «entity_status» STRING, «art_unit» STRING)

theorem eq_0_2 :
    sql%([PUBLICATIONS_schema]) "SELECT p.\"publication_number\" AS \"publication_number\", COUNT(CASE WHEN CAST(JSON_EXTRACT_PATH(f.value, 'category') AS TEXT) = 'SEA' THEN 1 END) AS \"SEA_BACKWARD_CITATIONS\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p LEFT JOIN LATERAL UNNEST(input => p.\"citation\", OUTER => TRUE) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE p.\"grant_date\" >= 20100101 AND p.\"grant_date\" <= 20181231 GROUP BY p.\"publication_number\" ORDER BY \"SEA_BACKWARD_CITATIONS\" DESC" = sql%([PUBLICATIONS_schema]) "SELECT p.\"publication_number\" AS \"publication_number\", COUNT(CASE WHEN CAST(JSON_EXTRACT_PATH(f.value, 'category') AS TEXT) = 'SEA' THEN 1 END) AS \"SEA_BACKWARD_CITATIONS\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p LEFT JOIN LATERAL UNNEST(input => p.\"citation\", OUTER => TRUE) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE p.\"grant_date\" >= 20100101 AND p.\"grant_date\" <= 20181231 GROUP BY p.\"publication_number\" ORDER BY \"SEA_BACKWARD_CITATIONS\" DESC, p.\"publication_number\" DESC" := by sql_equiv

end Gen_sf_bq027
