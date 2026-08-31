import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq342_eq_0_1

CREATE TABLE TOKEN_TRANSFERS («token_address» STRING, «from_address» STRING, «to_address» STRING, «value» STRING, «transaction_hash» STRING, «log_index» INT, «block_timestamp» INT, «block_number» INT, «block_hash» STRING)

theorem eq (t0 : TableRel TOKEN_TRANSFERS_schema) :
    (sql%([TOKEN_TRANSFERS_schema]) "WITH hourly_totals AS (SELECT EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000)) AS yr, DATE_TRUNC('HOUR', TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000)) AS hr, SUM(CAST(\"value\" AS DOUBLE PRECISION)) AS hourly_total FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TOKEN_TRANSFERS\" WHERE \"token_address\" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac' AND TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) >= '2019-01-01' AND TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2021-01-01' AND (\"from_address\" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d' OR \"to_address\" = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f') GROUP BY yr, hr), hourly_changes AS (SELECT yr, hr, hourly_total, hourly_total - LAG(hourly_total) OVER (PARTITION BY yr ORDER BY hr) AS hourly_change FROM hourly_totals), yearly_avg AS (SELECT yr, AVG(hourly_change) AS avg_hourly_change FROM hourly_changes WHERE NOT hourly_change IS NULL GROUP BY yr) SELECT MAX(CASE WHEN yr = 2020 THEN avg_hourly_change END) - MAX(CASE WHEN yr = 2019 THEN avg_hourly_change END) AS DIFFERENCE_2020_MINUS_2019 FROM yearly_avg") t0
  ~= (sql%([TOKEN_TRANSFERS_schema]) "WITH hourly AS (SELECT DATE_TRUNC('HOUR', TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000)) AS hour_ts, EXTRACT(YEAR FROM TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000)) AS yr, SUM(CAST(\"value\" AS DOUBLE PRECISION)) AS hourly_value FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TOKEN_TRANSFERS\" WHERE \"token_address\" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac' AND (\"from_address\" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d' OR \"to_address\" = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f') AND TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) >= '2019-01-01' AND TO_TIMESTAMP(CAST(\"block_timestamp\" AS DOUBLE PRECISION) / 1000000) < '2021-01-01' GROUP BY hour_ts, yr), changes AS (SELECT yr, hour_ts, hourly_value, hourly_value - LAG(hourly_value) OVER (PARTITION BY yr ORDER BY hour_ts) AS hourly_change FROM hourly), yearly_avg AS (SELECT yr, AVG(hourly_change) AS avg_hourly_change FROM changes WHERE NOT hourly_change IS NULL GROUP BY yr) SELECT MAX(CASE WHEN yr = 2020 THEN avg_hourly_change END) - MAX(CASE WHEN yr = 2019 THEN avg_hourly_change END) AS DIFFERENCE_2020_MINUS_2019 FROM yearly_avg") t0
  := by first | sql_equiv | sorry

end N_sf_bq342_eq_0_1
