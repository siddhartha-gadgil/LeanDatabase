import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local198 — crossskill equivalence(s)

Question: Using the sales data, what is the median value of total sales made in countries where the number of customers is greater than 4?

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local198

CREATE TABLE CUSTOMERS («CustomerId» INT, «FirstName» STRING, «LastName» STRING, «Company» STRING, «Address» STRING, «City» STRING, «State» STRING, «Country» STRING, «PostalCode» STRING, «Phone» STRING, «Fax» STRING, «Email» STRING, «SupportRepId» INT)
CREATE TABLE INVOICES («InvoiceId» INT, «CustomerId» INT, «InvoiceDate» STRING, «BillingAddress» STRING, «BillingCity» STRING, «BillingState» STRING, «BillingCountry» STRING, «BillingPostalCode» STRING, «Total» FLOAT)

theorem eq_0_1 : ∀ t,
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_sales AS (SELECT i.\"BillingCountry\", SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c ON i.\"CustomerId\" = c.\"CustomerId\" GROUP BY i.\"BillingCountry\" HAVING COUNT(DISTINCT c.\"CustomerId\") > 4) SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM country_sales") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM (SELECT c.\"Country\", SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c ON i.\"CustomerId\" = c.\"CustomerId\" GROUP BY c.\"Country\" HAVING COUNT(DISTINCT c.\"CustomerId\") > 4) AS country_sales") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_sales AS (SELECT i.\"BillingCountry\", SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c ON i.\"CustomerId\" = c.\"CustomerId\" GROUP BY i.\"BillingCountry\" HAVING COUNT(DISTINCT c.\"CustomerId\") > 4) SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM country_sales") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_customer_counts AS (SELECT \"Country\", COUNT(*) AS customer_count FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" GROUP BY \"Country\" HAVING COUNT(*) > 4), country_total_sales AS (SELECT i.\"BillingCountry\" AS country, SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i GROUP BY i.\"BillingCountry\") SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cts.total_sales) AS \"median_total_sales\" FROM country_total_sales AS cts INNER JOIN country_customer_counts AS cc ON cts.country = cc.\"Country\"") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_3 : ∀ t,
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_sales AS (SELECT i.\"BillingCountry\", SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c ON i.\"CustomerId\" = c.\"CustomerId\" GROUP BY i.\"BillingCountry\" HAVING COUNT(DISTINCT c.\"CustomerId\") > 4) SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM country_sales") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM (SELECT \"BillingCountry\", SUM(\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" WHERE \"BillingCountry\" IN (SELECT \"Country\" FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" GROUP BY \"Country\" HAVING COUNT(*) > 4) GROUP BY \"BillingCountry\") AS country_sales") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM (SELECT c.\"Country\", SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c ON i.\"CustomerId\" = c.\"CustomerId\" GROUP BY c.\"Country\" HAVING COUNT(DISTINCT c.\"CustomerId\") > 4) AS country_sales") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_customer_counts AS (SELECT \"Country\", COUNT(*) AS customer_count FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" GROUP BY \"Country\" HAVING COUNT(*) > 4), country_total_sales AS (SELECT i.\"BillingCountry\" AS country, SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i GROUP BY i.\"BillingCountry\") SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cts.total_sales) AS \"median_total_sales\" FROM country_total_sales AS cts INNER JOIN country_customer_counts AS cc ON cts.country = cc.\"Country\"") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM (SELECT c.\"Country\", SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c ON i.\"CustomerId\" = c.\"CustomerId\" GROUP BY c.\"Country\" HAVING COUNT(DISTINCT c.\"CustomerId\") > 4) AS country_sales" = sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM (SELECT \"BillingCountry\", SUM(\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" WHERE \"BillingCountry\" IN (SELECT \"Country\" FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" GROUP BY \"Country\" HAVING COUNT(*) > 4) GROUP BY \"BillingCountry\") AS country_sales" := by
  first | sql_equiv | sorry

theorem eq_2_3 : ∀ t,
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_customer_counts AS (SELECT \"Country\", COUNT(*) AS customer_count FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" GROUP BY \"Country\" HAVING COUNT(*) > 4), country_total_sales AS (SELECT i.\"BillingCountry\" AS country, SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i GROUP BY i.\"BillingCountry\") SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cts.total_sales) AS \"median_total_sales\" FROM country_total_sales AS cts INNER JOIN country_customer_counts AS cc ON cts.country = cc.\"Country\"") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM (SELECT \"BillingCountry\", SUM(\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" WHERE \"BillingCountry\" IN (SELECT \"Country\" FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" GROUP BY \"Country\" HAVING COUNT(*) > 4) GROUP BY \"BillingCountry\") AS country_sales") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_local198
