-- Расчет АВС для ТОВАРов по КОЛИЧЕСТВУ
declare @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,                -- дата окончания периода расчета
        @periodMonth     int = 3,             -- количество месяцев в периоде расчета
        @promoCoeff      float = 0.5,         -- доля акционных продаж
        @minPresentStock float = 0,           -- Минимальный презентационный запас. Получаем из вне ли как-то считаем
        @minStock        float = 1;           -- Минимальный остаток на конец дня
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))
--print @dateFinish
declare @itemTest float       = 55015, 
        @shopTest varchar(50) = 'Алматинский филиал №1';                -- for test

-- Удаляем существующий расчет за заданный период
delete from dbo.[ABC_Товар] where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish;
     
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
) -- Товары прогруппированные [Код товара] и взвешенные на сумму общих продаж
, Items ([Код товара], [Доля продаж]) as (
select [Код товара], cast(SUM([Кол-во продаж розница]) as float)/(select SUM([Кол-во продаж розница]) from ItemsForABC)
  from ItemsForABC
group by [Код товара]
) -- Товары ГРУППЫ А 
, ItemsA([Код товара], [Доля продаж]) as (
select [Код товара], [Доля продаж]
  from Items
 where [Доля продаж] >= 1./(select count(*) from Items)
) -- Товары ГРУППЫ BC
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
group by src.[Код товара]
)
, ItemsB([Код товара], [Доля продаж]) as (
select [Код товара], [Доля продаж]
  from ItemsBC_pr
 where [Доля продаж] >= 1./(select count(*) from ItemsBC_pr)
), 
ItemsC([Код товара], [Доля продаж]) as (
select [Код товара], [Доля продаж]
  from ItemsBC_pr
 where [Доля продаж] < 1./(select count(*) from ItemsBC_pr)
)
--select * from PromoException
--select * from Items
--select count(*) from Items   -- Кол-во товаров для расчета АВС == 198
--select SUM([Кол-во продаж розница]) from ItemsForABC where [Код товара] = @itemTest;
--select * from ItemsGroups;
--select * from ItemsA where [Код товара] = @itemTest;
--select * from ItemsBC;
--select * from ItemsBC_pr;
--select * from ItemsB;
--select * from ItemsC
insert into dbo.[ABC_Товар] ([Начало периода], [Окончание периода], [Код товара], [Категория, ед.], [Категория, сумма])
select @dateStart, @dateFinish, [Код товара], 'A', '' from ItemsA
union all
select @dateStart, @dateFinish, [Код товара], 'B', '' from ItemsB
union all
select @dateStart, @dateFinish, [Код товара], 'C', '' from ItemsC;
