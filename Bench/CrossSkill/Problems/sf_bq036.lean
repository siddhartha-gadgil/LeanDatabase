import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq036 — crossskill equivalence(s)

Question: What was the average number of GitHub commits made per month in 2016 for repositories containing Python code?

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq036

CREATE TABLE LANGUAGES («repo_name» STRING, «language» STRING)
CREATE TABLE SAMPLE_COMMITS («commit» STRING, «tree» STRING, «parent» STRING, «author» STRING, «committer» STRING, «subject» STRING, «message» STRING, «trailer» STRING, «difference» STRING, «difference_truncated» BOOL, «repo_name» STRING, «encoding» STRING)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 :
    sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "SELECT CAST(COUNT(*) AS DOUBLE PRECISION) / 12.0 AS AVG_MONTHLY_COMMITS FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" AS c INNER JOIN (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'Python') AS python_repos ON c.\"repo_name\" = python_repos.\"repo_name\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(JSON_EXTRACT_PATH(c.\"author\", 'date') AS DECIMAL(38, 0)) / POWER(10, 6))) = 2016" = sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "/* Average number of GitHub commits per month in 2016 for repositories containing Python code */ /* \"Per month\" = total commits in 2016 / 12 (all months of the year, not just months with data) */ SELECT CAST(COUNT(*) AS DOUBLE PRECISION) / 12.0 AS \"AVG_MONTHLY_COMMITS\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" AS sc WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(JSON_EXTRACT_PATH(sc.\"author\", 'date') AS DECIMAL(38, 0)) / 1000000)) = 2016 AND sc.\"repo_name\" IN (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'Python')" := by
  first | sql_equiv | sorry

-- eq_0_2: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_2 : ∀ t,
    (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "SELECT CAST(COUNT(*) AS DOUBLE PRECISION) / 12.0 AS AVG_MONTHLY_COMMITS FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" AS c INNER JOIN (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'Python') AS python_repos ON c.\"repo_name\" = python_repos.\"repo_name\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(JSON_EXTRACT_PATH(c.\"author\", 'date') AS DECIMAL(38, 0)) / POWER(10, 6))) = 2016") t ~= (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "WITH python_repos AS (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'Python'), total_commits AS (SELECT COUNT(*) AS total_count FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" AS c INNER JOIN python_repos AS p ON c.\"repo_name\" = p.\"repo_name\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(JSON_EXTRACT_PATH(c.\"author\", 'date') AS DECIMAL(38, 0)) / POWER(10, 6))) = 2016) SELECT ROUND(CAST(CAST(total_count AS DOUBLE PRECISION) / 12.0 AS DECIMAL), 6) AS \"AVG_MONTHLY_COMMITS\" FROM total_commits") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "/* Average number of GitHub commits per month in 2016 for repositories containing Python code */ /* \"Per month\" = total commits in 2016 / 12 (all months of the year, not just months with data) */ SELECT CAST(COUNT(*) AS DOUBLE PRECISION) / 12.0 AS \"AVG_MONTHLY_COMMITS\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" AS sc WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(JSON_EXTRACT_PATH(sc.\"author\", 'date') AS DECIMAL(38, 0)) / 1000000)) = 2016 AND sc.\"repo_name\" IN (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'Python')") t ~= (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "WITH python_repos AS (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'Python'), total_commits AS (SELECT COUNT(*) AS total_count FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" AS c INNER JOIN python_repos AS p ON c.\"repo_name\" = p.\"repo_name\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(JSON_EXTRACT_PATH(c.\"author\", 'date') AS DECIMAL(38, 0)) / POWER(10, 6))) = 2016) SELECT ROUND(CAST(CAST(total_count AS DOUBLE PRECISION) / 12.0 AS DECIMAL), 6) AS \"AVG_MONTHLY_COMMITS\" FROM total_commits") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq036
