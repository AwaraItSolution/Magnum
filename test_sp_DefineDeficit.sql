declare @item float = 176739,--117740, 
        @shop nvarchar(50) = 4,--'Алматинский филиал №11',
        @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,
        @periodMonth int = 1;
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))        
/*
exec sp_DefineDeficit @dateStart   = @dateStart,   -- дата начала периода расчета
	                  @periodMonth = @periodMonth; -- количество месяцев в периоде расчета
*/
select [Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Остаток на конец (ед)], [Сумма продаж розница с НДС], 
		PromoFail_count, PromoFail_amount, Deficit_count
  from [dbo].[ABC_Data] t_now
 where t_now.[Дата] between @dateStart and @dateFinish 
--and Deficit_count <> 0
and t_now.[Код товара] = @item
and t_now.[Код филиала] = @shop
order by t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара];
/*
with AvgSales([Подгруппа],[Код товара],[Продаж в день, ед.],[Продаж в день, сумма]) as (
	select [Подгруппа], [Код товара], 
		   avg([Кол-во продаж розница])      as [Продаж в день, ед.],
		   avg([Сумма продаж розница с НДС]) as [Продаж в день, сумма]
	  from [dbo].[ABC_Data]
	where [Дата] between @dateStart and @dateFinish and [Дефицит] = 0

and [Код товара] = @item
and [Код филиала] = @shop

	group by [Подгруппа], [Код товара]
)
--select * from AvgSales;
select t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара], [Кол-во продаж розница], [Сумма продаж розница с НДС]
  from [dbo].[ABC_Data] t_now join AvgSales avSl 
		on t_now.[Подгруппа] = avSl.[Подгруппа] and t_now.[Код товара] = avSl.[Код товара]
 where t_now.[Дата] between @dateStart and @dateFinish and [Дефицит] = 0 and 
		t_now.[Остаток на конец (ед)] < 1 and (t_now.[Кол-во продаж розница] < avSl.[Продаж в день, ед.] * 0.4) 
and t_now.[Код товара] = @item
and t_now.[Код филиала] = @shop
order by t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара]
*/