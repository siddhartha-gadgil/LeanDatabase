import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq212_eq_1_2

CREATE TABLE PUBLICATIONS («publication_number» STRING, «application_number» STRING, «country_code» STRING, «kind_code» STRING, «application_kind» STRING, «application_number_formatted» STRING, «pct_number» STRING, «family_id» STRING, «spif_publication_number» STRING, «spif_application_number» STRING, «title_localized» STRING, «abstract_localized» STRING, «claims_localized» STRING, «claims_localized_html» STRING, «description_localized» STRING, «description_localized_html» STRING, «publication_date» INT, «filing_date» INT, «grant_date» INT, «priority_date» INT, «priority_claim» STRING, «inventor» STRING, «inventor_harmonized» STRING, «assignee» STRING, «assignee_harmonized» STRING, «examiner» STRING, «uspc» STRING, «ipc» STRING, «cpc» STRING, «fi» STRING, «fterm» STRING, «locarno» STRING, «citation» STRING, «parent» STRING, «child» STRING, «entity_status» STRING, «art_unit» STRING)

theorem eq (t0 : TableRel PUBLICATIONS_schema) :
    (sql%([PUBLICATIONS_schema]) "WITH patent_ipc AS (SELECT p.\"publication_number\", LEFT(CAST(JSON_EXTRACT_PATH(f.value, 'code') AS TEXT), 4) AS IPC4, COUNT(*) AS ipc4_count FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p, LATERAL UNNEST(input => p.\"ipc\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE p.\"country_code\" = 'US' AND p.\"kind_code\" = 'B2' AND p.\"grant_date\" >= 20220601 AND p.\"grant_date\" <= 20220930 GROUP BY p.\"publication_number\", IPC4), ranked AS (SELECT \"publication_number\", IPC4, ipc4_count, ROW_NUMBER() OVER (PARTITION BY \"publication_number\" ORDER BY ipc4_count DESC) AS rn FROM patent_ipc) SELECT \"publication_number\", IPC4 FROM ranked WHERE rn = 1 AND ipc4_count >= 10 ORDER BY \"publication_number\"") t0
  ~= (sql%([PUBLICATIONS_schema]) "WITH ipc_counts AS (SELECT p.\"publication_number\", SUBSTRING(CAST(JSON_EXTRACT_PATH(f.value, 'code') AS TEXT) FROM 1 FOR 4) AS IPC4, COUNT(*) AS ipc4_count FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p, LATERAL UNNEST(input => p.\"ipc\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE p.\"country_code\" = 'US' AND p.\"kind_code\" = 'B2' AND p.\"grant_date\" >= 20220601 AND p.\"grant_date\" <= 20220930 GROUP BY p.\"publication_number\", IPC4), most_frequent AS (SELECT \"publication_number\", IPC4, ipc4_count, ROW_NUMBER() OVER (PARTITION BY \"publication_number\" ORDER BY ipc4_count DESC, IPC4) AS rn FROM ipc_counts) SELECT \"publication_number\", IPC4 AS \"IPC4\" FROM most_frequent WHERE rn = 1 AND ipc4_count >= 10 ORDER BY \"publication_number\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq212_eq_1_2
