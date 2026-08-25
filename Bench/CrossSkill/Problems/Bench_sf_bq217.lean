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
    (sql%([LANGUAGES_schema]) "WITH js_repos AS (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e JOIN js_repos AS j ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = j.\"repo_name\" WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t ~= (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e JOIN \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = l.\"repo_name\", LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened' AND CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript'") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : LANGUAGES "CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') AS js_repos ON CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS TEXT) = \"repo_name\" WHERE \"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(\"payload\" AS JSON), 'action') AS TEXT) = 'opened'"
theorem eq_0_2 (t : TableRel LANGUAGES_schema) (h0 : hyp0_2_0 t) :
    (sql%([LANGUAGES_schema]) "WITH js_repos AS (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e JOIN js_repos AS j ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = j.\"repo_name\" WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t ~= (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS \"TOTAL_PULL_REQUESTS\" FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS d JOIN (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') AS js_repos ON CAST(JSON_EXTRACT_PATH(d.\"repo\", 'name') AS TEXT) = js_repos.\"repo_name\" WHERE d.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(d.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : LANGUAGES "CAST(JSON_EXTRACT_PATH(lang.value, 'name') AS TEXT) = 'JavaScript') AS l ON CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS TEXT) = \"repo_name\" WHERE \"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(\"payload\" AS JSON), 'action') AS TEXT) = 'opened'"
theorem eq_0_3 (t : TableRel LANGUAGES_schema) (h0 : hyp0_3_0 t) :
    (sql%([LANGUAGES_schema]) "WITH js_repos AS (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e JOIN js_repos AS j ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = j.\"repo_name\" WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t ~= (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e INNER JOIN (SELECT DISTINCT \"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\", LATERAL UNNEST(input => CAST(\"language\" AS JSON)) AS lang(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(lang.value, 'name') AS TEXT) = 'JavaScript') AS l ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = l.\"repo_name\" WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : LANGUAGES "CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') AS js_repos ON CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS TEXT) = \"repo_name\" WHERE \"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(\"payload\" AS JSON), 'action') AS TEXT) = 'opened'"
theorem eq_1_2 (t : TableRel LANGUAGES_schema) (h0 : hyp1_2_0 t) :
    (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e JOIN \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = l.\"repo_name\", LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened' AND CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript'") t = (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS \"TOTAL_PULL_REQUESTS\" FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS d JOIN (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') AS js_repos ON CAST(JSON_EXTRACT_PATH(d.\"repo\", 'name') AS TEXT) = js_repos.\"repo_name\" WHERE d.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(d.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : LANGUAGES "CAST(JSON_EXTRACT_PATH(lang.value, 'name') AS TEXT) = 'JavaScript') AS l ON CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS TEXT) = \"repo_name\" WHERE \"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(\"payload\" AS JSON), 'action') AS TEXT) = 'opened'"
theorem eq_1_3 (t : TableRel LANGUAGES_schema) (h0 : hyp1_3_0 t) :
    (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e JOIN \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = l.\"repo_name\", LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened' AND CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript'") t = (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e INNER JOIN (SELECT DISTINCT \"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\", LATERAL UNNEST(input => CAST(\"language\" AS JSON)) AS lang(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(lang.value, 'name') AS TEXT) = 'JavaScript') AS l ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = l.\"repo_name\" WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : LANGUAGES "CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') AS js_repos ON CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS TEXT) = \"repo_name\" WHERE \"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(\"payload\" AS JSON), 'action') AS TEXT) = 'opened'"
HYPOTHESIS hyp2_3_1 : LANGUAGES "CAST(JSON_EXTRACT_PATH(lang.value, 'name') AS TEXT) = 'JavaScript') AS l ON CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS TEXT) = \"repo_name\" WHERE \"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(\"payload\" AS JSON), 'action') AS TEXT) = 'opened'"
theorem eq_2_3 (t : TableRel LANGUAGES_schema) (h0 : hyp2_3_0 t) (h1 : hyp2_3_1 t) :
    (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS \"TOTAL_PULL_REQUESTS\" FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS d JOIN (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') AS js_repos ON CAST(JSON_EXTRACT_PATH(d.\"repo\", 'name') AS TEXT) = js_repos.\"repo_name\" WHERE d.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(d.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t = (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e INNER JOIN (SELECT DISTINCT \"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\", LATERAL UNNEST(input => CAST(\"language\" AS JSON)) AS lang(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(lang.value, 'name') AS TEXT) = 'JavaScript') AS l ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = l.\"repo_name\" WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t := by
  first | sql_equiv | sorry

end Bench_sf_bq217
