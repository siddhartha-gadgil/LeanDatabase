import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq090 — crossskill equivalence(s)

Question: How much higher the average intrinsic value is for trades using the feeling-lucky strategy compared to those using the momentum strategy under long-side trades?

NOTE: uses WITH RECURSIVE / LATERAL / FLATTEN — may not elaborate yet.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq090

CREATE TABLE TRADE_CAPTURE_REPORT («SendingTime» INT, «TargetCompID» STRING, «SenderCompID» STRING, «Symbol» STRING, «Quantity» INT, «OrderID» STRING, «TransactTime» INT, «StrikePrice» FLOAT, «LastPx» FLOAT, «MaturityDate» INT, «TradeReportID» STRING, «TradeDate» STRING, «CFICode» STRING, «Sides» STRING)

theorem eq_0_1 : ∀ t,
    (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH long_trades AS (SELECT CASE WHEN CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'LUCKY%' THEN 'feeling-lucky' WHEN CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'MOMO%' THEN 'momentum' END AS strategy_group, GREATEST(0, t.\"LastPx\" - t.\"StrikePrice\") AS intrinsic_value FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" AS t, LATERAL UNNEST(input => t.\"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(input => JSON_EXTRACT_PATH(s.value, 'PartyIDs')) AS p(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS VARCHAR) = 'LONG' AND (CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'LUCKY%' OR CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'MOMO%')) SELECT AVG(CASE WHEN strategy_group = 'feeling-lucky' THEN intrinsic_value END) - AVG(CASE WHEN strategy_group = 'momentum' THEN intrinsic_value END) AS DIFF FROM long_trades") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT AVG(CASE WHEN t.\"TargetCompID\" LIKE 'LUCKY%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) - AVG(CASE WHEN t.\"TargetCompID\" LIKE 'MOMO%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) AS DIFF FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" AS t, LATERAL UNNEST(input => t.\"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS TEXT) = 'LONG'") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : TRADE_CAPTURE_REPORT "CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG'"
HYPOTHESIS hyp0_2_1 : TRADE_CAPTURE_REPORT "SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) IN ('LUCK', 'MOMO')"
theorem eq_0_2 (t : TableRel TRADE_CAPTURE_REPORT_schema) (h0 : hyp0_2_0 t) (h1 : hyp0_2_1 t) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH long_trades AS (SELECT CASE WHEN CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'LUCKY%' THEN 'feeling-lucky' WHEN CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'MOMO%' THEN 'momentum' END AS strategy_group, GREATEST(0, t.\"LastPx\" - t.\"StrikePrice\") AS intrinsic_value FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" AS t, LATERAL UNNEST(input => t.\"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(input => JSON_EXTRACT_PATH(s.value, 'PartyIDs')) AS p(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS VARCHAR) = 'LONG' AND (CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'LUCKY%' OR CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'MOMO%')) SELECT AVG(CASE WHEN strategy_group = 'feeling-lucky' THEN intrinsic_value END) - AVG(CASE WHEN strategy_group = 'momentum' THEN intrinsic_value END) AS DIFF FROM long_trades") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT AVG(CASE WHEN SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) = 'LUCK' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END) - AVG(CASE WHEN SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) = 'MOMO' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END) AS \"DIFF\" FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" WHERE CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG' AND SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) IN ('LUCK', 'MOMO')") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp0_3_0 : TRADE_CAPTURE_REPORT "CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG'"
theorem eq_0_3 (t : TableRel TRADE_CAPTURE_REPORT_schema) (h0 : hyp0_3_0 t) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH long_trades AS (SELECT CASE WHEN CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'LUCKY%' THEN 'feeling-lucky' WHEN CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'MOMO%' THEN 'momentum' END AS strategy_group, GREATEST(0, t.\"LastPx\" - t.\"StrikePrice\") AS intrinsic_value FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" AS t, LATERAL UNNEST(input => t.\"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(input => JSON_EXTRACT_PATH(s.value, 'PartyIDs')) AS p(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS VARCHAR) = 'LONG' AND (CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'LUCKY%' OR CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'MOMO%')) SELECT AVG(CASE WHEN strategy_group = 'feeling-lucky' THEN intrinsic_value END) - AVG(CASE WHEN strategy_group = 'momentum' THEN intrinsic_value END) AS DIFF FROM long_trades") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH data AS (SELECT CASE WHEN CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'PartyIDs', '0', 'PartyID') AS TEXT) LIKE 'LUCKY%' THEN 'LUCKY' WHEN CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'PartyIDs', '0', 'PartyID') AS TEXT) LIKE 'MOMO%' THEN 'MOMO' END AS grp, GREATEST(0, \"LastPx\" - \"StrikePrice\") AS iv FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" WHERE CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG' AND CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'PartyIDs', '0', 'PartyID') AS TEXT) LIKE ANY ('LUCKY%', 'MOMO%')) SELECT (SELECT AVG(iv) FROM data WHERE grp = 'LUCKY') - (SELECT AVG(iv) FROM data WHERE grp = 'MOMO') AS DIFF") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : TRADE_CAPTURE_REPORT "CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG'"
HYPOTHESIS hyp1_2_1 : TRADE_CAPTURE_REPORT "SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) IN ('LUCK', 'MOMO')"
theorem eq_1_2 (t : TableRel TRADE_CAPTURE_REPORT_schema) (h0 : hyp1_2_0 t) (h1 : hyp1_2_1 t) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT AVG(CASE WHEN t.\"TargetCompID\" LIKE 'LUCKY%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) - AVG(CASE WHEN t.\"TargetCompID\" LIKE 'MOMO%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) AS DIFF FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" AS t, LATERAL UNNEST(input => t.\"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS TEXT) = 'LONG'") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT AVG(CASE WHEN SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) = 'LUCK' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END) - AVG(CASE WHEN SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) = 'MOMO' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END) AS \"DIFF\" FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" WHERE CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG' AND SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) IN ('LUCK', 'MOMO')") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp1_3_0 : TRADE_CAPTURE_REPORT "CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG'"
theorem eq_1_3 (t : TableRel TRADE_CAPTURE_REPORT_schema) (h0 : hyp1_3_0 t) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT AVG(CASE WHEN t.\"TargetCompID\" LIKE 'LUCKY%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) - AVG(CASE WHEN t.\"TargetCompID\" LIKE 'MOMO%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) AS DIFF FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" AS t, LATERAL UNNEST(input => t.\"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS TEXT) = 'LONG'") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH data AS (SELECT CASE WHEN CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'PartyIDs', '0', 'PartyID') AS TEXT) LIKE 'LUCKY%' THEN 'LUCKY' WHEN CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'PartyIDs', '0', 'PartyID') AS TEXT) LIKE 'MOMO%' THEN 'MOMO' END AS grp, GREATEST(0, \"LastPx\" - \"StrikePrice\") AS iv FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" WHERE CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG' AND CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'PartyIDs', '0', 'PartyID') AS TEXT) LIKE ANY ('LUCKY%', 'MOMO%')) SELECT (SELECT AVG(iv) FROM data WHERE grp = 'LUCKY') - (SELECT AVG(iv) FROM data WHERE grp = 'MOMO') AS DIFF") t := by
  first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : TRADE_CAPTURE_REPORT "SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) IN ('LUCK', 'MOMO')"
theorem eq_2_3 (t : TableRel TRADE_CAPTURE_REPORT_schema) (h0 : hyp2_3_0 t) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT AVG(CASE WHEN SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) = 'LUCK' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END) - AVG(CASE WHEN SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) = 'MOMO' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END) AS \"DIFF\" FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" WHERE CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG' AND SUBSTRING(\"TargetCompID\" FROM 1 FOR 4) IN ('LUCK', 'MOMO')") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH data AS (SELECT CASE WHEN CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'PartyIDs', '0', 'PartyID') AS TEXT) LIKE 'LUCKY%' THEN 'LUCKY' WHEN CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'PartyIDs', '0', 'PartyID') AS TEXT) LIKE 'MOMO%' THEN 'MOMO' END AS grp, GREATEST(0, \"LastPx\" - \"StrikePrice\") AS iv FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" WHERE CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG' AND CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'PartyIDs', '0', 'PartyID') AS TEXT) LIKE ANY ('LUCKY%', 'MOMO%')) SELECT (SELECT AVG(iv) FROM data WHERE grp = 'LUCKY') - (SELECT AVG(iv) FROM data WHERE grp = 'MOMO') AS DIFF") t := by
  first | sql_equiv | sorry

end Bench_sf_bq090
