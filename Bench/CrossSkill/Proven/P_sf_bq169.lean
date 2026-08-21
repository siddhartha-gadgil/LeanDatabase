import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000

/-!
# sf_bq169 — a proven cross-skill equivalence

Question: Retrieve distinct case references, case numbers, investigation numbers, and clone information where a single clone simultaneously exhibits all three of the following genetic alterations: (1) a loss on chromosome 13 between positions 48,303,751 and 48,481,890, (2) a loss on chromosome 17 between positions 7,668,421 and 7,687,490, and (3) a gain on chromosome 11 between positions 108,223,067 and 108,369,102. For each matching clone, display the chromosomal details for each of these three regions (including chromosome number represented by ChrOrd, start position, and end position) and the corresponding karyotype short description from the KaryClone table. Use the CytoConverted and KaryClone.

Two independently-written SQL answers to the same question, proved equivalent for *all*
table contents by `sql_equiv` (not just on one instance).
-/

namespace P_sf_bq169

CREATE TABLE CYTOCONVERTED («RefNo» INT, «CaseNo» STRING, «InvNo» INT, «Clone» INT, «Chr» STRING, «ChrOrd» INT, «Start» INT, «End» INT, «Type» STRING)
CREATE TABLE KARYCLONE («RefNo» INT, «CaseNo» STRING, «InvNo» INT, «CloneNo» INT, «CloneShort» STRING)

/-- Variant A:  SELECT DISTINCT c13."RefNo", c13."CaseNo", c13."InvNo", c13."Clone", k."CloneShort" AS "KaryotypeShortDescription", c13."ChrOrd" AS "Chr13_ChrOrd", c13."Start" 
    Variant B:  SELECT DISTINCT c13."RefNo", c13."CaseNo", c13."InvNo", c13."Clone", k."CloneShort" AS "KaryotypeShortDescription", c13."ChrOrd" AS "Chr13_ChrOrd", c13."Start"  -/
theorem equivalent :
    sql%([CYTOCONVERTED_schema, KARYCLONE_schema]) "SELECT DISTINCT\n    c13.\"RefNo\",\n    c13.\"CaseNo\",\n    c13.\"InvNo\",\n    c13.\"Clone\",\n    k.\"CloneShort\" AS \"KaryotypeShortDescription\",\n    c13.\"ChrOrd\" AS \"Chr13_ChrOrd\",\n    c13.\"Start\" AS \"Chr13_Start\",\n    c13.\"End\" AS \"Chr13_End\",\n    c17.\"ChrOrd\" AS \"Chr17_ChrOrd\",\n    c17.\"Start\" AS \"Chr17_Start\",\n    c17.\"End\" AS \"Chr17_End\",\n    c11.\"ChrOrd\" AS \"Chr11_ChrOrd\",\n    c11.\"Start\" AS \"Chr11_Start\",\n    c11.\"End\" AS \"Chr11_End\"\nFROM \"MITELMAN\".\"PROD\".\"CYTOCONVERTED\" c13\nJOIN \"MITELMAN\".\"PROD\".\"CYTOCONVERTED\" c17\n    ON c13.\"RefNo\" = c17.\"RefNo\"\n    AND c13.\"CaseNo\" = c17.\"CaseNo\"\n    AND c13.\"InvNo\" = c17.\"InvNo\"\n    AND c13.\"Clone\" = c17.\"Clone\"\nJOIN \"MITELMAN\".\"PROD\".\"CYTOCONVERTED\" c11\n    ON c13.\"RefNo\" = c11.\"RefNo\"\n    AND c13.\"CaseNo\" = c11.\"CaseNo\"\n    AND c13.\"InvNo\" = c11.\"InvNo\"\n    AND c13.\"Clone\" = c11.\"Clone\"\nJOIN \"MITELMAN\".\"PROD\".\"KARYCLONE\" k\n    ON c13.\"RefNo\" = k.\"RefNo\"\n    AND c13.\"CaseNo\" = k.\"CaseNo\"\n    AND c13.\"InvNo\" = k.\"InvNo\"\n    AND c13.\"Clone\" = k.\"CloneNo\"\nWHERE\n    c13.\"Chr\" = 'chr13' AND c13.\"Type\" = 'Loss'\n    AND c13.\"Start\" <= 48481890 AND c13.\"End\" >= 48303751\n    AND c17.\"Chr\" = 'chr17' AND c17.\"Type\" = 'Loss'\n    AND c17.\"Start\" <= 7687490 AND c17.\"End\" >= 7668421\n    AND c11.\"Chr\" = 'chr11' AND c11.\"Type\" = 'Gain'\n    AND c11.\"Start\" <= 108369102 AND c11.\"End\" >= 108223067\nORDER BY c13.\"RefNo\", c13.\"CaseNo\", c13.\"InvNo\", c13.\"Clone\";"
      = sql%([CYTOCONVERTED_schema, KARYCLONE_schema]) "SELECT DISTINCT\n    c13.\"RefNo\",\n    c13.\"CaseNo\",\n    c13.\"InvNo\",\n    c13.\"Clone\",\n    k.\"CloneShort\" AS \"KaryotypeShortDescription\",\n    c13.\"ChrOrd\" AS \"Chr13_ChrOrd\",\n    c13.\"Start\" AS \"Chr13_Start\",\n    c13.\"End\" AS \"Chr13_End\",\n    c17.\"ChrOrd\" AS \"Chr17_ChrOrd\",\n    c17.\"Start\" AS \"Chr17_Start\",\n    c17.\"End\" AS \"Chr17_End\",\n    c11.\"ChrOrd\" AS \"Chr11_ChrOrd\",\n    c11.\"Start\" AS \"Chr11_Start\",\n    c11.\"End\" AS \"Chr11_End\"\nFROM \"MITELMAN\".\"PROD\".\"CYTOCONVERTED\" c13\nJOIN \"MITELMAN\".\"PROD\".\"CYTOCONVERTED\" c17\n    ON c13.\"RefNo\" = c17.\"RefNo\"\n    AND c13.\"CaseNo\" = c17.\"CaseNo\"\n    AND c13.\"InvNo\" = c17.\"InvNo\"\n    AND c13.\"Clone\" = c17.\"Clone\"\nJOIN \"MITELMAN\".\"PROD\".\"CYTOCONVERTED\" c11\n    ON c13.\"RefNo\" = c11.\"RefNo\"\n    AND c13.\"CaseNo\" = c11.\"CaseNo\"\n    AND c13.\"InvNo\" = c11.\"InvNo\"\n    AND c13.\"Clone\" = c11.\"Clone\"\nJOIN \"MITELMAN\".\"PROD\".\"KARYCLONE\" k\n    ON c13.\"RefNo\" = k.\"RefNo\"\n    AND c13.\"CaseNo\" = k.\"CaseNo\"\n    AND c13.\"InvNo\" = k.\"InvNo\"\n    AND c13.\"Clone\" = k.\"CloneNo\"\nWHERE\n    -- Loss on chromosome 13 overlapping RB1 gene region [48303751, 48481890]\n    c13.\"Type\" = 'Loss'\n    AND c13.\"Chr\" = 'chr13'\n    AND c13.\"Start\" <= 48481890\n    AND c13.\"End\" >= 48303751\n    -- Loss on chromosome 17 overlapping TP53 gene region [7668421, 7687490]\n    AND c17.\"Type\" = 'Loss'\n    AND c17.\"Chr\" = 'chr17'\n    AND c17.\"Start\" <= 7687490\n    AND c17.\"End\" >= 7668421\n    -- Gain on chromosome 11 overlapping ATM gene region [108223067, 108369102]\n    AND c11.\"Type\" = 'Gain'\n    AND c11.\"Chr\" = 'chr11'\n    AND c11.\"Start\" <= 108369102\n    AND c11.\"End\" >= 108223067\nORDER BY c13.\"RefNo\", c13.\"CaseNo\", c13.\"InvNo\", c13.\"Clone\";" := by sql_equiv

end P_sf_bq169
