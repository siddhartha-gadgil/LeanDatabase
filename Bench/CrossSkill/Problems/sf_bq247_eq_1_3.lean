import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq247_eq_1_3

CREATE TABLE PUBLICATIONS («publication_number» STRING, «application_number» STRING, «country_code» STRING, «kind_code» STRING, «application_kind» STRING, «application_number_formatted» STRING, «pct_number» STRING, «family_id» STRING, «title_localized» STRING, «abstract_localized» STRING, «claims_localized» STRING, «description_localized» STRING, «publication_date» INT, «filing_date» INT, «grant_date» INT, «priority_date» INT, «priority_claim» STRING, «inventor» STRING, «inventor_harmonized» STRING, «assignee» STRING, «assignee_harmonized» STRING, «examiner» STRING, «uspc» STRING, «ipc» STRING, «cpc» STRING, «fi» STRING, «fterm» STRING, «citation» STRING, «entity_status» STRING, «art_unit» STRING)
CREATE TABLE ABS_AND_EMB («publication_number» STRING, «title» STRING, «title_translated» BOOL, «abstract» STRING, «abstract_translated» BOOL, «cpc» STRING, «cpc_low» STRING, «cpc_inventive_low» STRING, «top_terms» STRING, «similar» STRING, «url» STRING, «country» STRING, «publication_description» STRING, «cited_by» STRING, «embedding_v1» STRING)

theorem eq (t0 : TableRel PUBLICATIONS_schema) (t1 : TableRel ABS_AND_EMB_schema) :
    (sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> ''") t0 t1
  = (sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> '' ORDER BY p.\"family_id\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq247_eq_1_3
