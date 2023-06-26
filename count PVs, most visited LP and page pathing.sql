-- ** Counting Page Views

-- SELECT
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_title') as pageTitle,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') as page,
--     count(event_name) as pageViews
-- FROM `ookla-speedtest.analytics_264062063.events_20220417`
-- WHERE event_name = 'page_view'
-- GROUP BY 1,2
-- ORDER BY pageViews DESC

-- ** Unique Page Views

-- WITH prep AS (
--     SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'ga_session_id') as sessionId,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_title') as pageTitle,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') as page
-- FROM `ookla-speedtest.analytics_264062063.events_20220417`
-- WHERE event_name = 'page_view'
-- )

-- SELECT 
--     pageTitle,
--     page,
--     COUNT(*) as totalPageViews,
--     COUNT(distinct CONCAT(user_pseudo_id, sessionId)) as uniquePageViews
-- FROM prep
-- GROUP BY
--     pageTitle,
--     page
-- ORDER BY uniquePageViews DESC

-- ** Most Visited Landing Pages

-- WITH prep AS (
--     SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'ga_session_id') as sessionId,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') as page,
--     CASE WHEN (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'entrances') = 1 THEN TRUE ELSE FALSE END as landingPage
-- FROM `ookla-speedtest.analytics_264062063.events_20220417`
-- WHERE event_name = 'page_view'
-- )

-- SELECT 
--     CASE WHEN landingPage is TRUE then page ELSE NULL END as landingPage,
--     COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)) as entrances
-- FROM prep
-- GROUP BY 1
-- HAVING landingPage is not NULL
-- ORDER BY entrances DESC


-- ** Identify the exit page of a single session & then identify most popular exits pages
 
--  WITH prep AS(
--  SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'ga_session_id') as sessionId,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') as page,
--     event_timestamp as timeStamp
-- FROM `ookla-speedtest.analytics_264062063.events_20220417`
-- WHERE event_name = 'page_view'
-- ORDER BY timeStamp ASC
--  ),

-- prepExit as (
-- SELECT
--     user_pseudo_id,
--     sessionId,
--     page,
--     timeStamp,
--     FIRST_VALUE(CONCAT(page, timeStamp)) OVER (PARTITION BY user_pseudo_id, sessionId ORDER BY timeStamp DESC) AS exitPage
-- FROM prep
-- ORDER BY timeStamp ASC
-- )

-- SELECT
--     CASE WHEN CONCAT(page, timeStamp) = exitPage THEN page ELSE NULL END as exitPage,
--     COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)) as exits
-- FROM prepExit
-- GROUP BY exitPage
-- HAVING exitPage IS NOT NULL
-- ORDER BY exits DESC

-- ** Identify the page pathing for a single session

--  WITH prep AS(
--  SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'ga_session_id') as sessionId,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') as page,
--     event_timestamp as timeStamp
-- FROM `ookla-speedtest.analytics_264062063.events_20220417`
-- WHERE event_name = 'page_view'
-- ORDER BY timeStamp ASC
--  )

-- SELECT
--     user_pseudo_id,
--     sessionId,
--     LAG(page, 1) OVER (PARTITION BY user_pseudo_id, sessionId ORDER BY timeStamp ASC) as previousPage,
--     page,
--     LEAD(page, 1) OVER (PARTITION BY user_pseudo_id, sessionId ORDER BY timeStamp ASC) as nextPage,
--     timeStamp
-- FROM prep

-- ** Identify the most popular pathing for any page

 WITH prep AS(
 SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'ga_session_id') as sessionId,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'page_view' AND key = 'page_location') as page,
    event_timestamp as timeStamp
FROM `ookla-speedtest.analytics_264062063.events_20220417`
WHERE event_name = 'page_view'
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
WHERE page = 'https://www.ookla.com/'
GROUP BY 1,2,3
HAVING page NOT IN (previousPage, nextPage)
ORDER BY count DESC