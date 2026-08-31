import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local201_eq_0_2

CREATE TABLE WORD_LIST («words» STRING)

theorem eq (t0 : TableRel WORD_LIST_schema) :
    (sql%([WORD_LIST_schema]) "WITH all_words AS (SELECT DISTINCT \"words\" AS word, ARRAY_TO_STRING(SORT_ARRAY(REGEXP_EXTRACT_ALL(\"words\", '.', 0)), '') AS sorted_letters FROM \"MODERN_DATA\".\"MODERN_DATA\".\"WORD_LIST\" WHERE LENGTH(\"words\") BETWEEN 4 AND 5), r_words AS (SELECT word, sorted_letters FROM all_words WHERE word LIKE 'r%'), anagram_counts AS (SELECT r.word AS WORD, COUNT(a.word) AS ANAGRAM_COUNT FROM r_words AS r JOIN all_words AS a ON r.sorted_letters = a.sorted_letters AND r.word <> a.word GROUP BY r.word HAVING COUNT(a.word) >= 1) SELECT WORD, ANAGRAM_COUNT FROM anagram_counts ORDER BY WORD LIMIT 10") t0
  ~= (sql%([WORD_LIST_schema]) "WITH word_sigs AS (SELECT \"words\", ARRAY_TO_STRING(SORT_ARRAY(REGEXP_EXTRACT_ALL(\"words\", '.', 0)), '') AS sig FROM \"MODERN_DATA\".\"MODERN_DATA\".\"WORD_LIST\" WHERE LENGTH(\"words\") BETWEEN 4 AND 5), anagram_counts AS (SELECT sig, COUNT(*) AS total_count FROM word_sigs GROUP BY sig HAVING COUNT(*) > 1) SELECT w.\"words\" AS \"WORD\", a.total_count - 1 AS \"ANAGRAM_COUNT\" FROM word_sigs AS w JOIN anagram_counts AS a ON w.sig = a.sig WHERE w.\"words\" LIKE 'r%' ORDER BY w.\"words\" LIMIT 10") t0
  := by first | sql_equiv | sorry

end N_sf_local201_eq_0_2
