-- Расчет АВС для ТОВАРов по КОЛИЧЕСТВУ
declare @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,                -- дата окончания периода расчета
        @periodMonth     int = 1,             -- количество месяцев в периоде расчета
        @promoCoeff      float = 0.5,         -- доля акционных продаж
        @minPresentStock float = 0,           -- Минимальный презентационный запас. Получаем из вне ли как-то считаем
        @minStock        float = 1;           -- Минимальный остаток на конец дня
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))
--print @dateFinish
declare @itemTest float = 54849,--117740, 
        @shopTest int   = 3--4--'Алматинский филиал №11'
        
/*select * from dbo.Филиал*/

select [Дата], [Код филиала], [Код товара], [Кол-во продаж розница], [Остаток на конец (ед)], PromoFail_count,PromoFail_amount,Deficit_count, [Сумма продаж розница с НДС]
  from dbo.ABC_Data
 where [Дата] between @dateStart and @dateFinish
and [Код филиала] = @shopTest 
and [Код товара] = @itemTest;
			
select *--[Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница с НДС]
  from dbo.ABC_Филиал_Товар
 where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish 
--and not ([Категория, сумма] IS NULL)
and [Код филиала] = @shopTest 
and [Код товара] = @itemTest;

--/* Тестовая выборка, формирующаяся из вне, по которой расчитываем АВС
;with ItemsForABC ([Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница]) as (
	select [Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница с НДС]
	  from dbo.ABC_Data
	 where [Дата] between @dateStart and @dateFinish and 
			PromoFail_count = 0 AND Deficit_count = 0
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