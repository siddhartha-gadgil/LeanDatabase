import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq340_eq_2_3

CREATE TABLE TOKEN_TRANSFERS («token_address» STRING, «from_address» STRING, «to_address» STRING, «value» STRING, «transaction_hash» STRING, «log_index» INT, «block_timestamp» INT, «block_number» INT, «block_hash» STRING)

theorem eq (t0 : TableRel TOKEN_TRANSFERS_schema) :
    (sql%([TOKEN_TRANSFERS_schema]) "WITH all_changes AS (SELECT \"to_address\" AS address, CAST(\"value\" AS DECIMAL(38, 0)) AS change, \"block_number\", \"log_index\" FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TOKEN_TRANSFERS\" WHERE \"token_address\" IN ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0', '0x1e15c05cbad367f044cbfbafda3d9a1510db5513') UNION ALL SELECT \"from_address\" AS address, -CAST(\"value\" AS DECIMAL(38, 0)) AS change, \"block_number\", \"log_index\" FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TOKEN_TRANSFERS\" WHERE \"token_address\" IN ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0', '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')), ranked AS (SELECT address, change, ROW_NUMBER() OVER (PARTITION BY address ORDER BY \"block_number\" DESC, \"log_index\" DESC) AS rn FROM all_changes WHERE address <> '0x0000000000000000000000000000000000000000') SELECT address AS \"ADDRESS\" FROM ranked WHERE rn = 1 ORDER BY ABS(change) DESC LIMIT 6") t0
  ~= (sql%([TOKEN_TRANSFERS_schema]) "WITH transfers AS (/* Incoming transfers: positive value for to_address */ SELECT \"to_address\" AS address, CAST(\"value\" AS DECIMAL(38, 0)) AS val, \"block_timestamp\", \"log_index\" FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TOKEN_TRANSFERS\" WHERE \"token_address\" IN ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0', '0x1e15c05cbad367f044cbfbafda3d9a1510db5513') UNION ALL /* Outgoing transfers: negative value for from_address */ SELECT \"from_address\" AS address, -CAST(\"value\" AS DECIMAL(38, 0)) AS val, \"block_timestamp\", \"log_index\" FROM \"CRYPTO\".\"CRYPTO_ETHEREUM\".\"TOKEN_TRANSFERS\" WHERE \"token_address\" IN ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0', '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')), running_balances AS (SELECT address, SUM(val) OVER (PARTITION BY address ORDER BY \"block_timestamp\", \"log_index\" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance, ROW_NUMBER() OVER (PARTITION BY address ORDER BY \"block_timestamp\" DESC, \"log_index\" DESC) AS rn FROM transfers WHERE address <> '0x0000000000000000000000000000000000000000'), last_two AS (SELECT address, MAX(CASE WHEN rn = 1 THEN balance END) AS current_balance, MAX(CASE WHEN rn = 2 THEN balance END) AS previous_balance FROM running_balances WHERE rn <= 2 GROUP BY address) SELECT address FROM last_two ORDER BY ABS(current_balance - COALESCE(previous_balance, 0)) DESC LIMIT 6") t0
  := by first | sql_equiv | sorry

end N_sf_bq340_eq_2_3
