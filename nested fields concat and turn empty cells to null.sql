-- SELECT
--     extract(year from timestamp_micros(user_first_touch_timestamp)) as yearFirstTouch,
--     count(distinct(user_pseudo_id)) as users
-- FROM `ookla-speedtest.analytics_264062063.events_20220407`
-- GROUP BY 1
-- HAVING yearFirstTouch is not null
-- ORDER BY 1 ASC



-- **Course 5 part 7, nested fields:

-- SELECT 
--     traffic_source.source,
--     traffic_source.medium,
--     traffic_source.name as campaign,
--     count(distinct user_pseudo_id) as users
-- FROM `ookla-speedtest.analytics_264062063.events_20220409`
-- GROUP BY 1,2,3
-- ORDER BY users DESC

-- **Concat example:

-- select
--     concat(traffic_source.source, " / ", traffic_source.medium) as source_medium,
--     count(distinct user_pseudo_id) as users
-- FROM `ookla-speedtest.analytics_264062063.events_20220409`
-- group by
--     source_medium
-- order by
--     users desc

-- **Turning empty fields into NULL:

-- SELECT 
--     geo.continent,
--     geo.country,
--     NULLIF(geo.city, regexp_extract(geo.city, r'^\(not set\)$|^\s*$')) as city, --regular expression matches '(not set)' or '' and NULLIF turns them to null
--     COUNT(DISTINCT user_pseudo_id) as users
-- FROM `ookla-speedtest.analytics_264062063.events_20220409`
-- GROUP BY 1,2,3
-- ORDER BY users DESC

-- ** Accessing records within records

SELECT
    device.category,
    device.operating_system,
    device.operating_system_version,
    device.language,
    device.web_info.browser,
    device.web_info.browser_version,
    device.web_info.hostname,
    COUNT(DISTINCT user_pseudo_id) as users
FROM `ookla-speedtest.analytics_264062063.events_20220409`
GROUP BY 1,2,3,4,5,6,7
ORDER BY users DESC