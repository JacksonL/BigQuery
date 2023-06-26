-- ** Flatten GA4 Schema for Relational Databases

-- Table 1: flat_events
select
    (select value.int_value from unnest(event_params) where key = 'ga_session_id') as ga_session_id,
    * except(event_params,user_properties,items),
    concat(user_pseudo_id,event_timestamp,event_name,row_number() over(partition by user_pseudo_id, event_timestamp, event_name)) as join_key
from
    `ookla-speedtest.analytics_264062063.events_20220518`;

-- Table 2: flat_event_params
with prep as (
select
    row_number() over(partition by user_pseudo_id, event_timestamp, event_name) as dedup_id,
    *
from
    `ookla-speedtest.analytics_264062063.events_20220518`),

prep_unnest as (
select 
    user_pseudo_id,
    case when event_params.key = 'ga_session_id' then event_params.value.int_value else null end as ga_session_id,
    event_timestamp,
    event_name,
    event_params.key,
    event_params.value.string_value,
    event_params.value.int_value,
    event_params.value.float_value,
    event_params.value.double_value,
    dedup_id
from
    prep,
    unnest(event_params) as event_params)

select
    max(ga_session_id) over (partition by event_timestamp,event_name) as ga_session_id,
    * except(ga_session_id,dedup_id),
    concat(user_pseudo_id,event_timestamp,event_name,dedup_id) as join_key
from
    prep_unnest;

-- Table 3: flat_user_properties
with prep as (
select 
    row_number() over(partition by user_pseudo_id, event_timestamp, event_name) as dedup_id,
    *
from
    `ookla-speedtest.analytics_264062063.events_20220518`)

select 
    user_pseudo_id,
    event_timestamp,
    event_name,
    user_properties.key,
    user_properties.value.string_value,
    user_properties.value.int_value,
    user_properties.value.float_value,
    user_properties.value.double_value,
    user_properties.value.set_timestamp_micros,
    concat(user_pseudo_id,event_timestamp,event_name,dedup_id) as join_key
from
    prep,
    unnest(user_properties) as user_properties;

-- Table 4: flat_items
with prep as (
select
    row_number() over(partition by user_pseudo_id, event_timestamp, event_name) as dedup_id,
    *
from
    `ookla-speedtest.analytics_264062063.events_20220518`)

select
    user_pseudo_id,
    event_timestamp,
    event_name,
    items.item_id,
    items.item_name,
    items.item_brand,
    items.item_variant,
    items.item_category,
    items.item_category2,
    items.item_category3,
    items.item_category4,
    items.item_category5,
    items.price_in_usd,
    items.price,
    items.quantity,
    items.item_revenue_in_usd,
    items.item_revenue,
    items.item_refund_in_usd,
    items.item_refund,
    items.coupon,
    items.affiliation,
    items.location_id,
    items.item_list_id,
    items.item_list_name,
    items.item_list_index,
    items.promotion_id,
    items.promotion_name,
    items.creative_name,
    items.creative_slot,
    concat(user_pseudo_id,event_timestamp,event_name,dedup_id) as join_key
from 
    prep,
    unnest(items) as items

-- If above created to separate tables, then can query like normal SQL:

select
    device.category,
    count(distinct events.user_pseudo_id) as users,
    count(distinct concat(events.user_pseudo_id,events.ga_session_id)) as sessions,
    count(distinct case when user_properties.key = 'visitor_status' and user_properties.string_value = 'buyer' then user_properties.user_pseudo_id else null end) as buyers,
    count(distinct case when event_params.key = 'engagement_time_msec' and event_params.int_value > 0 then event_params.user_pseudo_id else null end) as active_users,
    count(distinct case when items.event_name = 'add_to_cart' then concat(events.user_pseudo_id,events.ga_session_id) else null end) as sessions_with_add_to_cart
from 
    `bigquery-ga4-course.ga4_flat.flat_events` as events
    left join `bigquery-ga4-course.ga4_flat.flat_user_properties` as user_properties on events.join_key = user_properties.join_key
    left join `bigquery-ga4-course.ga4_flat.flat_event_params` as event_params on events.join_key = event_params.join_key
    left join `bigquery-ga4-course.ga4_flat.flat_items` as items on events.join_key = items.join_key
group by 
    category