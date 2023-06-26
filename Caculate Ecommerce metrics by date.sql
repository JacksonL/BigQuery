-- ** Caculate Ecommerce metrics by date

-- SELECT
--     event_date as date,
--     COUNT(DISTINCT ecommerce.transaction_id) as transactions,
--     SUM(ecommerce.purchase_revenue) as revenue
-- FROM `ookla-speedtest.analytics_207499972.events_intraday_20220505`
-- GROUP BY 1
-- ORDER BY 1 ASC

-- ** Calculate Conversion Rate By Engaged Sessions

-- WITH prep AS(
-- SELECT
--     user_pseudo_id,
--     (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') as sessionId,
--     event_date,
--     MAX((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged')) as sessionEngaged,
--     ecommerce.transaction_id,
--     ecommerce.purchase_revenue
-- FROM `ookla-speedtest.analytics_207499972.events_*`
-- WHERE _table_suffix BETWEEN '20220501' AND '20220502'
-- GROUP BY 1,2,3,5,6
-- )

-- SELECT 
--     event_date as date,
--     COUNT(DISTINCT transaction_id) as transactions,
--     SUM(purchase_revenue) as purchaseRevenue,
--     COUNT(DISTINCT transaction_id) / COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId)) as ecommerceConversionRateAllSessions,
--     COUNT(DISTINCT transaction_id) / COUNT(DISTINCT CASE WHEN sessionEngaged = '1' THEN CONCAT(user_pseudo_id, sessionId) ELSE NULL END) as ecommerceConversionRateEngagedSessions
-- FROM prep
-- GROUP BY 1
-- ORDER BY 1


-- ** Add tax, refund and shipping details

WITH prep AS(
SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') as sessionId,
    event_date,
    MAX((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged')) as sessionEngaged,
    ecommerce.transaction_id,
    ecommerce.purchase_revenue,
    ecommerce.total_item_quantity,
    ecommerce.refund_value,
    ecommerce.tax_value,
    ecommerce.shipping_value
FROM `ookla-speedtest.analytics_207499972.events_*`
WHERE _table_suffix BETWEEN '20220501' AND '20220502'
GROUP BY 1,2,3,5,6,7,8,9,10
)

SELECT 
    event_date as date,
    COUNT(DISTINCT transaction_id) as transactions,
    SUM(purchase_revenue) as purchaseRevenue,
    SAFE_DIVIDE(COUNT(DISTINCT transaction_id), COUNT(DISTINCT CONCAT(user_pseudo_id, sessionId))) as ecommerceConversionRateAllSessions,
    SAFE_DIVIDE(COUNT(DISTINCT transaction_id), COUNT(DISTINCT CASE WHEN sessionEngaged = '1' THEN CONCAT(user_pseudo_id, sessionId) ELSE NULL END)) as ecommerceConversionRateEngagedSessions,
    SUM(total_item_quantity) as items,
    SUM(refund_value) as refundValue,
    SUM(tax_value) as taxValue,
    SUM(shipping_value) as shippingValue,
    SAFE_DIVIDE(SUM(purchase_revenue), COUNT(DISTINCT transaction_id)) as avgTransactionValue,
    SAFE_DIVIDE(SUM(shipping_value), COUNT(DISTINCT transaction_id)) as avgShippingValue,
    SAFE_DIVIDE(SUM(total_item_quantity), COUNT(DISTINCT transaction_id)) as avgItems
FROM prep
GROUP BY 1
ORDER BY 1

