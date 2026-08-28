import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq247 — crossskill equivalence(s)

Question: From the publications dataset, first identify the top six families with the most publications whose family_id is not '-1'. Then, using the abs_and_emb table (joined on publication_number), provide each of those families’ IDs alongside every non-empty abstract associated with their publications.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq247

CREATE TABLE PUBLICATIONS («publication_number» STRING, «application_number» STRING, «country_code» STRING, «kind_code» STRING, «application_kind» STRING, «application_number_formatted» STRING, «pct_number» STRING, «family_id» STRING, «title_localized» STRING, «abstract_localized» STRING, «claims_localized» STRING, «description_localized» STRING, «publication_date» INT, «filing_date» INT, «grant_date» INT, «priority_date» INT, «priority_claim» STRING, «inventor» STRING, «inventor_harmonized» STRING, «assignee» STRING, «assignee_harmonized» STRING, «examiner» STRING, «uspc» STRING, «ipc» STRING, «cpc» STRING, «fi» STRING, «fterm» STRING, «citation» STRING, «entity_status» STRING, «art_unit» STRING)
CREATE TABLE ABS_AND_EMB («publication_number» STRING, «title» STRING, «title_translated» BOOL, «abstract» STRING, «abstract_translated» BOOL, «cpc» STRING, «cpc_low» STRING, «cpc_inventive_low» STRING, «top_terms» STRING, «similar» STRING, «url» STRING, «country» STRING, «publication_description» STRING, «cited_by» STRING, «embedding_v1» STRING)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 :
    sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> -1 GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p INNER JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" INNER JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" WHERE NOT a.\"abstract\" IS NULL AND TRIM(a.\"abstract\") <> ''" = sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> ''" := by
  first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 : ∀ t,
    (sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> -1 GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p INNER JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" INNER JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" WHERE NOT a.\"abstract\" IS NULL AND TRIM(a.\"abstract\") <> ''") t ~= (sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\", COUNT(*) AS pub_count FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY pub_count DESC LIMIT 6) SELECT p.\"family_id\" AS \"family_id\", a.\"abstract\" AS \"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> '' ORDER BY tf.pub_count DESC, p.\"family_id\", a.\"abstract\"") t := by
  intro t; first | sql_equiv | sorry

-- eq_0_3: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_3 :
    sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> -1 GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p INNER JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" INNER JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" WHERE NOT a.\"abstract\" IS NULL AND TRIM(a.\"abstract\") <> ''" = sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> '' ORDER BY p.\"family_id\"" := by
  first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> ''") t ~= (sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\", COUNT(*) AS pub_count FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY pub_count DESC LIMIT 6) SELECT p.\"family_id\" AS \"family_id\", a.\"abstract\" AS \"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> '' ORDER BY tf.pub_count DESC, p.\"family_id\", a.\"abstract\"") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> ''" = sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> '' ORDER BY p.\"family_id\"" := by
  first | sql_equiv | sorry

theorem eq_2_3 : ∀ t,
    (sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\", COUNT(*) AS pub_count FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY pub_count DESC LIMIT 6) SELECT p.\"family_id\" AS \"family_id\", a.\"abstract\" AS \"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> '' ORDER BY tf.pub_count DESC, p.\"family_id\", a.\"abstract\"") t ~= (sql%([PUBLICATIONS_schema, ABS_AND_EMB_schema]) "WITH top_families AS (SELECT \"family_id\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" WHERE \"family_id\" <> '-1' GROUP BY \"family_id\" ORDER BY COUNT(*) DESC LIMIT 6) SELECT p.\"family_id\", a.\"abstract\" FROM \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"PUBLICATIONS\" AS p JOIN top_families AS tf ON p.\"family_id\" = tf.\"family_id\" JOIN \"PATENTS_GOOGLE\".\"PATENTS_GOOGLE\".\"ABS_AND_EMB\" AS a ON p.\"publication_number\" = a.\"publication_number\" WHERE NOT a.\"abstract\" IS NULL AND a.\"abstract\" <> '' ORDER BY p.\"family_id\"") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq247
