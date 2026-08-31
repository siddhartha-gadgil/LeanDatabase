import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq100_eq_2_3

CREATE TABLE SAMPLE_CONTENTS («id» STRING, «size» INT, «content» STRING, «binary» BOOL, «copies» INT, «sample_repo_name» STRING, «sample_ref» STRING, «sample_path» STRING, «sample_mode» INT, «sample_symlink_target» STRING)

theorem eq (t0 : TableRel SAMPLE_CONTENTS_schema) :
    (sql%([SAMPLE_CONTENTS_schema]) "WITH import_blocks AS (SELECT REGEXP_EXTRACT(\"content\", 'import \\([^)]*\\)', 1, 1, 's', 0) AS block FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\" WHERE \"content\" LIKE '%import (%'), split_lines AS (SELECT TRIM(CAST(pkg.VALUE AS TEXT)) AS line FROM import_blocks, LATERAL UNNEST(INPUT => SPLIT(block, ' ')) AS pkg(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE NOT block IS NULL), packages AS (SELECT REGEXP_EXTRACT(line, '\"([^\"]*)\"', 1, 1, 'e', 0) AS package FROM split_lines) SELECT package AS \"PACKAGE\", COUNT(*) AS \"F0_\" FROM packages WHERE NOT package IS NULL GROUP BY package ORDER BY \"F0_\" DESC, \"PACKAGE\" ASC LIMIT 10") t0
  ~= (sql%([SAMPLE_CONTENTS_schema]) "WITH import_blocks AS (SELECT REGEXP_EXTRACT(\"content\", 'import \\(([^)]+)\\)', 1, 1, 'es', 1) AS import_block FROM \"GITHUB_REPOS\".\"GITHUB_REPOS\".\"SAMPLE_CONTENTS\" WHERE \"content\" LIKE '%import (%'), lines AS (SELECT TRIM(CAST(f.value AS TEXT)) AS line FROM import_blocks, LATERAL UNNEST(input => SPLIT(import_block, ' ')) AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE TRIM(CAST(f.value AS TEXT)) <> ''), packages AS (SELECT REGEXP_EXTRACT(line, '\"([^\"]+)\"', 1, 1, 'e', 1) AS package FROM lines WHERE line LIKE '%\"%') SELECT package, COUNT(*) AS f0_ FROM packages WHERE NOT package IS NULL GROUP BY package ORDER BY f0_ DESC, package ASC LIMIT 10") t0
  := by first | sql_equiv | sorry

end N_sf_bq100_eq_2_3
