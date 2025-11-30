-- removing not wanted signs
DROP TEMPORARY TABLE IF EXISTS cleaned_data;
create temporary table cleaned_data AS
SELECT
    `Date`,
    `Country`,
    `Segment`,
    `Product`,
    `Month Number`,
    `Year`,
    NULLIF(REGEXP_REPLACE(`Profit`, '[^0-9.\-]', ''), '') * 1 as profit,
    NULLIF(REGEXP_REPLACE(`Units Sold`, '[^0-9.\-]', ''), '') * 1 as Units_Sold,
    NULLIF(REGEXP_REPLACE(`Manufacturing Price`, '[^0-9.\-]', ''), '') * 1 as Manufacturing_Price,
    NULLIF(REGEXP_REPLACE(`Sale Price`, '[^0-9.\-]', ''), '') * 1 as Sale_Price,
    NULLIF(REGEXP_REPLACE(`Gross Sales`, '[^0-9.\-]', ''), '') * 1 as Gross_Sales,
    NULLIF(REGEXP_REPLACE(`Discounts`, '[^0-9.\-]', ''), '') * 1 as Discounts,
    NULLIF(REGEXP_REPLACE(`COGS`, '[^0-9.\-]', ''), '') * 1 as COGS,
    NULLIF(REGEXP_REPLACE(`Sales`, '[^0-9.\-]', ''), '') * 1 as Sales
FROM financials;
-- ALTER TABLE cleaned_data MODIFY `Date` DATE;
DROP TEMPORARY TABLE IF EXISTS cleaned_data_with_date;
CREATE TEMPORARY TABLE cleaned_data_with_date AS
SELECT
    STR_TO_DATE(`Date`, '%d/%m/%Y') AS `Date`, 
    `Country`,
    `Segment`,
    `Product`,
    `Month Number`,
    `Year`,
    `Profit`,
    `Units_Sold`,
    `Manufacturing_Price`,
    `Sale_Price`,
    `Gross_Sales`,
    `Discounts`,
    `COGS`,
    `Sales`
FROM cleaned_data;
    -- monthly sales
DROP TEMPORARY TABLE IF EXISTS monthly_sales;
CREATE TEMPORARY TABLE monthly_sales as
SELECT
    `Product`,
    `Year`,
    `Month Number`,
    SUM(`Sales`) AS total_sales,
    LAG(SUM(Sales)) OVER (PARTITION BY Product Order by Year, `Month Number`) as previous_month_sales, 
    CASE  
        WHEN LAG(sum(Sales)) over (partition by Product Order by Year, `Month Number`) = 0
             then null
	    else
            ((SUM(Sales) - LAG(SUM(Sales)) over (PARTITION BY Product ORDER by Year, `Month Number`)) /
            LAG(SUM(Sales)) over (PARTITION BY Product order by Year, `Month Number`)) * 100
	END AS month_growth
FROM cleaned_data_with_date
group by `Product`, `Year`, `Month Number`    
order by `Product`, `Year`, `Month Number`;

-- year over year growth
DROP TEMPORARY TABLE IF EXISTS yearbyyear;
CREATE TEMPORARY TABLE yearbyyear as
SELECT
    `Product`,
    `Month Number`,
    `Year`,
    SUM(`Sales`) as total_sales
FROM cleaned_data_with_date
group by `Product`, `Month Number`, `Year`;
-- pivot funcitonaloity
set @year1 = (SELECT MIN(`Year`) from cleaned_data_with_date);
set @year2 = (SELECT MAX(`Year`) from cleaned_data_with_date);

DROP TEMPORARY TABLE IF EXISTS year1_data;
CREATE TEMPORARY TABLE year1_data AS
SELECT `Product`, `Month Number`, total_sales
from yearbyyear
WHERE `Year` = @year1;
DROP TEMPORARY TABLE IF EXISTS year2_data;
CREATE TEMPORARY TABLE year2_data AS
SELECT `Product`, `Month Number`, total_sales
from yearbyyear
WHERE `Year` = @year2;

DROP TEMPORARY TABLE IF EXISTS yearpivot;
CREATE TEMPORARY TABLE yearpivot AS
SELECT
    y1.`Product`,
    y1.`Month Number`,
    y1.total_sales as year1_sales,
    y2.total_sales as year2_sales,
    ((y2.total_sales - y1.total_sales) / y1.total_sales) * 100 AS year_growth
FROM year1_data y1
INNER JOIN year2_data y2
    ON y1.`Product` = y2.`Product`
    AND y1.`Month Number` = y2.`Month Number`;

-- yearly growth by product
DROP TEMPORARY TABLE IF EXISTS yearsales;
CREATE TEMPORARY TABLE yearsales as
Select
    `Product`,
    `Year`,
    sum(`Sales`) as total_sales
from cleaned_data_with_date
group by `Product`, `Year`;

DROP TEMPORARY TABLE IF EXISTS year1_sales_data;
CREATE TEMPORARY TABLE year1_sales_data AS
SELECT `Product`, total_sales
FROM yearsales
WHERE `Year` = @year1;
DROP TEMPORARY TABLE IF EXISTS year2_sales_data;
CREATE TEMPORARY TABLE year2_sales_data AS
SELECT `Product`, total_sales
FROM yearsales
WHERE `Year` = @year2;
DROP TEMPORARY TABLE IF EXISTS yeargrowth;
CREATE TEMPORARY TABLE yeargrowth as
select
    y1.`Product`,
    y1.total_sales as year1_sales,
    y2.total_sales as year2_sales,
    ((y2.total_sales - y1.total_sales) / y1.total_sales) * 100 AS yeargrowthpct
FROM year1_sales_data y1
Join year2_sales_data y2
   on y1.`Product` = y2.`Product`;
-- new orders count
DROP temporary table if exists neworders;
create temporary table neworders as
select
     `Date`, 
     `Country`,
     `Segment`,
     Count(*) as new_orders
From cleaned_data_with_date
group by `Date`, `Country`, `Segment`;

-- sales performance metrics
drop temporary table if exists salesperformance;
create temporary table salesperformance as
select
    `Country`,
    `Segment`,
    sum(`Sales`) as total_sales,
    sum(`Profit`) as total_profit,
    sum(`Units_Sold`) as total_units_sold,
    sum(`Discounts`) as total_discounts,
    (sum(`Profit`) / sum(`Sales`)) * 100 as profitmargin,
    (sum(`Discounts`) / sum(`Sales`)) * 100 as avgtdiscountrate

From cleaned_data_with_date
group by `Country`, `Segment`;
-- view results
select 'Monthly Sales' as table_name, count(*) as row_count from monthly_sales
union all
select 'Year Pivot', count(*) from yearpivot
union all
select 'Year Growth', count(*) from yeargrowth
union all
select 'New Orders', count(*) from neworders
union all
select 'Sales Performance', count(*) from salesperformance;
-- show an individual table
select * from monthly_sales limit 50;