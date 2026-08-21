import LeanDatabase.Hypothesis
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 8000
set_option sqlEquivLlm.provider "gemini"
set_option sqlEquivLlm.model "gemini-pro-latest"

/-!
# sf_bq307 — crossskill equivalence(s)

Question: Find the top 10 gold badges that users most commonly earn as their first gold badge on Stack Overflow. For each of these badges, display the badge name, the number of users who earned it as their first gold badge, and the average number of days from the user's account creation date to the date they earned the badge, calculated in days without any adjustments for date formats.

Each theorem: `first | sql_equiv | sorry` — proved by `sql_equiv` where it closes, else
`sorry`. Data-dependent differences are stated as explicit `HYPOTHESIS` antecedents (sound).
-/

namespace Bench_sf_bq307

CREATE TABLE USERS («id» INT, «display_name» STRING, «about_me» STRING, «age» STRING, «creation_date» INT, «last_access_date» INT, «location» STRING, «reputation» INT, «up_votes» INT, «down_votes» INT, «views» INT, «profile_image_url» STRING, «website_url» STRING)
CREATE TABLE BADGES («id» INT, «name» STRING, «date» INT, «user_id» INT, «class» INT, «tag_based» BOOL)

-- eq_0_1: needs a data hypothesis over multiple tables (not stated); likely `sorry`.
theorem eq_0_1 : ∀ t,
    (sql%([USERS_schema, BADGES_schema]) "WITH first_gold AS (\n  SELECT\n    b.\"user_id\",\n    b.\"name\" AS badge_name,\n    b.\"date\" AS badge_date,\n    ROW_NUMBER() OVER (PARTITION BY b.\"user_id\" ORDER BY b.\"date\" ASC, b.\"id\" ASC) AS rn\n  FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\" b\n  WHERE b.\"class\" = 1\n)\nSELECT\n  fg.badge_name AS BADGE_NAME,\n  COUNT(*) AS USER_COUNT,\n  AVG((fg.badge_date - u.\"creation_date\") / 1000000.0 / 86400.0) AS AVG_DAYS_TO_EARN\nFROM first_gold fg\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON fg.\"user_id\" = u.\"id\"\nWHERE fg.rn = 1\nGROUP BY fg.badge_name\nORDER BY USER_COUNT DESC\nLIMIT 10;") t ~= (sql%([USERS_schema, BADGES_schema]) "-- sf_bq307: Find top 10 gold badges most commonly earned as first gold badge\n-- Gold badges = class 1\n-- First gold badge determined by earliest date, tie-broken by badge id\n-- Days calculated as raw arithmetic: (badge_date - creation_date) / 1e6 / 86400\nWITH ranked AS (\n  SELECT\n    \"user_id\",\n    \"name\",\n    \"date\",\n    ROW_NUMBER() OVER (PARTITION BY \"user_id\" ORDER BY \"date\", \"id\") AS rn\n  FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\"\n  WHERE \"class\" = 1\n)\nSELECT\n  r.\"name\" AS BADGE_NAME,\n  COUNT(*) AS USER_COUNT,\n  AVG((r.\"date\" - u.\"creation_date\") / 1000000.0 / 86400.0) AS AVG_DAYS_TO_EARN\nFROM ranked r\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON r.\"user_id\" = u.\"id\"\nWHERE r.rn = 1\nGROUP BY r.\"name\"\nORDER BY USER_COUNT DESC\nLIMIT 10;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_0_2 : ∀ t,
    (sql%([USERS_schema, BADGES_schema]) "WITH first_gold AS (\n  SELECT\n    b.\"user_id\",\n    b.\"name\" AS badge_name,\n    b.\"date\" AS badge_date,\n    ROW_NUMBER() OVER (PARTITION BY b.\"user_id\" ORDER BY b.\"date\" ASC, b.\"id\" ASC) AS rn\n  FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\" b\n  WHERE b.\"class\" = 1\n)\nSELECT\n  fg.badge_name AS BADGE_NAME,\n  COUNT(*) AS USER_COUNT,\n  AVG((fg.badge_date - u.\"creation_date\") / 1000000.0 / 86400.0) AS AVG_DAYS_TO_EARN\nFROM first_gold fg\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON fg.\"user_id\" = u.\"id\"\nWHERE fg.rn = 1\nGROUP BY fg.badge_name\nORDER BY USER_COUNT DESC\nLIMIT 10;") t ~= (sql%([USERS_schema, BADGES_schema]) "WITH gold_badges AS (\n    SELECT\n        b.\"id\" AS badge_id,\n        b.\"name\" AS badge_name,\n        b.\"date\" AS badge_date,\n        b.\"user_id\",\n        u.\"creation_date\" AS user_creation_date\n    FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\" b\n    JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n        ON b.\"user_id\" = u.\"id\"\n    WHERE b.\"class\" = 1\n),\nfirst_gold AS (\n    SELECT\n        \"user_id\",\n        badge_name,\n        badge_date,\n        user_creation_date,\n        ROW_NUMBER() OVER (PARTITION BY \"user_id\" ORDER BY badge_date ASC, badge_id ASC) AS rn\n    FROM gold_badges\n)\nSELECT\n    badge_name AS \"BADGE_NAME\",\n    COUNT(*) AS \"USER_COUNT\",\n    AVG((badge_date - user_creation_date) / 1000000.0 / 86400.0) AS \"AVG_DAYS_TO_EARN\"\nFROM first_gold\nWHERE rn = 1\nGROUP BY badge_name\nORDER BY \"USER_COUNT\" DESC\nLIMIT 10;") t := by
  intro t; first | sql_equiv | sorry

theorem eq_1_2 : ∀ t,
    (sql%([USERS_schema, BADGES_schema]) "-- sf_bq307: Find top 10 gold badges most commonly earned as first gold badge\n-- Gold badges = class 1\n-- First gold badge determined by earliest date, tie-broken by badge id\n-- Days calculated as raw arithmetic: (badge_date - creation_date) / 1e6 / 86400\nWITH ranked AS (\n  SELECT\n    \"user_id\",\n    \"name\",\n    \"date\",\n    ROW_NUMBER() OVER (PARTITION BY \"user_id\" ORDER BY \"date\", \"id\") AS rn\n  FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\"\n  WHERE \"class\" = 1\n)\nSELECT\n  r.\"name\" AS BADGE_NAME,\n  COUNT(*) AS USER_COUNT,\n  AVG((r.\"date\" - u.\"creation_date\") / 1000000.0 / 86400.0) AS AVG_DAYS_TO_EARN\nFROM ranked r\nJOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n  ON r.\"user_id\" = u.\"id\"\nWHERE r.rn = 1\nGROUP BY r.\"name\"\nORDER BY USER_COUNT DESC\nLIMIT 10;") t ~= (sql%([USERS_schema, BADGES_schema]) "WITH gold_badges AS (\n    SELECT\n        b.\"id\" AS badge_id,\n        b.\"name\" AS badge_name,\n        b.\"date\" AS badge_date,\n        b.\"user_id\",\n        u.\"creation_date\" AS user_creation_date\n    FROM \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"BADGES\" b\n    JOIN \"STACKOVERFLOW\".\"STACKOVERFLOW\".\"USERS\" u\n        ON b.\"user_id\" = u.\"id\"\n    WHERE b.\"class\" = 1\n),\nfirst_gold AS (\n    SELECT\n        \"user_id\",\n        badge_name,\n        badge_date,\n        user_creation_date,\n        ROW_NUMBER() OVER (PARTITION BY \"user_id\" ORDER BY badge_date ASC, badge_id ASC) AS rn\n    FROM gold_badges\n)\nSELECT\n    badge_name AS \"BADGE_NAME\",\n    COUNT(*) AS \"USER_COUNT\",\n    AVG((badge_date - user_creation_date) / 1000000.0 / 86400.0) AS \"AVG_DAYS_TO_EARN\"\nFROM first_gold\nWHERE rn = 1\nGROUP BY badge_name\nORDER BY \"USER_COUNT\" DESC\nLIMIT 10;") t := by
  intro t; first | sql_equiv | sorry

end Bench_sf_bq307
