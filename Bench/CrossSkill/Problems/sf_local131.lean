import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local131 — crossskill equivalence(s)

Question: Could you list each musical style with the number of times it appears as a 1st, 2nd, or 3rd preference in a single row per style?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local131

CREATE TABLE MUSICAL_STYLES («StyleID» INT, «StyleName» STRING)
CREATE TABLE MUSICAL_PREFERENCES («CustomerID» INT, «StyleID» INT, «PreferenceSeq» INT)

theorem eq_0_1 :
    sql%([MUSICAL_STYLES_schema, MUSICAL_PREFERENCES_schema]) "SELECT ms.\"StyleID\", ms.\"StyleName\", SUM(CASE WHEN mp.\"PreferenceSeq\" = 1 THEN 1 ELSE 0 END) AS \"FirstPreferenceCount\", SUM(CASE WHEN mp.\"PreferenceSeq\" = 2 THEN 1 ELSE 0 END) AS \"SecondPreferenceCount\", SUM(CASE WHEN mp.\"PreferenceSeq\" = 3 THEN 1 ELSE 0 END) AS \"ThirdPreferenceCount\" FROM \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_STYLES\" AS ms LEFT JOIN \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_PREFERENCES\" AS mp ON ms.\"StyleID\" = mp.\"StyleID\" GROUP BY ms.\"StyleID\", ms.\"StyleName\" ORDER BY ms.\"StyleID\"" = sql%([MUSICAL_STYLES_schema, MUSICAL_PREFERENCES_schema]) "SELECT ms.\"StyleID\" AS \"StyleID\", ms.\"StyleName\" AS \"StyleName\", COALESCE(SUM(CASE WHEN mp.\"PreferenceSeq\" = 1 THEN 1 ELSE 0 END), 0) AS \"FirstPreferenceCount\", COALESCE(SUM(CASE WHEN mp.\"PreferenceSeq\" = 2 THEN 1 ELSE 0 END), 0) AS \"SecondPreferenceCount\", COALESCE(SUM(CASE WHEN mp.\"PreferenceSeq\" = 3 THEN 1 ELSE 0 END), 0) AS \"ThirdPreferenceCount\" FROM \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_STYLES\" AS ms LEFT JOIN \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_PREFERENCES\" AS mp ON ms.\"StyleID\" = mp.\"StyleID\" GROUP BY ms.\"StyleID\", ms.\"StyleName\" ORDER BY ms.\"StyleID\"" := by
  first | sql_equiv | sorry

end Bench_sf_local131
