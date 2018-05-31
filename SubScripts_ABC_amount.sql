-- Расчет АВС по сумме
declare @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,                -- дата окончания периода расчета
        @periodMonth     int = 1              -- количество месяцев в периоде расчета
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))

declare @itemTest float       = 55015, 
        @shopTest varchar(50) = 'Алматинский филиал №1';                -- for test

-- чтобы merge не выводил output info
declare @mergeOut table(descript varchar(20), item float, cat_count tinyint, cat_amount tinyint);

-- Удаляем существующий расчет за заданный период
update dbo.[ABC_Товар] set [Категория, сумма] = NULL
 where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish;
    
-- Выбираем продажи за период без промоакций и дефицита
with ItemsForABC ([Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница]) as (
	select [Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница с НДС]
	  from dbo.ABC_Data
	 where [Дата] between @dateStart and @dateFinish and 
			PromoFail_amount = 0 AND Deficit_count = 0
) -- Товары прогруппированные [Код товара] и взвешенные на сумму общих продаж
, Items ([Код товара], [Доля продаж]) as (
	select [Код товара], cast(SUM([Сумма продаж розница]) as float)/iif((select SUM([Сумма продаж розница]) from ItemsForABC)=0,1,
																		(select SUM([Сумма продаж розница]) from ItemsForABC))
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
	select src.[Код товара], cast(SUM(src.[Сумма продаж розница]) as float)/iif((select SUM(src1.[Сумма продаж розница]) 
																				   from ItemsForABC src1 join ItemsBC bc1 
																						on src1.[Код товара] = bc1.[Код товара])=0,1,
																				 (select SUM(src1.[Сумма продаж розница]) 
																				   from ItemsForABC src1 join ItemsBC bc1 
																						on src1.[Код товара] = bc1.[Код товара])
																			   )
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
, ItemsABCbyAmount([Начало периода],[Окончание периода],[Код товара],[Категория, сумма]) as (
	select @dateStart, @dateFinish, [Код товара], 0 from ItemsA
	union all
	select @dateStart, @dateFinish, [Код товара], 1 from ItemsB
	union all
	select @dateStart, @dateFinish, [Код товара], 2 from ItemsC
)
merge dbo.[ABC_Товар] t
using ItemsABCbyAmount s on t.[Начало периода]= s.[Начало периода] and t.[Окончание периода] = s.[Окончание периода] and t.[Код товара] = s.[Код товара]
when matched
    then update set [Категория, сумма] = s.[Категория, сумма]
when not matched
    then insert ([Начало периода],[Окончание периода],[Код товара],[Категория, сумма]) 
		 values (s.[Начало периода], s.[Окончание периода], s.[Код товара],s.[Категория, сумма])
output $action as [action], isnull(Inserted.[Код товара], Deleted.[Код товара]) as [Код товара], 
							isnull(Inserted.[Категория, ед.], Deleted.[Категория, ед.]) as [Категория, ед.],
							isnull(Inserted.[Категория, сумма], Deleted.[Категория, сумма]) as [Категория, сумма];
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
--insert into dbo.[ABC_Товар] ([Начало периода], [Окончание периода], [Код товара], [Категория, ед.], [Категория, сумма])
--select * from ItemsABCbyAmount
