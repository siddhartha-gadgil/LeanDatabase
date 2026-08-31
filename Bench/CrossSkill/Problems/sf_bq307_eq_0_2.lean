import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq307_eq_0_2

CREATE TABLE USERS («id» INT, «display_name» STRING, «about_me» STRING, «age» STRING, «creation_date» INT, «last_access_date» INT, «location» STRING, «reputation» INT, «up_votes» INT, «down_votes» INT, «views» INT, «profile_image_url» STRING, «website_url» STRING)
CREATE TABLE BADGES («id» INT, «name» STRING, «date» INT, «user_id» INT, «class» INT, «tag_based» BOOL)

theorem eq (t0 : TableRel USERS_schema) (t1 : TableRel BADGES_schema) :
    (sql%([USERS_schema, BADGES_schema]) "WITH first_gold AS (SELECT b.\"user_id\", b.\"name\" AS badge_name, b.\"date\" AS badge_date, ROW_NUMBER() OVER (PARTITION BY b.\"user_id\" ORDER BY b.\"date\" ASC, b.\"id\" ASC) AS rn FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\" AS b WHERE b.\"class\" = 1) SELECT fg.badge_name AS BADGE_NAME, COUNT(*) AS USER_COUNT, AVG(CAST(CAST((fg.badge_date - u.\"creation_date\") AS DOUBLE PRECISION) / 1000000.0 AS DOUBLE PRECISION) / 86400.0) AS AVG_DAYS_TO_EARN FROM first_gold AS fg JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" AS u ON fg.\"user_id\" = u.\"id\" WHERE fg.rn = 1 GROUP BY fg.badge_name ORDER BY USER_COUNT DESC LIMIT 10") t0 t1
  ~= (sql%([USERS_schema, BADGES_schema]) "WITH gold_badges AS (SELECT b.\"id\" AS badge_id, b.\"name\" AS badge_name, b.\"date\" AS badge_date, b.\"user_id\", u.\"creation_date\" AS user_creation_date FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\" AS b JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" AS u ON b.\"user_id\" = u.\"id\" WHERE b.\"class\" = 1), first_gold AS (SELECT \"user_id\", badge_name, badge_date, user_creation_date, ROW_NUMBER() OVER (PARTITION BY \"user_id\" ORDER BY badge_date ASC, badge_id ASC) AS rn FROM gold_badges) SELECT badge_name AS \"BADGE_NAME\", COUNT(*) AS \"USER_COUNT\", AVG(CAST(CAST((badge_date - user_creation_date) AS DOUBLE PRECISION) / 1000000.0 AS DOUBLE PRECISION) / 86400.0) AS \"AVG_DAYS_TO_EARN\" FROM first_gold WHERE rn = 1 GROUP BY badge_name ORDER BY \"USER_COUNT\" DESC LIMIT 10") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq307_eq_0_2
