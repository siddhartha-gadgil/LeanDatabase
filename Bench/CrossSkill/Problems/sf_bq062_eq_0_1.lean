import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq062_eq_0_1

CREATE TABLE PACKAGEVERSIONS («SnapshotAt» INT, «System» STRING, «Name» STRING, «Version» STRING, «Licenses» STRING, «Links» STRING, «Advisories» STRING, «VersionInfo» STRING, «Hashes» STRING, «DependenciesProcessed» BOOL, «DependencyError» BOOL, «UpstreamPublishedAt» INT, «Registries» STRING, «SLSAProvenance» STRING, «UpstreamIdentifiers» STRING, «Purl» STRING)

theorem eq (t0 : TableRel PACKAGEVERSIONS_schema) :
    (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (SELECT \"System\", CAST(f.value AS TEXT) AS \"License\", COUNT(DISTINCT \"Name\") AS package_count FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\", LATERAL UNNEST(input => \"Licenses\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) GROUP BY \"System\", CAST(f.value AS TEXT)), ranked AS (SELECT \"System\", \"License\", package_count, ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY package_count DESC) AS rn FROM license_counts) SELECT \"System\", \"License\" FROM ranked WHERE rn = 1 ORDER BY \"System\"") t0
  ~= (sql%([PACKAGEVERSIONS_schema]) "WITH license_counts AS (SELECT \"System\", CAST(lic.VALUE AS TEXT) AS \"License\", COUNT(DISTINCT \"Name\") AS pkg_count FROM \"DEPS_DEV_V1\".\"DEPS_DEV_V1\".\"PACKAGEVERSIONS\", LATERAL UNNEST(input => \"Licenses\") AS lic(SEQ, KEY, PATH, INDEX, VALUE, THIS) GROUP BY \"System\", CAST(lic.VALUE AS TEXT)), ranked AS (SELECT \"System\", \"License\", pkg_count, ROW_NUMBER() OVER (PARTITION BY \"System\" ORDER BY pkg_count DESC) AS rn FROM license_counts) SELECT \"System\", \"License\" FROM ranked WHERE rn = 1 ORDER BY \"System\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq062_eq_0_1
