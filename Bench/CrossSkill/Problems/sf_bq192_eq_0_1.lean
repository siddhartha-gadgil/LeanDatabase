import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq192_eq_0_1

CREATE TABLE SAMPLE_FILES («repo_name» STRING, «ref» STRING, «path» STRING, «mode» INT, «id» STRING, «symlink_target» STRING)
CREATE TABLE LICENSES («repo_name» STRING, «license» STRING)
CREATE TABLE _202204 («type» STRING, «public» BOOL, «payload» STRING, «repo» STRING, «actor» STRING, «org» STRING, «created_at» INT, «id» STRING, «other» STRING)

theorem eq (t0 : TableRel SAMPLE_FILES_schema) (t1 : TableRel LICENSES_schema) (t2 : TableRel _202204_schema) :
    (sql%([SAMPLE_FILES_schema, LICENSES_schema, _202204_schema]) "WITH python_repos AS (SELECT DISTINCT \"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"SAMPLE_FILES\" WHERE \"ref\" = 'refs/heads/master' AND \"path\" LIKE '%.py'), licensed_repos AS (SELECT DISTINCT \"repo_name\" FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LICENSES\" WHERE \"license\" IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')), watches AS (SELECT CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS TEXT) AS repo_name, COUNT(*) AS watch_count FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\" WHERE \"type\" = 'WatchEvent' GROUP BY 1), issues AS (SELECT CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS TEXT) AS repo_name, COUNT(*) AS issue_count FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\" WHERE \"type\" = 'IssuesEvent' GROUP BY 1), forks AS (SELECT CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS TEXT) AS repo_name, COUNT(*) AS fork_count FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\" WHERE \"type\" = 'ForkEvent' GROUP BY 1) SELECT w.repo_name AS REPO_NAME, COALESCE(f.fork_count, 0) + COALESCE(i.issue_count, 0) + COALESCE(w.watch_count, 0) AS TOTAL_ACTIVITY FROM watches AS w LEFT JOIN issues AS i ON w.repo_name = i.repo_name LEFT JOIN forks AS f ON w.repo_name = f.repo_name INNER JOIN python_repos AS p ON w.repo_name = p.\"repo_name\" INNER JOIN licensed_repos AS l ON w.repo_name = l.\"repo_name\" ORDER BY TOTAL_ACTIVITY DESC LIMIT 1") t0 t1 t2
  = (sql%([SAMPLE_FILES_schema, LICENSES_schema, _202204_schema]) "WITH python_repos AS (SELECT DISTINCT sf.\"repo_name\" AS repo_name FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"SAMPLE_FILES\" AS sf JOIN \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LICENSES\" AS l ON sf.\"repo_name\" = l.\"repo_name\" WHERE LOWER(sf.\"path\") LIKE '%.py' AND LOWER(l.\"license\") IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')), watches AS (SELECT CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS VARCHAR) AS repo_name, COUNT(*) AS num_watches FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\" WHERE \"type\" = 'WatchEvent' GROUP BY repo_name), issues AS (SELECT CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS VARCHAR) AS repo_name, COUNT(*) AS num_issues FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\" WHERE \"type\" = 'IssuesEvent' GROUP BY repo_name), forks AS (SELECT CAST(JSON_EXTRACT_PATH(\"repo\", 'name') AS VARCHAR) AS repo_name, COUNT(*) AS num_forks FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\" WHERE \"type\" = 'ForkEvent' GROUP BY repo_name) SELECT p.repo_name AS \"REPO_NAME\", COALESCE(w.num_watches, 0) + COALESCE(i.num_issues, 0) + COALESCE(f.num_forks, 0) AS \"TOTAL_ACTIVITY\" FROM python_repos AS p LEFT JOIN watches AS w ON p.repo_name = w.repo_name LEFT JOIN issues AS i ON p.repo_name = i.repo_name LEFT JOIN forks AS f ON p.repo_name = f.repo_name ORDER BY \"TOTAL_ACTIVITY\" DESC LIMIT 1") t0 t1 t2
  := by first | sql_equiv | sorry

end N_sf_bq192_eq_0_1
