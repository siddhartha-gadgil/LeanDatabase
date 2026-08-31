import LeanDatabase.Parser
import LeanDatabase.SQLSyntax
open LeanDatabase Lean
set_option maxHeartbeats 1000000
set_option maxRecDepth 1000000

namespace N_sf_bq085_eq_2_3

CREATE TABLE SUMMARY («province_state» STRING, «country_region» STRING, «date» STRING, «latitude» FLOAT, «longitude» FLOAT, «location_geom» STRING, «confirmed» INT, «deaths» INT, «recovered» STRING, «active» INT, «fips» STRING, «admin2» STRING, «combined_key» STRING)
CREATE TABLE INDICATORS_DATA («country_name» STRING, «country_code» STRING, «indicator_name» STRING, «indicator_code» STRING, «value» FLOAT, «year» INT)

theorem eq (t0 : TableRel SUMMARY_schema) (t1 : TableRel INDICATORS_DATA_schema) :
    (sql%([SUMMARY_schema, INDICATORS_DATA_schema]) "WITH covid AS (SELECT \"country_region\", SUM(\"confirmed\") AS total_confirmed_cases FROM \"COVID19_JHU_WORLD_BANK\".\"COVID19_JHU_CSSE\".\"SUMMARY\" WHERE \"date\" = '2020-04-20' AND \"country_region\" IN ('US', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran') GROUP BY \"country_region\"), pop AS (SELECT \"country_name\", \"value\" AS population FROM \"COVID19_JHU_WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" WHERE \"indicator_code\" = 'SP.POP.TOTL' AND \"year\" = 2020 AND \"country_name\" IN ('United States', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran, Islamic Rep.')), country_map AS (SELECT 'US' AS covid_name, 'United States' AS pop_name UNION ALL SELECT 'France', 'France' UNION ALL SELECT 'China', 'China' UNION ALL SELECT 'Italy', 'Italy' UNION ALL SELECT 'Spain', 'Spain' UNION ALL SELECT 'Germany', 'Germany' UNION ALL SELECT 'Iran', 'Iran, Islamic Rep.') SELECT p.\"country_name\" AS COUNTRY, c.total_confirmed_cases AS TOTAL_CONFIRMED_CASES, ROUND(CAST(c.total_confirmed_cases * 100000.0 AS DOUBLE PRECISION) / p.population, 2) AS CASES_PER_100K FROM covid AS c JOIN country_map AS m ON c.\"country_region\" = m.covid_name JOIN pop AS p ON m.pop_name = p.\"country_name\" ORDER BY CASES_PER_100K DESC") t0 t1
  ~= (sql%([SUMMARY_schema, INDICATORS_DATA_schema]) "WITH confirmed AS (SELECT CASE \"country_region\" WHEN 'US' THEN 'United States' WHEN 'Iran' THEN 'Iran, Islamic Rep.' ELSE \"country_region\" END AS country, SUM(\"confirmed\") AS total_confirmed_cases FROM \"COVID19_JHU_WORLD_BANK\".\"COVID19_JHU_CSSE\".\"SUMMARY\" WHERE \"country_region\" IN ('US', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran') AND \"date\" = '2020-04-20' GROUP BY \"country_region\"), population AS (SELECT \"country_name\" AS country, SUM(\"value\") AS pop FROM \"COVID19_JHU_WORLD_BANK\".\"WORLD_BANK_WDI\".\"INDICATORS_DATA\" WHERE \"indicator_code\" = 'SP.POP.TOTL' AND \"year\" = 2020 AND \"country_name\" IN ('United States', 'Iran, Islamic Rep.', 'France', 'China', 'Italy', 'Spain', 'Germany') GROUP BY \"country_name\") SELECT c.country AS \"COUNTRY\", c.total_confirmed_cases AS \"TOTAL_CONFIRMED_CASES\", ROUND(CAST(c.total_confirmed_cases AS DOUBLE PRECISION) / p.pop * 100000, 2) AS \"CASES_PER_100K\" FROM confirmed AS c JOIN population AS p ON c.country = p.country ORDER BY \"CASES_PER_100K\" DESC") t0 t1
  := by first | sql_equiv | sorry

end N_sf_bq085_eq_2_3
