import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local041_eq_2_3

CREATE TABLE TREES («idx» INT, «tree_id» INT, «tree_dbh» INT, «stump_diam» INT, «status» STRING, «health» STRING, «spc_latin» STRING, «spc_common» STRING, «address» STRING, «zipcode» INT, «borocode» INT, «boroname» STRING, «nta_name» STRING, «state» STRING, «latitude» FLOAT, «longitude» FLOAT)

theorem eq (t0 : TableRel TREES_schema) :
    (sql%([TREES_schema]) "SELECT ROUND(CAST(CAST(100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 2) AS \"percentage\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\" WHERE \"boroname\" = 'Bronx'") t0
  = (sql%([TREES_schema]) "SELECT ROUND(CAST(CAST(100.0 * SUM(CASE WHEN \"health\" = 'Good' THEN 1 ELSE 0 END) AS DOUBLE PRECISION) / COUNT(*) AS DECIMAL), 2) AS \"Percentage\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"TREES\" WHERE \"boroname\" = 'Bronx'") t0
  := by first | sql_equiv | sorry

end N_sf_local041_eq_2_3
