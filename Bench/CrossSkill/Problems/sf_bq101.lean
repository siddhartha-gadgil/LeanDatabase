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
    (sql%([SAMPLE_CONTENTS_schema]) "SELECT package_name AS \"PACKAGE_NAME\", COUNT(*) AS \"IMPORT_COUNT\" FROM (SELECT CASE WHEN TRIM(value) LIKE 'import static %' THEN REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(value), '^import\\s+static\\s+', '', 'g'), '\\.[^.]+;\\s*$', '', 'g'), '\\.[^.]+$', '', 'g') /* Static import: strip 'import static ', then remove last TWO dot-segments (class.method) */ ELSE REGEXP_REPLACE(REGEXP_REPLACE(TRIM(value), '^import\\s+', '', 'g'), '\\.[^.]+;\\s*$', '', 'g') /* Regular import: strip 'import ', then remove last ONE dot-segment (class) */ END AS package_name FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\", LATERAL SPLIT_TO_TABLE(\"content\", '\n') WHERE \"sample_path\" LIKE '%.java' AND TRIM(value) LIKE 'import %') AS sub WHERE NOT package_name IS NULL AND package_name <> '' GROUP BY package_name ORDER BY \"IMPORT_COUNT\" DESC LIMIT 10") t ~= (sql%([SAMPLE_CONTENTS_schema]) "WITH java_imports AS (SELECT TRIM(CAST(line.VALUE AS TEXT)) AS import_line FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\" AS c, LATERAL UNNEST(INPUT => SPLIT(c.\"content\", '\n')) AS line(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE LOWER(c.\"sample_path\") LIKE '%.java' AND TRIM(CAST(line.VALUE AS TEXT)) LIKE 'import %'), cleaned_imports AS (SELECT CASE WHEN import_line LIKE 'import static %' THEN REGEXP_REPLACE(TRIM(REPLACE(SUBSTRING(import_line FROM 15), ';', '')), '\\s+', '', 'g') /* static import: extract full_path, then strip last TWO segments (Class.method) */ ELSE REGEXP_REPLACE(TRIM(REPLACE(SUBSTRING(import_line FROM 8), ';', '')), '\\s+', '', 'g') /* regular import: extract full_path, then strip last ONE segment (Class) */ END AS full_import, CASE WHEN import_line LIKE 'import static %' THEN TRUE ELSE FALSE END AS is_static FROM java_imports), package_extracted AS (SELECT CASE WHEN is_static AND ARRAY_LENGTH(SPLIT(full_import, '.'), 1) >= 3 THEN ARRAY_TO_STRING(ARRAY_SLICE(SPLIT(full_import, '.'), 0, ARRAY_LENGTH(SPLIT(full_import, '.'), 1) - 2), '.') /* For static imports, strip last 2 segments (class + method) */ WHEN POSITION('.' IN full_import) > 0 THEN SUBSTRING(full_import FROM 1 FOR LENGTH(full_import) - POSITION('.' IN REVERSE(full_import))) /* For regular imports, strip last segment (class) */ ELSE NULL END AS PACKAGE_NAME FROM cleaned_imports WHERE POSITION('.' IN full_import) > 0) SELECT PACKAGE_NAME, COUNT(*) AS IMPORT_COUNT FROM package_extracted WHERE NOT PACKAGE_NAME IS NULL AND PACKAGE_NAME <> '' GROUP BY PACKAGE_NAME ORDER BY IMPORT_COUNT DESC LIMIT 10") t := by
  first | sql_equiv | sorry

end Bench_sf_bq101
