## IF WE EVER ADD A PLACEMENT, UPDATE WHERE STATEMENT BELOW TO INCLUDE PLACEMENT ID AS WELL AS THE CASE STATEMENT

WITH placementIds AS (
SELECT 
    Id,
    CASE
        WHEN name = 'Speedtest Desktop - All' THEN 'ST Desktop'
        WHEN name = 'Speedtest Mobile Web - All' THEN 'ST Mobile Web'
        WHEN name = 'Speedtest AAX' THEN 'ST AAX'
        WHEN name = 'Speedtest iOS' THEN 'ST iOS'
        WHEN name = 'Speedtest Android' THEN 'ST Android'
        WHEN name = 'DD Web - All' THEN 'Downdetector'
        WHEN name = 'DD AAX' THEN 'Downdetector'
        ELSE NULL
    END AS Name, 
    CAST(targetedAdUnitIDs AS INT64) AS targetedAdUnitIDs
FROM `ookla-speedtest.speedtest_ads_6692.MatchTablePlacement_6692` AS p, 
UNNEST(p.targetedAdUnitIDs) as targetedAdUnitIDs
WHERE _DATA_DATE = DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
AND Id IN (29799705, 29808361, 29785812, 29826806, 30942134, 30649302, 30697523) -- limits to main placements to avoid overlapping and duplicating
),

gamData AS (
SELECT
    NI._DATA_DATE AS date,
    IFNULL(Country, 'Unknown') AS country,
    CASE
        WHEN DeviceCategory = 'Smartphone' THEN 'Mobile'
        WHEN DeviceCategory = 'Connected TV' THEN 'CTV'
        WHEN DeviceCategory = 'Feature Phone' THEN 'Mobile'
        ELSE DeviceCategory
    END AS deviceCategory,
    MTP.Name AS placementName,
    AdUnitId AS adUnitId,
    lineItemId,
    IFNULL(MTLI.LineItemType, 'Yield Group') AS lineItemType,
    dealId, 
    MTLI.CostPerUnitInNetworkCurrency AS rate, 
    IFNULL(MTLI.costType, 'CPM') AS costType, 
    COUNT(*) AS impressions,
    SUM(EstimatedBackfillrevenue) AS adxRev
FROM
    `ookla-speedtest.speedtest_ads_6692.NetworkImpressions_6692` AS NI
LEFT JOIN speedtest_ads_6692.MatchTableLineItem_6692 AS MTLI ON NI.lineItemId = MTLI.ID AND NI._DATA_DATE = MTLI._DATA_DATE
LEFT JOIN speedtest_ads_6692.MatchTableAdUnit_6692 AS MTAU ON NI.AdUnitID = MTAU.ID AND NI._DATA_DATE = MTAU._DATA_DATE
LEFT JOIN placementIds as MTP ON MTAU.ID = MTP.targetedAdUnitIDs
WHERE
    lineItemId != 0 -- these are recorded in the networkBackfillImpressions table
    AND NI._DATA_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 day) AND NI._DATA_DATE < CURRENT_DATE()
GROUP BY
    date,
    country,
    deviceCategory,
    placementName,
    adUnitId,
    lineItemId,
    lineItemType,
    dealId, 
    rate, 
    costType

UNION ALL

SELECT
    NBI._DATA_DATE AS date,
    IFNULL(Country, 'Unknown') AS country,
    CASE
        WHEN DeviceCategory = 'Smartphone' THEN 'Mobile'
        WHEN DeviceCategory = 'Connected TV' THEN 'CTV'
        WHEN DeviceCategory = 'Feature Phone' THEN 'Mobile'
        ELSE DeviceCategory
    END AS deviceCategory,
    MTP.Name AS placementName,
    AdUnitId AS adUnitId,
    lineItemId,
    IFNULL(MTLI.LineItemType, 'Yield Group') AS lineItemType,
    dealId, 
    MTLI.CostPerUnitInNetworkCurrency AS rate, 
    IFNULL(MTLI.costType, 'Yield Group') AS costType,
    COUNT(*) AS impressions,
    SUM(EstimatedBackfillrevenue) AS adxRev
FROM
    `ookla-speedtest.speedtest_ads_6692.NetworkBackfillImpressions_6692` AS NBI
LEFT JOIN speedtest_ads_6692.MatchTableLineItem_6692 AS MTLI ON NBI.lineItemId = MTLI.ID AND NBI._DATA_DATE = MTLI._DATA_DATE
LEFT JOIN speedtest_ads_6692.MatchTableAdUnit_6692 AS MTAU ON NBI.AdUnitID = MTAU.ID AND NBI._DATA_DATE = MTAU._DATA_DATE
LEFT JOIN placementIds as MTP ON MTAU.ID = MTP.targetedAdUnitIDs
WHERE
    NBI._DATA_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 day) AND NBI._DATA_DATE < CURRENT_DATE()
GROUP BY
    date,
    country,
    deviceCategory,
    placementName,
    adUnitId,
    lineItemId,
    lineItemType,
    dealId, 
    rate, 
    costType
)

SELECT
    date,
    country,
    deviceCategory,
    placementName,
    adUnitId,
    lineItemId,
    lineItemType,
    dealId,
    rate,
    costType,
    impressions,
    CASE
        WHEN costType = 'CPM' AND dealId IS NOT NULL THEN ((impressions * rate) / 1000 * .9)
        WHEN costType = 'CPD' AND dealId IS NULL THEN (rate / (SUM(impressions) OVER(PARTITION BY lineItemId ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) * impressions) -- This calculates average eCPM from all lines and uses it to assign revenue per line based on impressions.
        WHEN costType = 'CPD' AND dealId IS NOT NULL THEN (rate / (SUM(impressions) OVER(PARTITION BY lineItemId ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) * impressions *.9) -- This calculates average eCPM from all lines and uses it to assign revenue per line based on impressions.
        WHEN costType = 'OB' THEN 0
        ELSE ((impressions * rate) / 1000) -- GAM Data Transfer does not use value CPM rate as their CostPerUnitInNEtworkCurrency field. So revenue is different than GAM reporting
    END AS revenue,
    adxRev
FROM
    gamData
GROUP BY 
    date,
    country,
    deviceCategory,
    placementName,
    adUnitId,
    costType,
    lineItemId,
    lineItemType,
    dealId,
    rate,
    impressions,
    adxRev