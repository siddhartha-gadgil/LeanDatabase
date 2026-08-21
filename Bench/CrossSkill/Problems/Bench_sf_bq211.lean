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
    (sql%([PUBLICATIONS_schema]) "-- Among patents granted between 2010 and 2023 in CN,\n-- how many of them belong to families that have a total of over one distinct applications?\n\nWITH multi_app_families AS (\n  -- Find families with more than 1 distinct application (global scope)\n  SELECT \"family_id\"\n  FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n  GROUP BY \"family_id\"\n  HAVING COUNT(DISTINCT \"application_number\") > 1\n)\nSELECT COUNT(*) AS \"OUTPUT\"\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nINNER JOIN multi_app_families f\n  ON p.\"family_id\" = f.\"family_id\"\nWHERE p.\"country_code\" = 'CN'\n  AND FLOOR(p.\"grant_date\" / 10000) BETWEEN 2010 AND 2023;") t ~= (sql%([PUBLICATIONS_schema]) "SELECT COUNT(*) AS OUTPUT\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nWHERE p.\"country_code\" = 'CN'\n  AND p.\"grant_date\" >= 20100101\n  AND p.\"grant_date\" <= 20231231\n  AND p.\"family_id\" IN (\n    SELECT \"family_id\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    GROUP BY \"family_id\"\n    HAVING COUNT(DISTINCT \"application_number\") > 1\n  );") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : PUBLICATIONS "\"country_code\" = 'CN'"
HYPOTHESIS hyp0_2_1 : PUBLICATIONS "\"grant_date\" >= 20100101"
theorem eq_0_2 (t : TableRel PUBLICATIONS_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([PUBLICATIONS_schema]) "-- Among patents granted between 2010 and 2023 in CN,\n-- how many of them belong to families that have a total of over one distinct applications?\n\nWITH multi_app_families AS (\n  -- Find families with more than 1 distinct application (global scope)\n  SELECT \"family_id\"\n  FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n  GROUP BY \"family_id\"\n  HAVING COUNT(DISTINCT \"application_number\") > 1\n)\nSELECT COUNT(*) AS \"OUTPUT\"\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nINNER JOIN multi_app_families f\n  ON p.\"family_id\" = f.\"family_id\"\nWHERE p.\"country_code\" = 'CN'\n  AND FLOOR(p.\"grant_date\" / 10000) BETWEEN 2010 AND 2023;") t ~= (sql%([PUBLICATIONS_schema]) "WITH cn_patents AS (\n    SELECT\n        \"publication_number\",\n        \"family_id\",\n        \"application_number\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    WHERE \"country_code\" = 'CN'\n      AND \"grant_date\" >= 20100101\n      AND \"grant_date\" <= 20231231\n),\nfamily_counts AS (\n    SELECT\n        \"family_id\",\n        COUNT(DISTINCT \"application_number\") AS app_count\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    WHERE \"family_id\" IN (SELECT DISTINCT \"family_id\" FROM cn_patents)\n    GROUP BY \"family_id\"\n    HAVING COUNT(DISTINCT \"application_number\") > 1\n)\nSELECT COUNT(*) AS \"OUTPUT\"\nFROM cn_patents p\nJOIN family_counts f ON p.\"family_id\" = f.\"family_id\";") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : PUBLICATIONS "\"country_code\" = 'CN'"
HYPOTHESIS hyp0_3_1 : PUBLICATIONS "\"grant_date\" >= 20100101"
HYPOTHESIS hyp0_3_2 : PUBLICATIONS "\"grant_date\" <= 20231231"
theorem eq_0_3 (t : TableRel PUBLICATIONS_schema) (h0 : hyp0_3_0 t) (h1 : hyp0_3_1 t) (h2 : hyp0_3_2 t) :
    (sql%([PUBLICATIONS_schema]) "-- Among patents granted between 2010 and 2023 in CN,\n-- how many of them belong to families that have a total of over one distinct applications?\n\nWITH multi_app_families AS (\n  -- Find families with more than 1 distinct application (global scope)\n  SELECT \"family_id\"\n  FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n  GROUP BY \"family_id\"\n  HAVING COUNT(DISTINCT \"application_number\") > 1\n)\nSELECT COUNT(*) AS \"OUTPUT\"\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nINNER JOIN multi_app_families f\n  ON p.\"family_id\" = f.\"family_id\"\nWHERE p.\"country_code\" = 'CN'\n  AND FLOOR(p.\"grant_date\" / 10000) BETWEEN 2010 AND 2023;") t ~= (sql%([PUBLICATIONS_schema]) "-- Among patents granted between 2010 and 2023 in CN,\n-- how many of them belong to families that have a total of over one distinct applications?\n\nWITH cn_granted AS (\n    SELECT \"publication_number\", \"family_id\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    WHERE \"country_code\" = 'CN'\n      AND \"grant_date\" >= 20100101\n      AND \"grant_date\" <= 20231231\n      AND \"grant_date\" > 0\n),\nfamily_app_counts AS (\n    SELECT \"family_id\", COUNT(DISTINCT \"application_number\") AS distinct_apps\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    GROUP BY \"family_id\"\n    HAVING COUNT(DISTINCT \"application_number\") > 1\n)\nSELECT COUNT(*) AS cnt\nFROM cn_granted cg\nJOIN family_app_counts fac\n  ON cg.\"family_id\" = fac.\"family_id\";") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : PUBLICATIONS "\"country_code\" = 'CN'"
HYPOTHESIS hyp1_2_1 : PUBLICATIONS "\"grant_date\" >= 20100101"
HYPOTHESIS hyp1_2_2 : PUBLICATIONS "\"grant_date\" <= 20231231"
theorem eq_1_2 (t : TableRel PUBLICATIONS_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) (h2 : hyp1_2_2 t) :
    (sql%([PUBLICATIONS_schema]) "SELECT COUNT(*) AS OUTPUT\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nWHERE p.\"country_code\" = 'CN'\n  AND p.\"grant_date\" >= 20100101\n  AND p.\"grant_date\" <= 20231231\n  AND p.\"family_id\" IN (\n    SELECT \"family_id\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    GROUP BY \"family_id\"\n    HAVING COUNT(DISTINCT \"application_number\") > 1\n  );") t ~= (sql%([PUBLICATIONS_schema]) "WITH cn_patents AS (\n    SELECT\n        \"publication_number\",\n        \"family_id\",\n        \"application_number\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    WHERE \"country_code\" = 'CN'\n      AND \"grant_date\" >= 20100101\n      AND \"grant_date\" <= 20231231\n),\nfamily_counts AS (\n    SELECT\n        \"family_id\",\n        COUNT(DISTINCT \"application_number\") AS app_count\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    WHERE \"family_id\" IN (SELECT DISTINCT \"family_id\" FROM cn_patents)\n    GROUP BY \"family_id\"\n    HAVING COUNT(DISTINCT \"application_number\") > 1\n)\nSELECT COUNT(*) AS \"OUTPUT\"\nFROM cn_patents p\nJOIN family_counts f ON p.\"family_id\" = f.\"family_id\";") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : PUBLICATIONS "\"country_code\" = 'CN'"
HYPOTHESIS hyp1_3_1 : PUBLICATIONS "\"grant_date\" >= 20100101"
HYPOTHESIS hyp1_3_2 : PUBLICATIONS "\"grant_date\" <= 20231231"
theorem eq_1_3 (t : TableRel PUBLICATIONS_schema) (h0 : hyp1_3_0 t) (h1 : hyp1_3_1 t) (h2 : hyp1_3_2 t) :
    (sql%([PUBLICATIONS_schema]) "SELECT COUNT(*) AS OUTPUT\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nWHERE p.\"country_code\" = 'CN'\n  AND p.\"grant_date\" >= 20100101\n  AND p.\"grant_date\" <= 20231231\n  AND p.\"family_id\" IN (\n    SELECT \"family_id\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    GROUP BY \"family_id\"\n    HAVING COUNT(DISTINCT \"application_number\") > 1\n  );") t ~= (sql%([PUBLICATIONS_schema]) "-- Among patents granted between 2010 and 2023 in CN,\n-- how many of them belong to families that have a total of over one distinct applications?\n\nWITH cn_granted AS (\n    SELECT \"publication_number\", \"family_id\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    WHERE \"country_code\" = 'CN'\n      AND \"grant_date\" >= 20100101\n      AND \"grant_date\" <= 20231231\n      AND \"grant_date\" > 0\n),\nfamily_app_counts AS (\n    SELECT \"family_id\", COUNT(DISTINCT \"application_number\") AS distinct_apps\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    GROUP BY \"family_id\"\n    HAVING COUNT(DISTINCT \"application_number\") > 1\n)\nSELECT COUNT(*) AS cnt\nFROM cn_granted cg\nJOIN family_app_counts fac\n  ON cg.\"family_id\" = fac.\"family_id\";") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : PUBLICATIONS "\"grant_date\" <= 20231231"
theorem eq_2_3 (t : TableRel PUBLICATIONS_schema) (h0 : hyp2_3_0 t) :
    (sql%([PUBLICATIONS_schema]) "WITH cn_patents AS (\n    SELECT\n        \"publication_number\",\n        \"family_id\",\n        \"application_number\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    WHERE \"country_code\" = 'CN'\n      AND \"grant_date\" >= 20100101\n      AND \"grant_date\" <= 20231231\n),\nfamily_counts AS (\n    SELECT\n        \"family_id\",\n        COUNT(DISTINCT \"application_number\") AS app_count\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    WHERE \"family_id\" IN (SELECT DISTINCT \"family_id\" FROM cn_patents)\n    GROUP BY \"family_id\"\n    HAVING COUNT(DISTINCT \"application_number\") > 1\n)\nSELECT COUNT(*) AS \"OUTPUT\"\nFROM cn_patents p\nJOIN family_counts f ON p.\"family_id\" = f.\"family_id\";") t ~= (sql%([PUBLICATIONS_schema]) "-- Among patents granted between 2010 and 2023 in CN,\n-- how many of them belong to families that have a total of over one distinct applications?\n\nWITH cn_granted AS (\n    SELECT \"publication_number\", \"family_id\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    WHERE \"country_code\" = 'CN'\n      AND \"grant_date\" >= 20100101\n      AND \"grant_date\" <= 20231231\n      AND \"grant_date\" > 0\n),\nfamily_app_counts AS (\n    SELECT \"family_id\", COUNT(DISTINCT \"application_number\") AS distinct_apps\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\"\n    GROUP BY \"family_id\"\n    HAVING COUNT(DISTINCT \"application_number\") > 1\n)\nSELECT COUNT(*) AS cnt\nFROM cn_granted cg\nJOIN family_app_counts fac\n  ON cg.\"family_id\" = fac.\"family_id\";") t := by
  first | sql_equiv | sorry

end Bench_sf_bq211
