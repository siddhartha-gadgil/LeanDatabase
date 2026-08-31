import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local131_eq_0_1

CREATE TABLE MUSICAL_STYLES («StyleID» INT, «StyleName» STRING)
CREATE TABLE MUSICAL_PREFERENCES («CustomerID» INT, «StyleID» INT, «PreferenceSeq» INT)

theorem eq (t0 : TableRel MUSICAL_STYLES_schema) (t1 : TableRel MUSICAL_PREFERENCES_schema) :
    (sql%([MUSICAL_STYLES_schema, MUSICAL_PREFERENCES_schema]) "SELECT ms.\"StyleID\", ms.\"StyleName\", SUM(CASE WHEN mp.\"PreferenceSeq\" = 1 THEN 1 ELSE 0 END) AS \"FirstPreferenceCount\", SUM(CASE WHEN mp.\"PreferenceSeq\" = 2 THEN 1 ELSE 0 END) AS \"SecondPreferenceCount\", SUM(CASE WHEN mp.\"PreferenceSeq\" = 3 THEN 1 ELSE 0 END) AS \"ThirdPreferenceCount\" FROM \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_STYLES\" AS ms LEFT JOIN \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_PREFERENCES\" AS mp ON ms.\"StyleID\" = mp.\"StyleID\" GROUP BY ms.\"StyleID\", ms.\"StyleName\" ORDER BY ms.\"StyleID\"") t0 t1
  = (sql%([MUSICAL_STYLES_schema, MUSICAL_PREFERENCES_schema]) "SELECT ms.\"StyleID\" AS \"StyleID\", ms.\"StyleName\" AS \"StyleName\", COALESCE(SUM(CASE WHEN mp.\"PreferenceSeq\" = 1 THEN 1 ELSE 0 END), 0) AS \"FirstPreferenceCount\", COALESCE(SUM(CASE WHEN mp.\"PreferenceSeq\" = 2 THEN 1 ELSE 0 END), 0) AS \"SecondPreferenceCount\", COALESCE(SUM(CASE WHEN mp.\"PreferenceSeq\" = 3 THEN 1 ELSE 0 END), 0) AS \"ThirdPreferenceCount\" FROM \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_STYLES\" AS ms LEFT JOIN \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_PREFERENCES\" AS mp ON ms.\"StyleID\" = mp.\"StyleID\" GROUP BY ms.\"StyleID\", ms.\"StyleName\" ORDER BY ms.\"StyleID\"") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local131_eq_0_1
