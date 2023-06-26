CREATE TEMP FUNCTION
  NUMFORMAT(number FLOAT64) AS ( CONCAT(REGEXP_EXTRACT(CAST((number*100) AS string), r'\d*\.\d{2}'), ' %') );

WITH prep AS (
SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') as sessionId,
    (SELECT value.string_value FROM UNNEST (event_params) WHERE key = 'page_location') as pageLocation,
    MAX((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged')) as sessionEngaged,
    SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) as engagementTime,
    IF(SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) > 30000, 'yes', 'no') as refreshEligibleLow,
    IF(SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) > 20000, 'yes', 'no') as refreshEligibleHigh
FROM `ookla-speedtest.analytics_251126210.events_intraday_20220422`
GROUP BY 1,2,3)

SELECT
    CASE WHEN REGEXP_CONTAINS(pageLocation, '^.*status|stoerung|storing|problemas|problemi|statut|fora-do-ar|ne-rabotaet|shougai|problem-storningar|durum|masalah|problema|ei-toimi|problem-fejl|problemy|problem|feil-problem|zeug|nu-merge|statut.*$') THEN 'statusPage' ELSE 'nonStatusPage' END as page,
    CONCAT(ROUND(SAFE_DIVIDE(AVG(IFNULL(engagementTime, 0)), 1000), 0), 's') as avgEngagement, -- set null engagementTime to zero to get avg engagement for all users not just active users
    CONCAT(ROUND(SAFE_DIVIDE(AVG(engagementTime), 1000), 0), 's') as activeAvgEngagement,
    COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)) as sessions,
    COUNT(DISTINCT CASE WHEN sessionEngaged = '1' THEN CONCAT (user_pseudo_id, sessionId) ELSE NULL END) as engagedSessions,
    COUNTIF(refreshEligibleLow = 'yes') as eligibleRefreshSessionsLow,
    COUNTIF(refreshEligibleHigh = 'yes') as eligibleRefreshSessionsHigh,
    NUMFORMAT(SAFE_DIVIDE(COUNTIF(refreshEligibleLow = 'yes'), COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)))) as percentRefreshSessionsLow,
    NUMFORMAT(SAFE_DIVIDE(COUNTIF(refreshEligibleHigh = 'yes'), COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)))) as percentRefreshSessionsHigh
FROM prep
GROUP BY 1
-- HAVING page = 'statusPage'
ORDER BY 3 DESC