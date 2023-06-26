#create table "tmp_video_fiam_conversions"

WITH fiam AS (
SELECT * FROM `ookla-speedtest.speedtest.tmp_video_fiam_users`
)

SELECT
    'Video Prompt' AS FIAM,
    platform AS platform,
    main.user_pseudo_id AS user_pseudo_id,
    COUNTIF(event_name = "videoScreenView") AS videoScreenViews,
    COUNTIF(event_name = "beginVideoTest") AS videoTestsBegun,
    COUNT(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'completeVideoTest' AND key = 'videoResultId')) AS videoTestsComplete,
    COUNTIF(event_name = "videoTestCancel") AS videoTestsCancelled,
    CASE WHEN COUNTIF(event_name = 'videoScreenView') > 0 THEN 1 ELSE 0 END AS videoScreenViewConversion,
    CASE WHEN COUNTIF(event_name = 'beginVideoTest') > 0 THEN 1 ELSE 0 END AS videoTestStartConversion,
    CASE WHEN COUNT(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'completeVideoTest' AND key = 'videoResultId')) > 0 THEN 1 ELSE 0 END AS videoTestCompleteConversion
FROM `ookla-speedtest.analytics_207499972.events_*` AS main
LEFT JOIN fiam ON main.user_pseudo_id = fiam.user_pseudo_id
WHERE platform IN ('IOS', 'ANDROID')
AND _table_suffix BETWEEN FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 36 day)) and FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 day))
AND fiam.user_pseudo_id IS NOT NULL
AND
# Make sure, if Android, App version is 4.6.0 or higher (should account for eventual >= 5.0.0 releases)
((PLATFORM = "ANDROID" AND (IF(safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) = 4,safe_cast(split(app_info.version,".")[safe_offset(1)] as int64) >= 6,safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) > 4))) 
OR
# Make sure, if iOS, App version is 4.3.0 or higher (should account for eventual >= 5.0.0 releases)
(PLATFORM = "IOS" AND (IF(safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) = 4,safe_cast(split(app_info.version,".")[safe_offset(1)] as int64) >= 3,safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) > 4))))
GROUP BY 1,2,3

UNION ALL

SELECT
    'No Video Prompt' AS FIAM,
    platform AS platform,
    main.user_pseudo_id AS user_pseudo_id,
    COUNTIF(event_name = "videoScreenView") AS videoScreenViews,
    COUNTIF(event_name = "beginVideoTest") AS videoTestsBegun,
    COUNT(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'completeVideoTest' AND key = 'videoResultId')) AS videoTestsComplete,
    COUNTIF(event_name = "videoTestCancel") AS videoTestsCancelled,
    CASE WHEN COUNTIF(event_name = 'videoScreenView') > 0 THEN 1 ELSE 0 END AS videoScreenViewConversion,
    CASE WHEN COUNTIF(event_name = 'beginVideoTest') > 0 THEN 1 ELSE 0 END AS videoTestStartConversion,
    CASE WHEN COUNT(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'completeVideoTest' AND key = 'videoResultId')) > 0 THEN 1 ELSE 0 END AS videoTestCompleteConversion
FROM `ookla-speedtest.analytics_207499972.events_*` AS main
LEFT JOIN fiam ON main.user_pseudo_id = fiam.user_pseudo_id
WHERE platform IN ('IOS', 'ANDROID')
AND _table_suffix BETWEEN FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 36 day)) and FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 day))
AND fiam.user_pseudo_id IS NULL
AND
# Make sure, if Android, App version is 4.6.0 or higher (should account for eventual >= 5.0.0 releases)
((PLATFORM = "ANDROID" AND (IF(safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) = 4,safe_cast(split(app_info.version,".")[safe_offset(1)] as int64) >= 6,safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) > 4))) 
OR
# Make sure, if iOS, App version is 4.3.0 or higher (should account for eventual >= 5.0.0 releases)
(PLATFORM = "IOS" AND (IF(safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) = 4,safe_cast(split(app_info.version,".")[safe_offset(1)] as int64) >= 3,safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) > 4))))
GROUP BY 1,2,3