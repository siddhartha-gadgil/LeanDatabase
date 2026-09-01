import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_34_eq

CREATE TABLE X («A» INT, «K» INT)
CREATE TABLE Y («A» INT, «K» INT)

theorem eq (t0 : TableRel X_schema) (t1 : TableRel Y_schema) :
    (sql%([X_schema, Y_schema]) "SELECT X.A AS A FROM X AS X, Y AS Y WHERE X.K = Y.K") t0 t1
  ~= (sql%([X_schema, Y_schema]) "SELECT X1.A AS X1A FROM (SELECT X.A AS A, X.K AS K FROM X AS X) AS X1, Y AS Y WHERE X1.K = Y.K") t0 t1
  := by sql_equiv

end N_34_eq
