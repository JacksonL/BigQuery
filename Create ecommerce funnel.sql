-- ** Create ecommerce funnel

WITH prep AS(
SELECT  
    event_name,
    items.item_name,
    SUM(items.quantity) as items
FROM 
    `ookla-speedtest.analytics_207499972.events_intraday_20220506`,
    UNNEST(items) as items
GROUP BY 1,2
)

SELECT 
    item_name,
    SUM(CASE WHEN event_name = 'view_item' THEN items ELSE 0 END) as viewItem,
    SUM(CASE WHEN event_name = 'add_to_cart' THEN items ELSE 0 END) as addToCart,
    SUM(CASE WHEN event_name = 'begin_checkout' THEN items ELSE 0 END) as beginCheckout,
    SUM(CASE WHEN event_name = 'purchase' THEN items ELSE 0 END) as purchases,
    SAFE_DIVIDE(SUM(CASE WHEN event_name = 'purchase' THEN items ELSE 0 END), SUM(CASE WHEN event_name = 'view_item' THEN items ELSE 0 END)) as viewToPurchaseRate
FROM prep
GROUP BY 1
ORDER BY 6 DESC