import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_9_eq

CREATE TABLE USER («UID» INT, «UNAME» INT, «CITY» INT)
CREATE TABLE PICTURE («UID» INT, «SIZE» INT)

theorem eq (t0 : TableRel USER_schema) (t1 : TableRel PICTURE_schema) :
    (sql%([USER_schema, PICTURE_schema]) "SELECT X.UID AS UID, X.UNAME, (SELECT COUNT(*) FROM PICTURE AS Y WHERE X.UID = Y.UID AND Y.SIZE > 1000000) AS CNT FROM USER AS X WHERE X.CITY = 3") t0 t1
  ~= (sql%([USER_schema, PICTURE_schema]) "SELECT X.UID AS UID, X.UNAME AS UNAME, COUNT(*) AS CNT FROM USER AS X, PICTURE AS Y WHERE X.UID = Y.UID AND Y.SIZE > 1000000 AND X.CITY = 3 GROUP BY X.UID, X.UNAME") t0 t1
  := by first | sql_equiv | sorry

end N_9_eq
