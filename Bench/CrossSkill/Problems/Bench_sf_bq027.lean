import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq027 — crossskill equivalence(s)

Question: For patents granted between 2010 and 2018, provide the publication number of each patent and the number of backward citations it has received in the SEA category.

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq027

CREATE TABLE PUBLICATIONS («publication_number» STRING, «application_number» STRING, «country_code» STRING, «kind_code» STRING, «application_kind» STRING, «application_number_formatted» STRING, «pct_number» STRING, «family_id» STRING, «spif_publication_number» STRING, «spif_application_number» STRING, «title_localized» STRING, «abstract_localized» STRING, «claims_localized» STRING, «claims_localized_html» STRING, «description_localized» STRING, «description_localized_html» STRING, «publication_date» INT, «filing_date» INT, «grant_date» INT, «priority_date» INT, «priority_claim» STRING, «inventor» STRING, «inventor_harmonized» STRING, «assignee» STRING, «assignee_harmonized» STRING, «examiner» STRING, «uspc» STRING, «ipc» STRING, «cpc» STRING, «fi» STRING, «fterm» STRING, «locarno» STRING, «citation» STRING, «parent» STRING, «child» STRING, «entity_status» STRING, «art_unit» STRING)

HYPOTHESIS hyp0_1_0 : PUBLICATIONS "\"grant_date\" >= 20100101"
HYPOTHESIS hyp0_1_1 : PUBLICATIONS "\"grant_date\" <= 20181231"
theorem eq_0_1 (t : TableRel PUBLICATIONS_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) :
    (sql%([PUBLICATIONS_schema]) "SELECT \n    p.\"publication_number\" AS \"publication_number\",\n    COUNT(CASE WHEN f.value:\"category\"::STRING = 'SEA' THEN 1 END) AS \"SEA_BACKWARD_CITATIONS\"\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nLEFT JOIN LATERAL FLATTEN(input => p.\"citation\", OUTER => TRUE) f\nWHERE p.\"grant_date\" >= 20100101 AND p.\"grant_date\" <= 20181231\nGROUP BY p.\"publication_number\"\nORDER BY \"SEA_BACKWARD_CITATIONS\" DESC;") t = (sql%([PUBLICATIONS_schema]) "SELECT \n    p.\"publication_number\",\n    COALESCE(sea.\"SEA_BACKWARD_CITATIONS\", 0) AS \"SEA_BACKWARD_CITATIONS\"\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nLEFT JOIN (\n    SELECT \n        p2.\"publication_number\",\n        COUNT(*) AS \"SEA_BACKWARD_CITATIONS\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p2,\n    LATERAL FLATTEN(input => p2.\"citation\") f\n    WHERE FLOOR(p2.\"grant_date\" / 10000) BETWEEN 2010 AND 2018\n      AND f.value:category::STRING = 'SEA'\n    GROUP BY p2.\"publication_number\"\n) sea ON p.\"publication_number\" = sea.\"publication_number\"\nWHERE FLOOR(p.\"grant_date\" / 10000) BETWEEN 2010 AND 2018\nORDER BY \"SEA_BACKWARD_CITATIONS\" DESC;") t := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([PUBLICATIONS_schema]) "SELECT \n    p.\"publication_number\" AS \"publication_number\",\n    COUNT(CASE WHEN f.value:\"category\"::STRING = 'SEA' THEN 1 END) AS \"SEA_BACKWARD_CITATIONS\"\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nLEFT JOIN LATERAL FLATTEN(input => p.\"citation\", OUTER => TRUE) f\nWHERE p.\"grant_date\" >= 20100101 AND p.\"grant_date\" <= 20181231\nGROUP BY p.\"publication_number\"\nORDER BY \"SEA_BACKWARD_CITATIONS\" DESC;" = sql%([PUBLICATIONS_schema]) "SELECT \n    p.\"publication_number\" AS \"publication_number\",\n    COUNT(CASE WHEN f.value:category::STRING = 'SEA' THEN 1 END) AS \"SEA_BACKWARD_CITATIONS\"\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nLEFT JOIN LATERAL FLATTEN(input => p.\"citation\", OUTER => TRUE) f\nWHERE p.\"grant_date\" >= 20100101 AND p.\"grant_date\" <= 20181231\nGROUP BY p.\"publication_number\"\nORDER BY \"SEA_BACKWARD_CITATIONS\" DESC, p.\"publication_number\" DESC;" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : PUBLICATIONS "\"grant_date\" >= 20100101"
HYPOTHESIS hyp1_2_1 : PUBLICATIONS "\"grant_date\" <= 20181231"
theorem eq_1_2 (t : TableRel PUBLICATIONS_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) :
    (sql%([PUBLICATIONS_schema]) "SELECT \n    p.\"publication_number\",\n    COALESCE(sea.\"SEA_BACKWARD_CITATIONS\", 0) AS \"SEA_BACKWARD_CITATIONS\"\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nLEFT JOIN (\n    SELECT \n        p2.\"publication_number\",\n        COUNT(*) AS \"SEA_BACKWARD_CITATIONS\"\n    FROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p2,\n    LATERAL FLATTEN(input => p2.\"citation\") f\n    WHERE FLOOR(p2.\"grant_date\" / 10000) BETWEEN 2010 AND 2018\n      AND f.value:category::STRING = 'SEA'\n    GROUP BY p2.\"publication_number\"\n) sea ON p.\"publication_number\" = sea.\"publication_number\"\nWHERE FLOOR(p.\"grant_date\" / 10000) BETWEEN 2010 AND 2018\nORDER BY \"SEA_BACKWARD_CITATIONS\" DESC;") t = (sql%([PUBLICATIONS_schema]) "SELECT \n    p.\"publication_number\" AS \"publication_number\",\n    COUNT(CASE WHEN f.value:category::STRING = 'SEA' THEN 1 END) AS \"SEA_BACKWARD_CITATIONS\"\nFROM \"PATENTS\".\"PATENTS\".\"PUBLICATIONS\" p\nLEFT JOIN LATERAL FLATTEN(input => p.\"citation\", OUTER => TRUE) f\nWHERE p.\"grant_date\" >= 20100101 AND p.\"grant_date\" <= 20181231\nGROUP BY p.\"publication_number\"\nORDER BY \"SEA_BACKWARD_CITATIONS\" DESC, p.\"publication_number\" DESC;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq027
