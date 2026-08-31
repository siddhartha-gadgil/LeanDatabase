import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_local054_eq_0_3

CREATE TABLE CUSTOMERS («CustomerId» INT, «FirstName» STRING, «LastName» STRING, «Company» STRING, «Address» STRING, «City» STRING, «State» STRING, «Country» STRING, «PostalCode» STRING, «Phone» STRING, «Fax» STRING, «Email» STRING, «SupportRepId» INT)
CREATE TABLE TRACKS («TrackId» INT, «Name» STRING, «AlbumId» INT, «MediaTypeId» INT, «GenreId» INT, «Composer» STRING, «Milliseconds» INT, «Bytes» INT, «UnitPrice» FLOAT)
CREATE TABLE ALBUMS («AlbumId» INT, «Title» STRING, «ArtistId» INT)
CREATE TABLE ARTISTS («ArtistId» INT, «Name» STRING)
CREATE TABLE INVOICES («InvoiceId» INT, «CustomerId» INT, «InvoiceDate» STRING, «BillingAddress» STRING, «BillingCity» STRING, «BillingState» STRING, «BillingCountry» STRING, «BillingPostalCode» STRING, «Total» FLOAT)
CREATE TABLE INVOICE_ITEMS («InvoiceLineId» INT, «InvoiceId» INT, «TrackId» INT, «UnitPrice» FLOAT, «Quantity» INT)

theorem eq (t0 : TableRel CUSTOMERS_schema) (t1 : TableRel TRACKS_schema) (t2 : TableRel ALBUMS_schema) (t3 : TableRel ARTISTS_schema) (t4 : TableRel INVOICES_schema) (t5 : TableRel INVOICE_ITEMS_schema) :
    (sql%([CUSTOMERS_schema, TRACKS_schema, ALBUMS_schema, ARTISTS_schema, INVOICES_schema, INVOICE_ITEMS_schema]) "WITH best_selling_artist AS (SELECT ar.\"ArtistId\" FROM \"CHINOOK\".\"CHINOOK\".\"ARTISTS\" AS ar JOIN \"CHINOOK\".\"CHINOOK\".\"ALBUMS\" AS al ON ar.\"ArtistId\" = al.\"ArtistId\" JOIN \"CHINOOK\".\"CHINOOK\".\"TRACKS\" AS t ON al.\"AlbumId\" = t.\"AlbumId\" JOIN \"CHINOOK\".\"CHINOOK\".\"INVOICE_ITEMS\" AS ii ON t.\"TrackId\" = ii.\"TrackId\" GROUP BY ar.\"ArtistId\" ORDER BY SUM(ii.\"UnitPrice\" * ii.\"Quantity\") DESC LIMIT 1), customer_spending AS (SELECT c.\"FirstName\" AS FIRSTNAME, SUM(ii.\"UnitPrice\" * ii.\"Quantity\") AS AMOUNT_SPENT FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c JOIN \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS inv ON c.\"CustomerId\" = inv.\"CustomerId\" JOIN \"CHINOOK\".\"CHINOOK\".\"INVOICE_ITEMS\" AS ii ON inv.\"InvoiceId\" = ii.\"InvoiceId\" JOIN \"CHINOOK\".\"CHINOOK\".\"TRACKS\" AS t ON ii.\"TrackId\" = t.\"TrackId\" JOIN \"CHINOOK\".\"CHINOOK\".\"ALBUMS\" AS al ON t.\"AlbumId\" = al.\"AlbumId\" WHERE al.\"ArtistId\" = (SELECT \"ArtistId\" FROM best_selling_artist) GROUP BY c.\"CustomerId\", c.\"FirstName\") SELECT FIRSTNAME, AMOUNT_SPENT FROM customer_spending WHERE AMOUNT_SPENT < 1 ORDER BY FIRSTNAME") t0 t1 t2 t3 t4 t5
  ~= (sql%([CUSTOMERS_schema, TRACKS_schema, ALBUMS_schema, ARTISTS_schema, INVOICES_schema, INVOICE_ITEMS_schema]) "WITH best_selling_artist AS (SELECT ar.\"ArtistId\", ar.\"Name\", SUM(ii.\"Quantity\") AS total_sold FROM \"CHINOOK\".\"CHINOOK\".\"INVOICE_ITEMS\" AS ii JOIN \"CHINOOK\".\"CHINOOK\".\"TRACKS\" AS t ON ii.\"TrackId\" = t.\"TrackId\" JOIN \"CHINOOK\".\"CHINOOK\".\"ALBUMS\" AS al ON t.\"AlbumId\" = al.\"AlbumId\" JOIN \"CHINOOK\".\"CHINOOK\".\"ARTISTS\" AS ar ON al.\"ArtistId\" = ar.\"ArtistId\" GROUP BY ar.\"ArtistId\", ar.\"Name\" ORDER BY total_sold DESC LIMIT 1), customer_spending AS (SELECT c.\"FirstName\" AS FIRSTNAME, SUM(ii.\"UnitPrice\" * ii.\"Quantity\") AS AMOUNT_SPENT FROM \"CHINOOK\".\"CHINOOK\".\"CUSTOMERS\" AS c JOIN \"CHINOOK\".\"CHINOOK\".\"INVOICES\" AS inv ON c.\"CustomerId\" = inv.\"CustomerId\" JOIN \"CHINOOK\".\"CHINOOK\".\"INVOICE_ITEMS\" AS ii ON inv.\"InvoiceId\" = ii.\"InvoiceId\" JOIN \"CHINOOK\".\"CHINOOK\".\"TRACKS\" AS t ON ii.\"TrackId\" = t.\"TrackId\" JOIN \"CHINOOK\".\"CHINOOK\".\"ALBUMS\" AS al ON t.\"AlbumId\" = al.\"AlbumId\" JOIN best_selling_artist AS bsa ON al.\"ArtistId\" = bsa.\"ArtistId\" GROUP BY c.\"CustomerId\", c.\"FirstName\") SELECT FIRSTNAME, AMOUNT_SPENT FROM customer_spending WHERE AMOUNT_SPENT < 1 ORDER BY FIRSTNAME") t0 t1 t2 t3 t4 t5
  := by first | sql_equiv | sorry

end N_sf_local054_eq_0_3
