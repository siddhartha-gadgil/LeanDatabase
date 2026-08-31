import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq307_eq_1_2

CREATE TABLE USERS («id» INT, «display_name» STRING, «about_me» STRING, «age» STRING, «creation_date» INT, «last_access_date» INT, «location» STRING, «reputation» INT, «up_votes» INT, «down_votes» INT, «views» INT, «profile_image_url» STRING, «website_url» STRING)
CREATE TABLE BADGES («id» INT, «name» STRING, «date» INT, «user_id» INT, «class» INT, «tag_based» BOOL)

theorem eq (t0 : TableRel USERS_schema) (t1 : TableRel BADGES_schema) :
    (sql%([USERS_schema, BADGES_schema]) "/* sf_bq307: Find top 10 gold badges most commonly earned as first gold badge */ /* Gold badges = class 1 */ /* First gold badge determined by earliest date, tie-broken by badge id */ /* Days calculated as raw arithmetic: (badge_date - creation_date) / 1e6 / 86400 */ WITH ranked AS (SELECT \"user_id\", \"name\", \"date\", ROW_NUMBER() OVER (PARTITION BY \"user_id\" ORDER BY \"date\", \"id\") AS rn FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\" WHERE \"class\" = 1) SELECT r.\"name\" AS BADGE_NAME, COUNT(*) AS USER_COUNT, AVG(CAST(CAST((r.\"date\" - u.\"creation_date\") AS DOUBLE PRECISION) / 1000000.0 AS DOUBLE PRECISION) / 86400.0) AS AVG_DAYS_TO_EARN FROM ranked AS r JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" AS u ON r.\"user_id\" = u.\"id\" WHERE r.rn = 1 GROUP BY r.\"name\" ORDER BY USER_COUNT DESC LIMIT 10") t0 t1
  ~= (sql%([USERS_schema, BADGES_schema]) "WITH gold_badges AS (SELECT b.\"id\" AS badge_id, b.\"name\" AS badge_name, b.\"date\" AS badge_date, b.\"user_id\", u.\"creation_date\" AS user_creation_date FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\" AS b JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" AS u ON b.\"user_id\" = u.\"id\" WHERE b.\"class\" = 1), first_gold AS (SELECT \"user_id\", badge_name, badge_date, user_creation_date, ROW_NUMBER() OVER (PARTITION BY \"user_id\" ORDER BY badge_date ASC, badge_id ASC) AS rn FROM gold_badges) SELECT badge_name AS \"BADGE_NAME\", COUNT(*) AS \"USER_COUNT\", AVG(CAST(CAST((badge_date - user_creation_date) AS DOUBLE PRECISION) / 1000000.0 AS DOUBLE PRECISION) / 86400.0) AS \"AVG_DAYS_TO_EARN\" FROM first_gold WHERE rn = 1 GROUP BY badge_name ORDER BY \"USER_COUNT\" DESC LIMIT 10") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq307_eq_1_2
