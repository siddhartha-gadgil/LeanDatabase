import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_local040 — proven cross-skill equivalence(s)

Question: In the combined dataset that unifies the trees data with the income data by ZIP code, filling missing ZIP values where necessary, which three boroughs, restricted to records with median and mean income both greater than zero and a valid borough name, contain the highest number of trees, and what is the average mean income for each of these three boroughs?

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` fact, that data assumption is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_local040

CREATE TABLE INCOME_TREES («zipcode» INT, «Estimate_Total» INT, «Margin_of_Error_Total» INT, «Estimate_Median_income» INT, «Margin_of_Error_Median_income» INT, «Estimate_Mean_income» INT, «Margin_of_Error_Mean_income» INT)
CREATE TABLE TREES («idx» INT, «tree_id» INT, «tree_dbh» INT, «stump_diam» INT, «status» STRING, «health» STRING, «spc_latin» STRING, «spc_common» STRING, «address» STRING, «zipcode» INT, «borocode» INT, «boroname» STRING, «nta_name» STRING, «state» STRING, «latitude» FLOAT, «longitude» FLOAT)

theorem eq_1_2 :
    sql%([INCOME_TREES_schema, TREES_schema]) "WITH borough_stats AS (SELECT t.\"boroname\", COUNT(*) AS tree_count, ROUND(CAST(AVG(i.\"Estimate_Mean_income\") AS DECIMAL), 4) AS mean_income FROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\" AS t INNER JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"INCOME_TREES\" AS i ON t.\"zipcode\" = i.\"zipcode\" WHERE i.\"Estimate_Median_income\" > 0 AND i.\"Estimate_Mean_income\" > 0 AND NOT t.\"boroname\" IS NULL AND t.\"boroname\" <> '' GROUP BY t.\"boroname\" ORDER BY tree_count DESC LIMIT 3) SELECT \"boroname\", mean_income FROM borough_stats ORDER BY mean_income DESC" = sql%([INCOME_TREES_schema, TREES_schema]) "WITH top3 AS (SELECT t.\"boroname\", COUNT(*) AS tree_count, ROUND(CAST(AVG(i.\"Estimate_Mean_income\") AS DECIMAL), 4) AS \"mean_income\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\" AS t JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"INCOME_TREES\" AS i ON t.\"zipcode\" = i.\"zipcode\" WHERE i.\"Estimate_Median_income\" > 0 AND i.\"Estimate_Mean_income\" > 0 AND NOT t.\"boroname\" IS NULL AND t.\"boroname\" <> '' GROUP BY t.\"boroname\" ORDER BY tree_count DESC LIMIT 3) SELECT \"boroname\", \"mean_income\" FROM top3 ORDER BY \"mean_income\" DESC" := by sql_equiv

end P_sf_local040
