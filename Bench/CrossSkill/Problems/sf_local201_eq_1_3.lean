import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local201_eq_1_3

CREATE TABLE WORD_LIST («words» STRING)

theorem eq (t0 : TableRel WORD_LIST_schema) :
    (sql%([WORD_LIST_schema]) "WITH distinct_words AS (SELECT DISTINCT \"words\" FROM \"MODERN_DATA\".\"MODERN_DATA\".\"WORD_LIST\" WHERE LENGTH(\"words\") BETWEEN 4 AND 5), word_chars AS (SELECT w.\"words\", SUBSTRING(w.\"words\" FROM g.pos FOR 1) AS ch FROM distinct_words AS w, (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS pos FROM TABLE(GENERATOR(5))) AS g WHERE g.pos <= LENGTH(w.\"words\")), sorted_words AS (SELECT \"words\", STRING_AGG(ch, '' ORDER BY ch) AS sorted_chars FROM word_chars GROUP BY \"words\"), anagram_counts AS (SELECT s1.\"words\" AS WORD, COUNT(*) AS ANAGRAM_COUNT FROM sorted_words AS s1 JOIN sorted_words AS s2 ON s1.sorted_chars = s2.sorted_chars AND LENGTH(s1.\"words\") = LENGTH(s2.\"words\") AND s1.\"words\" <> s2.\"words\" WHERE s1.\"words\" LIKE 'r%' GROUP BY s1.\"words\" HAVING COUNT(*) >= 1) SELECT WORD, ANAGRAM_COUNT FROM anagram_counts ORDER BY WORD LIMIT 10") t0
  ~= (sql%([WORD_LIST_schema]) "WITH sorted_words AS (SELECT w.\"words\", LENGTH(w.\"words\") AS word_len, STRING_AGG(CAST(c.value AS TEXT), '' ORDER BY CAST(c.value AS TEXT)) AS sorted_word FROM \"MODERN_DATA\".\"MODERN_DATA\".\"WORD_LIST\" AS w, LATERAL UNNEST(input => REGEXP_EXTRACT_ALL(w.\"words\", '.', 0)) AS c(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE LENGTH(w.\"words\") BETWEEN 4 AND 5 GROUP BY w.\"words\", LENGTH(w.\"words\")) SELECT s1.\"words\" AS WORD, COUNT(*) AS ANAGRAM_COUNT FROM sorted_words AS s1 JOIN sorted_words AS s2 ON s1.sorted_word = s2.sorted_word AND s1.word_len = s2.word_len AND s1.\"words\" <> s2.\"words\" WHERE LOWER(s1.\"words\") LIKE 'r%' GROUP BY s1.\"words\" ORDER BY s1.\"words\" LIMIT 10") t0
  := by first | sql_equiv | sorry

end N_sf_local201_eq_1_3
