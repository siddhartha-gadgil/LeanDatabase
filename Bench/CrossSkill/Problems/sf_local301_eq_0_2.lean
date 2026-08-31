import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local301_eq_0_2

CREATE TABLE CLEANED_WEEKLY_SALES («week_date_formatted» STRING, «week_date» STRING, «region» STRING, «platform» STRING, «segment» STRING, «customer_type» STRING, «transactions» INT, «sales» INT, «week_number» INT, «month_number» INT, «calendar_year» INT, «age_band» STRING, «demographic» STRING, «avg_transaction» FLOAT)

theorem eq (t0 : TableRel CLEANED_WEEKLY_SALES_schema) :
    (sql%([CLEANED_WEEKLY_SALES_schema]) "WITH period_sales AS (SELECT \"calendar_year\", SUM(CASE WHEN \"week_number\" BETWEEN 21 AND 24 THEN \"sales\" ELSE 0 END) AS BEFORE_EFFECT, SUM(CASE WHEN \"week_number\" BETWEEN 25 AND 28 THEN \"sales\" ELSE 0 END) AS AFTER_EFFECT FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CLEANED_WEEKLY_SALES\" WHERE \"calendar_year\" IN (2018, 2019, 2020) AND \"week_number\" BETWEEN 21 AND 28 GROUP BY \"calendar_year\") SELECT BEFORE_EFFECT, AFTER_EFFECT, AFTER_EFFECT - BEFORE_EFFECT AS CHANGE_AMOUNT, ROUND(CAST((AFTER_EFFECT - BEFORE_EFFECT) * 100.0 AS DOUBLE PRECISION) / BEFORE_EFFECT, 2) AS PERCENT_CHANGE, \"calendar_year\" AS YEAR FROM period_sales ORDER BY \"calendar_year\"") t0
  ~= (sql%([CLEANED_WEEKLY_SALES_schema]) "WITH yearly_june15 AS (SELECT \"calendar_year\", DATE_FROM_PARTS(\"calendar_year\", 6, 15) AS june15 FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CLEANED_WEEKLY_SALES\" GROUP BY \"calendar_year\"), before_sales AS (SELECT c.\"calendar_year\", SUM(c.\"sales\") AS before_effect FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CLEANED_WEEKLY_SALES\" AS c JOIN yearly_june15 AS y ON c.\"calendar_year\" = y.\"calendar_year\" WHERE c.\"week_date\" >= y.june15 + INTERVAL '-4 WEEK' AND c.\"week_date\" < y.june15 GROUP BY c.\"calendar_year\"), after_sales AS (SELECT c.\"calendar_year\", SUM(c.\"sales\") AS after_effect FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CLEANED_WEEKLY_SALES\" AS c JOIN yearly_june15 AS y ON c.\"calendar_year\" = y.\"calendar_year\" WHERE c.\"week_date\" >= y.june15 AND c.\"week_date\" < y.june15 + INTERVAL '4 WEEK' GROUP BY c.\"calendar_year\") SELECT b.before_effect AS \"BEFORE_EFFECT\", a.after_effect AS \"AFTER_EFFECT\", a.after_effect - b.before_effect AS \"CHANGE_AMOUNT\", ROUND(CAST(100.0 * (a.after_effect - b.before_effect) AS DOUBLE PRECISION) / b.before_effect, 2) AS \"PERCENT_CHANGE\", b.\"calendar_year\" AS \"YEAR\" FROM before_sales AS b JOIN after_sales AS a ON b.\"calendar_year\" = a.\"calendar_year\" ORDER BY b.\"calendar_year\"") t0
  := by first | sql_equiv | sorry

end N_sf_local301_eq_0_2
