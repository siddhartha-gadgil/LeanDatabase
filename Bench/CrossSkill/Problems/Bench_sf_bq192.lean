import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq192 — crossskill equivalence(s)

Question: Find the most active Python repository on GitHub based on watcher count, issues, and forks. The query should select repositories with specific open-source licenses (`artistic-2.0`, `isc`, `mit`, `apache-2.0`), count distinct watchers, issue events, and forks for each repository in April 2022, and include only those with `.py` files on the `master` branch. Join the license data with watch counts, issue events, and fork counts, then sort by a combined metric of forks, issues, and watches, returning the name and count of the most active repository.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq192

CREATE TABLE SAMPLE_FILES («repo_name» STRING, «ref» STRING, «path» STRING, «mode» INT, «id» STRING, «symlink_target» STRING)
CREATE TABLE LICENSES («repo_name» STRING, «license» STRING)
CREATE TABLE _202204 («type» STRING, «public» BOOL, «payload» STRING, «repo» STRING, «actor» STRING, «org» STRING, «created_at» INT, «id» STRING, «other» STRING)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 :
    sql%([SAMPLE_FILES_schema, LICENSES_schema, _202204_schema]) "WITH python_repos AS (\n  SELECT DISTINCT \"repo_name\"\n  FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"SAMPLE_FILES\"\n  WHERE \"ref\" = 'refs/heads/master' \n    AND \"path\" LIKE '%.py'\n),\nlicensed_repos AS (\n  SELECT DISTINCT \"repo_name\"\n  FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LICENSES\"\n  WHERE \"license\" IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')\n),\nwatches AS (\n  SELECT \"repo\":\"name\"::STRING AS repo_name, COUNT(*) AS watch_count\n  FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\"\n  WHERE \"type\" = 'WatchEvent'\n  GROUP BY 1\n),\nissues AS (\n  SELECT \"repo\":\"name\"::STRING AS repo_name, COUNT(*) AS issue_count\n  FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\"\n  WHERE \"type\" = 'IssuesEvent'\n  GROUP BY 1\n),\nforks AS (\n  SELECT \"repo\":\"name\"::STRING AS repo_name, COUNT(*) AS fork_count\n  FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\"\n  WHERE \"type\" = 'ForkEvent'\n  GROUP BY 1\n)\nSELECT \n  w.repo_name AS REPO_NAME,\n  COALESCE(f.fork_count, 0) + COALESCE(i.issue_count, 0) + COALESCE(w.watch_count, 0) AS TOTAL_ACTIVITY\nFROM watches w\nLEFT JOIN issues i ON w.repo_name = i.repo_name\nLEFT JOIN forks f ON w.repo_name = f.repo_name\nINNER JOIN python_repos p ON w.repo_name = p.\"repo_name\"\nINNER JOIN licensed_repos l ON w.repo_name = l.\"repo_name\"\nORDER BY TOTAL_ACTIVITY DESC\nLIMIT 1;" = sql%([SAMPLE_FILES_schema, LICENSES_schema, _202204_schema]) "WITH python_repos AS (\n  SELECT DISTINCT sf.\"repo_name\" AS repo_name\n  FROM \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"SAMPLE_FILES\" sf\n  JOIN \"GITHUB_REPOS_DATE\".\"GITHUB_REPOS\".\"LICENSES\" l ON sf.\"repo_name\" = l.\"repo_name\"\n  WHERE LOWER(sf.\"path\") LIKE '%.py' \n    AND LOWER(l.\"license\") IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')\n),\nwatches AS (\n  SELECT \"repo\":\"name\"::VARCHAR AS repo_name, COUNT(*) AS num_watches\n  FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\"\n  WHERE \"type\" = 'WatchEvent'\n  GROUP BY repo_name\n),\nissues AS (\n  SELECT \"repo\":\"name\"::VARCHAR AS repo_name, COUNT(*) AS num_issues\n  FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\"\n  WHERE \"type\" = 'IssuesEvent'\n  GROUP BY repo_name\n),\nforks AS (\n  SELECT \"repo\":\"name\"::VARCHAR AS repo_name, COUNT(*) AS num_forks\n  FROM \"GITHUB_REPOS_DATE\".\"MONTH\".\"_202204\"\n  WHERE \"type\" = 'ForkEvent'\n  GROUP BY repo_name\n)\nSELECT p.repo_name AS \"REPO_NAME\",\n       COALESCE(w.num_watches, 0) + COALESCE(i.num_issues, 0) + COALESCE(f.num_forks, 0) AS \"TOTAL_ACTIVITY\"\nFROM python_repos p\nLEFT JOIN watches w ON p.repo_name = w.repo_name\nLEFT JOIN issues i ON p.repo_name = i.repo_name\nLEFT JOIN forks f ON p.repo_name = f.repo_name\nORDER BY \"TOTAL_ACTIVITY\" DESC\nLIMIT 1;" := by
  first | sql_equiv | sorry

end Bench_sf_bq192
