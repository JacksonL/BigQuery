-- ** Calculating user lifetime value

-- SELECT  
--     user_pseudo_id,
--     SUM(ecommerce.purchase_revenue) as lifetimeValue
-- FROM `ookla-speedtest.analytics_207499972.events_*`
-- WHERE 
--     _table_suffix BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 3 day))
--     AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 day))
--     AND ecommerce.purchase_revenue IS NOT NULL
-- GROUP BY 1
-- ORDER BY 1 DESC


-- ** Calculating average lifetime revenue

WITH prep AS(
SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS sessionId,
    PARSE_DATE('%Y%m%d', event_date) as sessionDate,
    FIRST_VALUE(PARSE_DATE('%Y%m%d', event_date)) OVER (PARTITION BY user_pseudo_id ORDER BY event_date ASC) as firstSessionDate,
    SUM(ecommerce.purchase_revenue) as revenue
FROM `ookla-speedtest.analytics_264062063.events_*`
WHERE _table_suffix BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 60 day)) AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 day))
GROUP BY
    user_pseudo_id,
    sessionId,
    event_date
ORDER BY
    user_pseudo_id,
    sessionId
),

prepLtv as(
SELECT
    DATE_DIFF(sessionDate, firstSessionDate, day) as day,
    COUNT(DISTINCT user_pseudo_id) as users,
    SUM(revenue) as ltvRevByDay,
    SUM(revenue), MAX(COUNT(DISTINCT user_pseudo_id)) OVER () as avgLtvRevPerDay,
FROM prep
GROUP BY day
ORDER BY day ASC
)

SELECT 
    day,
    SUM(avgLtvRevPerDay) OVER (ORDER BY day) as averageLtvRev
FROM prepLtv
GROUP BY 
    day,
    avgLtvRevPerDay
ORDER BY day