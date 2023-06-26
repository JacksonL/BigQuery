


SELECT
    CAST(event_date AS DATE FORMAT 'YYYYMMDD') as date,
    CASE
        WHEN regexp_contains(geo.country, r'^\(not set\)$|^\s*$') = true THEN 'Unknown'
        ELSE REPLACE(geo.country, '&', 'and')
    END AS country,
    CASE
        WHEN platform = 'WEB' AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'mobile_web_test') = 'false' AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'adblock_status') = 'False' THEN 'ST Desktop'
        WHEN platform = 'WEB' AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'mobile_web_test') = 'true' AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'adblock_status') = 'False' THEN 'ST Mobile Web'
        WHEN platform = 'ANDROID' THEN 'ST Android'
        WHEN platform = 'IOS' THEN 'ST iOS'
        WHEN platform = 'WEB' AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'adblock_status') = 'True' THEN 'ST AAX'
        ELSE NULL
    END AS platform,
    CASE
        WHEN device.category = 'desktop' THEN 'Desktop'
        WHEN device.category = 'smart tv' THEN 'CTV'
        WHEN device.category = 'mobile' THEN 'Mobile'
        WHEN device.category = 'tablet' THEN 'Tablet'
        ELSE device.category
    END AS deviceCategory,
    COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) as sessions
FROM `ookla-speedtest.analytics_207499972.events_*`
WHERE
    _table_suffix BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 3 day)) AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 day))
    AND event_name IN ('beginTest',
    'completeTest',
    'page_view',
    'openScreen',
    'beginVideoTest',
    'vpnConnectTap',
    'completeVideoTest',
    'coverageMapInteraction')
GROUP BY 1,2,3,4
HAVING platform IS NOT NULL

UNION ALL

SELECT
    CAST(event_date AS DATE FORMAT 'YYYYMMDD') as date,
    CASE
        WHEN regexp_contains(geo.country, r'^\(not set\)$|^\s*$') = true THEN 'Unknown'
        ELSE REPLACE(geo.country, '&', 'and')
    END AS country,
    'Downdetector' AS platform,
    CASE
        WHEN device.category = 'desktop' THEN 'Desktop'
        WHEN device.category = 'smart tv' THEN 'CTV'
        WHEN device.category = 'mobile' THEN 'Mobile'
        WHEN device.category = 'tablet' THEN 'Tablet'
        ELSE device.category
    END AS deviceCategory,
    COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) as sessions
FROM `ookla-speedtest.analytics_251126210.events_*`
WHERE _table_suffix BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 3 day)) AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 day))
GROUP BY 1,2,3,4