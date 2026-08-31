import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq402_eq_0_1

CREATE TABLE WEB_ANALYTICS («visitorId» INT, «visitNumber» INT, «visitId» INT, «visitStartTime» INT, «date» STRING, «totals» STRING, «trafficSource» STRING, «device» STRING, «geoNetwork» STRING, «customDimensions» STRING, «hits» STRING, «fullVisitorId» STRING, «userId» STRING, «channelGrouping» STRING, «socialEngagementType» STRING)

theorem eq (t0 : TableRel WEB_ANALYTICS_schema) :
    (sql%([WEB_ANALYTICS_schema]) "SELECT COUNT(DISTINCT \"fullVisitorId\") AS TOTAL_UNIQUE_VISITORS, COUNT(DISTINCT CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN \"fullVisitorId\" END) AS UNIQUE_PURCHASERS, SUM(CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN CAST(JSON_EXTRACT_PATH(\"totals\", 'transactions') AS INT) ELSE 0 END) AS TOTAL_TRANSACTIONS, ROUND(CAST(CAST(COUNT(DISTINCT CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN \"fullVisitorId\" END) AS DOUBLE PRECISION) / CAST(COUNT(DISTINCT \"fullVisitorId\") AS DOUBLE PRECISION) * 100 AS DECIMAL), 1) AS CONVERSION_RATE_PERCENTAGE, ROUND(CAST(CAST(SUM(CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN CAST(JSON_EXTRACT_PATH(\"totals\", 'transactions') AS INT) ELSE 0 END) AS DOUBLE PRECISION) / CAST(COUNT(DISTINCT CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN \"fullVisitorId\" END) AS DOUBLE PRECISION) AS DECIMAL), 2) AS AVG_TRANSACTIONS_PER_PURCHASER FROM \"ECOMMERCE\".\"ECOMMERCE\".\"WEB_ANALYTICS\"") t0
  = (sql%([WEB_ANALYTICS_schema]) "SELECT COUNT(DISTINCT \"fullVisitorId\") AS TOTAL_UNIQUE_VISITORS, COUNT(DISTINCT CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN \"fullVisitorId\" END) AS UNIQUE_PURCHASERS, SUM(CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN CAST(JSON_EXTRACT_PATH(\"totals\", 'transactions') AS INT) ELSE 0 END) AS TOTAL_TRANSACTIONS, ROUND(CAST(CAST(COUNT(DISTINCT CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN \"fullVisitorId\" END) * 100.0 AS DOUBLE PRECISION) / COUNT(DISTINCT \"fullVisitorId\") AS DECIMAL), 1) AS CONVERSION_RATE_PERCENTAGE, ROUND(CAST(CAST(SUM(CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN CAST(JSON_EXTRACT_PATH(\"totals\", 'transactions') AS INT) ELSE 0 END) * 1.0 AS DOUBLE PRECISION) / NULLIF(COUNT(DISTINCT CASE WHEN NOT JSON_EXTRACT_PATH(\"totals\", 'transactions') IS NULL THEN \"fullVisitorId\" END), 0) AS DECIMAL), 2) AS AVG_TRANSACTIONS_PER_PURCHASER FROM \"ECOMMERCE\".\"ECOMMERCE\".\"WEB_ANALYTICS\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq402_eq_0_1
