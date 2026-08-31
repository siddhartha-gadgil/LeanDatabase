import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq207_eq_0_1

CREATE TABLE PUBLICATIONS («publication_number» STRING, «application_number» STRING, «country_code» STRING, «kind_code» STRING, «application_kind» STRING, «application_number_formatted» STRING, «pct_number» STRING, «family_id» STRING, «spif_publication_number» STRING, «spif_application_number» STRING, «title_localized» STRING, «abstract_localized» STRING, «claims_localized» STRING, «claims_localized_html» STRING, «description_localized» STRING, «description_localized_html» STRING, «publication_date» INT, «filing_date» INT, «grant_date» INT, «priority_date» INT, «priority_claim» STRING, «inventor» STRING, «inventor_harmonized» STRING, «assignee» STRING, «assignee_harmonized» STRING, «examiner» STRING, «uspc» STRING, «ipc» STRING, «cpc» STRING, «fi» STRING, «fterm» STRING, «locarno» STRING, «citation» STRING, «parent» STRING, «child» STRING, «entity_status» STRING, «art_unit» STRING)
CREATE TABLE MATCH («pgpub_doc_num» STRING, «grant_doc_num» STRING, «publication_number» STRING)
CREATE TABLE PATENT_CLAIMS_STATS («pat_no» STRING, «claim_no» STRING, «word_ct» STRING, «char_ct» STRING, «or_ct» STRING, «sf_ct» STRING, «cns_ct» STRING, «ind_flg» STRING, «appl_id» STRING)

theorem eq (t0 : TableRel PUBLICATIONS_schema) (t1 : TableRel MATCH_schema) (t2 : TableRel PATENT_CLAIMS_STATS_schema) :
    (sql%([PUBLICATIONS_schema, MATCH_schema, PATENT_CLAIMS_STATS_schema]) "WITH earliest_pub AS (SELECT \"application_number\", \"publication_number\", \"publication_date\", ROW_NUMBER() OVER (PARTITION BY \"application_number\" ORDER BY \"publication_date\" ASC) AS rn FROM \"PATENTS_USPTO\".\"PATENTS\".\"PUBLICATIONS\") SELECT ep.\"application_number\" AS \"APPLN_NR\", ep.\"publication_number\" AS \"PUBLN_NR\", cs.\"claim_no\", cs.\"word_ct\" FROM \"PATENTS_USPTO\".\"USPTO_OCE_CLAIMS\".\"PATENT_CLAIMS_STATS\" AS cs JOIN \"PATENTS_USPTO\".\"USPTO_OCE_CLAIMS\".\"MATCH\" AS m ON cs.\"pat_no\" = m.\"pat_no\" JOIN earliest_pub AS ep ON m.\"publication_number\" = ep.\"publication_number\" WHERE cs.\"ind_flg\" = 1 AND ep.rn = 1 ORDER BY CAST(cs.\"word_ct\" AS INT) DESC LIMIT 100") t0 t1 t2
  ~= (sql%([PUBLICATIONS_schema, MATCH_schema, PATENT_CLAIMS_STATS_schema]) "WITH earliest_pub AS (SELECT p.\"application_number\", p.\"publication_number\", ROW_NUMBER() OVER (PARTITION BY p.\"application_number\" ORDER BY p.\"publication_date\" ASC) AS rn FROM \"PATENTS_USPTO\".\"PATENTS\".\"PUBLICATIONS\" AS p), earliest AS (SELECT \"application_number\", \"publication_number\" FROM earliest_pub WHERE rn = 1) SELECT e.\"application_number\" AS \"APPLN_NR\", e.\"publication_number\" AS \"PUBLN_NR\", cs.\"claim_no\", CAST(cs.\"word_ct\" AS INT) AS \"word_ct\" FROM \"PATENTS_USPTO\".\"USPTO_OCE_CLAIMS\".\"PATENT_CLAIMS_STATS\" AS cs JOIN \"PATENTS_USPTO\".\"USPTO_OCE_CLAIMS\".\"MATCH\" AS m ON cs.\"pat_no\" = m.\"pat_no\" JOIN earliest AS e ON m.\"publication_number\" = e.\"publication_number\" WHERE cs.\"ind_flg\" = '1' ORDER BY CAST(cs.\"word_ct\" AS INT) DESC LIMIT 100") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_bq207_eq_0_1
