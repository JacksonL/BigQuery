with date_range as (
select
    date('2021-07-01') as start_date,
    date('2021-07-15') as end_date),

weather as (
select
    date(cast(year as int64),cast(mo as int64),cast(da as int64)) as date,
    case when temp = 9999.9 then null else temp end as temperature_fahrenheit_mean,
    case when max = 9999.9 then null else temp end as temperature_fahrenheit_max,
    case when min = 9999.9 then null else temp end as temperature_fahrenheit_min,
    case when visib = 999.9 then null else visib end as visibility_mi,
    case when wdsp = '999.9' then null else wdsp end as wind_speed_kn,
    case when prcp = 99.99 then null else prcp end as precipitation_in,
    case when sndp = 999.9 then 0.0 else sndp end as snow_depth_in,
    case when temp = 9999.9 then null else round((temp - 32) * (5/9),1) end as temperature_celcius_mean,
    case when max = 9999.9 then null else round((max - 32) * (5/9),1) end as temperature_celcius_max,
    case when min = 9999.9 then null else round((min - 32) * (5/9),1) end as temperature_celcius_min,
    case when visib = 999.9 then null else round(visib * 1.609,1) end as visibility_km,
    case when wdsp = '999.9' then null else round(cast(wdsp as float64) * 1.852,1) end as wind_speed_kmh,
    case when prcp = 99.99 then null else round(prcp * 25.4,1) end as precipitation_mm,
    case when sndp = 999.9 then 0.0 else round(sndp * 25.4,1) end as snow_depth_mm,
    fog,
    rain_drizzle,
    hail,
    thunder
from
    `bigquery-public-data.noaa_gsod.gsod*`,
    date_range
where
    _table_suffix between cast(extract(year from start_date) as string) and cast(extract(year from end_date) as string)
    and date(cast(year as int64),cast(mo as int64),cast(da as int64)) >= start_date
    and date(cast(year as int64),cast(mo as int64),cast(da as int64)) <= end_date
    and stn = '727930'
order by
    date)

select
    events.event_date,
    count(distinct concat(user_pseudo_id, (select value.int_value from unnest(event_params) where key = 'ga_session_id'))) as sessions,
    count(distinct ecommerce.transaction_id) as transactions,
    ifnull(sum(ecommerce.purchase_revenue),0) as purchase_revenue,
    max(weather.temperature_fahrenheit_max) as temperature_fahrenheit_max,
    max(weather.temperature_fahrenheit_mean) as temperature_fahrenheit_mean,
    max(weather.precipitation_in) as precipitation_in,
    max(weather.wind_speed_kn) as wind_speed_kn
from
    `ookla-speedtest.analytics_264062063.events_*` as events,
    date_range
    left join weather on events.event_date = format_date('%Y%m%d',weather.date)
where
    _table_suffix between format_date('%Y%m%d',date_range.start_date) and format_date('%Y%m%d',date_range.end_date)
group by
    event_date
order by
    event_date desc