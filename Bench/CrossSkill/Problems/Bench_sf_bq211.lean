import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq211 — crossskill equivalence(s)

Question: Among patents granted between 2010 and 2023 in CN, how many of them belong to families that have a total of over one distinct applications?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq211

CREATE TABLE PUBLICATIONS («publication_number» STRING, «application_number» STRING, «country_code» STRING, «kind_code» STRING, «application_kind» STRING, «application_number_formatted» STRING, «pct_number» STRING, «family_id» STRING, «spif_publication_number» STRING, «spif_application_number» STRING, «title_localized» STRING, «abstract_localized» STRING, «claims_localized» STRING, «claims_localized_html» STRING, «description_localized» STRING, «description_localized_html» STRING, «publication_date» INT, «filing_date» INT, «grant_date» INT, «priority_date» INT, «priority_claim» STRING, «inventor» STRING, «inventor_harmonized» STRING, «assignee» STRING, «assignee_harmonized» STRING, «examiner» STRING, «uspc» STRING, «ipc» STRING, «cpc» STRING, «fi» STRING, «fterm» STRING, «locarno» STRING, «citation» STRING, «parent» STRING, «child» STRING, «entity_status» STRING, «art_unit» STRING)

HYPOTHESIS hyp0_1_0 : PUBLICATIONS "\"grant_date\" >= 20100101"
HYPOTHESIS hyp0_1_1 : PUBLICATIONS "\"grant_date\" <= 20231231"
theorem eq_0_1 (t : TableRel PUBLICATIONS_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) :
    (sql%([PUBLICATIONS_schema]) "/* Among patents granted between 2010 and 2023 in CN, */ /* how many of them belong to families that have a total of over one distinct applications? */ WITH multi_app_families AS (/* Find families with more than 1 distinct application (global scope) */ SELECT \"family_id\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1) SELECT COUNT(*) AS \"OUTPUT\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p INNER JOIN multi_app_families AS f ON p.\"family_id\" = f.\"family_id\" WHERE p.\"country_code\" = 'CN' AND FLOOR(CAST(p.\"grant_date\" AS DOUBLE PRECISION) / 10000) BETWEEN 2010 AND 2023") t ~= (sql%([PUBLICATIONS_schema]) "SELECT COUNT(*) AS OUTPUT FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p WHERE p.\"country_code\" = 'CN' AND p.\"grant_date\" >= 20100101 AND p.\"grant_date\" <= 20231231 AND p.\"family_id\" IN (SELECT \"family_id\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1)") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : PUBLICATIONS "\"country_code\" = 'CN'"
HYPOTHESIS hyp0_2_1 : PUBLICATIONS "\"grant_date\" >= 20100101"
theorem eq_0_2 (t : TableRel PUBLICATIONS_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([PUBLICATIONS_schema]) "/* Among patents granted between 2010 and 2023 in CN, */ /* how many of them belong to families that have a total of over one distinct applications? */ WITH multi_app_families AS (/* Find families with more than 1 distinct application (global scope) */ SELECT \"family_id\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1) SELECT COUNT(*) AS \"OUTPUT\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p INNER JOIN multi_app_families AS f ON p.\"family_id\" = f.\"family_id\" WHERE p.\"country_code\" = 'CN' AND FLOOR(CAST(p.\"grant_date\" AS DOUBLE PRECISION) / 10000) BETWEEN 2010 AND 2023") t ~= (sql%([PUBLICATIONS_schema]) "WITH cn_patents AS (SELECT \"publication_number\", \"family_id\", \"application_number\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" WHERE \"country_code\" = 'CN' AND \"grant_date\" >= 20100101 AND \"grant_date\" <= 20231231), family_counts AS (SELECT \"family_id\", COUNT(DISTINCT \"application_number\") AS app_count FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" WHERE \"family_id\" IN (SELECT DISTINCT \"family_id\" FROM cn_patents) GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1) SELECT COUNT(*) AS \"OUTPUT\" FROM cn_patents AS p JOIN family_counts AS f ON p.\"family_id\" = f.\"family_id\"") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : PUBLICATIONS "\"country_code\" = 'CN'"
HYPOTHESIS hyp0_3_1 : PUBLICATIONS "\"grant_date\" >= 20100101"
HYPOTHESIS hyp0_3_2 : PUBLICATIONS "\"grant_date\" <= 20231231"
theorem eq_0_3 (t : TableRel PUBLICATIONS_schema) (h0 : hyp0_3_0 t) (h1 : hyp0_3_1 t) (h2 : hyp0_3_2 t) :
    (sql%([PUBLICATIONS_schema]) "/* Among patents granted between 2010 and 2023 in CN, */ /* how many of them belong to families that have a total of over one distinct applications? */ WITH multi_app_families AS (/* Find families with more than 1 distinct application (global scope) */ SELECT \"family_id\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1) SELECT COUNT(*) AS \"OUTPUT\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p INNER JOIN multi_app_families AS f ON p.\"family_id\" = f.\"family_id\" WHERE p.\"country_code\" = 'CN' AND FLOOR(CAST(p.\"grant_date\" AS DOUBLE PRECISION) / 10000) BETWEEN 2010 AND 2023") t ~= (sql%([PUBLICATIONS_schema]) "/* Among patents granted between 2010 and 2023 in CN, */ /* how many of them belong to families that have a total of over one distinct applications? */ WITH cn_granted AS (SELECT \"publication_number\", \"family_id\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" WHERE \"country_code\" = 'CN' AND \"grant_date\" >= 20100101 AND \"grant_date\" <= 20231231 AND \"grant_date\" > 0), family_app_counts AS (SELECT \"family_id\", COUNT(DISTINCT \"application_number\") AS distinct_apps FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1) SELECT COUNT(*) AS cnt FROM cn_granted AS cg JOIN family_app_counts AS fac ON cg.\"family_id\" = fac.\"family_id\"") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : PUBLICATIONS "\"country_code\" = 'CN'"
HYPOTHESIS hyp1_2_1 : PUBLICATIONS "\"grant_date\" >= 20100101"
HYPOTHESIS hyp1_2_2 : PUBLICATIONS "\"grant_date\" <= 20231231"
theorem eq_1_2 (t : TableRel PUBLICATIONS_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) (h2 : hyp1_2_2 t) :
    (sql%([PUBLICATIONS_schema]) "SELECT COUNT(*) AS OUTPUT FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p WHERE p.\"country_code\" = 'CN' AND p.\"grant_date\" >= 20100101 AND p.\"grant_date\" <= 20231231 AND p.\"family_id\" IN (SELECT \"family_id\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1)") t ~= (sql%([PUBLICATIONS_schema]) "WITH cn_patents AS (SELECT \"publication_number\", \"family_id\", \"application_number\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" WHERE \"country_code\" = 'CN' AND \"grant_date\" >= 20100101 AND \"grant_date\" <= 20231231), family_counts AS (SELECT \"family_id\", COUNT(DISTINCT \"application_number\") AS app_count FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" WHERE \"family_id\" IN (SELECT DISTINCT \"family_id\" FROM cn_patents) GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1) SELECT COUNT(*) AS \"OUTPUT\" FROM cn_patents AS p JOIN family_counts AS f ON p.\"family_id\" = f.\"family_id\"") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : PUBLICATIONS "\"country_code\" = 'CN'"
HYPOTHESIS hyp1_3_1 : PUBLICATIONS "\"grant_date\" >= 20100101"
HYPOTHESIS hyp1_3_2 : PUBLICATIONS "\"grant_date\" <= 20231231"
theorem eq_1_3 (t : TableRel PUBLICATIONS_schema) (h0 : hyp1_3_0 t) (h1 : hyp1_3_1 t) (h2 : hyp1_3_2 t) :
    (sql%([PUBLICATIONS_schema]) "SELECT COUNT(*) AS OUTPUT FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" AS p WHERE p.\"country_code\" = 'CN' AND p.\"grant_date\" >= 20100101 AND p.\"grant_date\" <= 20231231 AND p.\"family_id\" IN (SELECT \"family_id\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1)") t ~= (sql%([PUBLICATIONS_schema]) "/* Among patents granted between 2010 and 2023 in CN, */ /* how many of them belong to families that have a total of over one distinct applications? */ WITH cn_granted AS (SELECT \"publication_number\", \"family_id\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" WHERE \"country_code\" = 'CN' AND \"grant_date\" >= 20100101 AND \"grant_date\" <= 20231231 AND \"grant_date\" > 0), family_app_counts AS (SELECT \"family_id\", COUNT(DISTINCT \"application_number\") AS distinct_apps FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1) SELECT COUNT(*) AS cnt FROM cn_granted AS cg JOIN family_app_counts AS fac ON cg.\"family_id\" = fac.\"family_id\"") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : PUBLICATIONS "\"grant_date\" <= 20231231"
theorem eq_2_3 (t : TableRel PUBLICATIONS_schema) (h0 : hyp2_3_0 t) :
    (sql%([PUBLICATIONS_schema]) "WITH cn_patents AS (SELECT \"publication_number\", \"family_id\", \"application_number\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" WHERE \"country_code\" = 'CN' AND \"grant_date\" >= 20100101 AND \"grant_date\" <= 20231231), family_counts AS (SELECT \"family_id\", COUNT(DISTINCT \"application_number\") AS app_count FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" WHERE \"family_id\" IN (SELECT DISTINCT \"family_id\" FROM cn_patents) GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1) SELECT COUNT(*) AS \"OUTPUT\" FROM cn_patents AS p JOIN family_counts AS f ON p.\"family_id\" = f.\"family_id\"") t ~= (sql%([PUBLICATIONS_schema]) "/* Among patents granted between 2010 and 2023 in CN, */ /* how many of them belong to families that have a total of over one distinct applications? */ WITH cn_granted AS (SELECT \"publication_number\", \"family_id\" FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" WHERE \"country_code\" = 'CN' AND \"grant_date\" >= 20100101 AND \"grant_date\" <= 20231231 AND \"grant_date\" > 0), family_app_counts AS (SELECT \"family_id\", COUNT(DISTINCT \"application_number\") AS distinct_apps FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" GROUP BY \"family_id\" HAVING COUNT(DISTINCT \"application_number\") > 1) SELECT COUNT(*) AS cnt FROM cn_granted AS cg JOIN family_app_counts AS fac ON cg.\"family_id\" = fac.\"family_id\"") t := by
  first | sql_equiv | sorry

end Bench_sf_bq211
