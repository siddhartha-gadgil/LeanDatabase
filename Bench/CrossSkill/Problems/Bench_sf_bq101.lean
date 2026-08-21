import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq101 — crossskill equivalence(s)

Question: From GitHub Repos contents, how can we identify the top 10 most frequently imported package names in Java source files by splitting each file's content into lines, filtering for valid import statements, extracting only the package portion using a suitable regex, grouping by these extracted package names, counting their occurrences, and finally returning the 10 packages that appear most often in descending order of frequency?

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq101

CREATE TABLE SAMPLE_CONTENTS («id» STRING, «size» INT, «content» STRING, «binary» BOOL, «copies» INT, «sample_repo_name» STRING, «sample_ref» STRING, «sample_path» STRING, «sample_mode» INT, «sample_symlink_target» STRING)

HYPOTHESIS hyp0_1_0 : SAMPLE_CONTENTS "\"sample_path\" LIKE '%.java'"
HYPOTHESIS hyp0_1_1 : SAMPLE_CONTENTS "LOWER(\"sample_path\") LIKE '%.java'"
theorem eq_0_1 (t : TableRel SAMPLE_CONTENTS_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) :
    (sql%([SAMPLE_CONTENTS_schema]) "SELECT \n  package_name AS \"PACKAGE_NAME\",\n  COUNT(*) AS \"IMPORT_COUNT\"\nFROM (\n  SELECT \n    CASE \n      WHEN TRIM(value) LIKE 'import static %' THEN\n        -- Static import: strip 'import static ', then remove last TWO dot-segments (class.method)\n        REGEXP_REPLACE(\n          REGEXP_REPLACE(\n            REGEXP_REPLACE(TRIM(value), '^import\\\\s+static\\\\s+', ''),\n            '\\\\.[^.]+;\\\\s*$', ''\n          ),\n          '\\\\.[^.]+$', ''\n        )\n      ELSE\n        -- Regular import: strip 'import ', then remove last ONE dot-segment (class)\n        REGEXP_REPLACE(\n          REGEXP_REPLACE(TRIM(value), '^import\\\\s+', ''),\n          '\\\\.[^.]+;\\\\s*$', ''\n        )\n    END AS package_name\n  FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\",\n    LATERAL SPLIT_TO_TABLE(\"content\", '\\n') \n  WHERE \"sample_path\" LIKE '%.java'\n    AND TRIM(value) LIKE 'import %'\n) sub\nWHERE package_name IS NOT NULL AND package_name != ''\nGROUP BY package_name\nORDER BY \"IMPORT_COUNT\" DESC\nLIMIT 10;") t ~= (sql%([SAMPLE_CONTENTS_schema]) "WITH java_imports AS (\n  SELECT\n    TRIM(line.VALUE::STRING) AS import_line\n  FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\" c,\n  LATERAL FLATTEN(INPUT => SPLIT(c.\"content\", '\\n')) AS line\n  WHERE LOWER(c.\"sample_path\") LIKE '%.java'\n    AND TRIM(line.VALUE::STRING) LIKE 'import %'\n),\ncleaned_imports AS (\n  SELECT\n    CASE\n      WHEN import_line LIKE 'import static %' THEN\n        -- static import: extract full_path, then strip last TWO segments (Class.method)\n        REGEXP_REPLACE(TRIM(REPLACE(SUBSTRING(import_line, 15), ';', '')), '\\\\s+', '')\n      ELSE\n        -- regular import: extract full_path, then strip last ONE segment (Class)\n        REGEXP_REPLACE(TRIM(REPLACE(SUBSTRING(import_line, 8), ';', '')), '\\\\s+', '')\n    END AS full_import,\n    CASE WHEN import_line LIKE 'import static %' THEN TRUE ELSE FALSE END AS is_static\n  FROM java_imports\n),\npackage_extracted AS (\n  SELECT\n    CASE\n      WHEN is_static AND ARRAY_SIZE(SPLIT(full_import, '.')) >= 3 THEN\n        -- For static imports, strip last 2 segments (class + method)\n        ARRAY_TO_STRING(\n          ARRAY_SLICE(\n            SPLIT(full_import, '.'),\n            0,\n            ARRAY_SIZE(SPLIT(full_import, '.')) - 2\n          ), '.'\n        )\n      WHEN CHARINDEX('.', full_import) > 0 THEN\n        -- For regular imports, strip last segment (class)\n        SUBSTRING(full_import, 1, LENGTH(full_import) - CHARINDEX('.', REVERSE(full_import)))\n      ELSE NULL\n    END AS PACKAGE_NAME\n  FROM cleaned_imports\n  WHERE CHARINDEX('.', full_import) > 0\n)\nSELECT\n  PACKAGE_NAME,\n  COUNT(*) AS IMPORT_COUNT\nFROM package_extracted\nWHERE PACKAGE_NAME IS NOT NULL AND PACKAGE_NAME != ''\nGROUP BY PACKAGE_NAME\nORDER BY IMPORT_COUNT DESC\nLIMIT 10;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq101
