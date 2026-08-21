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

theorem eq_0_1 :
    sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "SELECT\n  COUNT(*) / 12.0 AS AVG_MONTHLY_COMMITS\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" c\nINNER JOIN (\n  SELECT DISTINCT l.\"repo_name\"\n  FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n  LATERAL FLATTEN(input => l.\"language\") f\n  WHERE f.value:name::STRING = 'Python'\n) python_repos\n  ON c.\"repo_name\" = python_repos.\"repo_name\"\nWHERE EXTRACT(YEAR FROM TO_TIMESTAMP(c.\"author\":date::NUMBER, 6)) = 2016;" = sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "-- Average number of GitHub commits per month in 2016 for repositories containing Python code\n-- \"Per month\" = total commits in 2016 / 12 (all months of the year, not just months with data)\nSELECT \n  COUNT(*) / 12.0 AS \"AVG_MONTHLY_COMMITS\"\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" sc\nWHERE EXTRACT(YEAR FROM TO_TIMESTAMP(sc.\"author\":date::NUMBER / 1000000)) = 2016\n  AND sc.\"repo_name\" IN (\n    SELECT DISTINCT l.\"repo_name\"\n    FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n    LATERAL FLATTEN(input => l.\"language\") f\n    WHERE f.value:name::STRING = 'Python'\n  );" := by
  first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "SELECT\n  COUNT(*) / 12.0 AS AVG_MONTHLY_COMMITS\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" c\nINNER JOIN (\n  SELECT DISTINCT l.\"repo_name\"\n  FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n  LATERAL FLATTEN(input => l.\"language\") f\n  WHERE f.value:name::STRING = 'Python'\n) python_repos\n  ON c.\"repo_name\" = python_repos.\"repo_name\"\nWHERE EXTRACT(YEAR FROM TO_TIMESTAMP(c.\"author\":date::NUMBER, 6)) = 2016;") t ~= (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "WITH python_repos AS (\n    SELECT DISTINCT l.\"repo_name\"\n    FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n    LATERAL FLATTEN(input => l.\"language\") f\n    WHERE f.value:\"name\"::STRING = 'Python'\n),\ntotal_commits AS (\n    SELECT COUNT(*) AS total_count\n    FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" c\n    INNER JOIN python_repos p ON c.\"repo_name\" = p.\"repo_name\"\n    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(c.\"author\":\"date\"::NUMBER, 6)) = 2016\n)\nSELECT ROUND(total_count / 12.0, 6) AS \"AVG_MONTHLY_COMMITS\"\nFROM total_commits;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "-- Average number of GitHub commits per month in 2016 for repositories containing Python code\n-- \"Per month\" = total commits in 2016 / 12 (all months of the year, not just months with data)\nSELECT \n  COUNT(*) / 12.0 AS \"AVG_MONTHLY_COMMITS\"\nFROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" sc\nWHERE EXTRACT(YEAR FROM TO_TIMESTAMP(sc.\"author\":date::NUMBER / 1000000)) = 2016\n  AND sc.\"repo_name\" IN (\n    SELECT DISTINCT l.\"repo_name\"\n    FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n    LATERAL FLATTEN(input => l.\"language\") f\n    WHERE f.value:name::STRING = 'Python'\n  );") t ~= (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "WITH python_repos AS (\n    SELECT DISTINCT l.\"repo_name\"\n    FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n    LATERAL FLATTEN(input => l.\"language\") f\n    WHERE f.value:\"name\"::STRING = 'Python'\n),\ntotal_commits AS (\n    SELECT COUNT(*) AS total_count\n    FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" c\n    INNER JOIN python_repos p ON c.\"repo_name\" = p.\"repo_name\"\n    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(c.\"author\":\"date\"::NUMBER, 6)) = 2016\n)\nSELECT ROUND(total_count / 12.0, 6) AS \"AVG_MONTHLY_COMMITS\"\nFROM total_commits;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq036
