import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq442_eq_0_3

CREATE TABLE TRADE_CAPTURE_REPORT («SendingTime» INT, «TargetCompID» STRING, «SenderCompID» STRING, «Symbol» STRING, «Quantity» INT, «OrderID» STRING, «TransactTime» INT, «StrikePrice» FLOAT, «LastPx» FLOAT, «MaturityDate» INT, «TradeReportID» STRING, «TradeDate» STRING, «CFICode» STRING, «Sides» STRING)

theorem eq (t0 : TableRel TRADE_CAPTURE_REPORT_schema) :
    (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT t.\"OrderID\" AS TRADEID, TO_CHAR(TO_TIMESTAMP(CAST(t.\"TransactTime\" AS DOUBLE PRECISION) / POWER(10, 6)), 'YYYY-MM-DD HH24:MI:SS.US') || ' UTC' AS TRADETIMESTAMP, CASE WHEN LEFT(t.\"TargetCompID\", 4) = 'MOMO' THEN 'Momentum' WHEN LEFT(t.\"TargetCompID\", 4) = 'LUCK' THEN 'Feeling Lucky' WHEN LEFT(t.\"TargetCompID\", 4) = 'PRED' THEN 'Prediction' END AS ALGORITHM, t.\"Symbol\" AS SYMBOL, t.\"LastPx\" AS OPENPRICE, t.\"StrikePrice\" AS CLOSEPRICE, CAST(JSON_EXTRACT_PATH(f.value, 'Side') AS TEXT) AS TRADEDIRECTION, CASE WHEN CAST(JSON_EXTRACT_PATH(f.value, 'Side') AS TEXT) = 'SHORT' THEN -1 WHEN CAST(JSON_EXTRACT_PATH(f.value, 'Side') AS TEXT) = 'LONG' THEN 1 END AS TRADEMULTIPLIER FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" AS t, LATERAL UNNEST(input => t.\"Sides\") AS f(SEQ, KEY, PATH, INDEX, VALUE, THIS) ORDER BY t.\"StrikePrice\" DESC, t.\"TransactTime\" DESC LIMIT 6") t0
  = (sql%([TRADE_CAPTURE_REPORT_schema]) "SELECT \"OrderID\" AS TRADEID, TO_CHAR(TO_TIMESTAMP(CAST(\"TransactTime\" AS DOUBLE PRECISION) / POWER(10, 6)), 'YYYY-MM-DD HH24:MI:SS.US') || ' UTC' AS TRADETIMESTAMP, CASE WHEN \"TargetCompID\" LIKE 'MOMO%' THEN 'Momentum' WHEN \"TargetCompID\" LIKE 'PREDICT%' THEN 'Prediction' WHEN \"TargetCompID\" LIKE 'LUCK%' THEN 'Feeling Lucky' END AS ALGORITHM, \"Symbol\" AS SYMBOL, \"LastPx\" AS OPENPRICE, \"StrikePrice\" AS CLOSEPRICE, CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) AS TRADEDIRECTION, CASE WHEN CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'SHORT' THEN -1 WHEN CAST(JSON_EXTRACT_PATH(\"Sides\"[1], 'Side') AS TEXT) = 'LONG' THEN 1 END AS TRADEMULTIPLIER FROM \"CYMBAL_INVESTMENTS\".\"CYMBAL_INVESTMENTS\".\"TRADE_CAPTURE_REPORT\" ORDER BY \"StrikePrice\" DESC LIMIT 6") t0
  := by first | sql_equiv | sorry

end N_sf_bq442_eq_0_3
