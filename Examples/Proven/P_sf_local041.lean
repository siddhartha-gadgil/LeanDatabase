import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_local041 — proven cross-skill equivalence(s)

Question: What percentage of trees in the Bronx have a health status of Good?

Independently-written SQL variants proved equal for all table contents by `sql_equiv`; where
they differ by a `WHERE`/`SELECT` fact, that data assumption is an explicit `HYPOTHESIS` antecedent.
-/

namespace P_sf_local041

CREATE TABLE TREES («idx» INT, «tree_id» INT, «tree_dbh» INT, «stump_diam» INT, «status» STRING, «health» STRING, «spc_latin» STRING, «spc_common» STRING, «address» STRING, «zipcode» INT, «borocode» INT, «boroname» STRING, «nta_name» STRING, «state» STRING, «latitude» FLOAT, «longitude» FLOAT)

theorem eq_0_1 (t : TableRel TREES_schema) :
    (sql%([TREES_schema]) "SELECT\n    ROUND(\n        COUNT(CASE WHEN \"health\" = 'Good' THEN 1 END) * 100.0 / COUNT(*),\n        2\n    ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t = (sql%([TREES_schema]) "SELECT \n  ROUND(\n    SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n    2\n  ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t := by sql_equiv
theorem eq_0_2 (t : TableRel TREES_schema) :
    (sql%([TREES_schema]) "SELECT\n    ROUND(\n        COUNT(CASE WHEN \"health\" = 'Good' THEN 1 END) * 100.0 / COUNT(*),\n        2\n    ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t = (sql%([TREES_schema]) "SELECT\n    ROUND(\n        100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*),\n        2\n    ) AS \"percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t := by sql_equiv
theorem eq_0_3 (t : TableRel TREES_schema) :
    (sql%([TREES_schema]) "SELECT\n    ROUND(\n        COUNT(CASE WHEN \"health\" = 'Good' THEN 1 END) * 100.0 / COUNT(*),\n        2\n    ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t = (sql%([TREES_schema]) "SELECT \n    ROUND(100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 2) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t := by sql_equiv
theorem eq_1_2 (t : TableRel TREES_schema) :
    (sql%([TREES_schema]) "SELECT \n  ROUND(\n    SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n    2\n  ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t = (sql%([TREES_schema]) "SELECT\n    ROUND(\n        100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*),\n        2\n    ) AS \"percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t := by sql_equiv
theorem eq_1_3 (t : TableRel TREES_schema) :
    (sql%([TREES_schema]) "SELECT \n  ROUND(\n    SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n    2\n  ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t = (sql%([TREES_schema]) "SELECT \n    ROUND(100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 2) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t := by sql_equiv
theorem eq_2_3 (t : TableRel TREES_schema) :
    (sql%([TREES_schema]) "SELECT\n    ROUND(\n        100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*),\n        2\n    ) AS \"percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t = (sql%([TREES_schema]) "SELECT \n    ROUND(100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 2) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';") t := by sql_equiv

end P_sf_local041
