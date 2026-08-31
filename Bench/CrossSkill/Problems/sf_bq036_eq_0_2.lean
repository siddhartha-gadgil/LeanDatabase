import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq036_eq_0_2

CREATE TABLE LANGUAGES («repo_name» STRING, «language» STRING)
CREATE TABLE SAMPLE_COMMITS («commit» STRING, «tree» STRING, «parent» STRING, «author» STRING, «committer» STRING, «subject» STRING, «message» STRING, «trailer» STRING, «difference» STRING, «difference_truncated» BOOL, «repo_name» STRING, «encoding» STRING)

theorem eq (t0 : TableRel LANGUAGES_schema) (t1 : TableRel SAMPLE_COMMITS_schema) :
    (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "SELECT CAST(COUNT(*) AS DOUBLE PRECISION) / 12.0 AS AVG_MONTHLY_COMMITS FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" AS c INNER JOIN (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'Python') AS python_repos ON c.\"repo_name\" = python_repos.\"repo_name\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(JSON_EXTRACT_PATH(c.\"author\", 'date') AS DECIMAL(38, 0)) / POWER(10, 6))) = 2016") t0 t1
  ~= (sql%([LANGUAGES_schema, SAMPLE_COMMITS_schema]) "WITH python_repos AS (SELECT DISTINCT l.\"repo_name\" FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"LANGUAGES\" AS l, LATERAL UNNEST(input => l.\"language\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(f.value, 'name') AS TEXT) = 'Python'), total_commits AS (SELECT COUNT(*) AS total_count FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_COMMITS\" AS c INNER JOIN python_repos AS p ON c.\"repo_name\" = p.\"repo_name\" WHERE EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(JSON_EXTRACT_PATH(c.\"author\", 'date') AS DECIMAL(38, 0)) / POWER(10, 6))) = 2016) SELECT ROUND(CAST(CAST(total_count AS DOUBLE PRECISION) / 12.0 AS DECIMAL), 6) AS \"AVG_MONTHLY_COMMITS\" FROM total_commits") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq036_eq_0_2
