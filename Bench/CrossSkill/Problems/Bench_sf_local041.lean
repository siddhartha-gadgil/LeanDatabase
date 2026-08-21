import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local041 — crossskill equivalence(s)

Question: What percentage of trees in the Bronx have a health status of Good?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local041

CREATE TABLE TREES («idx» INT, «tree_id» INT, «tree_dbh» INT, «stump_diam» INT, «status» STRING, «health» STRING, «spc_latin» STRING, «spc_common» STRING, «address» STRING, «zipcode» INT, «borocode» INT, «boroname» STRING, «nta_name» STRING, «state» STRING, «latitude» FLOAT, «longitude» FLOAT)

theorem eq_0_1 :
    sql%([TREES_schema]) "SELECT\n    ROUND(\n        COUNT(CASE WHEN \"health\" = 'Good' THEN 1 END) * 100.0 / COUNT(*),\n        2\n    ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" = sql%([TREES_schema]) "SELECT \n  ROUND(\n    SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n    2\n  ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([TREES_schema]) "SELECT\n    ROUND(\n        COUNT(CASE WHEN \"health\" = 'Good' THEN 1 END) * 100.0 / COUNT(*),\n        2\n    ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" = sql%([TREES_schema]) "SELECT\n    ROUND(\n        100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*),\n        2\n    ) AS \"percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" := by
  first | sql_equiv | sorry

theorem eq_0_3 :
    sql%([TREES_schema]) "SELECT\n    ROUND(\n        COUNT(CASE WHEN \"health\" = 'Good' THEN 1 END) * 100.0 / COUNT(*),\n        2\n    ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" = sql%([TREES_schema]) "SELECT \n    ROUND(100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 2) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" := by
  first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([TREES_schema]) "SELECT \n  ROUND(\n    SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n    2\n  ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" = sql%([TREES_schema]) "SELECT\n    ROUND(\n        100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*),\n        2\n    ) AS \"percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" := by
  first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([TREES_schema]) "SELECT \n  ROUND(\n    SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), \n    2\n  ) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" = sql%([TREES_schema]) "SELECT \n    ROUND(100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 2) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" := by
  first | sql_equiv | sorry

theorem eq_2_3 :
    sql%([TREES_schema]) "SELECT\n    ROUND(\n        100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*),\n        2\n    ) AS \"percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" = sql%([TREES_schema]) "SELECT \n    ROUND(100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 2) AS \"Percentage\"\nFROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\"\nWHERE \"boroname\" = 'Bronx';" := by
  first | sql_equiv | sorry

end Bench_sf_local041
