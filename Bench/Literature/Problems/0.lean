import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_0_eq

CREATE TABLE ITP («ITEMN» INT, «PONUM» INT)
CREATE TABLE ITM («ITEMN» INT, «TYPE» INT)
CREATE TABLE PUR («PONUM» INT, «ODATE» INT, «VENDN» INT)

theorem eq (t0 : TableRel ITP_schema) (t1 : TableRel ITM_schema) (t2 : TableRel PUR_schema) :
    (sql%([ITP_schema, ITM_schema, PUR_schema]) "SELECT ITM.ITEMN, ITPV.VENDN FROM ITM AS ITM, (SELECT DISTINCT ITP.ITEMN, PUR.VENDN FROM ITP AS ITP, PUR AS PUR WHERE ITP.PONUM = PUR.PONUM AND PUR.ODATE > 85) AS ITPV WHERE ITM.ITEMN = ITPV.ITEMN AND ITM.ITEMN > 1 AND ITM.ITEMN < 20") t0 t1 t2
  ~= (sql%([ITP_schema, ITM_schema, PUR_schema]) "SELECT DISTINCT ITM.ITEMN, PUR.VENDN FROM ITM AS ITM, ITP AS ITP, PUR AS PUR WHERE ITP.PONUM = PUR.PONUM AND ITM.ITEMN = ITP.ITEMN AND PUR.ODATE > 85 AND ITM.ITEMN > 1 AND ITM.ITEMN < 20") t0 t1 t2
  := by first | sql_equiv | sorry

end N_0_eq
