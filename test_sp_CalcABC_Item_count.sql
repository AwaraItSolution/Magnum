declare @item float = 176739,--117740, 
        @shop nvarchar(50) = 4,--'Алматинский филиал №11',
        @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,
        @periodMonth int = 1;
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))        
/*
exec sp_CalcABC_Item_count  @dateStart   = @dateStart,   -- дата начала периода расчета
							@periodMonth = @periodMonth; -- количество месяцев в периоде расчета
*/
--truncate table dbo.ABC_Товар
select * from dbo.ABC_Товар where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish;
/*
select [Код товара] 
from dbo.ABC_Data 
where [Дата] between @dateStart and @dateFinish
group by [Код товара]
*/