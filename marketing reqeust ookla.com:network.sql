-- marketing reqeust ookla.com/network

-- ookla.com/network Unique Page Views Jan 2023 - April 2023

WITH prep AS (
    SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'ga_session_id') as sessionId,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') as page
FROM `ookla-speedtest.analytics_264062063.events_2023*`
WHERE _table_suffix >= '0101' AND _table_suffix < '0501'
AND (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') LIKE 'https://www.ookla.com%/network' -- /network page in all languages
)

SELECT 
    page,
    COUNT(*) as totalPageViews,
    COUNT(distinct CONCAT(user_pseudo_id, sessionId)) as uniquePageViews
FROM prep
GROUP BY
    page
ORDER BY uniquePageViews DESC

-- ookla.com/network traffic sources Jan 2023 - April 2023

WITH prep as (
SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) where key = 'ga_session_id') as sessionId,
    MAX((SELECT value.string_value FROM UNNEST(event_params) where key = 'source')) as source,
    MAX((SELECT value.string_value FROM UNNEST(event_params) where key = 'medium')) as medium
FROM `ookla-speedtest.analytics_264062063.events_2023*`
WHERE _table_suffix >= '0101' AND _table_suffix < '0501'
AND (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') LIKE 'https://www.ookla.com%/network'
GROUP BY 1,2)

SELECT
    CONCAT(IFNULL(source, '(direct)'), ' / ', IFNULL(medium, '(none)')) as sourceMedium,
    COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)) as sessions,
    COUNT(DISTINCT user_pseudo_id) as users,
FROM prep
GROUP BY 1
ORDER BY 2 DESC

 -- Page pathing for /network on Ookla.com Jan 2023 - April 2023
 
 WITH prep AS(
 SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'ga_session_id') as sessionId,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') as page,
    event_timestamp as timeStamp
FROM `ookla-speedtest.analytics_264062063.events_2023*`
WHERE _table_suffix >= '0101' AND _table_suffix < '0501'
AND event_name = 'page_view'
 ),

prepNavigation AS(
SELECT
    user_pseudo_id,
    sessionId,
    LAG(page, 1) OVER (PARTITION BY user_pseudo_id, sessionId ORDER BY timeStamp ASC) as previousPage,
    page,
    LEAD(page, 1) OVER (PARTITION BY user_pseudo_id, sessionId ORDER BY timeStamp ASC) as nextPage,
    timeStamp
FROM prep
)

SELECT
    IFNULL(previousPage,'(entrance)') as previousPage,
    page,
    IFNULL(nextPage, '(exit)') as nextPage,
    COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)) as count
FROM prepNavigation
WHERE page LIKE 'https://www.ookla.com%/network' -- /network page in all languages
GROUP BY 1,2,3
HAVING page NOT IN (previousPage, nextPage)
ORDER BY count DESC