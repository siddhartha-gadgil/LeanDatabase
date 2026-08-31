import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local284_eq_1_3

CREATE TABLE VEG_LOSS_RATE_DF («index» INT, «item_code» INT, «item_name» STRING)

theorem eq (t0 : TableRel VEG_LOSS_RATE_DF_schema) :
    (sql%([VEG_LOSS_RATE_DF_schema]) "WITH stats AS (SELECT AVG(\"loss_rate_%\") AS avg_lr, STDDEV(\"loss_rate_%\") AS std_lr FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"VEG_LOSS_RATE_DF\") SELECT avg_lr AS \"avg_loss_rate_%\", SUM(CASE WHEN \"loss_rate_%\" >= avg_lr - std_lr AND \"loss_rate_%\" <= avg_lr + std_lr THEN 1 ELSE 0 END) AS \"items_within_stdev\", SUM(CASE WHEN \"loss_rate_%\" > avg_lr + std_lr THEN 1 ELSE 0 END) AS \"above_stdev\", SUM(CASE WHEN \"loss_rate_%\" < avg_lr - std_lr THEN 1 ELSE 0 END) AS \"items_below_stdev\" FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"VEG_LOSS_RATE_DF\", stats GROUP BY avg_lr") t0
  = (sql%([VEG_LOSS_RATE_DF_schema]) "WITH stats AS (SELECT AVG(\"loss_rate_%\") AS avg_lr, STDDEV(\"loss_rate_%\") AS std_lr FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"VEG_LOSS_RATE_DF\") SELECT s.avg_lr AS \"avg_loss_rate_%\", SUM(CASE WHEN lr.\"loss_rate_%\" >= s.avg_lr - s.std_lr AND lr.\"loss_rate_%\" <= s.avg_lr + s.std_lr THEN 1 ELSE 0 END) AS \"items_within_stdev\", SUM(CASE WHEN lr.\"loss_rate_%\" > s.avg_lr + s.std_lr THEN 1 ELSE 0 END) AS \"above_stdev\", SUM(CASE WHEN lr.\"loss_rate_%\" < s.avg_lr - s.std_lr THEN 1 ELSE 0 END) AS \"items_below_stdev\" FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"VEG_LOSS_RATE_DF\" AS lr CROSS JOIN stats AS s GROUP BY s.avg_lr") t0
  := by first | sql_equiv | sorry

end N_sf_local284_eq_1_3
