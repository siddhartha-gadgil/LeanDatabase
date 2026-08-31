import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq371_eq_1_2

CREATE TABLE SALES_INVOICES («InvoiceID» INT, «CustomerID» INT, «BillToCustomerID» INT, «OrderID» INT, «DeliveryMethodID» INT, «ContactPersonID» INT, «AccountsPersonID» INT, «SalespersonPersonID» INT, «PackedByPersonID» INT, «InvoiceDate» STRING, «CustomerPurchaseOrderNumber» INT, «IsCreditNote» INT, «CreditNoteReason» FLOAT, «Comments» FLOAT, «DeliveryInstructions» STRING, «InternalComments» FLOAT, «TotalDryItems» INT, «TotalChillerItems» INT, «DeliveryRun» FLOAT, «RunPosition» FLOAT, «ReturnedDeliveryData» STRING, «ConfirmedDeliveryTime» STRING, «ConfirmedReceivedBy» STRING, «LastEditedBy» INT, «LastEditedWhen» STRING)
CREATE TABLE SALES_INVOICELINES («InvoiceLineID» INT, «InvoiceID» INT, «StockItemID» INT, «Description» STRING, «PackageTypeID» INT, «Quantity» INT, «UnitPrice» FLOAT, «TaxRate» FLOAT, «TaxAmount» FLOAT, «LineProfit» FLOAT, «ExtendedPrice» FLOAT, «LastEditedBy» INT, «LastEditedWhen» INT)

theorem eq (t0 : TableRel SALES_INVOICES_schema) (t1 : TableRel SALES_INVOICELINES_schema) :
    (sql%([SALES_INVOICES_schema, SALES_INVOICELINES_schema]) "WITH invoice_totals AS (SELECT i.\"InvoiceID\", CASE WHEN CAST(SUBSTRING(i.\"InvoiceDate\" FROM 6 FOR 2) AS INT) BETWEEN 1 AND 3 THEN 'Q1' WHEN CAST(SUBSTRING(i.\"InvoiceDate\" FROM 6 FOR 2) AS INT) BETWEEN 4 AND 6 THEN 'Q2' WHEN CAST(SUBSTRING(i.\"InvoiceDate\" FROM 6 FOR 2) AS INT) BETWEEN 7 AND 9 THEN 'Q3' WHEN CAST(SUBSTRING(i.\"InvoiceDate\" FROM 6 FOR 2) AS INT) BETWEEN 10 AND 12 THEN 'Q4' END AS quarter, SUM(il.\"Quantity\" * il.\"UnitPrice\") AS invoice_value FROM \"WIDE_WORLD_IMPORTERS\".\"WIDE_WORLD_IMPORTERS\".\"SALES_INVOICES\" AS i JOIN \"WIDE_WORLD_IMPORTERS\".\"WIDE_WORLD_IMPORTERS\".\"SALES_INVOICELINES\" AS il ON i.\"InvoiceID\" = il.\"InvoiceID\" WHERE LEFT(i.\"InvoiceDate\", 4) = '2013' GROUP BY i.\"InvoiceID\", quarter), quarterly_avg AS (SELECT quarter, AVG(invoice_value) AS avg_invoice_value FROM invoice_totals GROUP BY quarter) SELECT MAX(avg_invoice_value) - MIN(avg_invoice_value) AS DIFFERENCE FROM quarterly_avg") t0 t1
  ~= (sql%([SALES_INVOICES_schema, SALES_INVOICELINES_schema]) "WITH invoice_totals AS (SELECT i.\"InvoiceID\", QUARTER(CAST(i.\"InvoiceDate\" AS DATE)) AS qtr, SUM(il.\"UnitPrice\" * il.\"Quantity\") AS invoice_total FROM \"WIDE_WORLD_IMPORTERS\".\"WIDE_WORLD_IMPORTERS\".\"SALES_INVOICES\" AS i JOIN \"WIDE_WORLD_IMPORTERS\".\"WIDE_WORLD_IMPORTERS\".\"SALES_INVOICELINES\" AS il ON i.\"InvoiceID\" = il.\"InvoiceID\" WHERE EXTRACT(YEAR FROM CAST(i.\"InvoiceDate\" AS DATE)) = 2013 GROUP BY i.\"InvoiceID\", QUARTER(CAST(i.\"InvoiceDate\" AS DATE))), quarterly_avg AS (SELECT qtr, AVG(invoice_total) AS avg_invoice_value FROM invoice_totals GROUP BY qtr) SELECT MAX(avg_invoice_value) - MIN(avg_invoice_value) AS \"DIFFERENCE\" FROM quarterly_avg") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq371_eq_1_2
