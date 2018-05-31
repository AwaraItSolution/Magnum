-- Расчет АВС для ТОВАРов по КОЛИЧЕСТВУ
declare @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,                -- дата окончания периода расчета
        @periodMonth     int = 3,             -- количество месяцев в периоде расчета
        @promoCoeff      float = 0.5,         -- доля акционных продаж
        @minPresentStock float = 0,           -- Минимальный презентационный запас. Получаем из вне ли как-то считаем
        @minStock        float = 1;           -- Минимальный остаток на конец дня
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))
--print @dateFinish
declare @itemTest float       = 51380, 
        @shopTest varchar(50) = 'Алматинский филиал №1';                -- for test

-- Удаляем существующий расчет за заданный период
--delete from dbo.[ABC_Товар] where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish;
     
--/* Тестовая выборка, формирующаяся из вне, по которой расчитываем АВС
;with PromoException([Подгруппа], [Код товара], [Доля акционных продаж]) as
(
 select [Подгруппа], [Код товара], sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
																		  sum([Кол-во продаж розница])) as [Доля акционных продаж]
   from [dbo].[ABC_Data]
  where [Дата] between @dateStart and @dateFinish
--and [Филиал] = @shopTest 
group by [Подгруппа], [Код товара]
 -- оставляем только товары которые имеют акционные продажи и они составляют менее 50% от общих продаж
 having  (sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
    									         sum([Кол-во продаж розница])) > 0) and 
		 (sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
										         sum([Кол-во продаж розница])) < @promoCoeff)
)
, ItemsForABC ([Дата], [Филиал], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница]) as (
-- Товары к расчету АВС, очищенные от акционных продаж и дефицита (как бы). Будет использоваться для подсчета [Доли продаж] для групп BC.
select [Дата], [Филиал], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница с НДС]
  from [dbo].[ABC_Data] abc
 where --[Филиал] = @shopTest and  
       not exists (select 1
                     from PromoException prmExc
                    where abc.Подгруппа = prmExc.[Подгруппа] and abc.[Код товара] = prmExc.[Код товара]
					      -- если товар в аbc имеет номер из группы исключения и код товара равный товару из группы исключения и при этом продажа акционная
                          and abc.[Количество продажи по акции] > 0
				  ) 
) -- Количество. Доля продаж Товара относительно всех продаж
, Items ([Код товара], [Доля продаж]) as (
select [Код товара], cast(SUM([Кол-во продаж розница]) as float)/(select SUM([Кол-во продаж розница]) from ItemsForABC)
  from ItemsForABC
group by [Код товара]
) -- Сумма. Доля продаж Товара относительно всех продаж
, ItemsByAmount ([Код товара], [Доля продаж]) as (
select [Код товара], cast(SUM([Сумма продаж розница]) as float)/(select SUM([Сумма продаж розница]) from ItemsForABC)
  from ItemsForABC
group by [Код товара]
)
, ItemsBC([Код товара], [Доля продаж]) as (
select [Код товара], [Доля продаж]
  from Items
 where [Доля продаж] < 1./(select count(*) from Items)
) -- Товары ГРУППЫ BC c расчитанными долями продаж относительно только группы ВС
, ItemsBC_pr([Код товара], [Доля продаж]) as (
select src.[Код товара], cast(SUM(src.[Кол-во продаж розница]) as float)/(select SUM(src1.[Кол-во продаж розница]) 
                                                                            from ItemsForABC src1 join ItemsBC bc1 
                                                                                  on src1.[Код товара] = bc1.[Код товара])
  from ItemsForABC src join ItemsBC bc on src.[Код товара] = bc.[Код товара]
 where bc.[Код товара] = @itemTest
group by src.[Код товара]
)
, ItemsBCbyAmount([Код товара], [Доля продаж]) as (
select [Код товара], [Доля продаж]
  from ItemsByAmount
 where [Доля продаж] < 1./(select count(*) from ItemsByAmount)
)
, ItemsBC_prByAmount([Код товара], [Доля продаж]) as (
select src.[Код товара], cast(SUM(src.[Сумма продаж розница]) as float)/(select SUM(src1.[Сумма продаж розница]) 
                                                                            from ItemsForABC src1 join ItemsBCbyAmount bc1 
                                                                                  on src1.[Код товара] = bc1.[Код товара])
  from ItemsForABC src join ItemsBCbyAmount bc on src.[Код товара] = bc.[Код товара]
 where bc.[Код товара] = @itemTest
group by src.[Код товара]
) -- Товары ГРУППЫ BC c расчитанными долями продаж относительно только группы ВС
, ItemsB([Код товара], [Доля продаж], [Кол-во товаров], [Категория]) as (
select [Код товара], [Доля продаж], (select count(*) from ItemsBC_pr), 'B'
  from ItemsBC_pr
 where [Доля продаж] >= 1./(select count(*) from ItemsBC_pr)
)
, ItemsBbyAmount([Код товара], [Доля продаж], [Кол-во товаров], [Категория]) as (
select [Код товара], [Доля продаж], (select count(*) from ItemsBC_prByAmount), 'B'
  from ItemsBC_prByAmount
 where [Доля продаж] >= 1./(select count(*) from ItemsBC_prByAmount)
),
ItemsC([Код товара], [Доля продаж], [Кол-во товаров], [Категория]) as (
select [Код товара], [Доля продаж], (select count(*) from ItemsBC_pr), 'C'
  from ItemsBC_pr
 where [Доля продаж] < 1./(select count(*) from ItemsBC_pr)
),
ItemsCbyAmount([Код товара], [Доля продаж], [Кол-во товаров], [Категория]) as (
select [Код товара], [Доля продаж], (select count(*) from ItemsBC_prByAmount), 'C'
  from ItemsBC_prByAmount
 where [Доля продаж] < 1./(select count(*) from ItemsBC_prByAmount)
)
select 'по кол-ву' as [Продажи], [Код товара], [Доля продаж], 1./(select count(*) from Items) as [Кол-во товаров],
		case when [Доля продаж] > 1./(select count(*) from Items) then 'A'
		else 'BC'
		end as [Категория]
  from Items where [Код товара] = @itemTest
UNION ALL
--/*
select 'по сумме' as [Продажи], [Код товара], [Доля продаж], 1./(select count(*) from Items),
		case when [Доля продаж] > 1./(select count(*) from Items) then 'A'
		else 'BC'
		end as [Категория]
  from ItemsByAmount where [Код товара] = @itemTest
--*/
UNION ALL
select 'по кол-ву', [Код товара], [Доля продаж], [Кол-во товаров], [Категория]
  from ItemsB
UNION ALL  
select 'по сумме', [Код товара], [Доля продаж], [Кол-во товаров], [Категория]
  from ItemsBbyAmount
UNION ALL
select 'по кол-ву', [Код товара], [Доля продаж], [Кол-во товаров], [Категория]
  from ItemsC
UNION ALL  
select 'по сумме', [Код товара], [Доля продаж], [Кол-во товаров], [Категория]
  from ItemsCbyAmount  