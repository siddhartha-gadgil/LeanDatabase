import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local040_eq_1_2

CREATE TABLE INCOME_TREES («zipcode» INT, «Estimate_Total» INT, «Margin_of_Error_Total» INT, «Estimate_Median_income» INT, «Margin_of_Error_Median_income» INT, «Estimate_Mean_income» INT, «Margin_of_Error_Mean_income» INT)
CREATE TABLE TREES («idx» INT, «tree_id» INT, «tree_dbh» INT, «stump_diam» INT, «status» STRING, «health» STRING, «spc_latin» STRING, «spc_common» STRING, «address» STRING, «zipcode» INT, «borocode» INT, «boroname» STRING, «nta_name» STRING, «state» STRING, «latitude» FLOAT, «longitude» FLOAT)

theorem eq (t0 : TableRel INCOME_TREES_schema) (t1 : TableRel TREES_schema) :
    (sql%([INCOME_TREES_schema, TREES_schema]) "WITH borough_stats AS (SELECT t.\"boroname\", COUNT(*) AS tree_count, ROUND(CAST(AVG(i.\"Estimate_Mean_income\") AS DECIMAL), 4) AS mean_income FROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\" AS t INNER JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"INCOME_TREES\" AS i ON t.\"zipcode\" = i.\"zipcode\" WHERE i.\"Estimate_Median_income\" > 0 AND i.\"Estimate_Mean_income\" > 0 AND NOT t.\"boroname\" IS NULL AND t.\"boroname\" <> '' GROUP BY t.\"boroname\" ORDER BY tree_count DESC LIMIT 3) SELECT \"boroname\", mean_income FROM borough_stats ORDER BY mean_income DESC") t0 t1
  = (sql%([INCOME_TREES_schema, TREES_schema]) "WITH top3 AS (SELECT t.\"boroname\", COUNT(*) AS tree_count, ROUND(CAST(AVG(i.\"Estimate_Mean_income\") AS DECIMAL), 4) AS \"mean_income\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\" AS t JOIN \"MODERN_DATA\".\"MODERN_DATA\".\"INCOME_TREES\" AS i ON t.\"zipcode\" = i.\"zipcode\" WHERE i.\"Estimate_Median_income\" > 0 AND i.\"Estimate_Mean_income\" > 0 AND NOT t.\"boroname\" IS NULL AND t.\"boroname\" <> '' GROUP BY t.\"boroname\" ORDER BY tree_count DESC LIMIT 3) SELECT \"boroname\", \"mean_income\" FROM top3 ORDER BY \"mean_income\" DESC") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local040_eq_1_2
