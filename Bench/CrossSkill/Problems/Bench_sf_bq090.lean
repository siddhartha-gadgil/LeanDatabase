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
    (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH long_trades AS (\n    SELECT \n        CASE \n            WHEN p.value:\"PartyID\"::VARCHAR LIKE 'LUCKY%' THEN 'feeling-lucky'\n            WHEN p.value:\"PartyID\"::VARCHAR LIKE 'MOMO%' THEN 'momentum'\n        END AS strategy_group,\n        GREATEST(0, t.\"LastPx\" - t.\"StrikePrice\") AS intrinsic_value\n    FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" t,\n    LATERAL FLATTEN(input => t.\"Sides\") s,\n    LATERAL FLATTEN(input => s.value:\"PartyIDs\") p\n    WHERE s.value:\"Side\"::VARCHAR = 'LONG'\n    AND (p.value:\"PartyID\"::VARCHAR LIKE 'LUCKY%' OR p.value:\"PartyID\"::VARCHAR LIKE 'MOMO%')\n)\nSELECT \n    AVG(CASE WHEN strategy_group = 'feeling-lucky' THEN intrinsic_value END) - \n    AVG(CASE WHEN strategy_group = 'momentum' THEN intrinsic_value END) AS DIFF\nFROM long_trades;") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT\n  AVG(CASE WHEN t.\"TargetCompID\" LIKE 'LUCKY%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END)\n  - AVG(CASE WHEN t.\"TargetCompID\" LIKE 'MOMO%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) AS DIFF\nFROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" t,\nLATERAL FLATTEN(input => t.\"Sides\") s\nWHERE s.value:\"Side\"::STRING = 'LONG'") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp0_2_0 : TRADE_CAPTURE_REPORT "SUBSTRING(\"TargetCompID\", 1, 4) IN ('LUCK', 'MOMO')"
theorem eq_0_2 (t : TableRel TRADE_CAPTURE_REPORT_schema) (h0 : hyp0_2_0 t) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH long_trades AS (\n    SELECT \n        CASE \n            WHEN p.value:\"PartyID\"::VARCHAR LIKE 'LUCKY%' THEN 'feeling-lucky'\n            WHEN p.value:\"PartyID\"::VARCHAR LIKE 'MOMO%' THEN 'momentum'\n        END AS strategy_group,\n        GREATEST(0, t.\"LastPx\" - t.\"StrikePrice\") AS intrinsic_value\n    FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" t,\n    LATERAL FLATTEN(input => t.\"Sides\") s,\n    LATERAL FLATTEN(input => s.value:\"PartyIDs\") p\n    WHERE s.value:\"Side\"::VARCHAR = 'LONG'\n    AND (p.value:\"PartyID\"::VARCHAR LIKE 'LUCKY%' OR p.value:\"PartyID\"::VARCHAR LIKE 'MOMO%')\n)\nSELECT \n    AVG(CASE WHEN strategy_group = 'feeling-lucky' THEN intrinsic_value END) - \n    AVG(CASE WHEN strategy_group = 'momentum' THEN intrinsic_value END) AS DIFF\nFROM long_trades;") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT\n  AVG(CASE WHEN SUBSTRING(\"TargetCompID\", 1, 4) = 'LUCK' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END)\n  - AVG(CASE WHEN SUBSTRING(\"TargetCompID\", 1, 4) = 'MOMO' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END)\n  AS \"DIFF\"\nFROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\"\nWHERE \"Sides\"[0]:\"Side\"::STRING = 'LONG'\n  AND SUBSTRING(\"TargetCompID\", 1, 4) IN ('LUCK', 'MOMO');") t := by
  first | sql_equiv | sorry

theorem eq_0_3 : ∀ t,
    (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH long_trades AS (\n    SELECT \n        CASE \n            WHEN p.value:\"PartyID\"::VARCHAR LIKE 'LUCKY%' THEN 'feeling-lucky'\n            WHEN p.value:\"PartyID\"::VARCHAR LIKE 'MOMO%' THEN 'momentum'\n        END AS strategy_group,\n        GREATEST(0, t.\"LastPx\" - t.\"StrikePrice\") AS intrinsic_value\n    FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" t,\n    LATERAL FLATTEN(input => t.\"Sides\") s,\n    LATERAL FLATTEN(input => s.value:\"PartyIDs\") p\n    WHERE s.value:\"Side\"::VARCHAR = 'LONG'\n    AND (p.value:\"PartyID\"::VARCHAR LIKE 'LUCKY%' OR p.value:\"PartyID\"::VARCHAR LIKE 'MOMO%')\n)\nSELECT \n    AVG(CASE WHEN strategy_group = 'feeling-lucky' THEN intrinsic_value END) - \n    AVG(CASE WHEN strategy_group = 'momentum' THEN intrinsic_value END) AS DIFF\nFROM long_trades;") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH data AS (\n  SELECT \n    CASE \n      WHEN \"Sides\"[0]:\"PartyIDs\"[0]:\"PartyID\"::STRING LIKE 'LUCKY%' THEN 'LUCKY'\n      WHEN \"Sides\"[0]:\"PartyIDs\"[0]:\"PartyID\"::STRING LIKE 'MOMO%' THEN 'MOMO' \n    END AS grp,\n    GREATEST(0, \"LastPx\" - \"StrikePrice\") AS iv\n  FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" \n  WHERE \"Sides\"[0]:\"Side\"::STRING = 'LONG'\n    AND \"Sides\"[0]:\"PartyIDs\"[0]:\"PartyID\"::STRING LIKE ANY ('LUCKY%', 'MOMO%')\n)\nSELECT \n  (SELECT AVG(iv) FROM data WHERE grp = 'LUCKY') -\n  (SELECT AVG(iv) FROM data WHERE grp = 'MOMO') AS DIFF;") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp1_2_0 : TRADE_CAPTURE_REPORT "SUBSTRING(\"TargetCompID\", 1, 4) IN ('LUCK', 'MOMO')"
theorem eq_1_2 (t : TableRel TRADE_CAPTURE_REPORT_schema) (h0 : hyp1_2_0 t) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT\n  AVG(CASE WHEN t.\"TargetCompID\" LIKE 'LUCKY%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END)\n  - AVG(CASE WHEN t.\"TargetCompID\" LIKE 'MOMO%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) AS DIFF\nFROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" t,\nLATERAL FLATTEN(input => t.\"Sides\") s\nWHERE s.value:\"Side\"::STRING = 'LONG'") t = (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT\n  AVG(CASE WHEN SUBSTRING(\"TargetCompID\", 1, 4) = 'LUCK' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END)\n  - AVG(CASE WHEN SUBSTRING(\"TargetCompID\", 1, 4) = 'MOMO' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END)\n  AS \"DIFF\"\nFROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\"\nWHERE \"Sides\"[0]:\"Side\"::STRING = 'LONG'\n  AND SUBSTRING(\"TargetCompID\", 1, 4) IN ('LUCK', 'MOMO');") t := by
  first | sql_equiv | sorry

theorem eq_1_3 : ∀ t,
    (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT\n  AVG(CASE WHEN t.\"TargetCompID\" LIKE 'LUCKY%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END)\n  - AVG(CASE WHEN t.\"TargetCompID\" LIKE 'MOMO%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) AS DIFF\nFROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" t,\nLATERAL FLATTEN(input => t.\"Sides\") s\nWHERE s.value:\"Side\"::STRING = 'LONG'") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH data AS (\n  SELECT \n    CASE \n      WHEN \"Sides\"[0]:\"PartyIDs\"[0]:\"PartyID\"::STRING LIKE 'LUCKY%' THEN 'LUCKY'\n      WHEN \"Sides\"[0]:\"PartyIDs\"[0]:\"PartyID\"::STRING LIKE 'MOMO%' THEN 'MOMO' \n    END AS grp,\n    GREATEST(0, \"LastPx\" - \"StrikePrice\") AS iv\n  FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" \n  WHERE \"Sides\"[0]:\"Side\"::STRING = 'LONG'\n    AND \"Sides\"[0]:\"PartyIDs\"[0]:\"PartyID\"::STRING LIKE ANY ('LUCKY%', 'MOMO%')\n)\nSELECT \n  (SELECT AVG(iv) FROM data WHERE grp = 'LUCKY') -\n  (SELECT AVG(iv) FROM data WHERE grp = 'MOMO') AS DIFF;") t := by
  intro t; first | sql_equiv | sorry

HYPOTHESIS hyp2_3_0 : TRADE_CAPTURE_REPORT "SUBSTRING(\"TargetCompID\", 1, 4) IN ('LUCK', 'MOMO')"
theorem eq_2_3 (t : TableRel TRADE_CAPTURE_REPORT_schema) (h0 : hyp2_3_0 t) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT\n  AVG(CASE WHEN SUBSTRING(\"TargetCompID\", 1, 4) = 'LUCK' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END)\n  - AVG(CASE WHEN SUBSTRING(\"TargetCompID\", 1, 4) = 'MOMO' THEN GREATEST(0, \"LastPx\" - \"StrikePrice\") END)\n  AS \"DIFF\"\nFROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\"\nWHERE \"Sides\"[0]:\"Side\"::STRING = 'LONG'\n  AND SUBSTRING(\"TargetCompID\", 1, 4) IN ('LUCK', 'MOMO');") t ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH data AS (\n  SELECT \n    CASE \n      WHEN \"Sides\"[0]:\"PartyIDs\"[0]:\"PartyID\"::STRING LIKE 'LUCKY%' THEN 'LUCKY'\n      WHEN \"Sides\"[0]:\"PartyIDs\"[0]:\"PartyID\"::STRING LIKE 'MOMO%' THEN 'MOMO' \n    END AS grp,\n    GREATEST(0, \"LastPx\" - \"StrikePrice\") AS iv\n  FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" \n  WHERE \"Sides\"[0]:\"Side\"::STRING = 'LONG'\n    AND \"Sides\"[0]:\"PartyIDs\"[0]:\"PartyID\"::STRING LIKE ANY ('LUCKY%', 'MOMO%')\n)\nSELECT \n  (SELECT AVG(iv) FROM data WHERE grp = 'LUCKY') -\n  (SELECT AVG(iv) FROM data WHERE grp = 'MOMO') AS DIFF;") t := by
  first | sql_equiv | sorry

end Bench_sf_bq090
