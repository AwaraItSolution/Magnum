-- Расчет АВС для Филиалов по количеству
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
--delete from dbo.[ABC_Филиал_Товар] where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish;
     
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
, ItemsForABC ([Дата], [Филиал], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница]) as (
-- Товары к расчету АВС, очищенные от акционных продаж и дефицита (как бы). Будет использоваться для подсчета [Доли продаж] для групп BC.
select [Дата], [Филиал], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница]
  from [dbo].[ABC_Data] abc
 where --[Филиал] = @shopTest and  
       not exists (select 1
                     from PromoException prmExc
                    where abc.Подгруппа = prmExc.[Подгруппа] and abc.[Код товара] = prmExc.[Код товара]
					      -- если товар в аbc имеет номер из группы исключения и код товара равный товару из группы исключения и при этом продажа акционная
                          and abc.[Количество продажи по акции] > 0
				  ) 
) -- Товары прогруппированные [Код товара] и взвешенные на сумму общих продаж [Доля продаж]
, Items ([Филиал], [Код товара], [Доля продаж]) as (
select anchor.[Филиал], anchor.[Код товара], anchor.[Кол-во продаж розница]/ss.shopSum
from (select abc.[Филиал], abc.[Код товара], cast(SUM(abc.[Кол-во продаж розница]) as float) as [Кол-во продаж розница]
	    from ItemsForABC abc
	   group by abc.[Филиал], abc.[Код товара]
	 ) anchor join 
	 (select subSums.[Филиал], SUM(subSums.[Кол-во продаж розница]) as shopSum
	    from ItemsForABC subSums
	   group by subSums.[Филиал]
	 ) ss on anchor.[Филиал] = ss.[Филиал]
)-- Сопоставляем суммарной Продаже каждого товара по магазину СУММУ всех продаж помагазину
, ItemsPartsSubCount([Филиал], [Код товара], [Доля продаж], [Кол-во товаров]) as (
select ip.[Филиал], ip.[Код товара], ip.[Доля продаж], ip1.itm_cnt
  from Items ip join
		(select [Филиал], count(*) as itm_cnt
		   from Items
		 group by [Филиал]) ip1 on ip.[Филиал] = ip1.[Филиал]
)
-- Товары ГРУППЫ А 
, ItemsA([Филиал], [Код товара], [Доля продаж]) as (
select [Филиал], [Код товара], [Доля продаж]
  from ItemsPartsSubCount
 where [Доля продаж] >= 1./[Кол-во товаров]
) -- Товары ГРУППЫ BC
, ItemsBC([Филиал], [Код товара], [Доля продаж]) as (
select [Филиал], [Код товара], [Доля продаж]
  from ItemsPartsSubCount
 where [Доля продаж] < 1./[Кол-во товаров]
) -- Товары ГРУППЫ BC c расчитанными долями продаж относительно только группы ВС
, ItemsBC_pr([Филиал], [Код товара], [Доля продаж], [Кол-во товаров]) as (
select anchor.[Филиал], anchor.[Код товара], anchor.[Кол-во продаж розница]/iif(ss.shopSum=0,1,ss.shopSum) as [Доля продаж], 
		it.shopItems
from(-- сумма продаж КАЖДОГО товара из группы "ВС" в каждом магазине
     select src.[Филиал], src.[Код товара], cast(SUM(src.[Кол-во продаж розница]) as float) as [Кол-во продаж розница]
	   from ItemsForABC src join ItemsBC bc on (src.[Филиал] = bc.[Филиал]) and (src.[Код товара] = bc.[Код товара])
      group by src.[Филиал], src.[Код товара]
	 ) anchor join 
	 (-- сумма продаж ВСЕХ товаров группы "ВС" в каждом магазине
	  select subSums.[Филиал], SUM(subSums.[Кол-во продаж розница]) as shopSum
		from ItemsForABC as subSums join ItemsBC bc1 on (subSums.[Филиал] = bc1.[Филиал]) and (subSums.[Код товара] = bc1.[Код товара])
	   group by subSums.[Филиал]
	 ) ss on anchor.[Филиал] = ss.[Филиал] join
	 (-- кол-во товаров группы "ВС" в каждом магазине
	  select bc2.[Филиал], count(*) as shopItems
		from ItemsBC bc2 
	  group by bc2.[Филиал] 
	 ) it on anchor.[Филиал] = it.[Филиал]
)
, ItemsB([Филиал], [Код товара], [Доля продаж]) as (
select [Филиал], [Код товара], [Доля продаж]
  from ItemsBC_pr 
 where [Доля продаж] >= 1./[Кол-во товаров]
)
, ItemsC([Филиал], [Код товара], [Доля продаж]) as (
select [Филиал], [Код товара], [Доля продаж]
  from ItemsBC_pr 
 where [Доля продаж] < 1./[Кол-во товаров]
)
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
--order by [Филиал], [Код товара]

insert into dbo.[ABC_Филиал_Товар] ([Начало периода], [Окончание периода], [Филиал], [Код товара], [Категория, ед.], [Категория, сумма])
select @dateStart, @dateFinish, [Филиал], [Код товара], 'A', '' from ItemsA
union all
select @dateStart, @dateFinish, [Филиал], [Код товара], 'B', '' from ItemsB
union all
select @dateStart, @dateFinish, [Филиал], [Код товара], 'C', '' from ItemsC;
