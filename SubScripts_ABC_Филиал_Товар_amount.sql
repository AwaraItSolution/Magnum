-- Расчет АВС для Филиалов по сумме
declare @dateStart   datetime = '2018-03-01', -- дата начала периода расчета
        @dateFinish  datetime,                -- дата окончания периода расчета
        @periodMonth     int = 1,             -- количество месяцев в периоде расчета
        @promoCoeff      float = 0.5,         -- доля акционных продаж
        @minPresentStock float = 0,           -- Минимальный презентационный запас. Получаем из вне ли как-то считаем
        @minStock        float = 1;           -- Минимальный остаток на конец дня
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))

declare @itemTest float       = 54993, 
        @shopTest varchar(50) = 'Алматинский филиал №1';                -- for test

-- Удаляем существующий расчет за заданный период
update dbo.[ABC_Филиал_Товар] set [Категория, сумма] = ''
 where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish;
     
--/* Тестовая выборка, формирующаяся из вне, по которой расчитываем АВС
;with PromoException([Подгруппа], [Код товара], [Доля акционных продаж]) as
(
 select [Подгруппа], [Код товара], sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
																		  sum([Кол-во продаж розница])) as [Доля акционных продаж]
   from [dbo].[ABC_Data]
  where [Дата] between @dateStart and @dateFinish
--and [Код филиала] = @shopTest
group by [Подгруппа], [Код товара]
 -- оставляем только товары которые имеют акционные продажи и они составляют менее 50% от общих продаж
 having  (sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
    									         sum([Кол-во продаж розница])) > 0) and 
		 (sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
										         sum([Кол-во продаж розница])) < @promoCoeff)
)
, ItemsForABC ([Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница]) as (
-- Товары к расчету АВС, очищенные от акционных продаж и дефицита (как бы). Будет использоваться для подсчета [Доли продаж] для групп BC.
select [Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница с НДС]
  from [dbo].[ABC_Data] abc
 where --[Код филиала] = @shopTest and  
       not exists (select 1
                     from PromoException prmExc
                    where abc.Подгруппа = prmExc.[Подгруппа] and abc.[Код товара] = prmExc.[Код товара]
					      -- если товар в аbc имеет номер из группы исключения и код товара равный товару из группы исключения и при этом продажа акционная
                          and abc.[Количество продажи по акции] > 0
				  ) 
) -- Товары прогруппированные [Код товара] и взвешенные на сумму общих продаж [Доля продаж]
, Items ([Код филиала], [Код товара], [Доля продаж]) as (
select anchor.[Код филиала], anchor.[Код товара], anchor.[Сумма продаж розница]/ss.shopSum
from (select abc.[Код филиала], abc.[Код товара], cast(SUM(abc.[Сумма продаж розница]) as float) as [Сумма продаж розница]
	    from ItemsForABC abc
	   group by abc.[Код филиала], abc.[Код товара]
	 ) anchor join 
	 (select subSums.[Код филиала], SUM(subSums.[Сумма продаж розница]) as shopSum
	    from ItemsForABC subSums
	   group by subSums.[Код филиала]
	 ) ss on anchor.[Код филиала] = ss.[Код филиала]
)-- Сопоставляем суммарной Продаже каждого товара по магазину СУММУ всех продаж помагазину
, ItemsPartsSubCount([Код филиала], [Код товара], [Доля продаж], [Кол-во товаров]) as (
select ip.[Код филиала], ip.[Код товара], ip.[Доля продаж], ip1.itm_cnt
  from Items ip join
		(select [Код филиала], count(*) as itm_cnt
		   from Items
		 group by [Код филиала]) ip1 on ip.[Код филиала] = ip1.[Код филиала]
)
-- Товары ГРУППЫ А 
, ItemsA([Код филиала], [Код товара], [Доля продаж]) as (
select [Код филиала], [Код товара], [Доля продаж]
  from ItemsPartsSubCount
 where [Доля продаж] >= 1./[Кол-во товаров]
) -- Товары ГРУППЫ BC
, ItemsBC([Код филиала], [Код товара], [Доля продаж]) as (
select [Код филиала], [Код товара], [Доля продаж]
  from ItemsPartsSubCount
 where [Доля продаж] < 1./[Кол-во товаров]
) -- Товары ГРУППЫ BC c расчитанными долями продаж относительно только группы ВС
, ItemsBC_pr([Код филиала], [Код товара], [Доля продаж], [Кол-во товаров]) as (
select anchor.[Код филиала], anchor.[Код товара], anchor.[Сумма продаж розница]/iif(ss.shopSum=0,1,ss.shopSum) as [Доля продаж], 
		it.shopItems
from(-- сумма продаж КАЖДОГО товара из группы "ВС" в каждом магазине
     select src.[Код филиала], src.[Код товара], cast(SUM(src.[Сумма продаж розница]) as float) as [Сумма продаж розница]
	   from ItemsForABC src join ItemsBC bc on (src.[Код филиала] = bc.[Код филиала]) and (src.[Код товара] = bc.[Код товара])
      group by src.[Код филиала], src.[Код товара]
	 ) anchor join 
	 (-- сумма продаж ВСЕХ товаров группы "ВС" в каждом магазине
	  select subSums.[Код филиала], SUM(subSums.[Сумма продаж розница]) as shopSum
		from ItemsForABC as subSums join ItemsBC bc1 on (subSums.[Код филиала] = bc1.[Код филиала]) and (subSums.[Код товара] = bc1.[Код товара])
	   group by subSums.[Код филиала]
	 ) ss on anchor.[Код филиала] = ss.[Код филиала] join
	 (-- кол-во товаров группы "ВС" в каждом магазине
	  select bc2.[Код филиала], count(*) as shopItems
		from ItemsBC bc2 
	  group by bc2.[Код филиала] 
	 ) it on anchor.[Код филиала] = it.[Код филиала]
)
, ItemsB([Код филиала], [Код товара], [Доля продаж]) as (
select [Код филиала], [Код товара], [Доля продаж]
  from ItemsBC_pr 
 where [Доля продаж] >= 1./[Кол-во товаров]
)
, ItemsC([Код филиала], [Код товара], [Доля продаж]) as (
select [Код филиала], [Код товара], [Доля продаж]
  from ItemsBC_pr 
 where [Доля продаж] < 1./[Кол-во товаров]
)
, ItemsABCbyAmount([Начало периода],[Окончание периода],[Код филиала],[Код товара],[Категория, сумма]) as (
select @dateStart, @dateFinish, [Код филиала], [Код товара], 0 from ItemsA
union all
select @dateStart, @dateFinish, [Код филиала], [Код товара], 1 from ItemsB
union all
select @dateStart, @dateFinish, [Код филиала], [Код товара], 2 from ItemsC
)
merge dbo.[ABC_Филиал_Товар] t
using ItemsABCbyAmount s on t.[Начало периода]= s.[Начало периода] and t.[Окончание периода] = s.[Окончание периода] and 
						 	t.[Код филиала] = s.[Код филиала] and t.[Код товара] = s.[Код товара]
when matched
    then update set [Категория, сумма] = s.[Категория, сумма]
when not matched
    then insert ([Начало периода],[Окончание периода],[Код филиала],[Код товара],[Категория, ед.],[Категория, сумма]) 
		 values (s.[Начало периода], s.[Окончание периода], s.[Код филиала], s.[Код товара],'',s.[Категория, сумма])
output $action as [action], isnull(Inserted.[Код филиала], Deleted.[Код филиала]) as [Код филиала], 
							isnull(Inserted.[Код товара], Deleted.[Код товара]) as [Код товара], 
							isnull(Inserted.[Категория, ед.], Deleted.[Категория, ед.]) as [Категория, ед.],
							isnull(Inserted.[Категория, сумма], Deleted.[Категория, сумма]) as [Категория, сумма];
--select * from ItemsForABC
--select * from Items
--select * from ItemsPartsSubCount
--select * from PromoException
--select count(*) from Items   -- Кол-во товаров для расчета АВС == 198
--select SUM([Кол-во продаж розница]) from ItemsForABC where [Код товара] = @itemTest;
--select * from ItemsA where [Код товара] = @itemTest;
--select * from ItemsBC;
--select * from ItemsBC_pr;
--select * from ItemsB;
--select * from ItemsC
--order by [Код филиала], [Код товара]							