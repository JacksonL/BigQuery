-- ** Custom Engaged Sessions

-- prep query to pull in all raw data
with prep as (
select
    user_pseudo_id,
    (select value.int_value from unnest(event_params) where key = 'ga_session_id') as session_id,
    event_name,
    event_timestamp,
    (select value.string_value from unnest(event_params) where event_name = 'page_view' and key = 'page_location') as pageview_location
from
    `ookla-speedtest.analytics_264062063.events_20220516`),

-- subquery to get all sessions with a length > 10 seconds
session_length as (
select
    user_pseudo_id,
    session_id,
    timestamp_seconds(session_id) as session_start_time,
    (MAX(event_timestamp)-MIN(event_timestamp))/1000000 as session_length_seconds
from
    prep
GROUP BY 1,2
HAVING session_length_seconds > 10), 


-- subquery to get all sessions with 2 or more (unique) page views
multiple_pageviews as (
select 
    user_pseudo_id,
    session_id,
    timestamp_seconds(session_id) as session_start_time,
    pageview_location,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id, session_id, pageview_location) -1 as count_duplicate_pages,
    COUNT(pageview_location) OVER (PARTITION BY user_pseudo_id, session_id) as unique_pageviews
from
    prep
WHERE pageview_location IS NOT NULL
GROUP BY 1,2,4, event_timestamp
QUALIFY 
    count_duplicate_pages = 0
    AND unique_pageviews >= 2),

-- subquery to get all sessions with a conversion event (in this example 'purchase')
conversion_event as (
select 
    user_pseudo_id,
    session_id,
    timestamp_seconds(session_id) as session_start_time,
from
    prep
WHERE event_name = 'purchase'),

-- subquery to combine and deduplicate all subqueries generated earlier
dedup as (
SELECT 
    user_pseudo_id,
    session_id,
    session_start_time
FROM session_length

UNION DISTINCT

SELECT 
    user_pseudo_id,
    session_id,
    session_start_time
FROM multiple_pageviews
GROUP BY
    user_pseudo_id,
    session_id,
    session_start_time

UNION DISTINCT

SELECT 
    user_pseudo_id,
    session_id,
    session_start_time
FROM conversion_event
)

-- main query to count unique engaged sessions by date in descending order
select *
    -- date(session_start_time, "America/Los_Angeles") as date,
    -- COUNT(DISTINCT CONCAT(user_pseudo_id,session_id)) as engaged_sessions
from
    dedup
-- group by
--     date
order by
    3 desc
