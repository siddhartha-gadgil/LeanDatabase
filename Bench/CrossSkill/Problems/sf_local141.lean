import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_local141 — crossskill equivalence(s)

Question: How did each salesperson's annual total sales compare to their annual sales quota? Provide the difference between their total sales and the quota for each year, organized by salesperson and year.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_local141

CREATE TABLE SALESORDERHEADER («salesorderid» INT, «revisionnumber» INT, «orderdate» STRING, «duedate» STRING, «shipdate» STRING, «STATUS» STRING, «onlineorderflag» STRING, «purchaseordernumber» STRING, «accountnumber» STRING, «customerid» INT, «salespersonid» STRING, «territoryid» INT, «billtoaddressid» INT, «shiptoaddressid» INT, «shipmethodid» INT, «creditcardid» STRING, «creditcardapprovalcode» STRING, «currencyrateid» STRING, «subtotal» FLOAT, «taxamt» FLOAT, «freight» FLOAT, «totaldue» FLOAT, «comment» STRING, «rowguid» STRING, «modifieddate» STRING)
CREATE TABLE SALESPERSONQUOTAHISTORY («BusinessEntityID» INT, «QuotaDate» STRING, «SalesQuota» FLOAT, «rowguid» STRING, «ModifiedDate» STRING)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 : ∀ t,
    (sql%([SALESORDERHEADER_schema, SALESPERSONQUOTAHISTORY_schema]) "SELECT CAST(s.\"salespersonid\" AS INT) AS \"SalesPersonID\", CAST(EXTRACT(YEAR FROM TO_TIMESTAMP(s.\"orderdate\")) AS INT) AS \"SalesYear\", SUM(s.\"totaldue\") AS \"TotalSales\", CAST(q.\"QuotaYear\" AS INT) AS \"SalesQuotaYear\", q.\"AnnualQuota\" AS \"SalesQuota\", SUM(s.\"totaldue\") - q.\"AnnualQuota\" AS \"Amt_Above_or_Below_Quota\" FROM \"ADVENTUREWORKS\".\"ADVENTUREWORKS\".\"SALESORDERHEADER\" AS s JOIN (SELECT \"BusinessEntityID\", EXTRACT(YEAR FROM TO_TIMESTAMP(\"QuotaDate\")) AS \"QuotaYear\", SUM(\"SalesQuota\") AS \"AnnualQuota\" FROM \"ADVENTUREWORKS\".\"ADVENTUREWORKS\".\"SALESPERSONQUOTAHISTORY\" GROUP BY \"BusinessEntityID\", \"QuotaYear\") AS q ON CAST(s.\"salespersonid\" AS INT) = q.\"BusinessEntityID\" AND EXTRACT(YEAR FROM TO_TIMESTAMP(s.\"orderdate\")) = q.\"QuotaYear\" WHERE NOT s.\"salespersonid\" IS NULL AND s.\"salespersonid\" <> '' GROUP BY CAST(s.\"salespersonid\" AS INT), EXTRACT(YEAR FROM TO_TIMESTAMP(s.\"orderdate\")), q.\"QuotaYear\", q.\"AnnualQuota\" ORDER BY \"SalesPersonID\", \"SalesYear\"") t ~= (sql%([SALESORDERHEADER_schema, SALESPERSONQUOTAHISTORY_schema]) "WITH sales AS (SELECT CAST(\"salespersonid\" AS DECIMAL(38, 0)) AS \"SalesPersonID\", EXTRACT(YEAR FROM CAST(\"orderdate\" AS DATE)) AS \"SalesYear\", SUM(\"totaldue\") AS \"TotalSales\" FROM \"ADVENTUREWORKS\".\"ADVENTUREWORKS\".\"SALESORDERHEADER\" WHERE NOT \"salespersonid\" IS NULL AND \"salespersonid\" <> '' GROUP BY \"salespersonid\", EXTRACT(YEAR FROM CAST(\"orderdate\" AS DATE))), quotas AS (SELECT \"BusinessEntityID\" AS \"SalesPersonID\", EXTRACT(YEAR FROM CAST(\"QuotaDate\" AS DATE)) AS \"SalesQuotaYear\", SUM(\"SalesQuota\") AS \"SalesQuota\" FROM \"ADVENTUREWORKS\".\"ADVENTUREWORKS\".\"SALESPERSONQUOTAHISTORY\" GROUP BY \"BusinessEntityID\", EXTRACT(YEAR FROM CAST(\"QuotaDate\" AS DATE))) SELECT s.\"SalesPersonID\", s.\"SalesYear\", s.\"TotalSales\", q.\"SalesQuotaYear\", q.\"SalesQuota\", s.\"TotalSales\" - q.\"SalesQuota\" AS \"Amt_Above_or_Below_Quota\" FROM sales AS s INNER JOIN quotas AS q ON s.\"SalesPersonID\" = q.\"SalesPersonID\" AND s.\"SalesYear\" = q.\"SalesQuotaYear\" ORDER BY s.\"SalesPersonID\", s.\"SalesYear\"") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_local141
