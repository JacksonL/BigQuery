# Append unique user_pseudo_id to table
INSERT
    `ookla-speedtest.speedtest.tmp_video_fiam_users` 

SELECT
    *
FROM (
SELECT 
    DISTINCT IFNULL(user_pseudo_id, 'noId') AS user_pseudo_id,
FROM `ookla-speedtest.analytics_207499972.events_*`
WHERE _table_suffix BETWEEN FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 3 day)) and FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 day))
AND platform IN ('IOS', 'ANDROID')
AND (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'message_name') IN ('Video Test Prompt', 'Android Tablet Device Video Test Relaunch', 'Android Mobile Device Video Test Relaunch')
AND IFNULL(user_pseudo_id, 'noId') NOT IN (SELECT user_pseudo_id FROM `ookla-speedtest.speedtest.tmp_video_fiam_users` )
);

DELETE
    `ookla-speedtest.speedtest.tmp_video_fiam_daily_data`
WHERE
# Delete last three days, BQ/Firebase seems to go back up to three days and edits tables.
  CAST(date AS DATE FORMAT 'YYYYMMDD') BETWEEN DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 3 day) and DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 day);
# Then go get those three days again, updated.
INSERT
    `ookla-speedtest.speedtest.tmp_video_fiam_daily_data`
SELECT
  *
FROM (
WITH fiam AS (
  SELECT * FROM `ookla-speedtest.speedtest.tmp_video_fiam_users`
)

SELECT
    'Yes' AS FIAM,
    event_date AS date,
    platform AS platform,
    app_info.version AS appVersion,
    COUNT(DISTINCT main.user_pseudo_id) AS users,
    COUNT(DISTINCT CONCAT(main.user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) as sessions,
    COUNTIF(event_name = "videoScreenView") AS videoScreenViews,
    COUNTIF(event_name = "beginVideoTest") AS videoTestsBegun,
    COUNT(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'completeVideoTest' AND key = 'videoResultId')) AS videoTestsComplete,
    COUNTIF(event_name = "videoTestCancel") AS videoTestsCancelled
FROM `ookla-speedtest.analytics_207499972.events_*` AS main
LEFT JOIN fiam ON main.user_pseudo_id = fiam.user_pseudo_id
WHERE platform IN ('IOS', 'ANDROID')
AND fiam.user_pseudo_id IS NOT NULL
AND _table_suffix BETWEEN FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 3 day)) and FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 day))
GROUP BY 1,2,3,4

UNION ALL

SELECT
    'No' AS FIAM,
    event_date AS date,
    platform AS platform,
    app_info.version AS appVersion,
    COUNT(DISTINCT main.user_pseudo_id) AS users,
    COUNT(DISTINCT CONCAT(main.user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) as sessions,
    COUNTIF(event_name = "videoScreenView") AS videoScreenViews,
    COUNTIF(event_name = "beginVideoTest") AS videoTestsBegun,
    COUNT(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'completeVideoTest' AND key = 'videoResultId')) AS videoTestsComplete,
    COUNTIF(event_name = "videoTestCancel") AS videoTestsCancelled
FROM `ookla-speedtest.analytics_207499972.events_*` AS main
LEFT JOIN fiam ON main.user_pseudo_id = fiam.user_pseudo_id
WHERE platform IN ('IOS', 'ANDROID')
AND fiam.user_pseudo_id IS NULL
AND _table_suffix BETWEEN FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 3 day)) and FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 day))
GROUP BY 1,2,3,4

ORDER BY date
);

# Append only new users not already present in table.
INSERT
    `ookla-speedtest.speedtest.tmp_video_fiam_conversions`
SELECT 
    *
FROM (
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
    CASE WHEN (main.user_pseudo_id NOT IN (SELECT user_pseudo_id FROM `ookla-speedtest.speedtest.tmp_video_fiam_conversions` WHERE FIAM = 'Video Prompt' AND videoScreenViewConversion = 1) AND COUNTIF(event_name = 'videoScreenView') > 0) THEN 1 ELSE 0 END AS videoScreenViewConversion,
    CASE WHEN (main.user_pseudo_id NOT IN (SELECT user_pseudo_id FROM `ookla-speedtest.speedtest.tmp_video_fiam_conversions` WHERE FIAM = 'Video Prompt' AND videoTestStartConversion = 1) AND COUNTIF(event_name = 'beginVideoTest') > 0) THEN 1 ELSE 0 END AS videoTestStartConversion,
    CASE WHEN (main.user_pseudo_id NOT IN (SELECT user_pseudo_id FROM `ookla-speedtest.speedtest.tmp_video_fiam_conversions` WHERE FIAM = 'Video Prompt' AND videoTestCompleteConversion = 1) AND COUNT(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'completeVideoTest' AND key = 'videoResultId')) > 0) THEN 1 ELSE 0 END AS videoTestCompleteConversion
FROM `ookla-speedtest.analytics_207499972.events_*` AS main
LEFT JOIN fiam ON main.user_pseudo_id = fiam.user_pseudo_id
WHERE platform IN ('IOS', 'ANDROID')
AND _table_suffix BETWEEN FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 3 day)) and FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 day))
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
    CASE WHEN (main.user_pseudo_id NOT IN (SELECT user_pseudo_id FROM `ookla-speedtest.speedtest.tmp_video_fiam_conversions` WHERE FIAM = 'No Video Prompt' AND videoScreenViewConversion = 1) AND COUNTIF(event_name = 'videoScreenView') > 0) THEN 1 ELSE 0 END AS videoScreenViewConversion,
    CASE WHEN (main.user_pseudo_id NOT IN (SELECT user_pseudo_id FROM `ookla-speedtest.speedtest.tmp_video_fiam_conversions` WHERE FIAM = 'No Video Prompt' AND videoTestStartConversion = 1) AND COUNTIF(event_name = 'beginVideoTest') > 0) THEN 1 ELSE 0 END AS videoTestStartConversion,
    CASE WHEN (main.user_pseudo_id NOT IN (SELECT user_pseudo_id FROM `ookla-speedtest.speedtest.tmp_video_fiam_conversions` WHERE FIAM = 'No Video Prompt' AND videoTestCompleteConversion = 1) AND COUNT(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE event_name = 'completeVideoTest' AND key = 'videoResultId')) > 0) THEN 1 ELSE 0 END AS videoTestCompleteConversion
FROM `ookla-speedtest.analytics_207499972.events_*` AS main
LEFT JOIN fiam ON main.user_pseudo_id = fiam.user_pseudo_id
WHERE platform IN ('IOS', 'ANDROID')
AND _table_suffix BETWEEN FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 3 day)) and FORMAT_DATE("%Y%m%d",DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 day))
AND fiam.user_pseudo_id IS NULL
AND
# Make sure, if Android, App version is 4.6.0 or higher (should account for eventual >= 5.0.0 releases)
((PLATFORM = "ANDROID" AND (IF(safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) = 4,safe_cast(split(app_info.version,".")[safe_offset(1)] as int64) >= 6,safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) > 4))) 
OR
# Make sure, if iOS, App version is 4.3.0 or higher (should account for eventual >= 5.0.0 releases)
(PLATFORM = "IOS" AND (IF(safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) = 4,safe_cast(split(app_info.version,".")[safe_offset(1)] as int64) >= 3,safe_cast(split(app_info.version,".")[safe_offset(0)] as int64) > 4))))
GROUP BY 1,2,3
);

# Delete aggregated table and replace with updated numbers
DELETE
    `ookla-speedtest.speedtest.tmp_video_fiam_conversions_aggregated`
WHERE 
    true;

INSERT
    `ookla-speedtest.speedtest.tmp_video_fiam_conversions_aggregated`
SELECT
    *
FROM(
    SELECT 
    FIAM,
    platform,
    COUNT(DISTINCT user_pseudo_id) as users,
    SUM(videoScreenViews) as videoScreenViews,
    SUM(videoTestsBegun) as videoTestsBegun,
    SUM(videoTestsComplete) as videoTestsComplete,
    SUM(videoTestsCancelled) as videoTestsCancelled,
    SUM(videoScreenViewConversion) as videoScreenViewConversion,
    SUM(videoTestStartConversion) as videoTestStartConversion,
    SUM(videoTestCompleteConversion) as videoTestCompleteConversion
FROM `ookla-speedtest.speedtest.tmp_video_fiam_conversions`
GROUP BY 1,2
)
