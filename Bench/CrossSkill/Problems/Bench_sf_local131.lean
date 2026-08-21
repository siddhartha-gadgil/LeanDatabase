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
    sql%([MUSICAL_STYLES_schema, MUSICAL_PREFERENCES_schema]) "SELECT \n  ms.\"StyleID\",\n  ms.\"StyleName\",\n  SUM(CASE WHEN mp.\"PreferenceSeq\" = 1 THEN 1 ELSE 0 END) AS \"FirstPreferenceCount\",\n  SUM(CASE WHEN mp.\"PreferenceSeq\" = 2 THEN 1 ELSE 0 END) AS \"SecondPreferenceCount\",\n  SUM(CASE WHEN mp.\"PreferenceSeq\" = 3 THEN 1 ELSE 0 END) AS \"ThirdPreferenceCount\"\nFROM \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_STYLES\" ms\nLEFT JOIN \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_PREFERENCES\" mp\n  ON ms.\"StyleID\" = mp.\"StyleID\"\nGROUP BY ms.\"StyleID\", ms.\"StyleName\"\nORDER BY ms.\"StyleID\";" = sql%([MUSICAL_STYLES_schema, MUSICAL_PREFERENCES_schema]) "SELECT\n    ms.\"StyleID\" AS \"StyleID\",\n    ms.\"StyleName\" AS \"StyleName\",\n    COALESCE(SUM(CASE WHEN mp.\"PreferenceSeq\" = 1 THEN 1 ELSE 0 END), 0) AS \"FirstPreferenceCount\",\n    COALESCE(SUM(CASE WHEN mp.\"PreferenceSeq\" = 2 THEN 1 ELSE 0 END), 0) AS \"SecondPreferenceCount\",\n    COALESCE(SUM(CASE WHEN mp.\"PreferenceSeq\" = 3 THEN 1 ELSE 0 END), 0) AS \"ThirdPreferenceCount\"\nFROM \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_STYLES\" ms\nLEFT JOIN \"ENTERTAINMENTAGENCY\".\"ENTERTAINMENTAGENCY\".\"MUSICAL_PREFERENCES\" mp\n    ON ms.\"StyleID\" = mp.\"StyleID\"\nGROUP BY ms.\"StyleID\", ms.\"StyleName\"\nORDER BY ms.\"StyleID\";" := by
  first | sql_equiv | sorry

end Bench_sf_local131
