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
theorem eq_0_1 :
    sql%([SALESORDERHEADER_schema, SALESPERSONQUOTAHISTORY_schema]) "SELECT \n    s.\"salespersonid\"::INT AS \"SalesPersonID\",\n    EXTRACT(YEAR FROM TO_TIMESTAMP(s.\"orderdate\"))::INT AS \"SalesYear\",\n    SUM(s.\"totaldue\") AS \"TotalSales\",\n    q.\"QuotaYear\"::INT AS \"SalesQuotaYear\",\n    q.\"AnnualQuota\" AS \"SalesQuota\",\n    SUM(s.\"totaldue\") - q.\"AnnualQuota\" AS \"Amt_Above_or_Below_Quota\"\nFROM \"ADVENTUREWORKS\".\"ADVENTUREWORKS\".\"SALESORDERHEADER\" s\nJOIN (\n    SELECT \n        \"BusinessEntityID\",\n        EXTRACT(YEAR FROM TO_TIMESTAMP(\"QuotaDate\")) AS \"QuotaYear\",\n        SUM(\"SalesQuota\") AS \"AnnualQuota\"\n    FROM \"ADVENTUREWORKS\".\"ADVENTUREWORKS\".\"SALESPERSONQUOTAHISTORY\"\n    GROUP BY \"BusinessEntityID\", \"QuotaYear\"\n) q ON s.\"salespersonid\"::INT = q.\"BusinessEntityID\" \n    AND EXTRACT(YEAR FROM TO_TIMESTAMP(s.\"orderdate\")) = q.\"QuotaYear\"\nWHERE s.\"salespersonid\" IS NOT NULL AND s.\"salespersonid\" != ''\nGROUP BY s.\"salespersonid\"::INT, \n    EXTRACT(YEAR FROM TO_TIMESTAMP(s.\"orderdate\")),\n    q.\"QuotaYear\",\n    q.\"AnnualQuota\"\nORDER BY \"SalesPersonID\", \"SalesYear\";" = sql%([SALESORDERHEADER_schema, SALESPERSONQUOTAHISTORY_schema]) "WITH sales AS (\n    SELECT\n        \"salespersonid\"::NUMBER AS \"SalesPersonID\",\n        EXTRACT(YEAR FROM \"orderdate\"::DATE) AS \"SalesYear\",\n        SUM(\"totaldue\") AS \"TotalSales\"\n    FROM \"ADVENTUREWORKS\".\"ADVENTUREWORKS\".\"SALESORDERHEADER\"\n    WHERE \"salespersonid\" IS NOT NULL AND \"salespersonid\" != ''\n    GROUP BY \"salespersonid\", EXTRACT(YEAR FROM \"orderdate\"::DATE)\n),\nquotas AS (\n    SELECT\n        \"BusinessEntityID\" AS \"SalesPersonID\",\n        EXTRACT(YEAR FROM \"QuotaDate\"::DATE) AS \"SalesQuotaYear\",\n        SUM(\"SalesQuota\") AS \"SalesQuota\"\n    FROM \"ADVENTUREWORKS\".\"ADVENTUREWORKS\".\"SALESPERSONQUOTAHISTORY\"\n    GROUP BY \"BusinessEntityID\", EXTRACT(YEAR FROM \"QuotaDate\"::DATE)\n)\nSELECT\n    s.\"SalesPersonID\",\n    s.\"SalesYear\",\n    s.\"TotalSales\",\n    q.\"SalesQuotaYear\",\n    q.\"SalesQuota\",\n    s.\"TotalSales\" - q.\"SalesQuota\" AS \"Amt_Above_or_Below_Quota\"\nFROM sales s\nINNER JOIN quotas q\n    ON s.\"SalesPersonID\" = q.\"SalesPersonID\"\n    AND s.\"SalesYear\" = q.\"SalesQuotaYear\"\nORDER BY s.\"SalesPersonID\", s.\"SalesYear\";" := by
  first | sql_equiv | sorry

end Bench_sf_local141
