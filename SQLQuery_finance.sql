select *
from GL;

select top(10) *
from GL;

select *
from GL
where Account_key = 10;

select *
from GL
where Account_key = 10 and Territory_key = 3 and Amount > 100000;

-- Change Date column data type from varchar to DATE
alter table GL
alter column Date DATE;

-- Filter date, string, and <> not equal
select *
from GL
where Date = '2019-06-30' and Details = 'Interest expense' and Territory_key <> 1;

select *
from GL
where Account_key between 1 and 30;

select *
from GL
where Date between '2019-01-01' and '2019-01-31';

--Extract year
select Date, year(Date) as YR, month(Date) as MO, day(Date) as DY
from GL;

select *
from GL
where year(Date) = 2020 and month(date) = 8;

-- Alter date datatype from VARCHAR to DATE
alter table Calendar
drop constraint PK_Calendar;

alter table Calendar
alter column Date DATE;

alter table Calendar
alter column Date DATE NOT NULL;

alter table Calendar
add constraint PK_Calendar PRIMARY KEY (Date);

-- Datepart
select Date,
datepart(year, date) as 'Year', 
datepart(quarter, date) as 'Quarter',
datepart(month, date) as 'Month',
datepart(day, date) as 'DayOfMonth',
datepart(dayofyear, date) as 'DayOfYear',
datepart(week, date) as 'Week',
datepart(weekday, date) as 'WeekDay'
from calendar;

/* look at the sales for the week, number 51 for each year in our data for Black Friday sales */
select *
from COA;
-- we've found the account sales is on account_key number 210.

select *, datepart(week, Date)
from GL
where Account_key = 210 and datepart(week, Date) = 51

/*SUM*/
select Territory_key, 
Account_key,
sum(Amount) as sum_amount
from GL
where Account_key = 210
group by Territory_key, Account_key
order by Territory_key, Account_key; 

/*Sub query*/
-- Cara 1
select Year(Date) as 'year',
sum(Amount) as 'amount'
from GL
group by Year(Date)
order by Year(Date);

-- Cara 2
select Year, sum(Amount) as 'Sum_amount'
from
(Select Year(Date) as 'Year', Amount
from GL) as Table1
group by Year
order by Year;

/*Pivot table*/
select [2018], [2019], [2020]
from(
    select year(Date) as Year, Amount
    from GL
) as Table1
pivot(
    sum(Amount) for YEAR in ([2018], [2019], [2020])
) as Table2;

/*Sub query & Pivot*/
select Account_key, [2018], [2019], [2020]
from(
select Account_key, year(Date) as 'Year', Amount
from GL
) as Table1
pivot(sum(Amount) for Year in ([2018], [2019], [2020])) as Table2;

/*VIEW*/
create view MySummary AS
select Account_key, [2018], [2019], [2020]
from(
select Account_key, year(Date) as 'Year', Amount
from GL
) as Table1
pivot(sum(Amount) for Year in ([2018], [2019], [2020])) as Table2;

select *
from MySummary;

/*Join*/
select *
from GL
join COA
on GL.Account_key = COA.Account_key;

select GL.Territory_key, Date, Amount, Country
from GL
full join Territory
on GL.Territory_key = Territory.Territory_key;


/*Join 4 tables*/
select top(10) *
from GL 
join Territory
on GL.Territory_key = Territory.Territory_key
join COA
on GL.Account_key = COA.Account_key
join Calendar
on GL.[Date] = Calendar.[Date];

/*Format Number*/
select Date, 
format(Amount, 'N0') as 'Amount'
from GL;

/*Profit & Loss Statement*/
select top(10)*
from GL

select top(10)*
from COA

/*Create report of profit and loss from '2020-03-01' and '2020-03-30'*/
select GL.Account_key, Report, Class, Account, sum(Amount)
from GL
join COA
on GL.Account_key = COA.Account_key
where Report = 'Profit and Loss' and [Date] between '2020-03-01' and '2020-03-30'
group by GL.Account_key, Report, Class, Account
order by GL.Account_key;

/*Create pivot table report of profit and loss for 2018,2019,2020*/
select Report, 
Class, 
Account, 
FORMAT([2018],'N0') as '2018',
FORMAT([2019],'N0') as '2019',
FORMAT([2020],'N0') as '2020'
from(
select GL.Account_key, Report, Class, Account, year(Date) as 'Year', sum(Amount) as 'Amount'
from GL
join COA
on GL.Account_key = COA.Account_key
where Report = 'Profit and Loss'
group by GL.Account_key, Report, Class, Account, year(Date)
) as Table1
PIVOT(sum(Amount) for Year in ([2018], [2019], [2020])) as Table2;

/*Create pivot table report of profit and loss for 2018,2019,2020 for country France*/
select Country,
Report, 
Class, 
Account, 
FORMAT([2018],'N0') as '2018',
FORMAT([2019],'N0') as '2019',
FORMAT([2020],'N0') as '2020'
from(
select Country, GL.Account_key, Report, Class, Account, year(Date) as 'Year', sum(Amount) as 'Amount'
from GL
join COA
on GL.Account_key = COA.Account_key
join Territory
on GL.Territory_key =  Territory.Territory_key
where Report = 'Profit and Loss' and Country = 'France'
group by Country, GL.Account_key, Report, Class, Account, year(Date)
) as Table1
PIVOT(sum(Amount) for Year in ([2018], [2019], [2020])) as Table2;

/*Balance sheet*/
/*This is wrong, because Balance sheet must cummulative amount*/
select Country, Report, Class, Account, FORMAT([2018], 'N0') as '2018', FORMAT([2019], 'N0') as '2019', FORMAT([2020], 'N0') as '2020'
FROM(
select Country, GL.Account_key, Report, Class, Account, YEAR(Date) as 'Year', SUM(Amount) as 'Amount' 
from GL
join COA
on GL.Account_key = COA.Account_key
join Territory
on GL.Territory_key = Territory.Territory_key
where Report = 'Balance Sheet'
group by Country, GL.Account_key, Report, Class, Account, YEAR(Date)
) as Table1
PIVOT
(SUM(Amount) FOR YEAR in ([2018],[2019],[2020])) as Table2;

/*Cummulative sum. Over doesn't need group by anymore*/
select distinct Date, SUM(Amount) OVER(Order by Date) as 'Cummulative Amount' 
from GL
order by Date;

/*Checking for detail of Cummulative sum*/
select Date, FORMAT(sum(Amount),'N0') as 'Sum Amount'
from GL
group by Date
order by Date;

/*This is wrong because even though the Account_key is different but Cummulative Amount is same, 
so we need Partition*/
SELECT Date, Territory_key, Account_key, SUM(Amount) OVER(ORDER BY Date) as 'Cummulative Amount'
from GL

/*Cummulative amount with Partition*/
SELECT DISTINCT Date, 
Territory_key, 
Account_key, 
SUM(Amount) OVER(PARTITION by Territory_Key, Account_key ORDER BY Date) as 'Cummulative Amount'
from GL
ORDER by Date;

/*Cummulative amount for year*/
SELECT DISTINCT YEAR(Date) AS 'Year', 
Territory_key, 
Account_key, 
SUM(Amount) OVER(PARTITION by Territory_Key, Account_key ORDER BY YEAR(Date)) as 'Cummulative Amount'
from GL
ORDER by YEAR(Date);

/*Balance Sheet*/
/*Partition bisa langsung SubAccount dan ngga perlu Report, dll, 
karena SubAccount merupakan tingkat terbawah,
jadi bagian di atasnya sudah include (Report, Class, dll)*/

select distinct YEAR(Date) AS 'Year', 
Country, 
Report, Class, SubClass, SubClass2, Account, SubAccount, 
SUM(Amount) OVER(PARTITION BY Country, SubAccount ORDER BY YEAR(Date)) as 'Sum Amount'
from GL 
join COA on GL.Account_key = COA.Account_key
join Territory on GL.Territory_key = Territory.Territory_key
Where Report = 'Balance Sheet';

/*Pivot table Balance Sheet*/
SELECT Report, Class, SubClass, SubClass2, Account, SubAccount,
[2018], [2019], [2020]
FROM(
SELECT DISTINCT YEAR(Date) as 'Year', 
Report, Class, SubClass, SubClass2, Account, SubAccount, 
SUM(Amount) OVER(PARTITION BY SubAccount ORDER BY Year(Date)) as 'Amount'
from GL 
join COA on GL.Account_key = COA.Account_key
join Territory on GL.Territory_key = Territory.Territory_key 
WHERE Report = 'Balance Sheet'
) AS Table1
PIVOT (SUM(Amount) for Year in ([2018], [2019], [2020])) as Table2
ORDER BY Class, SubClass, SubClass2, Account, SubAccount;

/*CASE WHEN*/
SELECT
SUM(CASE WHEN YEAR(Date) = 2018 THEN Amount ELSE 0 END) AS '2018',
SUM(CASE WHEN YEAR(Date) = 2019 THEN Amount ELSE 0 END) AS '2019',
SUM(CASE WHEN YEAR(Date) = 2020 THEN Amount ELSE 0 END) AS '2020'
FROM GL;

SELECT Territory_key, Account_key,
SUM(CASE WHEN YEAR(Date) = 2018 THEN Amount ELSE 0 END) AS '2018',
SUM(CASE WHEN YEAR(Date) = 2019 THEN Amount ELSE 0 END) AS '2019',
SUM(CASE WHEN YEAR(Date) = 2020 THEN Amount ELSE 0 END) AS '2020'
FROM GL
GROUP BY Territory_key, Account_key;

/*Amount of Sales*/
-- We need to know what column Sales row is located. See Account_key = 210 & 220
select *
from COA;

-- Amount of Sales
select YEAR(Date) as 'Year',
SUM(Case When SubClass = 'Sales' then Amount else 0 end) as 'Sales'
from GL
join COA
on GL.Account_key = COA.Account_key
group by YEAR(Date)
order by YEAR(Date);

/*Gross Profit*/
-- We need to know what column Sales & Cost of Sales row is located. See Account_key = 210 & 220
select *
from COA;

-- Check the Amount Sales and Cost of sales values. It turns out that Cost of Sales is minus, so just SUM with Sales to get Gross Profit
select distinct COA.*, Amount
from GL
join
COA
on GL.Account_key = COA.Account_key
where SubClass = 'Sales' or SubClass = 'Cost of Sales'
order by Amount;

-- Gross Profit
-- Gross profit = Sales – Cost of Sales 
select YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit'
from GL
join COA
on GL.Account_key = COA.Account_key
group by YEAR(Date)
order by YEAR(Date);

/*Net Profit
Net profit is the net value coming from the profit and loss statement.
Net Profit = Gross Profit - Operating expenses - Interest & Taxes
All of that is on Class where the Report is 'Profit and Loss'
So we can just SUM(Amount) for Report = Profit and Loss
*/
select COA.*, Amount
from GL
join COA
on GL.Account_key = COA.Account_key
where Report = 'Profit and Loss';

-- Net Profit
select YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit',
SUM(case when Report = 'Profit and Loss' then Amount else 0 end) as 'Net_Profit'
from GL
join COA
on GL.Account_key = COA.Account_key
group by YEAR(Date)
order by YEAR(Date);

/*EBITDA, Operating profit, PBIT*/
-- See the query in Profit and Loss statement
select *
from COA
where Report = 'Profit and Loss'

-- EBITDA
-- EBITDA = sales - cost of sales - all the operating expenses (Except depreciation and amortization)
select YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit',
SUM(case when Report = 'Profit and Loss' then Amount else 0 end) as 'Net_Profit',
SUM(case when SubClass = 'Sales' or SubClass = 'Cost of Sales' or SubClass = 'Operating Expenses' then Amount else 0 end) as 'EBITDA'
from GL
join COA
on GL.Account_key = COA.Account_key
group by YEAR(Date)
order by YEAR(Date);

-- Operating profit (EBIT) = Sales - Cost of sales - Operating expenses - Depreciation & Amortization
-- All of the components are in Class Trading account & Operating account in Report Profit & Loss
select YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit',
SUM(case when Report = 'Profit and Loss' then Amount else 0 end) as 'Net_Profit',
SUM(case when SubClass = 'Sales' or SubClass = 'Cost of Sales' or SubClass = 'Operating Expenses' then Amount else 0 end) as 'EBITDA',
SUM(case when Class = 'Trading account' or Class = 'Operating account' then Amount else 0 end) as 'Operating_Profit'
from GL
join COA
on GL.Account_key = COA.Account_key
group by YEAR(Date)
order by YEAR(Date);


-- PBIT (Profit Before Interest & Taxes)
-- PBIT = Sales - all of expenses Except Interest & Tax
-- All of the components are in Class Trading account & Operating account & Non-Operating in Report Profit & Loss
select YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit',
SUM(case when SubClass = 'Sales' or SubClass = 'Cost of Sales' or SubClass = 'Operating Expenses' then Amount else 0 end) as 'EBITDA',
SUM(case when Class = 'Trading account' or Class = 'Operating account' then Amount else 0 end) as 'Operating_Profit',
SUM(case when Class = 'Trading account' or Class = 'Operating account' or Class = 'Non-operating' then Amount else 0 end) as 'PBIT',
SUM(case when Report = 'Profit and Loss' then Amount else 0 end) as 'Net_Profit'
from GL
join COA
on GL.Account_key = COA.Account_key
group by YEAR(Date)
order by YEAR(Date);

/*Gross Profit Margin
GPM = Gross_Profit / Sales*/
-- Cara 1 (Using sub query)
select "Gross_Profit"/"Sales"*100 as GP_Margin
from(
select YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit',
SUM(case when SubClass = 'Sales' or SubClass = 'Cost of Sales' or SubClass = 'Operating Expenses' then Amount else 0 end) as 'EBITDA',
SUM(case when Class = 'Trading account' or Class = 'Operating account' then Amount else 0 end) as 'Operating_Profit',
SUM(case when Class = 'Trading account' or Class = 'Operating account' or Class = 'Non-operating' then Amount else 0 end) as 'PBIT',
SUM(case when Report = 'Profit and Loss' then Amount else 0 end) as 'Net_Profit'
from GL
join COA
on GL.Account_key = COA.Account_key
group by YEAR(Date)
)as Table1

-- Cara 2 (Create view table)
create view PLValues1 as

select YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit',
SUM(case when SubClass = 'Sales' or SubClass = 'Cost of Sales' or SubClass = 'Operating Expenses' then Amount else 0 end) as 'EBITDA',
SUM(case when Class = 'Trading account' or Class = 'Operating account' then Amount else 0 end) as 'Operating_Profit',
SUM(case when Class = 'Trading account' or Class = 'Operating account' or Class = 'Non-operating' then Amount else 0 end) as 'PBIT',
SUM(case when Report = 'Profit and Loss' then Amount else 0 end) as 'Net_Profit'
from GL
join COA
on GL.Account_key = COA.Account_key
group by YEAR(Date);


-- Test PLValues1
select *
from PLValues1;

select "Gross_Profit" / "Sales"*100 as GP_Margin
from PLValues1;

/*Breaking down values by Country*/
-- Cara 1
select Country, YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit',
SUM(case when SubClass = 'Sales' or SubClass = 'Cost of Sales' or SubClass = 'Operating Expenses' then Amount else 0 end) as 'EBITDA',
SUM(case when Class = 'Trading account' or Class = 'Operating account' then Amount else 0 end) as 'Operating_Profit',
SUM(case when Class = 'Trading account' or Class = 'Operating account' or Class = 'Non-operating' then Amount else 0 end) as 'PBIT',
SUM(case when Report = 'Profit and Loss' then Amount else 0 end) as 'Net_Profit'
from GL
join COA on GL.Account_key = COA.Account_key
join Territory on GL.Territory_key = Territory.Territory_key
group by YEAR(Date), Country
order by Country, YEAR(Date);

-- Cara 2 (Create View Table)
-- View table need to delete Order by
create view PLValues as 

select Country, YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit',
SUM(case when SubClass = 'Sales' or SubClass = 'Cost of Sales' or SubClass = 'Operating Expenses' then Amount else 0 end) as 'EBITDA',
SUM(case when Class = 'Trading account' or Class = 'Operating account' then Amount else 0 end) as 'Operating_Profit',
SUM(case when Class = 'Trading account' or Class = 'Operating account' or Class = 'Non-operating' then Amount else 0 end) as 'PBIT',
SUM(case when Report = 'Profit and Loss' then Amount else 0 end) as 'Net_Profit'
from GL
join COA on GL.Account_key = COA.Account_key
join Territory on GL.Territory_key = Territory.Territory_key
group by YEAR(Date), Country;

-- Test PLValues
select *
from PLValues
order by Country, Year;

-- If you already breaking down the country, but still want to see per year
select Year, sum(Sales) as 'Sales'
from PLValues
group by Year;

/*Calculating Ratios*/
-- Gross Profit Margin, Operating Profit Margin, Net Profit Margin
select Year, 
sum(Gross_Profit)/sum(Sales)*100 as 'GP_Margin',
sum(Operating_Profit)/sum(Sales)*100 as 'Operating_Margin',
sum(Net_Profit)/sum(Sales)*100 as 'Net_Margin'
from PLValues
group by Year;

-- Gross Profit Margin according by Country
select Year, sum(Gross_Profit)/sum(Sales)*100 as 'GP_Margin',
select 
from PLValues
where Country = 'France'
group by Year;

/*Calculating Balance Sheet Related Values*/
-- See COA Tables
select *
from COA;

-- Calculate Balance Sheet Related Values
-- Since this is a balance sheet value, we not only just need to apply SUM, 
-- we also need to mention the OVER clause so that the system knows that they have to calculate the rolling sum
select distinct YEAR(Date) as 'Year',
sum(case when Class = 'Assets' then Amount else 0 end) OVER(Order by YEAR(Date)) as 'Assets',
sum(case when SubClass2 = 'Current Assets' then Amount else 0 end) OVER(Order by YEAR(Date)) as 'Current_Assets',
sum(case when SubClass2 = 'Non-Current Assets' then Amount else 0 end) OVER(Order by YEAR(Date)) as 'NonCurrent_Assets',
sum(case when SubClass = 'Liabilities' then Amount else 0 end) OVER(Order by YEAR(Date)) as 'Liabilities',
sum(case when SubClass2 = 'Current Liabilities' then Amount else 0 end) OVER(Order by YEAR(Date)) as 'Current_Liabilities',
sum(case when SubClass2 = 'Long Term Liabilities' then Amount else 0 end) OVER(Order by YEAR(Date)) as 'NonCurrent_Liabilities',
sum(case when SubClass = 'Owners Equity' then Amount else 0 end) OVER(Order by YEAR(Date)) as 'Equity',
sum(case when Class = 'Liabilities and Owners Equity' then Amount else 0 end) OVER(Order by YEAR(Date)) as 'Liabilities_and_Equity',
sum(case when Account = 'Inventory' then Amount else 0 end) OVER(Order by YEAR(Date)) as 'Inventory'

from GL
join COA 
on GL.Account_key = COA.Account_key
order by Year;

-- Calculate Balance Sheet Related Values per Country
-- Because we put the Country, we need to include PARTITION
select distinct Country, YEAR(Date) as 'Year',
sum(case when Class = 'Assets' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Assets',
sum(case when SubClass2 = 'Current Assets' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Current_Assets',
sum(case when SubClass2 = 'Non-Current Assets' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'NonCurrent_Assets',
sum(case when SubClass = 'Liabilities' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Liabilities',
sum(case when SubClass2 = 'Current Liabilities' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Current_Liabilities',
sum(case when SubClass2 = 'Long Term Liabilities' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'NonCurrent_Liabilities',
sum(case when SubClass = 'Owners Equity' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Equity',
sum(case when Class = 'Liabilities and Owners Equity' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Liabilities_and_Equity',
sum(case when Account = 'Inventory' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Inventory'

from GL
join COA 
on GL.Account_key = COA.Account_key
join Territory
on GL.Territory_key = Territory.Territory_key
order by Country, Year;


/*Compiling all key values in one VIEW*/
-- BSValues
CREATE VIEW BSValues as

select distinct Country, YEAR(Date) as 'Year',
sum(case when Class = 'Assets' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Assets',
sum(case when SubClass2 = 'Current Assets' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Current_Assets',
sum(case when SubClass2 = 'Non-Current Assets' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'NonCurrent_Assets',
sum(case when SubClass = 'Liabilities' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Liabilities',
sum(case when SubClass2 = 'Current Liabilities' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Current_Liabilities',
sum(case when SubClass2 = 'Long Term Liabilities' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'NonCurrent_Liabilities',
sum(case when SubClass = 'Owners Equity' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Equity',
sum(case when Class = 'Liabilities and Owners Equity' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Liabilities_and_Equity',
sum(case when Account = 'Inventory' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Inventory'

from GL
join COA 
on GL.Account_key = COA.Account_key
join Territory
on GL.Territory_key = Territory.Territory_key;

-- See BSValues
select *
from BSValues;

-- JOIN Profit & Loss Statement(PLValues) and Balance Sheet (BSValues) Based on Country & Year, 
-- because we don’t have Account Key for this view table
select *
from BSValues
join PLValues on BSValues.Country = PLValues.Country AND BSValues.[Year] = PLValues.[Year]
order by BSValues.Country, BSValues.[Year];


-- CREATE VIEW for PLValues & BSValues
/*We want to CREATE VIEW so we can just call it every time, but it will get error because there is 2 Country and 2 Year. 
So we need to select everything EXCEPT Country and Year from PLValues.*/
CREATE VIEW FinValues as
select BSValues.*, 
PLValues.Sales, PLValues.Gross_Profit, PLValues.EBITDA, PLValues.Operating_Profit, PLValues.PBIT, PLValues.Net_Profit
from BSValues
join PLValues on BSValues.Country = PLValues.Country AND BSValues.[Year] = PLValues.[Year];


select top(10)*
from FinValues;

/*Calculating Ratios*/
select Year,
sum(Gross_Profit) / sum(Sales) *100 as 'GP_Margin',
sum(Operating_Profit) / sum(Sales) *100 as 'Operating_Margin',
sum(Net_Profit) / sum(Sales) *100 as 'Net_Margin',
sum(Sales) / sum(Assets) as 'Asset_Turnover',
sum(PBIT) / sum(Equity + NonCurrent_Liabilities) * 100 as 'ROCE',
sum(Net_Profit) / sum(Equity) * 100 as 'ROE',
sum(Liabilities) / sum(Equity) * 100 as 'Gearing_DER',
sum(Current_Assets) / sum(Current_Liabilities) as 'Current_Ratio',
(sum(Current_Assets) - sum(Inventory)) / sum(Current_Liabilities) as 'Quick_Ratio'

from FinValues
group by Year
order by [Year];


/*Update Cost of Sales & Interest Expense in PLValues*/
create view PLValues as 

select Country, YEAR(Date) as 'Year',
SUM(case when SubClass = 'Sales' then Amount else 0 end) as 'Sales',
SUM(case when Class = 'Trading account' then Amount else 0 end) as 'Gross_Profit',
SUM(case when SubClass = 'Sales' or SubClass = 'Cost of Sales' or SubClass = 'Operating Expenses' then Amount else 0 end) as 'EBITDA',
SUM(case when Class = 'Trading account' or Class = 'Operating account' then Amount else 0 end) as 'Operating_Profit',
SUM(case when Class = 'Trading account' or Class = 'Operating account' or Class = 'Non-operating' then Amount else 0 end) as 'PBIT',
SUM(case when Report = 'Profit and Loss' then Amount else 0 end) as 'Net_Profit',
SUM(case when SubClass = 'Cost of Sales' then Amount else 0 end) as 'Cost_of_Sales',
sum(case when SubClass = 'Interest Expense' then Amount else 0 end) as 'Interest_Expense'

from GL
join COA on GL.Account_key = COA.Account_key
join Territory on GL.Territory_key = Territory.Territory_key
group by YEAR(Date), Country;


-- See Update PLValues
SELECT top(10)* from PLValues


/*Receivables and Payables from BSValues*/
-- BSValues
CREATE VIEW BSValues as

select distinct Country, YEAR(Date) as 'Year',
sum(case when Class = 'Assets' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Assets',
sum(case when SubClass2 = 'Current Assets' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Current_Assets',
sum(case when SubClass2 = 'Non-Current Assets' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'NonCurrent_Assets',
sum(case when SubClass = 'Liabilities' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Liabilities',
sum(case when SubClass2 = 'Current Liabilities' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Current_Liabilities',
sum(case when SubClass2 = 'Long Term Liabilities' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'NonCurrent_Liabilities',
sum(case when SubClass = 'Owners Equity' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Equity',
sum(case when Class = 'Liabilities and Owners Equity' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Liabilities_and_Equity',
sum(case when Account = 'Inventory' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Inventory',
sum(case when SubAccount = 'Trade Receivables' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Trade_Receivables',
sum(case when Account = 'Trade Payables' then Amount else 0 end) OVER(PARTITION by Country Order by YEAR(Date)) as 'Trade_Payables'

from GL
join COA 
on GL.Account_key = COA.Account_key
join Territory
on GL.Territory_key = Territory.Territory_key;


-- See Update BSValues
SELECT top(10)* from BSValues;


/*Updating VIEW FinValues*/
CREATE VIEW FinValues as
select BSValues.*, 
PLValues.Sales, PLValues.Gross_Profit, PLValues.EBITDA, PLValues.Operating_Profit, PLValues.PBIT, PLValues.Net_Profit, PLValues.Cost_of_Sales, PLValues.Interest_Expense
from BSValues
join PLValues on BSValues.Country = PLValues.Country AND BSValues.[Year] = PLValues.[Year];


-- See Update FinValues
select top(10)*
from FinValues;


/*Update Ratio Interest Cover, Inventory | Receivables | Payables Turnover Period*/
select Year,
sum(Gross_Profit) / sum(Sales) *100 as 'GP_Margin',
sum(Operating_Profit) / sum(Sales) *100 as 'Operating_Margin',
sum(Net_Profit) / sum(Sales) *100 as 'Net_Margin',
sum(Sales) / sum(Assets) as 'Asset_Turnover',
sum(PBIT) / sum(Equity + NonCurrent_Liabilities) * 100 as 'ROCE',
sum(Net_Profit) / sum(Equity) * 100 as 'ROE',
sum(Liabilities) / sum(Equity) * 100 as 'Gearing_DER',
sum(Current_Assets) / sum(Current_Liabilities) as 'Current_Ratio',
(sum(Current_Assets) - sum(Inventory)) / sum(Current_Liabilities) as 'Quick_Ratio',
sum(PBIT) / sum(Interest_Expense)*-1 as 'Interest_Cover',
sum(Inventory) / sum(Cost_of_Sales) * -365 as 'Inventory_turnover_period',
sum(Trade_Receivables) / sum(Sales) * 365 as 'Receivables_turnover_period',
sum(Trade_Payables) / sum(Cost_of_Sales) * -365 as 'Payables_turnover_period'

from FinValues
group by Year
order by [Year];

/*Slicing Ratios for Country*/
select Year,
sum(Gross_Profit) / sum(Sales) *100 as 'GP_Margin',
sum(Operating_Profit) / sum(Sales) *100 as 'Operating_Margin',
sum(Net_Profit) / sum(Sales) *100 as 'Net_Margin',
sum(Sales) / sum(Assets) as 'Asset_Turnover',
sum(PBIT) / sum(Equity + NonCurrent_Liabilities) * 100 as 'ROCE',
sum(Net_Profit) / sum(Equity) * 100 as 'ROE',
sum(Liabilities) / sum(Equity) * 100 as 'Gearing_DER',
sum(Current_Assets) / sum(Current_Liabilities) as 'Current_Ratio',
(sum(Current_Assets) - sum(Inventory)) / sum(Current_Liabilities) as 'Quick_Ratio',
sum(PBIT) / sum(Interest_Expense)*-1 as 'Interest_Cover',
sum(Inventory) / sum(Cost_of_Sales) * -365 as 'Inventory_turnover_period',
sum(Trade_Receivables) / sum(Sales) * 365 as 'Receivables_turnover_period',
sum(Trade_Payables) / sum(Cost_of_Sales) * -365 as 'Payables_turnover_period'

from FinValues
where Country = 'Germany'
group by Year
order by [Year];

select *
from GL
join COA
on GL.Account_key = COA.Account_key
order by COA.Account_key;

select top(10)*
from CF;

select *
from CF;


/*Values for CF Statement*/
-- Calculates SUM Amount for the period value (Not Correct)
select Rank, Type, Subtype, YEAR(Date) as 'Year', SUM(Amount) as 'Amount'
from GL
join CF
on GL.Account_key = CF.Account_key
GROUP BY Rank, Type, Subtype, YEAR(Date);

-- Correction to Calculates SUM Amount for CF
select Rank, Type, Subtype, YEAR(Date) as 'Year', 
SUM(CASE WHEN ValueType = 'All_FTP' THEN Amount
    WHEN ValueType = 'All_FTP_CS' THEN Amount *-1
    WHEN ValueType = 'All_FTP_Negative' AND Amount < 0 THEN Amount
    WHEN ValueType = 'All_FTP_Positive' AND Amount > 0 THEN Amount
    WHEN ValueType = 'All_FTP_Negative_CS' AND Amount < 0 THEN Amount *-1
    WHEN ValueType = 'All_FTP_Positive_CS' AND Amount > 0 THEN Amount *-1
    ELSE 0 END
    ) AS Amount
from GL
join CF
on GL.Account_key = CF.Account_key
WHERE ValueType NOT IN('Opening_balance', 'Closing_balance')
GROUP BY Rank, Type, Subtype, YEAR(Date)
ORDER BY Rank;

-- Pivot CF Statement
select Rank, Type, Subtype, [2018], [2019], [2020]
from(
    select Rank, Type, Subtype, YEAR(Date) as 'Year', 
    SUM(CASE WHEN ValueType = 'All_FTP' THEN Amount
        WHEN ValueType = 'All_FTP_CS' THEN Amount *-1
        WHEN ValueType = 'All_FTP_Negative' AND Amount < 0 THEN Amount
        WHEN ValueType = 'All_FTP_Positive' AND Amount > 0 THEN Amount
        WHEN ValueType = 'All_FTP_Negative_CS' AND Amount < 0 THEN Amount *-1
        WHEN ValueType = 'All_FTP_Positive_CS' AND Amount > 0 THEN Amount *-1
        ELSE 0 END
        ) AS Amount
    from GL
    join CF
    on GL.Account_key = CF.Account_key
    WHERE ValueType NOT IN('Opening_balance', 'Closing_balance')
    GROUP BY Rank, Type, Subtype, YEAR(Date)
) as Table1
PIVOT (Sum(Amount) for Year in ([2018],[2019],[2020])) as Table2;


/* Calculating Cash & Cash Equivalents at the end of the Year*/
select DISTINCT Rank, Type, Subtype, YEAR(Date) as 'Year', 
    SUM(Amount) OVER (PARTITION by Rank, Type, Subtype ORDER by YEAR(Date)) AS 'Amount'
from GL
JOIN CF
on GL.Account_key = CF.Account_key
WHERE [Type] = 'Cash and Cash equivalents at the end of the year';

-- PIVOT Table Cash & Cash Equivalents at the end of the Year
 select Rank, Type, Subtype, [2018],[2019],[2020]
FROM(
    select DISTINCT Rank, Type, Subtype, YEAR(Date) as 'Year', 
        SUM(Amount) OVER (PARTITION by Rank, Type, Subtype ORDER by YEAR(Date)) AS 'Amount'
    from GL
    JOIN CF
    on GL.Account_key = CF.Account_key
    WHERE [Type] = 'Cash and Cash equivalents at the end of the year'
) AS Table1
PIVOT(Sum(Amount) for Year in ([2018],[2019],[2020])) AS Table2


/*Calculating Cash & Cash Equivalents at the start of the year*/
 select Rank=1, Type = 'Cash and Cash equivalents at the start of the year', 
 Subtype, Year, LAG(Amount,1,0) OVER(ORDER BY Year ASC) as 'Amount'
FROM(
    select DISTINCT Rank, Type, Subtype, YEAR(Date) as 'Year', 
            SUM(Amount) OVER (PARTITION by Rank, Type, Subtype ORDER by YEAR(Date)) AS 'Amount'
        from GL
        JOIN CF
        on GL.Account_key = CF.Account_key
        WHERE [Type] = 'Cash and Cash equivalents at the end of the year'
) AS Table1;

-- PIVOT Cash & Cash Equivalents at the start of the year
Select Rank, Type, Subtype, [2018], [2019], [2020]
from(
select Rank=1, Type = 'Cash and Cash equivalents at the start of the year', 
 Subtype, Year, LAG(Amount,1,0) OVER(ORDER BY Year ASC) as 'Amount'
FROM(
    select DISTINCT Rank, Type, Subtype, YEAR(Date) as 'Year', 
            SUM(Amount) OVER (PARTITION by Rank, Type, Subtype ORDER by YEAR(Date)) AS 'Amount'
        from GL
        JOIN CF
        on GL.Account_key = CF.Account_key
        WHERE [Type] = 'Cash and Cash equivalents at the end of the year'
) AS Table1
) AS Table2
PIVOT(SUM(Amount) for Year in ([2018], [2019], [2020])) AS Table3;

 
 /*UNION all CF Tables*/
 select Rank, Type, Subtype, [2018], [2019], [2020]
from(
    select Rank, Type, Subtype, YEAR(Date) as 'Year', 
    SUM(CASE WHEN ValueType = 'All_FTP' THEN Amount
        WHEN ValueType = 'All_FTP_CS' THEN Amount *-1
        WHEN ValueType = 'All_FTP_Negative' AND Amount < 0 THEN Amount
        WHEN ValueType = 'All_FTP_Positive' AND Amount > 0 THEN Amount
        WHEN ValueType = 'All_FTP_Negative_CS' AND Amount < 0 THEN Amount *-1
        WHEN ValueType = 'All_FTP_Positive_CS' AND Amount > 0 THEN Amount *-1
        ELSE 0 END
        ) AS Amount
    from GL
    join CF
    on GL.Account_key = CF.Account_key
    WHERE ValueType NOT IN('Opening_balance', 'Closing_balance')
    GROUP BY Rank, Type, Subtype, YEAR(Date)
) as Table1
PIVOT (Sum(Amount) for Year in ([2018],[2019],[2020])) as Table2

UNION
 select Rank, Type, Subtype, [2018],[2019],[2020]
FROM(
    select DISTINCT Rank, Type, Subtype, YEAR(Date) as 'Year', 
        SUM(Amount) OVER (PARTITION by Rank, Type, Subtype ORDER by YEAR(Date)) AS 'Amount'
    from GL
    JOIN CF
    on GL.Account_key = CF.Account_key
    WHERE [Type] = 'Cash and Cash equivalents at the end of the year'
) AS Table1
PIVOT(Sum(Amount) for Year in ([2018],[2019],[2020])) AS Table2

UNION
Select Rank, Type, Subtype, [2018], [2019], [2020]
from(
select Rank=1, Type = 'Cash and Cash equivalents at the start of the year', 
 Subtype, Year, LAG(Amount,1,0) OVER(ORDER BY Year ASC) as 'Amount'
FROM(
    select DISTINCT Rank, Type, Subtype, YEAR(Date) as 'Year', 
            SUM(Amount) OVER (PARTITION by Rank, Type, Subtype ORDER by YEAR(Date)) AS 'Amount'
        from GL
        JOIN CF
        on GL.Account_key = CF.Account_key
        WHERE [Type] = 'Cash and Cash equivalents at the end of the year'
) AS Table1
) AS Table2
PIVOT(SUM(Amount) for Year in ([2018], [2019], [2020])) AS Table3;