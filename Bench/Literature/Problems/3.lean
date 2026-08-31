import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_3

CREATE TABLE ITP («ITEMNO» INT, «NP» INT)
CREATE TABLE ITM («ITEMNO» INT, «TYPE» INT)

theorem eq :
    sql%([ITP_schema, ITM_schema]) "SELECT ITM.ITEMNO, ITEMPRICE.NP FROM (SELECT DISTINCT ITP.ITEMNO AS ITN, ITP.NP AS NP FROM ITP AS ITP) AS ITEMPRICE, ITM AS ITM WHERE ITEMPRICE.ITN = ITM.ITEMNO"
  = sql%([ITP_schema, ITM_schema]) "SELECT DISTINCT ITM.ITEMNO, ITP.NP FROM ITP AS ITP, ITM AS ITM WHERE ITP.ITEMNO = ITM.ITEMNO"
  := by first | sql_equiv | sorry

end Literature_3
