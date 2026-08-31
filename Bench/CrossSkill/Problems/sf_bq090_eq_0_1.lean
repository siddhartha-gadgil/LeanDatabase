import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq090_eq_0_1

CREATE TABLE TRADE_CAPTURE_REPORT («SendingTime» INT, «TargetCompID» STRING, «SenderCompID» STRING, «Symbol» STRING, «Quantity» INT, «OrderID» STRING, «TransactTime» INT, «StrikePrice» FLOAT, «LastPx» FLOAT, «MaturityDate» INT, «TradeReportID» STRING, «TradeDate» STRING, «CFICode» STRING, «Sides» STRING)

theorem eq (t0 : TableRel TRADE_CAPTURE_REPORT_schema) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "WITH long_trades AS (SELECT CASE WHEN CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'LUCKY%' THEN 'feeling-lucky' WHEN CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'MOMO%' THEN 'momentum' END AS strategy_group, GREATEST(0, t.\"LastPx\" - t.\"StrikePrice\") AS intrinsic_value FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" AS t, LATERAL UNNEST(input => t.\"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS), LATERAL UNNEST(input => JSON_EXTRACT_PATH(s.value, 'PartyIDs')) AS p(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS VARCHAR) = 'LONG' AND (CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'LUCKY%' OR CAST(JSON_EXTRACT_PATH(p.value, 'PartyID') AS VARCHAR) LIKE 'MOMO%')) SELECT AVG(CASE WHEN strategy_group = 'feeling-lucky' THEN intrinsic_value END) - AVG(CASE WHEN strategy_group = 'momentum' THEN intrinsic_value END) AS DIFF FROM long_trades") t0
  ~= (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT AVG(CASE WHEN t.\"TargetCompID\" LIKE 'LUCKY%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) - AVG(CASE WHEN t.\"TargetCompID\" LIKE 'MOMO%' THEN GREATEST(t.\"LastPx\" - t.\"StrikePrice\", 0) END) AS DIFF FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" AS t, LATERAL UNNEST(input => t.\"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS) WHERE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS TEXT) = 'LONG'") t0
  := by first | sql_equiv | sorry

end N_sf_bq090_eq_0_1
