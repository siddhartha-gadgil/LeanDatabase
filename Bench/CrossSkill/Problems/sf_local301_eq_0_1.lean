import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local301_eq_0_1

CREATE TABLE CLEANED_WEEKLY_SALES («week_date_formatted» STRING, «week_date» STRING, «region» STRING, «platform» STRING, «segment» STRING, «customer_type» STRING, «transactions» INT, «sales» INT, «week_number» INT, «month_number» INT, «calendar_year» INT, «age_band» STRING, «demographic» STRING, «avg_transaction» FLOAT)

theorem eq (t0 : TableRel CLEANED_WEEKLY_SALES_schema) :
    (sql%([CLEANED_WEEKLY_SALES_schema]) "WITH period_sales AS (SELECT \"calendar_year\", SUM(CASE WHEN \"week_number\" BETWEEN 21 AND 24 THEN \"sales\" ELSE 0 END) AS BEFORE_EFFECT, SUM(CASE WHEN \"week_number\" BETWEEN 25 AND 28 THEN \"sales\" ELSE 0 END) AS AFTER_EFFECT FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CLEANED_WEEKLY_SALES\" WHERE \"calendar_year\" IN (2018, 2019, 2020) AND \"week_number\" BETWEEN 21 AND 28 GROUP BY \"calendar_year\") SELECT BEFORE_EFFECT, AFTER_EFFECT, AFTER_EFFECT - BEFORE_EFFECT AS CHANGE_AMOUNT, ROUND(CAST((AFTER_EFFECT - BEFORE_EFFECT) * 100.0 AS DOUBLE PRECISION) / BEFORE_EFFECT, 2) AS PERCENT_CHANGE, \"calendar_year\" AS YEAR FROM period_sales ORDER BY \"calendar_year\"") t0
  ~= (sql%([CLEANED_WEEKLY_SALES_schema]) "WITH all_weeks AS (SELECT \"calendar_year\", \"week_number\", \"week_date_formatted\", SUM(\"sales\") AS weekly_sales, CASE WHEN CAST(TO_TIMESTAMP(\"week_date_formatted\", 'YYYY-MM-DD') AS DATE) < CAST(TO_TIMESTAMP(CAST(\"calendar_year\" AS VARCHAR) || '-06-15', 'YYYY-MM-DD') AS DATE) THEN 'before' ELSE 'after' END AS period FROM \"BANK_SALES_TRADING\".\"BANK_SALES_TRADING\".\"CLEANED_WEEKLY_SALES\" WHERE \"calendar_year\" IN (2018, 2019, 2020) GROUP BY \"calendar_year\", \"week_number\", \"week_date_formatted\"), ranked_weeks AS (SELECT *, CASE WHEN period = 'before' THEN ROW_NUMBER() OVER (PARTITION BY \"calendar_year\", period ORDER BY CAST(TO_TIMESTAMP(\"week_date_formatted\", 'YYYY-MM-DD') AS DATE) DESC) ELSE ROW_NUMBER() OVER (PARTITION BY \"calendar_year\", period ORDER BY CAST(TO_TIMESTAMP(\"week_date_formatted\", 'YYYY-MM-DD') AS DATE) ASC) END AS rn FROM all_weeks), filtered_weeks AS (SELECT \"calendar_year\", period, weekly_sales FROM ranked_weeks WHERE rn <= 4), aggregated AS (SELECT \"calendar_year\", SUM(CASE WHEN period = 'before' THEN weekly_sales ELSE 0 END) AS BEFORE_EFFECT, SUM(CASE WHEN period = 'after' THEN weekly_sales ELSE 0 END) AS AFTER_EFFECT FROM filtered_weeks GROUP BY \"calendar_year\") SELECT BEFORE_EFFECT, AFTER_EFFECT, (AFTER_EFFECT - BEFORE_EFFECT) AS CHANGE_AMOUNT, ROUND(CAST((AFTER_EFFECT - BEFORE_EFFECT) AS DOUBLE PRECISION) / BEFORE_EFFECT * 100, 2) AS PERCENT_CHANGE, \"calendar_year\" AS YEAR FROM aggregated ORDER BY \"calendar_year\"") t0
  := by first | sql_equiv | sorry

end N_sf_local301_eq_0_1
