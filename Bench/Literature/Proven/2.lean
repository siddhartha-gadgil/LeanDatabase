import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_2_eq

CREATE TABLE ITP («ITEMNO» INT, «NP» INT)
CREATE TABLE ITM («ITEMNO» INT, «TYPE» INT)

theorem eq :
    sql%([ITP_schema, ITM_schema]) "SELECT ITEMPRICE.NP, ITM.TYPE, ITM.ITEMNO FROM (SELECT DISTINCT ITP.ITEMNO AS ITN, ITP.NP AS NP FROM ITP AS ITP WHERE ITP.NP > 1000) AS ITEMPRICE, ITM AS ITM WHERE ITEMPRICE.ITN = ITM.ITEMNO"
  = sql%([ITP_schema, ITM_schema]) "SELECT DISTINCT ITP.NP, ITM.TYPE, ITM.ITEMNO FROM ITP AS ITP, ITM AS ITM WHERE ITP.NP > 1000 AND ITP.ITEMNO = ITM.ITEMNO"
  := by sql_equiv

end N_2_eq
