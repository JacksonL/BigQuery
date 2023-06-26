select
    case
        when traffic_source.source = '(direct)' and traffic_source.medium in ('(not set)', '(none)') then 'direct'
        when (regexp_contains(traffic_source.source,'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
            or regexp_contains(traffic_source.name, '^(.*(([^a-df-z]|^)shop|shopping).*)$'))
            and regexp_contains(traffic_source.medium, '^(.*cp.*|ppc|paid.*)$') then 'Paid Shopping'
         when regexp_contains(traffic_source.source,'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
            and regexp_contains(traffic_source.medium,'^(.*cp.*|ppc|paid.*)$') then 'Paid Search'
        when regexp_contains(traffic_source.source,'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
            and regexp_contains(traffic_source.medium,'^(.*cp.*|ppc|paid.*)$') then 'Paid Social'
        when regexp_contains(traffic_source.source,'dailymotion|disneyplus|netflix|youtube|vimeo|twitch|vimeo|youtube')
            and regexp_contains(traffic_source.medium,'^(.*cp.*|ppc|paid.*)$') then 'Paid Video'
        when traffic_source.medium in ('display', 'banner', 'expandable', 'interstitial', 'cpm') then 'Display'
        when regexp_contains(traffic_source.source,'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
            or regexp_contains(traffic_source.name, '^(.*(([^a-df-z]|^)shop|shopping).*)$') then 'Organic Shopping'
        when regexp_contains(traffic_source.source,'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
            or traffic_source.medium in ('social','social-network','social-media','sm','social network','social media') then 'Organic Social'
        when regexp_contains(traffic_source.source,'dailymotion|disneyplus|netflix|youtube|vimeo|twitch|vimeo|youtube')
            or regexp_contains(traffic_source.medium,'^(.*video.*)$') then 'Organic Video'
        when regexp_contains(traffic_source.source,'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
            or traffic_source.medium = 'organic' then 'Organic Search'
        when regexp_contains(traffic_source.source,'email|e-mail|e_mail|e mail')
            or regexp_contains(traffic_source.medium,'email|e-mail|e_mail|e mail') then 'Email'
        when traffic_source.medium = 'affiliate' then 'Affiliates'
        when traffic_source.medium = 'referral' then 'Referral'
        when traffic_source.medium = 'audio' then 'Audio'
        when traffic_source.medium = 'sms' then 'SMS'
        when traffic_source.medium like '%push'
            or regexp_contains(traffic_source.medium,'mobile|notification') then 'Mobile Push Notifications'
    else 'Unassigned' end as channel_grouping,
    traffic_source.source,
    traffic_source.medium,
    traffic_source.name as campaign,
    count(distinct user_pseudo_id) as users
from
    `ookla-speedtest.analytics_264062063.events_20220603`
group by
    channel_grouping,
    source,
    medium,
    campaign
order by
    users desc