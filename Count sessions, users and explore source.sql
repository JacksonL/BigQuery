-- ** Count regular sessions with ga_session_id and concat user_pseudo_id

-- SELECT
--     COUNT(DISTINCT (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) as sessionsIdOnly,
--     COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) as sessions
-- FROM `ookla-speedtest.analytics_264062063.events_20220412`


-- ** Engaged sessions. If MAX sessionEngaged is 1 the session is engaged, if 0 then it isn't engaged

-- SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) where key = 'ga_session_id') as sessionId,
--     MAX((SELECT value.string_value FROM UNNEST(event_params) where key = 'session_engaged')) as sessionEngaged
-- FROM `ookla-speedtest.analytics_264062063.events_20220412`
-- GROUP BY 1,2

-- ** Count Engaged Sessions

-- WITH prep as (
-- SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) where key = 'ga_session_id') as sessionId,
--     MAX((SELECT value.string_value FROM UNNEST(event_params) where key = 'session_engaged')) as sessionEngaged
-- FROM `ookla-speedtest.analytics_264062063.events_20220412`
-- GROUP BY 1,2)

-- SELECT
--     COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)) as sessions,
--     COUNT(DISTINCT CASE WHEN sessionEngaged = '1' THEN CONCAT (user_pseudo_id, sessionId) ELSE NULL END) as engagedSessions
-- FROM prep

-- ** Count Engaged ("active") Users

-- WITH prep as (
-- SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) where key = 'ga_session_id') as sessionId,
--     MAX((SELECT value.string_value FROM UNNEST(event_params) where key = 'session_engaged')) as sessionEngaged,
--     MAX((SELECT value.int_value FROM UNNEST(event_params) where key = 'engagement_time_msec')) as engagementTime
-- FROM `ookla-speedtest.analytics_264062063.events_20220412`
-- GROUP BY 1,2)

-- SELECT
--     COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)) as sessions,
--     COUNT(DISTINCT CASE WHEN sessionEngaged = '1' THEN CONCAT (user_pseudo_id, sessionId) ELSE NULL END) as engagedSessions,
--     COUNT(DISTINCT user_pseudo_id) as users,
--     COUNT(DISTINCT CASE WHEN engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as activeUsers
-- FROM prep

-- ** Exporing Traffic Source

WITH prep as (
SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) where key = 'ga_session_id') as sessionId,
    MAX((SELECT value.string_value FROM UNNEST(event_params) where key = 'session_engaged')) as sessionEngaged,
    MAX((SELECT value.int_value FROM UNNEST(event_params) where key = 'engagement_time_msec')) as engagementTime,
    MAX((SELECT value.string_value FROM UNNEST(event_params) where key = 'source')) as source,
    MAX((SELECT value.string_value FROM UNNEST(event_params) where key = 'medium')) as medium
FROM `ookla-speedtest.analytics_264062063.events_20220412`
GROUP BY 1,2)

SELECT
    CONCAT(IFNULL(source, '(direct)'), ' / ', IFNULL(medium, '(none)')) as sourceMedium,
    COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)) as sessions,
    COUNT(DISTINCT CASE WHEN sessionEngaged = '1' THEN CONCAT (user_pseudo_id, sessionId) ELSE NULL END) as engagedSessions,
    COUNT(DISTINCT user_pseudo_id) as users,
    COUNT(DISTINCT CASE WHEN engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as activeUsers
FROM prep
GROUP BY 1
ORDER BY 2 DESC
