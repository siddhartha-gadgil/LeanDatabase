import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq217 — crossskill equivalence(s)

Question: On January 18, 2023, how many pull request creation events occurred in GitHub repositories that include JavaScript as one of their programming languages? Use data from the githubarchive table for the events and the languages table for repository language information.

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq217

CREATE TABLE LANGUAGES («repo_name» STRING, «language» STRING)

theorem eq_0_1 : ∀ t,
    (sql%([LANGUAGES_schema]) "WITH js_repos AS (\n  SELECT DISTINCT l.\"repo_name\"\n  FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n  LATERAL FLATTEN(input => l.\"language\") f\n  WHERE f.value:name::STRING = 'JavaScript'\n)\nSELECT COUNT(*) AS TOTAL_PULL_REQUESTS\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" e\nJOIN js_repos j\n  ON e.\"repo\":\"name\"::STRING = j.\"repo_name\"\nWHERE e.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(e.\"payload\"):action::STRING = 'opened';") t ~= (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" e\nJOIN \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" l\n  ON e.\"repo\":\"name\"::STRING = l.\"repo_name\",\nLATERAL FLATTEN(input => l.\"language\") f\nWHERE e.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(e.\"payload\"):\"action\"::STRING = 'opened'\n  AND f.value:\"name\"::STRING = 'JavaScript';") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([LANGUAGES_schema]) "WITH js_repos AS (\n  SELECT DISTINCT l.\"repo_name\"\n  FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n  LATERAL FLATTEN(input => l.\"language\") f\n  WHERE f.value:name::STRING = 'JavaScript'\n)\nSELECT COUNT(*) AS TOTAL_PULL_REQUESTS\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" e\nJOIN js_repos j\n  ON e.\"repo\":\"name\"::STRING = j.\"repo_name\"\nWHERE e.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(e.\"payload\"):action::STRING = 'opened';") t ~= (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS \"TOTAL_PULL_REQUESTS\"\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" d\nJOIN (\n    SELECT DISTINCT l.\"repo_name\"\n    FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n    LATERAL FLATTEN(input => l.\"language\") f\n    WHERE f.value:\"name\"::STRING = 'JavaScript'\n) js_repos\nON d.\"repo\":\"name\"::STRING = js_repos.\"repo_name\"\nWHERE d.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(d.\"payload\"):\"action\"::STRING = 'opened';") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_3 : ∀ t,
    (sql%([LANGUAGES_schema]) "WITH js_repos AS (\n  SELECT DISTINCT l.\"repo_name\"\n  FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n  LATERAL FLATTEN(input => l.\"language\") f\n  WHERE f.value:name::STRING = 'JavaScript'\n)\nSELECT COUNT(*) AS TOTAL_PULL_REQUESTS\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" e\nJOIN js_repos j\n  ON e.\"repo\":\"name\"::STRING = j.\"repo_name\"\nWHERE e.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(e.\"payload\"):action::STRING = 'opened';") t ~= (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e\nINNER JOIN (\n    SELECT DISTINCT \"repo_name\"\n    FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\",\n    LATERAL FLATTEN(input => PARSE_JSON(\"language\")) AS lang\n    WHERE lang.value:name::STRING = 'JavaScript'\n) AS l\nON e.\"repo\":\"name\"::STRING = l.\"repo_name\"\nWHERE e.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(e.\"payload\"):action::STRING = 'opened';") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 :
    sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" e\nJOIN \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" l\n  ON e.\"repo\":\"name\"::STRING = l.\"repo_name\",\nLATERAL FLATTEN(input => l.\"language\") f\nWHERE e.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(e.\"payload\"):\"action\"::STRING = 'opened'\n  AND f.value:\"name\"::STRING = 'JavaScript';" = sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS \"TOTAL_PULL_REQUESTS\"\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" d\nJOIN (\n    SELECT DISTINCT l.\"repo_name\"\n    FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n    LATERAL FLATTEN(input => l.\"language\") f\n    WHERE f.value:\"name\"::STRING = 'JavaScript'\n) js_repos\nON d.\"repo\":\"name\"::STRING = js_repos.\"repo_name\"\nWHERE d.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(d.\"payload\"):\"action\"::STRING = 'opened';" := by
  first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" e\nJOIN \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" l\n  ON e.\"repo\":\"name\"::STRING = l.\"repo_name\",\nLATERAL FLATTEN(input => l.\"language\") f\nWHERE e.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(e.\"payload\"):\"action\"::STRING = 'opened'\n  AND f.value:\"name\"::STRING = 'JavaScript';" = sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e\nINNER JOIN (\n    SELECT DISTINCT \"repo_name\"\n    FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\",\n    LATERAL FLATTEN(input => PARSE_JSON(\"language\")) AS lang\n    WHERE lang.value:name::STRING = 'JavaScript'\n) AS l\nON e.\"repo\":\"name\"::STRING = l.\"repo_name\"\nWHERE e.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(e.\"payload\"):action::STRING = 'opened';" := by
  first | sql_equiv | sorry

theorem eq_2_3 :
    sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS \"TOTAL_PULL_REQUESTS\"\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" d\nJOIN (\n    SELECT DISTINCT l.\"repo_name\"\n    FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" l,\n    LATERAL FLATTEN(input => l.\"language\") f\n    WHERE f.value:\"name\"::STRING = 'JavaScript'\n) js_repos\nON d.\"repo\":\"name\"::STRING = js_repos.\"repo_name\"\nWHERE d.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(d.\"payload\"):\"action\"::STRING = 'opened';" = sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS\nFROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e\nINNER JOIN (\n    SELECT DISTINCT \"repo_name\"\n    FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\",\n    LATERAL FLATTEN(input => PARSE_JSON(\"language\")) AS lang\n    WHERE lang.value:name::STRING = 'JavaScript'\n) AS l\nON e.\"repo\":\"name\"::STRING = l.\"repo_name\"\nWHERE e.\"type\" = 'PullRequestEvent'\n  AND PARSE_JSON(e.\"payload\"):action::STRING = 'opened';" := by
  first | sql_equiv | sorry

end Bench_sf_bq217
