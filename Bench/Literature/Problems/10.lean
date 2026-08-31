import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace Literature_10

CREATE TABLE USR («USRUID» INT, «USRNAME» STRING)
CREATE TABLE PIC («PICUID» INT, «PICSIZE» INT)

theorem eq :
    sql%([USR_schema, PIC_schema]) "SELECT DISTINCT X.USRUID AS XID, X.USRNAME AS XNAME FROM USR AS X, PIC AS U, PIC AS V, PIC AS W WHERE X.USRUID = U.PICUID AND X.USRUID = V.PICUID AND X.USRUID = W.PICUID AND W.PICSIZE = V.PICSIZE AND B1(U) AND B2(V)"
  = sql%([USR_schema, PIC_schema]) "SELECT DISTINCT X.USRUID AS XID, X.USRNAME AS XNAME FROM USR AS X, PIC AS U, PIC AS V WHERE X.USRUID = U.PICUID AND X.USRUID = V.PICUID AND B1(U) AND B2(V)"
  := by first | sql_equiv | sorry

end Literature_10
