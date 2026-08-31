import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq397_eq_1_2

CREATE TABLE REV_TRANSACTIONS («fullVisitorId» STRING, «channelGrouping» STRING, «hits_time» INT, «geoNetwork_country» STRING, «geoNetwork_city» STRING, «totals_totalTransactionRevenue» INT, «totals_transactions» INT, «totals_timeOnSite» INT, «totals_pageviews» INT, «date» STRING, «visitId» INT, «hits_type» STRING, «hits_product_productRefundAmount» INT, «hits_product_productQuantity» INT, «hits_product_productPrice» INT, «hits_product_productRevenue» INT, «hits_product_productSKU» STRING, «hits_product_v2ProductName» STRING, «hits_product_v2ProductCategory» STRING, «hits_product_productVariant» STRING, «hits_item_currencyCode» STRING, «hits_item_itemQuantity» INT, «hits_item_itemRevenue» INT, «hits_transaction_transactionRevenue» INT, «hits_transaction_transactionId» STRING, «hits_page_pageTitle» STRING, «hits_page_searchKeyword» STRING, «hits_page_pagePathLevel1» STRING)

theorem eq (t0 : TableRel REV_TRANSACTIONS_schema) :
    (sql%([REV_TRANSACTIONS_schema]) "WITH deduped AS (SELECT DISTINCT \"fullVisitorId\", \"visitId\", \"channelGrouping\", \"geoNetwork_country\", \"totals_transactions\" FROM \"ECOMMERCE\".\"ECOMMERCE\".\"REV_TRANSACTIONS\"), multi_country AS (SELECT \"channelGrouping\" FROM deduped GROUP BY \"channelGrouping\" HAVING COUNT(DISTINCT \"geoNetwork_country\") > 1), country_sums AS (SELECT d.\"channelGrouping\", d.\"geoNetwork_country\", SUM(d.\"totals_transactions\") AS total_transactions FROM deduped AS d JOIN multi_country AS m ON d.\"channelGrouping\" = m.\"channelGrouping\" GROUP BY d.\"channelGrouping\", d.\"geoNetwork_country\"), ranked AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY \"channelGrouping\" ORDER BY total_transactions DESC) AS rn FROM country_sums) SELECT \"channelGrouping\", \"geoNetwork_country\" AS country, total_transactions FROM ranked WHERE rn = 1 ORDER BY \"channelGrouping\"") t0
  = (sql%([REV_TRANSACTIONS_schema]) "WITH deduped AS (SELECT DISTINCT \"fullVisitorId\", \"visitId\", \"channelGrouping\", \"geoNetwork_country\", \"totals_transactions\" FROM \"ECOMMERCE\".\"ECOMMERCE\".\"REV_TRANSACTIONS\"), channel_country_totals AS (SELECT \"channelGrouping\", \"geoNetwork_country\" AS \"COUNTRY\", SUM(\"totals_transactions\") AS \"TOTAL_TRANSACTIONS\" FROM deduped GROUP BY \"channelGrouping\", \"geoNetwork_country\"), multi_country AS (SELECT \"channelGrouping\" FROM channel_country_totals GROUP BY \"channelGrouping\" HAVING COUNT(DISTINCT \"COUNTRY\") > 1), ranked AS (SELECT cct.*, ROW_NUMBER() OVER (PARTITION BY cct.\"channelGrouping\" ORDER BY cct.\"TOTAL_TRANSACTIONS\" DESC) AS rnk FROM channel_country_totals AS cct JOIN multi_country AS mc ON cct.\"channelGrouping\" = mc.\"channelGrouping\") SELECT \"channelGrouping\", \"COUNTRY\", \"TOTAL_TRANSACTIONS\" FROM ranked WHERE rnk = 1 ORDER BY \"channelGrouping\"") t0
  := by first | sql_equiv | sorry

end N_sf_bq397_eq_1_2
