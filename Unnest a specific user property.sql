-- ** Unnest a specific user property

-- SELECT
--     user_pseudo_id,
--     value.string_value as vistorStatus
-- FROM 
--     `ookla-speedtest.analytics_207499972.events_intraday_20220412`,
--     UNNEST(user_properties)
-- WHERE key = 'vistor_status'
-- GROUP BY 1,2

-- ** Scaler subqueries

-- SELECT
--     user_pseudo_id,
--     MAX((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign')) as campaign
-- FROM
--     `ookla-speedtest.analytics_264062063.events_20220411`
-- GROUP BY 1
-- HAVING campaign is not NULL

-- ** Access multiple properties with Scaler subqueries

-- SELECT
--     user_pseudo_id,
--     MAX((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign')) as campaign,
--     MAX((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium')) as medium,
--     MAX((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source')) as source,
-- FROM
--     `ookla-speedtest.analytics_264062063.events_20220411`
-- GROUP BY 1
-- HAVING campaign is not NULL

-- ** Combine User Properties With Other User Data

SELECT
    user_pseudo_id,
    timestamp_micros(user_first_touch_timestamp) as userFirstTouchTimestamp,
    traffic_source.medium,
    MAX((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title')) as page_title,
    MAX((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) as ga_session_id,
    MAX((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number')) as ga_session_number,
    COUNTIF(event_name = 'session_start') as sessions
FROM
    `ookla-speedtest.analytics_264062063.events_20220411`
GROUP BY 1,2,3
ORDER BY sessions DESC