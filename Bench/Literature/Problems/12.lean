import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_12_eq

CREATE TABLE PARTS («PNUM» INT, «QOH» INT)
CREATE TABLE SUPPLY («PNUM» INT, «SHIPDATE» INT)

theorem eq :
    sql%([PARTS_schema, SUPPLY_schema]) "SELECT X.PNUM AS XP FROM PARTS AS X WHERE X.QOH = (SELECT COUNT(Y.SHIPDATE) AS CNT FROM SUPPLY AS Y WHERE Y.PNUM = X.PNUM AND Y.SHIPDATE < 10)"
  = sql%([PARTS_schema, SUPPLY_schema]) "SELECT X.PNUM AS XP FROM PARTS AS X, (SELECT Y.PNUM AS SUPPNUM, COUNT(Y.SHIPDATE) AS CT FROM SUPPLY AS Y WHERE Y.SHIPDATE < 10 GROUP BY Y.PNUM) AS TEMP WHERE X.QOH = TEMP.CT AND X.PNUM = TEMP.SUPPNUM"
  := by first | sql_equiv | sorry

end N_12_eq
