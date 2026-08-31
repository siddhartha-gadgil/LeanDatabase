import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq442_eq_1_2

CREATE TABLE TRADE_CAPTURE_REPORT («SendingTime» INT, «TargetCompID» STRING, «SenderCompID» STRING, «Symbol» STRING, «Quantity» INT, «OrderID» STRING, «TransactTime» INT, «StrikePrice» FLOAT, «LastPx» FLOAT, «MaturityDate» INT, «TradeReportID» STRING, «TradeDate» STRING, «CFICode» STRING, «Sides» STRING)

theorem eq (t0 : TableRel TRADE_CAPTURE_REPORT_schema) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT \"OrderID\" AS TRADEID, TO_CHAR(TO_TIMESTAMP(CAST(\"TransactTime\" AS DECIMAL(38, 0)) / POWER(10, 6)), 'YYYY-MM-DD HH24:MI:SS.US') || ' UTC' AS TRADETIMESTAMP, CASE LEFT(\"TargetCompID\", 4) WHEN 'MOMO' THEN 'Momentum' WHEN 'LUCK' THEN 'Feeling Lucky' WHEN 'PRED' THEN 'Prediction' END AS ALGORITHM, \"Symbol\" AS SYMBOL, \"LastPx\" AS OPENPRICE, \"StrikePrice\" AS CLOSEPRICE, CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS TEXT) AS TRADEDIRECTION, CASE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS TEXT) WHEN 'LONG' THEN 1 WHEN 'SHORT' THEN -1 END AS TRADEMULTIPLIER FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\", LATERAL UNNEST(input => \"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS) ORDER BY \"StrikePrice\" DESC LIMIT 6") t0
  = (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT \"OrderID\" AS TRADEID, TO_CHAR(TO_TIMESTAMP(CAST(\"TransactTime\" AS DECIMAL(38, 0)) / POWER(10, 6)), 'YYYY-MM-DD HH24:MI:SS.US') || ' UTC' AS TRADETIMESTAMP, CASE LEFT(\"TargetCompID\", 4) WHEN 'MOMO' THEN 'Momentum' WHEN 'LUCK' THEN 'Feeling Lucky' WHEN 'PRED' THEN 'Prediction' END AS ALGORITHM, \"Symbol\" AS SYMBOL, \"LastPx\" AS OPENPRICE, \"StrikePrice\" AS CLOSEPRICE, CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS TEXT) AS TRADEDIRECTION, CASE CAST(JSON_EXTRACT_PATH(s.value, 'Side') AS TEXT) WHEN 'SHORT' THEN -1 WHEN 'LONG' THEN 1 END AS TRADEMULTIPLIER FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\", LATERAL UNNEST(input => \"Sides\") AS s(SEQ, KEY, PATH, INDEX, VALUE, THIS) ORDER BY \"StrikePrice\" DESC, \"LastPx\" ASC LIMIT 6") t0
  := by first | sql_equiv | sorry

end N_sf_bq442_eq_1_2
