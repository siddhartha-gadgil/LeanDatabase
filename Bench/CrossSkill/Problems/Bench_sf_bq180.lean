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
    (sql%([SAMPLE_CONTENTS_schema]) "WITH python_imports AS (SELECT COALESCE(REGEXP_EXTRACT(TRIM(LEADING ' 	' FROM CAST(f.value AS TEXT)), '^import\\s+(\\w+)', 1, 1, 'e', 0), REGEXP_EXTRACT(TRIM(LEADING ' 	' FROM CAST(f.value AS TEXT)), '^from\\s+(\\w+)', 1, 1, 'e', 0)) AS module_name FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\", LATERAL UNNEST(input => SPLIT(\"content\", '\n')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE LOWER(\"sample_path\") LIKE '%.py' AND (TRIM(LEADING ' 	' FROM CAST(f.value AS TEXT)) LIKE 'import %' OR TRIM(LEADING ' 	' FROM CAST(f.value AS TEXT)) LIKE 'from %')), r_imports AS (SELECT REGEXP_EXTRACT(CAST(f.value AS TEXT), 'library\\((\\w+)', 1, 1, 'e', 0) AS module_name FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\", LATERAL UNNEST(input => SPLIT(\"content\", '\n')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE LOWER(\"sample_path\") LIKE '%.r' AND CAST(f.value AS TEXT) LIKE '%library(%'), all_imports AS (SELECT module_name FROM python_imports WHERE NOT module_name IS NULL UNION ALL SELECT module_name FROM r_imports WHERE NOT module_name IS NULL) SELECT module_name, COUNT(*) AS frequency FROM all_imports GROUP BY module_name ORDER BY frequency DESC LIMIT 5") t ~= (sql%([SAMPLE_CONTENTS_schema]) "WITH py_import AS (SELECT TRIM(CAST(module.VALUE AS TEXT)) AS module_name FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\", LATERAL UNNEST(REGEXP_EXTRACT_ALL(\"content\", '^\\s*import\\s+([a-zA-Z_][a-zA-Z0-9_]*)', 1, 'me', 1, 1)) AS module(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE LOWER(\"sample_path\") LIKE '%.py'), py_from AS (SELECT TRIM(CAST(module.VALUE AS TEXT)) AS module_name FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\", LATERAL UNNEST(REGEXP_EXTRACT_ALL(\"content\", '^\\s*from\\s+([a-zA-Z_][a-zA-Z0-9_]*)', 1, 'me', 1, 1)) AS module(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE LOWER(\"sample_path\") LIKE '%.py'), r_lib AS (SELECT TRIM(CAST(module.VALUE AS TEXT)) AS module_name FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\", LATERAL UNNEST(REGEXP_EXTRACT_ALL(\"content\", 'library\\(([a-zA-Z_][a-zA-Z0-9_.]*)', 0, 'e', 1, 1)) AS module(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE LOWER(\"sample_path\") LIKE '%.r'), all_modules AS (SELECT module_name FROM py_import UNION ALL SELECT module_name FROM py_from UNION ALL SELECT module_name FROM r_lib) SELECT module_name AS MODULE, COUNT(*) AS FREQUENCY FROM all_modules GROUP BY module_name ORDER BY FREQUENCY DESC LIMIT 5") t := by
  first | sql_equiv | sorry

end Bench_sf_bq180
