import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local198_eq_0_1

CREATE TABLE CUSTOMERS («CustomerId» INT, «FirstName» STRING, «LastName» STRING, «Company» STRING, «Address» STRING, «City» STRING, «State» STRING, «Country» STRING, «PostalCode» STRING, «Phone» STRING, «Fax» STRING, «Email» STRING, «SupportRepId» INT)
CREATE TABLE INVOICES («InvoiceId» INT, «CustomerId» INT, «InvoiceDate» STRING, «BillingAddress» STRING, «BillingCity» STRING, «BillingState» STRING, «BillingCountry» STRING, «BillingPostalCode» STRING, «Total» FLOAT)

theorem eq (t0 : TableRel CUSTOMERS_schema) (t1 : TableRel INVOICES_schema) :
    (sql%([CUSTOMERS_schema, INVOICES_schema]) "WITH country_sales AS (SELECT i.\"BillingCountry\", SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c ON i.\"CustomerId\" = c.\"CustomerId\" GROUP BY i.\"BillingCountry\" HAVING COUNT(DISTINCT c.\"CustomerId\") > 4) SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM country_sales") t0 t1
  ~= (sql%([CUSTOMERS_schema, INVOICES_schema]) "SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_total_sales FROM (SELECT c.\"Country\", SUM(i.\"Total\") AS total_sales FROM \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS i JOIN \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c ON i.\"CustomerId\" = c.\"CustomerId\" GROUP BY c.\"Country\" HAVING COUNT(DISTINCT c.\"CustomerId\") > 4) AS country_sales") t0 t1
  := by first | sql_equiv | sorry

end N_sf_local198_eq_0_1
