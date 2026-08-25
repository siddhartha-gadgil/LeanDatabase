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

HYPOTHESIS hyp0_1_0 : SAMPLE_FILES "REGEXP_COUNT(\"path\", '/') > 10"
HYPOTHESIS hyp0_1_1 : SAMPLE_FILES "(LENGTH(\"path\") - LENGTH(REPLACE(\"path\", '/', ''))) > 10"
theorem eq_0_1 (t : TableRel SAMPLE_FILES_schema) (h0 : hyp0_1_0 t) (h1 : hyp0_1_1 t) :
    (sql%([SAMPLE_FILES_schema]) "SELECT CASE WHEN \"path\" LIKE '%.py' THEN 'Python' WHEN \"path\" LIKE '%.c' THEN 'C' WHEN \"path\" LIKE '%.ipynb' THEN 'Jupyter Notebook' WHEN \"path\" LIKE '%.java' THEN 'Java' WHEN \"path\" LIKE '%.js' THEN 'JavaScript' END AS FILE_TYPE, COUNT(*) AS FILE_COUNT FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\" WHERE (\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js') AND REGEXP_COUNT(\"path\", '/') > 10 GROUP BY FILE_TYPE ORDER BY FILE_COUNT DESC LIMIT 1") t = (sql%([SAMPLE_FILES_schema]) "SELECT CASE WHEN \"path\" LIKE '%.py' THEN '.py' WHEN \"path\" LIKE '%.c' THEN '.c' WHEN \"path\" LIKE '%.ipynb' THEN '.ipynb' WHEN \"path\" LIKE '%.java' THEN '.java' WHEN \"path\" LIKE '%.js' THEN '.js' END AS FILE_TYPE, COUNT(*) AS FILE_COUNT FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\" WHERE (\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js') AND (LENGTH(\"path\") - LENGTH(REPLACE(\"path\", '/', ''))) > 10 GROUP BY FILE_TYPE ORDER BY FILE_COUNT DESC LIMIT 1") t := by
  first | sql_equiv | sorry

theorem eq_0_2 :
    sql%([SAMPLE_FILES_schema]) "SELECT CASE WHEN \"path\" LIKE '%.py' THEN 'Python' WHEN \"path\" LIKE '%.c' THEN 'C' WHEN \"path\" LIKE '%.ipynb' THEN 'Jupyter Notebook' WHEN \"path\" LIKE '%.java' THEN 'Java' WHEN \"path\" LIKE '%.js' THEN 'JavaScript' END AS FILE_TYPE, COUNT(*) AS FILE_COUNT FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\" WHERE (\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js') AND REGEXP_COUNT(\"path\", '/') > 10 GROUP BY FILE_TYPE ORDER BY FILE_COUNT DESC LIMIT 1" = sql%([SAMPLE_FILES_schema]) "SELECT CASE WHEN \"path\" LIKE '%.py' THEN 'Python' WHEN \"path\" LIKE '%.c' THEN 'C' WHEN \"path\" LIKE '%.ipynb' THEN 'Jupyter Notebook' WHEN \"path\" LIKE '%.java' THEN 'Java' WHEN \"path\" LIKE '%.js' THEN 'JavaScript' END AS file_type, COUNT(*) AS file_count FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\" WHERE REGEXP_COUNT(\"path\", '/') > 10 AND (\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js') GROUP BY file_type ORDER BY file_count DESC LIMIT 1" := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : SAMPLE_FILES "(LENGTH(\"path\") - LENGTH(REPLACE(\"path\", '/', ''))) > 10"
HYPOTHESIS hyp1_2_1 : SAMPLE_FILES "REGEXP_COUNT(\"path\", '/') > 10"
theorem eq_1_2 (t : TableRel SAMPLE_FILES_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) :
    (sql%([SAMPLE_FILES_schema]) "SELECT CASE WHEN \"path\" LIKE '%.py' THEN '.py' WHEN \"path\" LIKE '%.c' THEN '.c' WHEN \"path\" LIKE '%.ipynb' THEN '.ipynb' WHEN \"path\" LIKE '%.java' THEN '.java' WHEN \"path\" LIKE '%.js' THEN '.js' END AS FILE_TYPE, COUNT(*) AS FILE_COUNT FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\" WHERE (\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js') AND (LENGTH(\"path\") - LENGTH(REPLACE(\"path\", '/', ''))) > 10 GROUP BY FILE_TYPE ORDER BY FILE_COUNT DESC LIMIT 1") t = (sql%([SAMPLE_FILES_schema]) "SELECT CASE WHEN \"path\" LIKE '%.py' THEN 'Python' WHEN \"path\" LIKE '%.c' THEN 'C' WHEN \"path\" LIKE '%.ipynb' THEN 'Jupyter Notebook' WHEN \"path\" LIKE '%.java' THEN 'Java' WHEN \"path\" LIKE '%.js' THEN 'JavaScript' END AS file_type, COUNT(*) AS file_count FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_FILES\" WHERE REGEXP_COUNT(\"path\", '/') > 10 AND (\"path\" LIKE '%.py' OR \"path\" LIKE '%.c' OR \"path\" LIKE '%.ipynb' OR \"path\" LIKE '%.java' OR \"path\" LIKE '%.js') GROUP BY file_type ORDER BY file_count DESC LIMIT 1") t := by
  first | sql_equiv | sorry

end Bench_sf_bq375
