import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq180 — crossskill equivalence(s)

Question: Get the top 5 most frequently used module names from Python (`.py`) and R (`.r`) scripts, counting occurrences of modules in `import` and `from` statements for Python, and `library()` calls for R. The query should consider only Python and R files, group by module name, and return the top 5 modules ordered by frequency.

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq180

CREATE TABLE SAMPLE_CONTENTS («id» STRING, «size» INT, «content» STRING, «binary» BOOL, «copies» INT, «sample_repo_name» STRING, «sample_ref» STRING, «sample_path» STRING, «sample_mode» INT, «sample_symlink_target» STRING)

HYPOTHESIS hyp0_1_0 : SAMPLE_CONTENTS "LOWER(\"sample_path\") LIKE '%.py'"
theorem eq_0_1 (t : TableRel SAMPLE_CONTENTS_schema) (h0 : hyp0_1_0 t) :
    (sql%([SAMPLE_CONTENTS_schema]) "WITH python_imports AS (\n  SELECT COALESCE(\n    REGEXP_SUBSTR(LTRIM(f.value::STRING, ' \\t'), '^import\\\\s+(\\\\w+)', 1, 1, 'e'),\n    REGEXP_SUBSTR(LTRIM(f.value::STRING, ' \\t'), '^from\\\\s+(\\\\w+)', 1, 1, 'e')\n  ) AS module_name\n  FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\",\n    LATERAL FLATTEN(input => SPLIT(\"content\", '\\n')) f\n  WHERE LOWER(\"sample_path\") LIKE '%.py'\n  AND (LTRIM(f.value::STRING, ' \\t') LIKE 'import %' OR LTRIM(f.value::STRING, ' \\t') LIKE 'from %')\n),\nr_imports AS (\n  SELECT REGEXP_SUBSTR(f.value::STRING, 'library\\\\((\\\\w+)', 1, 1, 'e') AS module_name\n  FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\",\n    LATERAL FLATTEN(input => SPLIT(\"content\", '\\n')) f\n  WHERE LOWER(\"sample_path\") LIKE '%.r'\n  AND f.value::STRING LIKE '%library(%'\n),\nall_imports AS (\n  SELECT module_name FROM python_imports WHERE module_name IS NOT NULL\n  UNION ALL\n  SELECT module_name FROM r_imports WHERE module_name IS NOT NULL\n)\nSELECT module_name, COUNT(*) AS frequency\nFROM all_imports\nGROUP BY module_name\nORDER BY frequency DESC\nLIMIT 5;") t ~= (sql%([SAMPLE_CONTENTS_schema]) "WITH py_import AS (\n  SELECT TRIM(module.VALUE::STRING) AS module_name\n  FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\",\n    LATERAL FLATTEN(REGEXP_SUBSTR_ALL(\"content\", '^\\\\s*import\\\\s+([a-zA-Z_][a-zA-Z0-9_]*)', 1, 1, 'me', 1)) AS module\n  WHERE LOWER(\"sample_path\") LIKE '%.py'\n),\npy_from AS (\n  SELECT TRIM(module.VALUE::STRING) AS module_name\n  FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\",\n    LATERAL FLATTEN(REGEXP_SUBSTR_ALL(\"content\", '^\\\\s*from\\\\s+([a-zA-Z_][a-zA-Z0-9_]*)', 1, 1, 'me', 1)) AS module\n  WHERE LOWER(\"sample_path\") LIKE '%.py'\n),\nr_lib AS (\n  SELECT TRIM(module.VALUE::STRING) AS module_name\n  FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\",\n    LATERAL FLATTEN(REGEXP_SUBSTR_ALL(\"content\", 'library\\\\(([a-zA-Z_][a-zA-Z0-9_.]*)', 1, 1, 'e')) AS module\n  WHERE LOWER(\"sample_path\") LIKE '%.r'\n),\nall_modules AS (\n  SELECT module_name FROM py_import\n  UNION ALL SELECT module_name FROM py_from\n  UNION ALL SELECT module_name FROM r_lib\n)\nSELECT module_name AS MODULE, COUNT(*) AS FREQUENCY\nFROM all_modules\nGROUP BY module_name\nORDER BY FREQUENCY DESC\nLIMIT 5;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq180
