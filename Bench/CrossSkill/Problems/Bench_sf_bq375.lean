import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq375 — crossskill equivalence(s)

Question: Determine which file type among Python (.py), C (.c), Jupyter Notebook (.ipynb), Java (.java), and JavaScript (.js) in the GitHub codebase has the most files with a directory depth greater than 10, and provide the file count.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq375

CREATE TABLE SAMPLE_FILES («repo_name» STRING, «ref» STRING, «path» STRING, «mode» INT, «id» STRING, «symlink_target» STRING)

HYPOTHESIS hyp0_1_0 : SAMPLE_FILES "(\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js')"
HYPOTHESIS hyp0_1_1 : SAMPLE_FILES "REGEXP_COUNT(\"path\", '/') > 10"
HYPOTHESIS hyp0_1_2 : SAMPLE_FILES "(\n    \"path\" LIKE '%.py'\n    OR \"path\" LIKE '%.c'\n    OR \"path\" LIKE '%.ipynb'\n    OR \"path\" LIKE '%.java'\n    OR \"path\" LIKE '%.js'\n)"
HYPOTHESIS hyp0_1_3 : SAMPLE_FILES "(LENGTH(\"path\") - LENGTH(REPLACE(\"path\", '/', ''))) > 10"
theorem eq_0_1 (t : TableRel SAMPLE_FILES_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) (h2 : hyp0_1_2 t) (h3 : hyp0_1_3 t) :
    (sql%([SAMPLE_FILES_schema]) "SELECT \n  CASE \n    WHEN \"path\" LIKE '%.py' THEN 'Python'\n    WHEN \"path\" LIKE '%.c' THEN 'C'\n    WHEN \"path\" LIKE '%.ipynb' THEN 'Jupyter Notebook'\n    WHEN \"path\" LIKE '%.java' THEN 'Java'\n    WHEN \"path\" LIKE '%.js' THEN 'JavaScript'\n  END AS FILE_TYPE,\n  COUNT(*) AS FILE_COUNT\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\"\nWHERE (\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js')\n  AND REGEXP_COUNT(\"path\", '/') > 10\nGROUP BY FILE_TYPE\nORDER BY FILE_COUNT DESC\nLIMIT 1;") t = (sql%([SAMPLE_FILES_schema]) "SELECT\n    CASE\n        WHEN \"path\" LIKE '%.py' THEN '.py'\n        WHEN \"path\" LIKE '%.c' THEN '.c'\n        WHEN \"path\" LIKE '%.ipynb' THEN '.ipynb'\n        WHEN \"path\" LIKE '%.java' THEN '.java'\n        WHEN \"path\" LIKE '%.js' THEN '.js'\n    END AS FILE_TYPE,\n    COUNT(*) AS FILE_COUNT\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\"\nWHERE (\n    \"path\" LIKE '%.py'\n    OR \"path\" LIKE '%.c'\n    OR \"path\" LIKE '%.ipynb'\n    OR \"path\" LIKE '%.java'\n    OR \"path\" LIKE '%.js'\n)\nAND (LENGTH(\"path\") - LENGTH(REPLACE(\"path\", '/', ''))) > 10\nGROUP BY FILE_TYPE\nORDER BY FILE_COUNT DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : SAMPLE_FILES "(\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js')"
HYPOTHESIS hyp0_2_1 : SAMPLE_FILES "(\n    \"path\" LIKE '%.py'\n    OR \"path\" LIKE '%.c'\n    OR \"path\" LIKE '%.ipynb'\n    OR \"path\" LIKE '%.java'\n    OR \"path\" LIKE '%.js'\n  )"
theorem eq_0_2 (t : TableRel SAMPLE_FILES_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([SAMPLE_FILES_schema]) "SELECT \n  CASE \n    WHEN \"path\" LIKE '%.py' THEN 'Python'\n    WHEN \"path\" LIKE '%.c' THEN 'C'\n    WHEN \"path\" LIKE '%.ipynb' THEN 'Jupyter Notebook'\n    WHEN \"path\" LIKE '%.java' THEN 'Java'\n    WHEN \"path\" LIKE '%.js' THEN 'JavaScript'\n  END AS FILE_TYPE,\n  COUNT(*) AS FILE_COUNT\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\"\nWHERE (\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js')\n  AND REGEXP_COUNT(\"path\", '/') > 10\nGROUP BY FILE_TYPE\nORDER BY FILE_COUNT DESC\nLIMIT 1;") t = (sql%([SAMPLE_FILES_schema]) "SELECT\n    CASE\n        WHEN \"path\" LIKE '%.py' THEN 'Python'\n        WHEN \"path\" LIKE '%.c' THEN 'C'\n        WHEN \"path\" LIKE '%.ipynb' THEN 'Jupyter Notebook'\n        WHEN \"path\" LIKE '%.java' THEN 'Java'\n        WHEN \"path\" LIKE '%.js' THEN 'JavaScript'\n    END AS file_type,\n    COUNT(*) AS file_count\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\"\nWHERE REGEXP_COUNT(\"path\", '/') > 10\n  AND (\n    \"path\" LIKE '%.py'\n    OR \"path\" LIKE '%.c'\n    OR \"path\" LIKE '%.ipynb'\n    OR \"path\" LIKE '%.java'\n    OR \"path\" LIKE '%.js'\n  )\nGROUP BY file_type\nORDER BY file_count DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : SAMPLE_FILES "(\n    \"path\" LIKE '%.py'\n    OR \"path\" LIKE '%.c'\n    OR \"path\" LIKE '%.ipynb'\n    OR \"path\" LIKE '%.java'\n    OR \"path\" LIKE '%.js'\n)"
HYPOTHESIS hyp1_2_1 : SAMPLE_FILES "(LENGTH(\"path\") - LENGTH(REPLACE(\"path\", '/', ''))) > 10"
HYPOTHESIS hyp1_2_2 : SAMPLE_FILES "REGEXP_COUNT(\"path\", '/') > 10"
HYPOTHESIS hyp1_2_3 : SAMPLE_FILES "(\n    \"path\" LIKE '%.py'\n    OR \"path\" LIKE '%.c'\n    OR \"path\" LIKE '%.ipynb'\n    OR \"path\" LIKE '%.java'\n    OR \"path\" LIKE '%.js'\n  )"
theorem eq_1_2 (t : TableRel SAMPLE_FILES_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) (h2 : hyp1_2_2 t) (h3 : hyp1_2_3 t) :
    (sql%([SAMPLE_FILES_schema]) "SELECT\n    CASE\n        WHEN \"path\" LIKE '%.py' THEN '.py'\n        WHEN \"path\" LIKE '%.c' THEN '.c'\n        WHEN \"path\" LIKE '%.ipynb' THEN '.ipynb'\n        WHEN \"path\" LIKE '%.java' THEN '.java'\n        WHEN \"path\" LIKE '%.js' THEN '.js'\n    END AS FILE_TYPE,\n    COUNT(*) AS FILE_COUNT\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\"\nWHERE (\n    \"path\" LIKE '%.py'\n    OR \"path\" LIKE '%.c'\n    OR \"path\" LIKE '%.ipynb'\n    OR \"path\" LIKE '%.java'\n    OR \"path\" LIKE '%.js'\n)\nAND (LENGTH(\"path\") - LENGTH(REPLACE(\"path\", '/', ''))) > 10\nGROUP BY FILE_TYPE\nORDER BY FILE_COUNT DESC\nLIMIT 1;") t = (sql%([SAMPLE_FILES_schema]) "SELECT\n    CASE\n        WHEN \"path\" LIKE '%.py' THEN 'Python'\n        WHEN \"path\" LIKE '%.c' THEN 'C'\n        WHEN \"path\" LIKE '%.ipynb' THEN 'Jupyter Notebook'\n        WHEN \"path\" LIKE '%.java' THEN 'Java'\n        WHEN \"path\" LIKE '%.js' THEN 'JavaScript'\n    END AS file_type,\n    COUNT(*) AS file_count\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\"\nWHERE REGEXP_COUNT(\"path\", '/') > 10\n  AND (\n    \"path\" LIKE '%.py'\n    OR \"path\" LIKE '%.c'\n    OR \"path\" LIKE '%.ipynb'\n    OR \"path\" LIKE '%.java'\n    OR \"path\" LIKE '%.js'\n  )\nGROUP BY file_type\nORDER BY file_count DESC\nLIMIT 1;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq375
