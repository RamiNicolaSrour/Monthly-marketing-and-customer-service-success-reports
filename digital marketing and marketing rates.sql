-- add CTR column
alter table online_advertising_performance_data
drop column ctr;

alter table online_advertising_performance_data
add column ctr decimal(10,2)
generated always as (round((clicks / nullif(displays,0)) * 100, 2)) stored;
-- total clicks
select sum(clicks) as totalclicks from online_advertising_performance_data;
-- campaign clicks with ranking
drop temporary table if exists campaignclicks;

create temporary table campaignclicks as
select
    campaign_number,
    sum(clicks) as clicks,
    dense_rank() over (order by sum(clicks) desc) as `Rank`
From online_advertising_performance_data
group by campaign_number;

-- marketing metrics performance
drop temporary table if  exists marketingperformance;

create temporary table marketingperformance as
select
    campaign_number,
    sum(clicks) as clicks,
    sum(displays) as displays,
    sum(cost) as cost,
    sum(revenue) as revenue,
    CAST((sum(clicks) / sum(displays)) * 100 as decimal(10,2)) as CTR,
    CAST(sum(cost) / sum(clicks) as decimal(10,2)) as CPC,
    cast(sum(revenue) / sum(cost) as decimal(10,2)) as ROAS
FROM online_advertising_performance_data
group by campaign_number;

-- show a table
select * from marketingperformance;