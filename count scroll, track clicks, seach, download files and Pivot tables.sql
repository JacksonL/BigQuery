-- ** Three ways to count scroll interactions

-- #1 count of all scroll events by page
-- SELECT
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'scroll' AND key = 'page_location') as scrollPage,
--     COUNTIF(event_name = 'scroll') as scrolls
-- FROM `ookla-speedtest.analytics_264062063.events_20220425`
-- GROUP BY 1
-- ORDER BY scrolls DESC 


-- #2 Count only percent scrolled
-- SELECT
--     CASE
--       WHEN (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'scroll' and key = 'percent_scrolled') = 90
--       THEN (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'scroll' and key = 'page_location') 
--       ELSE NULL END AS scrollPage90Percent,
--     COUNTIF(event_name = 'scroll') as scrolls
-- FROM `ookla-speedtest.analytics_264062063.events_20220425`
-- GROUP BY scrollPage90Percent
-- ORDER BY scrolls DESC

-- #3 Anotehr way to count only percent scrolled
-- SELECT
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'scroll' and key = 'page_location') scrollPage,
--     COUNTIF(event_name = 'scroll' AND (SELECT value.int_value FROM UNNEST(event_params) WHERE event_name = 'scroll' and key = 'percent_scrolled') = 90) as scrolls
-- FROM `ookla-speedtest.analytics_264062063.events_20220425`
-- GROUP BY scrollPage
-- ORDER BY scrolls DESC


-- ** Track outbound click events

-- SELECT
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'click' AND key = 'page_location') as page,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'click' AND key = 'link_domain') as linkDomain,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'click' AND key = 'link_url') as linkUrl,
--     COUNTIF(event_name = 'click' AND (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'click' AND key = 'outbound') = 'true') as clicks
-- FROM `ookla-speedtest.analytics_264062063.events_20220425`
-- WHERE event_name = 'click'
-- GROUP BY 1,2,3
-- ORDER BY clicks DESC


-- ** Track site search

-- SELECT
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'view_search_results' AND key = 'search_term') as searchTerm,
--     COUNTIF(event_name = 'view_search_results') as searches
-- FROM `ookla-speedtest.analytics_251126210.events_intraday_20220426`
-- GROUP BY 1
-- ORDER BY searches DESC


-- ** Count download files

-- SELECT
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'file_download' AND key = 'file_extension') as file_type,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'file_download' AND key = 'file_name') as file_name,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'file_download' AND key = 'link_text') as link_text,
--     (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'file_download' AND key = 'link_url') as link_url,
--     COUNTIF(event_name = 'file_download') as downloads
-- FROM `ookla-speedtest.analytics_264062063.events_202204*`
-- WHERE _table_suffix >= '01'
-- AND _table_suffix <= '30'
-- GROUP BY 1,2,3,4
-- HAVING file_type IS NOT NULL
-- ORDER BY downloads DESC

-- ** PIVOT Function

-- #1 source query

SELECT *
FROM(

SELECT
    user_pseudo_id,
    event_name

FROM `ookla-speedtest.analytics_264062063.events_202204*`)
PIVOT (
-- #2 aggregate function
    COUNT(*)
-- #3 pivot column
FOR
    event_name
-- #4 filter events
IN (
    'session_start',
    'frist_visit',
    'page_view',
    'scroll',
    'click',
    'view_search_results',
    'file_download',
    'video_start')
)

