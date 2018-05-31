declare @item float = 117740, 
        @shop nvarchar(50)=4,--'Алматинский филиал №11',
        @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,
        @dateStartPrev   datetime,			  -- дата начала периода предшествующего расчету
        @dateFinishPrev  datetime,			  -- дата окончания периода предшествующего расчету
        @periodMonth int = 1;
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))
set @dateStartPrev = dateadd( MONTH, -@periodMonth, @dateStart);
set @dateFinishPrev= dateadd( MONTH, -@periodMonth, @dateFinish);
 print @dateFinish
-- print @dateStartPrev
-- print @dateFinishPrev  

--select top(10) * from dbo.ABC_Data where [Дата] between @dateStart and @dateFinish and [Остаток на конец (ед)] < 1      
--/*
select [Код товара], sum([Кол-во продаж розница]) as [Кол-во продаж розница], sum([Количество продажи по акции]) as [Количество продажи по акции], COUNT(*)
from dbo.ABC_Data
where [Дата] between @dateStart and @dateFinish 
and [Код товара] = @item
and [Код филиала] = @shop
group by [Подгруппа], [Код товара]
--*/
-- Все записи по товару за период
select Дата, [Код филиала], Отдел, Группа, Подгруппа, [Код товара], Товар, [Кол-во продаж розница], [Количество продажи по акции], [Остаток на конец (ед)]
from dbo.ABC_Data
where [Дата] between @dateStart and @dateFinish 
and [Код товара] = @item 
and [Код филиала] = @shop
--and (([Количество продажи по акции] > 0))
--and ([Кол-во продаж розница] <> [Количество продажи по акции])

--/*
select t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара], t_now.[Кол-во продаж розница], t_now.[Количество продажи по акции]
  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
		-- проверка того, что предыдущий день, как и текущий без продаж
		on (t_now.[Дата] = dateadd(day,-1,t_yest.[Дата])) and (t_now.[Код филиала] = t_yest.[Код филиала]) and
		   (t_now.[Отдел] = t_yest.[Отдел]) and (t_now.[Группа] = t_yest.[Группа]) and
		   (t_now.[Подгруппа] = t_yest.[Подгруппа]) and (t_now.[Код товара] = t_yest.[Код товара]) and 
		
		   (t_now.[Кол-во продаж розница] = isnull(t_yest.[Кол-во продаж розница],0))
		-- проверка того, что следующий день, как и текущий без продаж
        join [dbo].[ABC_Data] as t_tom
		on (t_now.[Дата] = dateadd(day,1,t_tom.[Дата])) and (t_now.[Код филиала] = t_tom.[Код филиала]) and
		   (t_now.[Отдел] = t_tom.[Отдел]) and (t_now.[Группа] = t_tom.[Группа]) and
		   (t_now.[Подгруппа] = t_tom.[Подгруппа]) and (t_now.[Код товара] = t_tom.[Код товара]) and 

		   (t_now.[Кол-во продаж розница] = isnull(t_tom.[Кол-во продаж розница],0))
where t_now.[Дата] between @dateStart and @dateFinish and
	   t_now.[Кол-во продаж розница] = 0
and t_now.[Код товара] = @item 
and t_now.[Код филиала] = @shop
order by t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара]
--*/