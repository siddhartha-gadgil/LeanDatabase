import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq284 — proven cross-skill equivalence(s)

Question: Can you provide a breakdown of the total number of articles into different categories and the percentage of those articles that mention "education" within each category from the BBC News?

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` expression, that data fact is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_bq284

CREATE TABLE FULLTEXT («body» STRING, «title» STRING, «filename» STRING, «category» STRING)

theorem eq_0_3 (t : TableRel FULLTEXT_schema) :
    (sql%([FULLTEXT_schema]) "SELECT \n    \"category\",\n    COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n    ROUND(\n        SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n        6\n    ) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";") t = (sql%([FULLTEXT_schema]) "SELECT\n  \"category\",\n  COUNT(*) AS NUMBER_TOTAL_BY_CATEGORY,\n  ROUND(100.0 * SUM(CASE WHEN LOWER(\"body\") LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*), 6) AS PERCENT_EDUCATION\nFROM \"BBC\".\"BBC_NEWS\".\"FULLTEXT\"\nGROUP BY \"category\"\nORDER BY \"category\";") t := by sql_equiv

end P_sf_bq284
