import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local201_eq_2_3

CREATE TABLE WORD_LIST («words» STRING)

theorem eq (t0 : TableRel WORD_LIST_schema) :
    (sql%([WORD_LIST_schema]) "WITH word_sigs AS (SELECT \"words\", ARRAY_TO_STRING(SORT_ARRAY(REGEXP_EXTRACT_ALL(\"words\", '.', 0)), '') AS sig FROM \"MODERN_DATA\".\"MODERN_DATA\".\"WORD_LIST\" WHERE LENGTH(\"words\") BETWEEN 4 AND 5), anagram_counts AS (SELECT sig, COUNT(*) AS total_count FROM word_sigs GROUP BY sig HAVING COUNT(*) > 1) SELECT w.\"words\" AS \"WORD\", a.total_count - 1 AS \"ANAGRAM_COUNT\" FROM word_sigs AS w JOIN anagram_counts AS a ON w.sig = a.sig WHERE w.\"words\" LIKE 'r%' ORDER BY w.\"words\" LIMIT 10") t0
  ~= (sql%([WORD_LIST_schema]) "WITH sorted_words AS (SELECT w.\"words\", LENGTH(w.\"words\") AS word_len, STRING_AGG(CAST(c.value AS TEXT), '' ORDER BY CAST(c.value AS TEXT)) AS sorted_word FROM \"MODERN_DATA\".\"MODERN_DATA\".\"WORD_LIST\" AS w, LATERAL UNNEST(input => REGEXP_EXTRACT_ALL(w.\"words\", '.', 0)) AS c(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE LENGTH(w.\"words\") BETWEEN 4 AND 5 GROUP BY w.\"words\", LENGTH(w.\"words\")) SELECT s1.\"words\" AS WORD, COUNT(*) AS ANAGRAM_COUNT FROM sorted_words AS s1 JOIN sorted_words AS s2 ON s1.sorted_word = s2.sorted_word AND s1.word_len = s2.word_len AND s1.\"words\" <> s2.\"words\" WHERE LOWER(s1.\"words\") LIKE 'r%' GROUP BY s1.\"words\" ORDER BY s1.\"words\" LIMIT 10") t0
  := by first | sql_equiv | sorry

end N_sf_local201_eq_2_3
