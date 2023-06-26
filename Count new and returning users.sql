-- ** Count new and returning users

-- WITH prep AS(
-- SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS sessionId,
--     (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS sessionNumber,
--     MAX((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS engagementTime
-- FROM `ookla-speedtest.analytics_264062063.events_*`
-- WHERE _table_suffix BETWEEN '20220401' AND '20220430'
-- GROUP BY 1,2,3
-- )

-- SELECT
--     COUNT(DISTINCT CASE WHEN sessionNumber = 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as newUsers,
--     COUNT(DISTINCT CASE WHEN sessionNumber > 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as returningUsers
-- FROM prep


-- ** Calculate user retention

-- WITH prep AS(
-- SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS sessionId,
--     (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS sessionNumber,
--     MAX((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS engagementTime,
--     PARSE_DATE('%Y%m%d', event_date) as sessionDate,
--     FIRST_VALUE(PARSE_DATE('%Y%m%d', event_date)) OVER (PARTITION BY user_pseudo_id ORDER BY event_date ASC) as firstSessionDate
-- FROM `ookla-speedtest.analytics_264062063.events_*`
-- WHERE _table_suffix BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 43 day)) AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 day))
-- GROUP BY
--     user_pseudo_id,
--     sessionId,
--     sessionNumber,
--     event_date
-- ORDER BY
--     user_pseudo_id,
--     sessionId,
--     sessionNumber
-- )

-- SELECT
--     DATE_DIFF(sessionDate, firstSessionDate, day) as day,
--     COUNT(DISTINCT CASE WHEN sessionNumber = 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as newUsers,
--     COUNT(DISTINCT CASE WHEN sessionNumber > 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as returningUsers,
--     COUNT(DISTINCT CASE WHEN sessionNumber > 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) / MAX(COUNT(DISTINCT CASE WHEN sessionNumber = 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END)) OVER () as retentionPercentage
-- FROM prep
-- GROUP BY 1
-- ORDER BY 1 ASC

-- ** Calculate user retention by cohort

WITH prep AS(
SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS sessionId,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS sessionNumber,
    MAX((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS engagementTime,
    PARSE_DATE('%Y%m%d', event_date) as sessionDate,
    FIRST_VALUE(PARSE_DATE('%Y%m%d', event_date)) OVER (PARTITION BY user_pseudo_id ORDER BY event_date ASC) as firstSessionDate
FROM `ookla-speedtest.analytics_264062063.events_*`
WHERE _table_suffix BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 100 day)) AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 day))
GROUP BY
    user_pseudo_id,
    sessionId,
    sessionNumber,
    event_date
ORDER BY
    user_pseudo_id,
    sessionId,
    sessionNumber
)

SELECT
    CONCAT(EXTRACT(isoyear from firstSessionDate), '-', FORMAT('%02d', EXTRACT(isoweek from firstSessionDate))) as yearWeek,
    COUNT(DISTINCT CASE WHEN DATE_DIFF(sessionDate, firstSessionDate, isoweek) = 0 AND sessionNumber >= 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as week_0,
    COUNT(DISTINCT CASE WHEN DATE_DIFF(sessionDate, firstSessionDate, isoweek) = 1 AND sessionNumber > 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as week_1,
    COUNT(DISTINCT CASE WHEN DATE_DIFF(sessionDate, firstSessionDate, isoweek) = 2 AND sessionNumber > 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as week_2,
    COUNT(DISTINCT CASE WHEN DATE_DIFF(sessionDate, firstSessionDate, isoweek) = 3 AND sessionNumber > 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as week_3,
    COUNT(DISTINCT CASE WHEN DATE_DIFF(sessionDate, firstSessionDate, isoweek) = 4 AND sessionNumber > 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as week_4,
    COUNT(DISTINCT CASE WHEN DATE_DIFF(sessionDate, firstSessionDate, isoweek) = 5 AND sessionNumber > 1 AND engagementTime > 0 THEN user_pseudo_id ELSE NULL END) as week_5
FROM prep
GROUP BY 1
ORDER BY 1 ASC
