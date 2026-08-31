import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_11_eq

CREATE TABLE USR («UID» INT, «UNAME» INT, «CITY» INT)
CREATE TABLE PIC («UID» INT, «SIZE» INT)

theorem eq (t0 : TableRel USR_schema) (t1 : TableRel PIC_schema) :
    (sql%([USR_schema, PIC_schema]) "SELECT X.UID AS XU, X.UNAME AS XN, (SELECT COUNT(*) AS CT FROM PIC AS Y WHERE X.UID = Y.UID AND Y.SIZE > 100000) AS CNT FROM USR AS X WHERE X.CITY = 3") t0 t1
  ~= (sql%([USR_schema, PIC_schema]) "SELECT X.UID AS XU, X.NAME AS XN, COUNT(*) AS CNT FROM USR AS X, PIC AS Y WHERE X.UID = Y.UID AND Y.SIZE > 100000 GROUP BY X.UID, X.UNAME") t0 t1
  := by first | sql_equiv | sorry

end N_11_eq
