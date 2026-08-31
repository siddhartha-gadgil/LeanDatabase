import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_4_eq

CREATE TABLE ITP («ITEMN» INT, «PONUM» INT)
CREATE TABLE ITL («ITEMN» INT, «WKCEN» INT, «LOCAN» INT)

theorem eq :
    sql%([ITP_schema, ITL_schema]) "SELECT * FROM ITP AS ITP WHERE EXISTS(SELECT * FROM ITL AS ITL WHERE ITL.ITEMN = ITP.ITEMN AND ITL.WKCEN = 468 AND ITL.LOCAN = 0)"
  = sql%([ITP_schema, ITL_schema]) "SELECT DISTINCT ITP.* FROM ITP AS ITP, ITL AS ITL WHERE ITP.ITEMN = ITL.ITEMN AND ITL.WKCEN = 468 AND ITL.LOCAN = 0"
  := by first | sql_equiv | sorry

end N_4_eq
