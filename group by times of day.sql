SELECT 
    -- event_date as date, 
    CASE 
        WHEN extract(dayofweek from parse_date('%Y%m%d',event_date)) in (7,1) THEN 'weekend'
        ELSE 'weekday'
        END as dayOfWeek, 
    CASE
        WHEN extract(hour from timestamp_micros(event_timestamp)) between 0 and 5 then 'night'
        WHEN extract(hour from timestamp_micros(event_timestamp)) between 6 and 11 then 'morning'
        WHEN extract(hour from timestamp_micros(event_timestamp)) between 12 and 17 then 'afternoon'
        ELSE 'evening'
        END as partOfDay,
    COUNT(*) AS eventCount
FROM `ookla-speedtest.analytics_264062063.events_*`
WHERE event_name = 'session_start'
AND regexp_extract(_table_suffix, '[0-9]+') BETWEEN '20220401' AND format_date('%Y%m%d',date_sub(current_date(), interval 0 day))
GROUP BY  1,2
ORDER BY eventCount DESC