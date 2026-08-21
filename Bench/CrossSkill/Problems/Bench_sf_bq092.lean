import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq092 — crossskill equivalence(s)

Question: In April 2023, what are the highest and lowest balances across all Dash addresses when calculating the net balance for each address using double-entry bookkeeping (where inputs are treated as debits/negative values and outputs as credits/positive values)? Consider all transactions filtered by block_timestamp_month='2023-04-01', and when an address appears as an array in the data, concatenate the array elements into a comma-separated string. For each address and type combination, sum all the values to determine the balance.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq092

CREATE TABLE TRANSACTIONS («block_height» INT, «block_timestamp» STRING, «block_timestamp_truncated» INT, «txhash» STRING, «transaction_type» STRING, «gas_wanted» INT, «gas_used» INT, «sender» STRING, «fee» STRING, «memo» STRING)
CREATE TABLE OUTPUTS («transaction_hash» STRING, «block_hash» STRING, «block_number» INT, «block_timestamp» INT, «index» INT, «script_asm» STRING, «script_hex» STRING, «required_signatures» INT, «type» STRING, «addresses» STRING, «value» INT)
CREATE TABLE INPUTS («transaction_hash» STRING, «block_hash» STRING, «block_number» INT, «block_timestamp» INT, «index» INT, «spent_transaction_hash» STRING, «spent_output_index» INT, «script_asm» STRING, «script_hex» STRING, «sequence» INT, «required_signatures» INT, «type» STRING, «addresses» STRING, «value» INT)
CREATE TABLE BALANCES («address» STRING, «eth_balance» INT)

theorem eq_0_1 : ∀ t,
    (sql%([TRANSACTIONS_schema, OUTPUTS_schema, INPUTS_schema, BALANCES_schema]) "WITH inputs AS (\n  SELECT \n    ARRAY_TO_STRING(i.\"addresses\", ',') AS address,\n    i.\"type\" AS type,\n    - i.\"value\" AS amount\n  FROM \"CRYPTO\".\"CRYPTO_DASH\".\"INPUTS\" i\n  INNER JOIN \"CRYPTO\".\"CRYPTO_DASH\".\"TRANSACTIONS\" t ON i.\"transaction_hash\" = t.\"hash\"\n  WHERE t.\"block_timestamp_month\" = '2023-04-01'\n),\noutputs AS (\n  SELECT \n    ARRAY_TO_STRING(o.\"addresses\", ',') AS address,\n    o.\"type\" AS type,\n    o.\"value\" AS amount\n  FROM \"CRYPTO\".\"CRYPTO_DASH\".\"OUTPUTS\" o\n  INNER JOIN \"CRYPTO\".\"CRYPTO_DASH\".\"TRANSACTIONS\" t ON o.\"transaction_hash\" = t.\"hash\"\n  WHERE t.\"block_timestamp_month\" = '2023-04-01'\n),\ncombined AS (\n  SELECT address, type, amount FROM inputs\n  UNION ALL\n  SELECT address, type, amount FROM outputs\n),\nbalances AS (\n  SELECT address, type, SUM(amount) AS balance\n  FROM combined\n  GROUP BY address, type\n)\nSELECT 'HIGHEST' AS extreme, address, type, balance\nFROM balances WHERE balance = (SELECT MAX(balance) FROM balances)\nUNION ALL\nSELECT 'LOWEST' AS extreme, address, type, balance\nFROM balances WHERE balance = (SELECT MIN(balance) FROM balances);") t ~= (sql%([TRANSACTIONS_schema, OUTPUTS_schema, INPUTS_schema, BALANCES_schema]) "WITH credits AS (\n  SELECT \n    ARRAY_TO_STRING(o.\"addresses\", ',') AS address,\n    o.\"type\" AS addr_type,\n    o.\"value\" AS val\n  FROM \"CRYPTO\".\"CRYPTO_DASH\".\"OUTPUTS\" o\n  JOIN \"CRYPTO\".\"CRYPTO_DASH\".\"TRANSACTIONS\" t ON o.\"transaction_hash\" = t.\"hash\"\n  WHERE t.\"block_timestamp_month\" = '2023-04-01'\n),\ndebits AS (\n  SELECT \n    ARRAY_TO_STRING(i.\"addresses\", ',') AS address,\n    i.\"type\" AS addr_type,\n    -1 * i.\"value\" AS val\n  FROM \"CRYPTO\".\"CRYPTO_DASH\".\"INPUTS\" i\n  JOIN \"CRYPTO\".\"CRYPTO_DASH\".\"TRANSACTIONS\" t ON i.\"transaction_hash\" = t.\"hash\"\n  WHERE t.\"block_timestamp_month\" = '2023-04-01'\n),\ncombined AS (\n  SELECT address, addr_type, val FROM credits\n  UNION ALL\n  SELECT address, addr_type, val FROM debits\n),\nbalances AS (\n  SELECT address, addr_type, SUM(val) AS balance\n  FROM combined\n  GROUP BY address, addr_type\n)\nSELECT * FROM (\n  SELECT 'HIGHEST' AS extreme, address, addr_type AS type, balance FROM balances ORDER BY balance DESC LIMIT 1\n)\nUNION ALL\nSELECT * FROM (\n  SELECT 'LOWEST' AS extreme, address, addr_type AS type, balance FROM balances ORDER BY balance ASC LIMIT 1\n);") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq092
