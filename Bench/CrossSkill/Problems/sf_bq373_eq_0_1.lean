import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq373_eq_0_1

CREATE TABLE SALES_INVOICES («InvoiceID» INT, «CustomerID» INT, «BillToCustomerID» INT, «OrderID» INT, «DeliveryMethodID» INT, «ContactPersonID» INT, «AccountsPersonID» INT, «SalespersonPersonID» INT, «PackedByPersonID» INT, «InvoiceDate» STRING, «CustomerPurchaseOrderNumber» INT, «IsCreditNote» INT, «CreditNoteReason» FLOAT, «Comments» FLOAT, «DeliveryInstructions» STRING, «InternalComments» FLOAT, «TotalDryItems» INT, «TotalChillerItems» INT, «DeliveryRun» FLOAT, «RunPosition» FLOAT, «ReturnedDeliveryData» STRING, «ConfirmedDeliveryTime» STRING, «ConfirmedReceivedBy» STRING, «LastEditedBy» INT, «LastEditedWhen» STRING)
CREATE TABLE SALES_INVOICELINES («InvoiceLineID» INT, «InvoiceID» INT, «StockItemID» INT, «Description» STRING, «PackageTypeID» INT, «Quantity» INT, «UnitPrice» FLOAT, «TaxRate» FLOAT, «TaxAmount» FLOAT, «LineProfit» FLOAT, «ExtendedPrice» FLOAT, «LastEditedBy» INT, «LastEditedWhen» INT)

theorem eq (t0 : TableRel SALES_INVOICES_schema) (t1 : TableRel SALES_INVOICELINES_schema) :
    (sql%([SALES_INVOICES_schema, SALES_INVOICELINES_schema]) "WITH customer_total AS (SELECT i.\"CustomerID\", SUM(il.\"ExtendedPrice\") AS total_spending FROM \"WIDE_WORLD_IMPORTERS\".\"WIDE_WORLD_IMPORTERS\".\"SALES_INVOICES\" AS i JOIN \"WIDE_WORLD_IMPORTERS\".\"WIDE_WORLD_IMPORTERS\".\"SALES_INVOICELINES\" AS il ON i.\"InvoiceID\" = il.\"InvoiceID\" WHERE i.\"InvoiceDate\" >= '2014-01-01' AND i.\"InvoiceDate\" < '2015-01-01' GROUP BY i.\"CustomerID\"), avg_monthly AS (SELECT \"CustomerID\", CAST(total_spending AS DOUBLE PRECISION) / 12 AS avg_monthly_spend FROM customer_total) SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_spend) AS MEDIAN_AVG_MONTHLY_SPEND FROM avg_monthly") t0 t1
  ~= (sql%([SALES_INVOICES_schema, SALES_INVOICELINES_schema]) "SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_monthly_spending) AS MEDIAN_AVG_MONTHLY_SPEND FROM (SELECT i.\"CustomerID\", CAST(SUM(CAST(il.\"ExtendedPrice\" AS DECIMAL(18, 2))) AS DOUBLE PRECISION) / 12 AS avg_monthly_spending FROM \"WIDE_WORLD_IMPORTERS\".\"WIDE_WORLD_IMPORTERS\".\"SALES_INVOICES\" AS i JOIN \"WIDE_WORLD_IMPORTERS\".\"WIDE_WORLD_IMPORTERS\".\"SALES_INVOICELINES\" AS il ON i.\"InvoiceID\" = il.\"InvoiceID\" WHERE i.\"InvoiceDate\" >= '2014-01-01' AND i.\"InvoiceDate\" < '2015-01-01' GROUP BY i.\"CustomerID\")") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq373_eq_0_1
