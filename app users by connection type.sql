CREATE TEMP FUNCTION
  NUMFORMAT(number FLOAT64) AS ( CONCAT(REGEXP_EXTRACT(CAST((number*100) AS string), r'\d*\.\d{2}'), ' %') );

WITH prep AS(
SELECT
    geo.country as country,
    platform as platform,
    CASE
        WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'connectionType') IN  ('NR', 'NRNSA') THEN '5G'
        WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'connectionType') = 'LTE' THEN '4G'
        ELSE '3G'
    END AS connectionType,
    COUNT(DISTINCT user_pseudo_id) AS users
FROM `ookla-speedtest.analytics_207499972.events_202301*`
WHERE platform = 'IOS'
AND _table_suffix BETWEEN '15' AND '21'
AND geo.country = 'India'
AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'connectionType') NOT IN  ('WIFI', 'Wifi')
GROUP BY 1,2,3
)

SELECT
    country,
    platform,
    connectionType,
    -- users,
    NUMFORMAT(SAFE_DIVIDE(users,SUM(users) OVER())) AS userPercent
FROM prep
GROUP BY country, platform, connectionType, users
ORDER BY users DESC