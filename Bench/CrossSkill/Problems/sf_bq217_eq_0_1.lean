import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq217_eq_0_1

CREATE TABLE LANGUAGES («repo_name» STRING, «language» STRING)

theorem eq (t0 : TableRel LANGUAGES_schema) :
    (sql%([LANGUAGES_schema]) "WITH js_repos AS (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript') SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e JOIN js_repos AS j ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = j.\"repo_name\" WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened'") t0
  ~= (sql%([LANGUAGES_schema]) "SELECT COUNT(*) AS TOTAL_PULL_REQUESTS FROM \"GITHUB_REPOS_DATE\".\"DAY\".\"_20230118\" AS e JOIN \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l ON CAST(JSON_EXTRACT_PATH(e.\"repo\", 'name') AS TEXT) = l.\"repo_name\", LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE e.\"type\" = 'PullRequestEvent' AND CAST(JSON_EXTRACT_PATH(CAST(e.\"payload\" AS JSON), 'action') AS TEXT) = 'opened' AND CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'JavaScript'") t0
  := by first | sql_equiv | sorry

end N_sf_bq217_eq_0_1
