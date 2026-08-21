import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq207 — crossskill equivalence(s)

Question: Could you provide the earliest publication numbers, corresponding application numbers, claim numbers, and word counts for the top 100 independent patent claims, based on the highest word count, retrieved from claims stats within uspto_oce_claims (filtered by ind_flg='1'), matched with their publication numbers from uspto_oce_claims match, and further joined with patents publications to ensure only the earliest publication for each application is included, ordered by descending word count, and limited to the top 100 results?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq207

CREATE TABLE PUBLICATIONS («publication_number» STRING, «application_number» STRING, «country_code» STRING, «kind_code» STRING, «application_kind» STRING, «application_number_formatted» STRING, «pct_number» STRING, «family_id» STRING, «spif_publication_number» STRING, «spif_application_number» STRING, «title_localized» STRING, «abstract_localized» STRING, «claims_localized» STRING, «claims_localized_html» STRING, «description_localized» STRING, «description_localized_html» STRING, «publication_date» INT, «filing_date» INT, «grant_date» INT, «priority_date» INT, «priority_claim» STRING, «inventor» STRING, «inventor_harmonized» STRING, «assignee» STRING, «assignee_harmonized» STRING, «examiner» STRING, «uspc» STRING, «ipc» STRING, «cpc» STRING, «fi» STRING, «fterm» STRING, «locarno» STRING, «citation» STRING, «parent» STRING, «child» STRING, «entity_status» STRING, «art_unit» STRING)
CREATE TABLE MATCH («pgpub_doc_num» STRING, «grant_doc_num» STRING, «publication_number» STRING)
CREATE TABLE PATENT_CLAIMS_STATS («pat_no» STRING, «claim_no» STRING, «word_ct» STRING, «char_ct» STRING, «or_ct» STRING, «sf_ct» STRING, «cns_ct» STRING, «ind_flg» STRING, «appl_id» STRING)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 : ∀ t,
    (sql%([PUBLICATIONS_schema, MATCH_schema, PATENT_CLAIMS_STATS_schema]) "WITH earliest_pub AS (\n  SELECT \n    \"application_number\",\n    \"publication_number\",\n    \"publication_date\",\n    ROW_NUMBER() OVER (PARTITION BY \"application_number\" ORDER BY \"publication_date\" ASC) AS rn\n  FROM \"PATENTS_USPTO\".\"PATENTS\".\"PUBLICATIONS\"\n)\nSELECT \n  ep.\"application_number\" AS \"APPLN_NR\",\n  ep.\"publication_number\" AS \"PUBLN_NR\",\n  cs.\"claim_no\",\n  cs.\"word_ct\"\nFROM \"PATENTS_USPTO\".\"USPTO_OCE_CLAIMS\".\"PATENT_CLAIMS_STATS\" cs\nJOIN \"PATENTS_USPTO\".\"USPTO_OCE_CLAIMS\".\"MATCH\" m \n  ON cs.\"pat_no\" = m.\"pat_no\"\nJOIN earliest_pub ep \n  ON m.\"publication_number\" = ep.\"publication_number\"\nWHERE cs.\"ind_flg\" = 1\n  AND ep.rn = 1\nORDER BY CAST(cs.\"word_ct\" AS INTEGER) DESC\nLIMIT 100;") t ~= (sql%([PUBLICATIONS_schema, MATCH_schema, PATENT_CLAIMS_STATS_schema]) "WITH earliest_pub AS (\n    SELECT \n        p.\"application_number\",\n        p.\"publication_number\",\n        ROW_NUMBER() OVER (\n            PARTITION BY p.\"application_number\" \n            ORDER BY p.\"publication_date\" ASC\n        ) AS rn\n    FROM \"PATENTS_USPTO\".\"PATENTS\".\"PUBLICATIONS\" p\n),\nearliest AS (\n    SELECT \"application_number\", \"publication_number\"\n    FROM earliest_pub\n    WHERE rn = 1\n)\nSELECT \n    e.\"application_number\" AS \"APPLN_NR\",\n    e.\"publication_number\" AS \"PUBLN_NR\",\n    cs.\"claim_no\",\n    cs.\"word_ct\"::INT AS \"word_ct\"\nFROM \"PATENTS_USPTO\".\"USPTO_OCE_CLAIMS\".\"PATENT_CLAIMS_STATS\" cs\nJOIN \"PATENTS_USPTO\".\"USPTO_OCE_CLAIMS\".\"MATCH\" m \n    ON cs.\"pat_no\" = m.\"pat_no\"\nJOIN earliest e\n    ON m.\"publication_number\" = e.\"publication_number\"\nWHERE cs.\"ind_flg\" = '1'\nORDER BY cs.\"word_ct\"::INT DESC\nLIMIT 100;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq207
