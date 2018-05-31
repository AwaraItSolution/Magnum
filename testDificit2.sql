declare @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,                -- дата окончания периода расчета
        @dateStartPrev   datetime,			  -- дата начала периода предшествующего расчету
        @dateFinishPrev  datetime,			  -- дата окончания периода предшествующего расчету
        @periodMonth     int = 1,             -- количество месяцев в периоде расчета
        @promoCoeff      float = 0.5,         -- доля акционных продаж
        @minPresentStock float = 0,           -- Минимальный презентационный запас. Получаем из вне ли как-то считаем
        @minStock        float = 1;           -- Минимальный остаток на конец дня
set @dateFinish = dateadd(second, -1, dateadd( MONTH, @periodMonth, @dateStart))
set @dateStartPrev = dateadd( MONTH, -@periodMonth, @dateStart);
set @dateFinishPrev= dateadd( MONTH, -@periodMonth, @dateFinish);
-- print @dateFinish
-- print @dateStartPrev
-- print @dateFinishPrev

/* Первый вариант расчета дефицитных дней по остаткам
if (@minStock <= @minPresentStock)
  set @maxOfMinStock = @minPresentStock + 0.000001
else
  set @maxOfMinStock = @minStock;
-- Выделяем строки, в которых [Остаток на конец (ед)] < 1 или <= @minPresentStock минимального презентационного запаса, чтобы потом исключить их из списка товаров
select [Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара]--, count(*) as [Дефицит по остатку]
  from [dbo].[ABC_Data]
 where [Остаток на конец (ед)] < @maxOfMinStock
*/

/*
-- Определение вложенных дней отсутствующих продаж. Проверка количества проданного, как (розница + акции)
select t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара]--, t_now.[Кол-во продаж розница], t_now.[Количество продажи по акции]
  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
		-- проверка того, что предыдущий день, как и текущий без продаж
		on (t_now.[Код товара] = t_yest.[Код товара]) and (t_now.[Дата] = dateadd(day,-1,t_yest.[Дата])
		   ) and 
		   ((t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = t_yest.[Кол-во продаж розница]+t_yest.[Количество продажи по акции]) and 
		    (t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = 0)) 
		    and t_now.[Код филиала] = t_yest.[Код филиала]
		-- проверка того, что следующий день, как и текущий без продаж
        join [dbo].[ABC_Data] as t_tom
		on (t_now.[Код товара] = t_tom.[Код товара]) and (t_now.[Дата] = dateadd(day,1,t_tom.[Дата])
		   ) and 
		   ((t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = t_tom.[Кол-во продаж розница]+t_tom.[Количество продажи по акции]) and 
		    (t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = 0))
		   and t_now.[Код филиала] = t_tom.[Код филиала]
where t_now.[Дата] between @dateStart and @dateFinish
--and t_now.[Код товара] = '10721' and t_now.[Код филиала] = 'Алматинский филиал №1'
--order by t_now.[Дата], t_now.[Код филиала], t_now.[Код товара]
*/
/*
select [Код товара], sum([Кол-во продаж розница]), count(*), AVG([Кол-во продаж розница]) as [Средняя продажа] --deficDays.*
  from [dbo].[ABC_Data] deficDays
 where ([Дата] between @dateStartPrev and @dateFinishPrev) 
   and deficDays.[Код товара] = 137113				-- for test
   and deficDays.[Код филиала] = 'Алматинский филиал №1'	-- for test
group by [Код товара]
*/
/*
-- Общая продажа товаров за период
select [Код товара],sum([Кол-во продаж розница] + [Количество продажи по акции]) as [Общее кол-во продаж]
--				   ,count(*) as [Кол-во дней продаж]
  from [dbo].[ABC_Data]
 where [Дата] between @dateStart and @dateFinish
group by [Код товара]
*/
--II. Определение дефицита
--II.1 Сначала определяем товары, у которых "Остаток на конец дня <= Минимального презентацтонного запаса ИЛИ Остаток на конец дня < 1"
-- Второй вариант расчета дефицитных дней по остаткам пока без расчета 40% от средних продаж
--/*
select deficDays.[Дата], deficDays.[Код филиала], deficDays.[Отдел], deficDays.[Группа], deficDays.[Подгруппа], deficDays.[Код товара], 
		deficDays.[Кол-во продаж розница], deficDays.[Остаток на конец (ед)] --count(*) as [Дефицит по остатку]
  from [dbo].[ABC_Data] deficDays
 where (deficDays.[Дата] between @dateStart and @dateFinish) and
       ((([Остаток на конец (ед)] <= @minPresentStock) or 
         ([Остаток на конец (ед)] < 1 and (1=1))
        ) 
     -- /*
       or
        exists( select 1--t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара]
				  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
						-- проверка того, что предыдущий день, как и текущий без продаж
						on (t_now.[Дата] = dateadd(day,-1,t_yest.[Дата])) and (t_now.[Код филиала] = t_yest.[Код филиала]) and
						   (t_now.[Отдел] = t_yest.[Отдел]) and (t_now.[Группа] = t_yest.[Группа]) and
						   (t_now.[Подгруппа] = t_yest.[Подгруппа]) and (t_now.[Код товара] = t_yest.[Код товара]) and 
						   
						   (t_now.[Кол-во продаж розница] = t_yest.[Кол-во продаж розница]) and 
						   (t_now.[Кол-во продаж розница] = 0)
						-- проверка того, что следующий день, как и текущий без продаж
						join [dbo].[ABC_Data] as t_tom
						on (t_now.[Дата] = dateadd(day,1,t_tom.[Дата])) and (t_now.[Код филиала] = t_tom.[Код филиала]) and
						   (t_now.[Отдел] = t_tom.[Отдел]) and (t_now.[Группа] = t_tom.[Группа]) and
						   (t_now.[Подгруппа] = t_tom.[Подгруппа]) and (t_now.[Код товара] = t_tom.[Код товара]) and 

						   (t_now.[Кол-во продаж розница] = t_tom.[Кол-во продаж розница]) and 
						   (t_now.[Кол-во продаж розница] = 0)
				 where 	deficDays.[Дата] = t_now.[Дата] and deficDays.[Код филиала] = t_now.[Код филиала] and deficDays.[Отдел] = t_now.[Отдел] and deficDays.[Группа] = t_now.[Группа] and 
						deficDays.[Подгруппа] = t_now.[Подгруппа] and deficDays.[Товар] = t_now.[Товар]
						-- ограничиваем предыдущий и последующий дни текущим периодом поиска дефицита
						and t_yest.[Дата] between @dateStart and @dateFinish 
						and t_tom.[Дата]  between @dateStart and @dateFinish 
                )
       )
               -- */
   and deficDays.[Код товара] = 117740				-- for test
   and deficDays.[Код филиала] = 4--'Алматинский филиал №11'-- for test
order by deficDays.[Дата], deficDays.[Код филиала], deficDays.[Отдел], deficDays.[Группа], deficDays.[Подгруппа], deficDays.[Код товара]
--*/

-- Ищем дефицитные строки в предыдущем периоде
/*
;with DeficitDays ([Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара]) as 
(
select [Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара]
  from [dbo].[ABC_Data] deficDays
 where ([Дата] between @dateStartPrev and @dateFinishPrev) and
        (([Остаток на конец (ед)] <= @minPresentStock) or 
         ([Остаток на конец (ед)] < @minStock) or
         exists(select t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара]
				  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
				  -- проверка того, что предыдущий день, как и текущий без продаж
						on (t_now.[Код товара] = t_yest.[Код товара]) and (t_now.[Дата] = dateadd(day,-1,t_yest.[Дата])
						   ) and 
						   ((t_now.[Кол-во продаж розница] = t_yest.[Кол-во продаж розница]) and 
							(t_now.[Кол-во продаж розница] = 0)) 
							and t_now.[Код филиала] = t_yest.[Код филиала]
						-- проверка того, что следующий день, как и текущий без продаж
						join [dbo].[ABC_Data] as t_tom
						on (t_now.[Код товара] = t_tom.[Код товара]) and (t_now.[Дата] = dateadd(day,1,t_tom.[Дата])
						   ) and 
						   ((t_now.[Кол-во продаж розница] = t_tom.[Кол-во продаж розница]) and 
							(t_now.[Кол-во продаж розница] = 0))
						   and t_now.[Код филиала] = t_tom.[Код филиала]
				 where 	deficDays.[Дата] = t_now.[Дата] and deficDays.[Код филиала] = t_now.[Код филиала] and deficDays.[Отдел] = t_now.[Отдел] and deficDays.[Группа] = t_now.[Группа] and 
						deficDays.[Подгруппа] = t_now.[Подгруппа] and deficDays.[Товар] = t_now.[Товар]
						-- ограничиваем предыдущий и последующий дни текущим периодом поиска дефицита
						and t_yest.[Дата] between @dateStartPrev and @dateFinishPrev
						and t_tom.[Дата]  between @dateStartPrev and @dateFinishPrev
                   )
        )
--   and deficDays.[Код товара] = 137113				-- for test
--   and deficDays.[Код филиала] = 'Алматинский филиал №1'	-- for test
)
select abc.[Код товара], avg(abc.[Кол-во продаж розница]) as [Средняя продажа, ед.] --abc.* --
  from [dbo].[ABC_Data] abc 
 where (abc.[Дата] between @dateStartPrev and @dateFinishPrev ) and
		not exists(select 1 
		             from DeficitDays defDays
		            where abc.[Дата] = defDays.[Дата] and abc.[Код филиала] = defDays.[Код филиала] and abc.[Отдел] = defDays.[Отдел] and abc.[Группа] = defDays.[Группа] and 
		                  abc.[Подгруппа] = defDays.[Подгруппа] and abc.[Код товара] = defDays.[Код товара]
                  )
--and abc.[Код товара] = 137113                -- for test
--and abc.[Код филиала] = 'Алматинский филиал №1'   -- for test
group by abc.[Код товара]
*/