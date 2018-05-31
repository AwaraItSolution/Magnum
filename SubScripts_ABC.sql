-- подсчет среднедневной продажи. 
/*
[Филиал] - магазин. Требуется найти 
    Для каждого товара в рамках периода и филиала определяются средние продажи в день исходя из периода расчета АВС, 
    Находим список товаров по дням, у которых остаток за эти дни < 1 и продажа за этот день меньше средней продажи за день в обрабатываемом периоде, 
    Находим список товаров по дням, у которых нет продаж. При этом продажи этого же товара за предыдущий и последующий день тоже отсутствуют 
    Выбираем все товары по дням для расчета АВС, за исключением тех, которые присутствуют в первом и во втором наборах, 
*/
declare @dateStart   datetime = '2018-02-01', -- дата начала периода расчета
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

declare @itemTest float       = 117740, 
        @shopTest varchar(50) = 'Алматинский филиал №11';                -- for test

--I.
/* Акционные продажи всех SKU каждой подгруппы в ОДНОМ регионе, ВНЕ зависимости от кластера, у которых 0 < %продаж < 0.5
   Выделяем эти товары, чтобы затем исключить их из расчета АВС. А именно оставляем товары у которых отношение суммы продаж по акции к сумме общих продаж < 0.5
   [Кол-во продаж розница] включает в себя продажи по акции
*/
/*
with PromoException([Подгруппа], [Код товара], [Доля акционных продаж]) as
(
 select [Подгруппа], [Код товара], sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
																		  sum([Кол-во продаж розница])) as [Доля акционных продаж]
   from [dbo].[ABC_Data]
  where [Дата] between @dateStart and @dateFinish
group by [Подгруппа], [Код товара]
 -- оставляем только товары которые имеют акционные продажи и они составляют менее 50% от общих продаж
 having  (sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
    									         sum([Кол-во продаж розница])) > 0) and 
		 (sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
										         sum([Кол-во продаж розница])) < @promoCoeff)
)
-- Товары к расчету АВС по анализу акционных продаж
select [Дата], [Филиал], [Отдел], [Группа], [Подгруппа], [Код товара]
  from [dbo].[ABC_Data] abc
 where not exists (select 1
                     from PromoException prmExc
                    where abc.Подгруппа = prmExc.[Подгруппа] and abc.[Код товара] = prmExc.[Код товара]
					      -- если товар в аbc имеет номер из группы исключения и код товара равный товару из группы исключения и при этом продажа акционная
                          and abc.[Количество продажи по акции] > 0
				  ) 
*/
--II. Определение дефицита
--II.1 Сначала определяем товары, у которых "Остаток на конец дня <= Минимального презентацтонного запаса ИЛИ Остаток на конец дня < 1"
-- Второй вариант расчета дефицитных дней по остаткам пока без расчета 40% от средних продаж
--/*
set @minPresentStock = null;
select [Дата], [Филиал], [Отдел], [Группа], [Подгруппа], [Код товара]
  from [dbo].[ABC_Data] deficDays
 where ([Дата] between @dateStart and @dateFinish) and
        (([Остаток на конец (ед)] <= isnull(@minPresentStock, -1000000)) or 
         ([Остаток на конец (ед)] < @minStock and (1=1)
         ) or exists(select t_now.[Дата], t_now.[Филиал], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара]
					  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
							-- проверка того, что предыдущий день, как и текущий без продаж
							on (t_now.[Код товара] = t_yest.[Код товара]) and (t_now.[Дата] = dateadd(day,-1,t_yest.[Дата])
							   ) and 
							   ((t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = t_yest.[Кол-во продаж розница]+t_yest.[Количество продажи по акции]) and 
								(t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = 0)) 
								and t_now.[Филиал] = t_yest.[Филиал]
							-- проверка того, что следующий день, как и текущий без продаж
							join [dbo].[ABC_Data] as t_tom
							on (t_now.[Код товара] = t_tom.[Код товара]) and (t_now.[Дата] = dateadd(day,1,t_tom.[Дата])
							   ) and 
							   ((t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = t_tom.[Кол-во продаж розница]+t_tom.[Количество продажи по акции]) and 
								(t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = 0))
							   and t_now.[Филиал] = t_tom.[Филиал]
					 where 	deficDays.[Дата] = t_now.[Дата] and deficDays.[Филиал] = t_now.[Филиал] and deficDays.[Отдел] = t_now.[Отдел] and deficDays.[Группа] = t_now.[Группа] and 
							deficDays.[Подгруппа] = t_now.[Подгруппа] and deficDays.[Товар] = t_now.[Товар]
							-- ограничиваем предыдущий и последующий дни текущим периодом поиска дефицита
							and t_yest.[Дата] between @dateStart and @dateFinish 
							and t_tom.[Дата]  between @dateStart and @dateFinish 
                    )
        )
   and deficDays.[Код товара] = @itemTest -- for test
   and deficDays.[Филиал] = @shopTest     -- for test
order by [Дата]                           -- for test
--*/

-- II.2 Расчет средних продаж ТОЛЬКО по коду товара по ВСЕМ объектам. Расчет осуществляется по 

-- Ищем дефицитные строки в /предыдущем/  периоде
--/*
;with DeficitDays ([Дата], [Филиал], [Отдел], [Группа], [Подгруппа], [Код товара]) as 
(
select [Дата], [Филиал], [Отдел], [Группа], [Подгруппа], [Код товара]
  from [dbo].[ABC_Data] deficDays
 where ([Дата] between @dateStartPrev and @dateFinishPrev) and
        (([Остаток на конец (ед)] <= isnull(@minPresentStock, -1000000) or 
         ([Остаток на конец (ед)] < @minStock)) or
         exists(select t_now.[Дата], t_now.[Филиал], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара]
				  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
				  -- проверка того, что предыдущий день, как и текущий без продаж
						on (t_now.[Код товара] = t_yest.[Код товара]) and (t_now.[Дата] = dateadd(day,-1,t_yest.[Дата])
						   ) and 
						   ((t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = t_yest.[Кол-во продаж розница]+t_yest.[Количество продажи по акции]) and 
							(t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = 0)) 
							and t_now.[Филиал] = t_yest.[Филиал]
						-- проверка того, что следующий день, как и текущий без продаж
						join [dbo].[ABC_Data] as t_tom
						on (t_now.[Код товара] = t_tom.[Код товара]) and (t_now.[Дата] = dateadd(day,1,t_tom.[Дата])
						   ) and 
						   ((t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = t_tom.[Кол-во продаж розница]+t_tom.[Количество продажи по акции]) and 
							(t_now.[Кол-во продаж розница]+t_now.[Количество продажи по акции] = 0))
						   and t_now.[Филиал] = t_tom.[Филиал]
				 where 	deficDays.[Дата] = t_now.[Дата] and deficDays.[Филиал] = t_now.[Филиал] and deficDays.[Отдел] = t_now.[Отдел] and deficDays.[Группа] = t_now.[Группа] and 
						deficDays.[Подгруппа] = t_now.[Подгруппа] and deficDays.[Товар] = t_now.[Товар]
						-- ограничиваем предыдущий и последующий дни текущим периодом поиска дефицита
						and t_yest.[Дата] between @dateStartPrev and @dateFinishPrev
						and t_tom.[Дата]  between @dateStartPrev and @dateFinishPrev
                   )
        )
   and deficDays.[Код товара] = @itemTest  -- for test
   and deficDays.[Филиал] = @shopTest      -- for test
)
select abc.* --abc.[Код товара], avg(abc.[Кол-во продаж розница]) as [Средняя продажа, ед.] 
  from [dbo].[ABC_Data] abc 
 where (abc.[Дата] between @dateStartPrev and @dateFinishPrev ) and
		not exists(select 1 
		             from DeficitDays defDays
		            where abc.[Дата] = defDays.[Дата] and abc.[Филиал] = defDays.[Филиал] and abc.[Отдел] = defDays.[Отдел] and abc.[Группа] = defDays.[Группа] and 
		                  abc.[Подгруппа] = defDays.[Подгруппа] and abc.[Код товара] = defDays.[Код товара]
                  )
and abc.[Код товара] = @itemTest  -- for test
and abc.[Филиал] = @shopTest      -- for test
--group by abc.[Код товара]
--*/