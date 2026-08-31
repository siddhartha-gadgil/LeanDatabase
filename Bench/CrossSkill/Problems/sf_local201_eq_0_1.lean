import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local201_eq_0_1

CREATE TABLE WORD_LIST («words» STRING)

theorem eq (t0 : TableRel WORD_LIST_schema) :
    (sql%([WORD_LIST_schema]) "WITH all_words AS (SELECT DISTINCT \"words\" AS word, ARRAY_TO_STRING(SORT_ARRAY(REGEXP_EXTRACT_ALL(\"words\", '.', 0)), '') AS sorted_letters FROM \"MODERN_DATA\".\"MODERN_DATA\".\"WORD_LIST\" WHERE LENGTH(\"words\") BETWEEN 4 AND 5), r_words AS (SELECT word, sorted_letters FROM all_words WHERE word LIKE 'r%'), anagram_counts AS (SELECT r.word AS WORD, COUNT(a.word) AS ANAGRAM_COUNT FROM r_words AS r JOIN all_words AS a ON r.sorted_letters = a.sorted_letters AND r.word <> a.word GROUP BY r.word HAVING COUNT(a.word) >= 1) SELECT WORD, ANAGRAM_COUNT FROM anagram_counts ORDER BY WORD LIMIT 10") t0
  ~= (sql%([WORD_LIST_schema]) "WITH distinct_words AS (SELECT DISTINCT \"words\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"WORD_LIST\" WHERE LENGTH(\"words\") BETWEEN 4 AND 5), word_chars AS (SELECT w.\"words\", SUBSTRING(w.\"words\" FROM g.pos FOR 1) AS ch FROM distinct_words AS w, (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS pos FROM TABLE(GENERATOR(5))) AS g WHERE g.pos <= LENGTH(w.\"words\")), sorted_words AS (SELECT \"words\", STRING_AGG(ch, '' ORDER BY ch) AS sorted_chars FROM word_chars GROUP BY \"words\"), anagram_counts AS (SELECT s1.\"words\" AS WORD, COUNT(*) AS ANAGRAM_COUNT FROM sorted_words AS s1 JOIN sorted_words AS s2 ON s1.sorted_chars = s2.sorted_chars AND LENGTH(s1.\"words\") = LENGTH(s2.\"words\") AND s1.\"words\" <> s2.\"words\" WHERE s1.\"words\" LIKE 'r%' GROUP BY s1.\"words\" HAVING COUNT(*) >= 1) SELECT WORD, ANAGRAM_COUNT FROM anagram_counts ORDER BY WORD LIMIT 10") t0
  := by first | sql_equiv | sorry

end N_sf_local201_eq_0_1
