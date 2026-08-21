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
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_sales AS (\n    SELECT\n        i.\"BillingCountry\",\n        SUM(i.\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" i\n    JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" c\n        ON i.\"CustomerId\" = c.\"CustomerId\"\n    GROUP BY i.\"BillingCountry\"\n    HAVING COUNT(DISTINCT c.\"CustomerId\") > 4\n)\nSELECT\n    MEDIAN(total_sales) AS median_total_sales\nFROM country_sales;") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT MEDIAN(total_sales) AS median_total_sales\nFROM (\n    SELECT c.\"Country\", SUM(i.\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" i\n    JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" c\n      ON i.\"CustomerId\" = c.\"CustomerId\"\n    GROUP BY c.\"Country\"\n    HAVING COUNT(DISTINCT c.\"CustomerId\") > 4\n) country_sales;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_sales AS (\n    SELECT\n        i.\"BillingCountry\",\n        SUM(i.\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" i\n    JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" c\n        ON i.\"CustomerId\" = c.\"CustomerId\"\n    GROUP BY i.\"BillingCountry\"\n    HAVING COUNT(DISTINCT c.\"CustomerId\") > 4\n)\nSELECT\n    MEDIAN(total_sales) AS median_total_sales\nFROM country_sales;") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_customer_counts AS (\n    SELECT \"Country\", COUNT(*) AS customer_count\n    FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\"\n    GROUP BY \"Country\"\n    HAVING COUNT(*) > 4\n),\ncountry_total_sales AS (\n    SELECT i.\"BillingCountry\" AS country, SUM(i.\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" i\n    GROUP BY i.\"BillingCountry\"\n)\nSELECT MEDIAN(cts.total_sales) AS \"median_total_sales\"\nFROM country_total_sales cts\nINNER JOIN country_customer_counts cc\n    ON cts.country = cc.\"Country\";") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_3 : ∀ t,
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_sales AS (\n    SELECT\n        i.\"BillingCountry\",\n        SUM(i.\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" i\n    JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" c\n        ON i.\"CustomerId\" = c.\"CustomerId\"\n    GROUP BY i.\"BillingCountry\"\n    HAVING COUNT(DISTINCT c.\"CustomerId\") > 4\n)\nSELECT\n    MEDIAN(total_sales) AS median_total_sales\nFROM country_sales;") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT MEDIAN(total_sales) AS median_total_sales\nFROM (\n    SELECT \"BillingCountry\", SUM(\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\"\n    WHERE \"BillingCountry\" IN (\n        SELECT \"Country\"\n        FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\"\n        GROUP BY \"Country\"\n        HAVING COUNT(*) > 4\n    )\n    GROUP BY \"BillingCountry\"\n) country_sales;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT MEDIAN(total_sales) AS median_total_sales\nFROM (\n    SELECT c.\"Country\", SUM(i.\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" i\n    JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" c\n      ON i.\"CustomerId\" = c.\"CustomerId\"\n    GROUP BY c.\"Country\"\n    HAVING COUNT(DISTINCT c.\"CustomerId\") > 4\n) country_sales;") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_customer_counts AS (\n    SELECT \"Country\", COUNT(*) AS customer_count\n    FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\"\n    GROUP BY \"Country\"\n    HAVING COUNT(*) > 4\n),\ncountry_total_sales AS (\n    SELECT i.\"BillingCountry\" AS country, SUM(i.\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" i\n    GROUP BY i.\"BillingCountry\"\n)\nSELECT MEDIAN(cts.total_sales) AS \"median_total_sales\"\nFROM country_total_sales cts\nINNER JOIN country_customer_counts cc\n    ON cts.country = cc.\"Country\";") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_3 :
    sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT MEDIAN(total_sales) AS median_total_sales\nFROM (\n    SELECT c.\"Country\", SUM(i.\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" i\n    JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" c\n      ON i.\"CustomerId\" = c.\"CustomerId\"\n    GROUP BY c.\"Country\"\n    HAVING COUNT(DISTINCT c.\"CustomerId\") > 4\n) country_sales;" = sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT MEDIAN(total_sales) AS median_total_sales\nFROM (\n    SELECT \"BillingCountry\", SUM(\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\"\n    WHERE \"BillingCountry\" IN (\n        SELECT \"Country\"\n        FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\"\n        GROUP BY \"Country\"\n        HAVING COUNT(*) > 4\n    )\n    GROUP BY \"BillingCountry\"\n) country_sales;" := by
  first | sql_equiv | sorry

theorem eq_2_3 : ∀ t,
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_customer_counts AS (\n    SELECT \"Country\", COUNT(*) AS customer_count\n    FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\"\n    GROUP BY \"Country\"\n    HAVING COUNT(*) > 4\n),\ncountry_total_sales AS (\n    SELECT i.\"BillingCountry\" AS country, SUM(i.\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" i\n    GROUP BY i.\"BillingCountry\"\n)\nSELECT MEDIAN(cts.total_sales) AS \"median_total_sales\"\nFROM country_total_sales cts\nINNER JOIN country_customer_counts cc\n    ON cts.country = cc.\"Country\";") t ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT MEDIAN(total_sales) AS median_total_sales\nFROM (\n    SELECT \"BillingCountry\", SUM(\"Total\") AS total_sales\n    FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\"\n    WHERE \"BillingCountry\" IN (\n        SELECT \"Country\"\n        FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\"\n        GROUP BY \"Country\"\n        HAVING COUNT(*) > 4\n    )\n    GROUP BY \"BillingCountry\"\n) country_sales;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_local198
