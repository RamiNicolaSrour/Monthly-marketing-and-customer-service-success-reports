-- convert churn to numeric data and calculate the customer and success metrics and KPIs
set sql_safe_updates = 0;

update `wa_fn-usec_-telco-customer-churn`
set Churn = case 
                when Churn = 'No' then 0 
                when Churn = 'Yes' then 1 end
WHERE churn in ('Yes', 'No');

Set @churn_user = (select sum(Churn) from `wa_fn-usec_-telco-customer-churn`);
set @total_users = (select count(*) from `wa_fn-usec_-telco-customer-churn`);
set @churn_rate = (@churn_user / @total_users) *  100;

set @activeusers = (select count(*) from `wa_fn-usec_-telco-customer-churn` where churn = 0);
set @activeusers2 = @total_users - @churn_user;
set @retentionrate = (@activeusers / @total_users) * 100;

set @tenurethreshold = 2;
set @newusers = (select count(*) from `wa_fn-usec_-telco-customer-churn` where tenure <= @tenurethreshold);
set sql_safe_updates = 1;

select
    @churn_user as churned_users,
    @total_user as total_users,
    @churn_rate as churn_rate_percent,
    @active_user as active_users,
    @retention_rate as retention_rate_percent,
    @new_user as new_users_within_tenure_threshold;

-- display churn analysis for services
select 'OnlineSecurity' as service, OnlineSecurity as plan,
       (Sum(case when Churn = 1 then 1 else 0 end) / count(*)) * 100 as churn_rate
from `wa_fn-usec_-telco-customer-churn`
group by OnlineSecurity
Union all
select 'DeviceProtection' as service, DeviceProtection,
       (Sum(case when Churn = 1 then 1 else 0 end) / count(*)) * 100 
from `wa_fn-usec_-telco-customer-churn`
group by DeviceProtection
Union all
select 'TechSupport', TechSupport,
       (Sum(case when Churn = 1 then 1 else 0 end) / count(*)) * 100 
from `wa_fn-usec_-telco-customer-churn`
group by TechSupport
Union all
select 'OnlineBackup', OnlineBackup,
       (Sum(case when Churn = 1 then 1 else 0 end) / count(*)) * 100 
from `wa_fn-usec_-telco-customer-churn`
group by OnlineBackup
Union all
select 'StreamingTV', StreamingTV,
       (Sum(case when Churn = 1 then 1 else 0 end) / count(*)) * 100 
from `wa_fn-usec_-telco-customer-churn`
group by StreamingTV
Union all
select 'StreamingMovies', StreamingMovies,
       (Sum(case when Churn = 1 then 1 else 0 end) / count(*)) * 100 
from `wa_fn-usec_-telco-customer-churn`
group by StreamingMovies
order by service;