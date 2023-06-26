-- For Global Rev and ADV Comparison, imp per session & 

WITH sessions AS(
    SELECT * FROM `ookla-speedtest._0bbb5654cb90928253a67c1343e91e69b15c4af9.anon27362d6f6c496f0f9cfc27c42ac43e3ce849e7e0650be54d9430335cf49170ca`
),

GAM AS (
    SELECT * FROM `ookla-speedtest._0bbb5654cb90928253a67c1343e91e69b15c4af9.anon1c79ab0d5ca30ca18631359830297d7e20d010bd8252abfb4de2fea8ffb9bf83` 
    WHERE LineItemType NOT IN ('BULK', 'HOUSE')
)

SELECT
    sessions.date,
    sessions.country,
    sessions.platform,
    sessions.deviceCategory,
    IFNULL(SUM(GAM.impressions), 0) AS impressions,
    (IFNULL(SUM(GAM.revenue), 0) + IFNULL(SUM(GAM.adxRev), 0)) AS revenue,
    sessions.sessions AS sessions
FROM
    sessions
    LEFT JOIN GAM ON sessions.date = GAM.date AND sessions.country = GAM.country AND sessions.platform = GAM.placementName AND sessions.deviceCategory = GAM.deviceCategory
GROUP BY 
    date,
    country,
    platform,
    deviceCategory,
    sessions


