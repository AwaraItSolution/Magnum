/*
	Выгрузка матриц АВС для Товаров по ВСЕЙ компании и АВС по Товарам в разрезе ФИЛИАЛОВ
	по МЕСЯЦАМ для более точного прогноза для заказчика (чтобы сгенерировать больше данных)
	Основная матрица АВС строится по итогам КВАРТАЛА
Признаки:
Год, месяц, Филиал, № филиала, товар, 
Количество выходных,
Количество праздничных дней,
Группа за -2 месяц
Группа за -1 месяц
Наличие акций
*/
declare @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
		@dateFinishL datetime,
        @dateFinish  datetime,                -- дата окончания периода расчета
        @periodMonth int = 3,                 -- количество месяцев в периоде расчета
		@periodIter  int = 1;                 -- количество месяцев, которые делят общий временной период
		
set @dateFinishL = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));
set @dateFinish  = dateadd(day, -1, dateadd( MONTH, @periodIter, @dateStart));
		
declare @holidays table([Год] int, [Месяц] int, [Выходные] int, [Праздники] int, 
PRIMARY KEY CLUSTERED([Год], [Месяц]));
insert into @holidays ([Год], [Месяц], [Выходные], [Праздники]) values(2018,1,7,3);
insert into @holidays ([Год], [Месяц], [Выходные], [Праздники]) values(2018,2,8,0);
insert into @holidays ([Год], [Месяц], [Выходные], [Праздники]) values(2018,3,8,5);
insert into @holidays ([Год], [Месяц], [Выходные], [Праздники]) values(2018,4,8,1);
insert into @holidays ([Год], [Месяц], [Выходные], [Праздники]) values(2018,5,7,4);
insert into @holidays ([Год], [Месяц], [Выходные], [Праздники]) values(2018,6,9,0);

truncate table Out_toML_Monthly_item
truncate table Out_toML_Monthly_shop_item

WHILE @dateFinish <= @dateFinishL
BEGIN
	print convert(datetime, @dateStart, 120); 
	print convert(datetime, @dateFinish, 120);
--/*	
	insert into Out_toML_Monthly_item
	select tot.[Год], tot.[Месяц],
			tot.[Код товара],
			hd.[Выходные], hd.[Праздники], 
			iif(tot.[Сумма продаж по акции] > 0,1,0) as [Наличие акций],
			abc_si.[Категория, ед.], [Категория, сумма]
	  from (select [Год], [Месяц], [Код товара]
					,sum([Сумма продаж по акции])		as [Сумма продаж по акции]
			  from (
					SELECT year([Дата]) as [Год], 
							month([Дата]) as [Месяц]
						  ,[Код товара]
						  ,[Сумма продаж по акции]
					  FROM [ABC_Data].[dbo].[ABC_Data]
					 where [Дата] between @dateStart and @dateFinish
					) pr
			 group by [Год], [Месяц], [Код товара]
		   ) tot join dbo.ABC_Товар abc_si 
					on tot.[Год] = year(abc_si.[Начало периода]) and tot.[Месяц] = month(abc_si.[Начало периода]) and 
						tot.[Код товара] = abc_si.[Код товара]
			join @holidays hd on tot.[Год] = hd.[Год] and tot.[Месяц] = hd.[Месяц]
	order by tot.[Год], tot.[Месяц], tot.[Код товара];

	insert into Out_toML_Monthly_shop_item
	select tot.[Год], tot.[Месяц],
		   tot.[Код филиала],
		   tot.[Код товара],
		   hd.[Выходные], hd.[Праздники], 
		   iif(tot.[Сумма продаж по акции] > 0,1,0) as [Наличие акций],
		   abc_si.[Категория, ед.], [Категория, сумма]
	  from (select [Год], [Месяц], [Код филиала], [Код товара]
					,sum([Сумма продаж по акции])		as [Сумма продаж по акции]
			  from (
					SELECT year([Дата])   as [Год], 
							month([Дата]) as [Месяц]
						  ,[Код филиала]
						  ,[Код товара]
						  ,[Сумма продаж по акции]
					  FROM [ABC_Data].[dbo].[ABC_Data]
					 where [Дата] between @dateStart and @dateFinish
					) pr
			 group by [Год], [Месяц], [Код филиала], [Код товара]
		   ) tot join dbo.ABC_Филиал_Товар abc_si on tot.[Год] = year(abc_si.[Начало периода]) and tot.[Месяц] = month(abc_si.[Начало периода]) and 
						tot.[Код филиала] = abc_si.[Код филиала] and tot.[Код товара] = abc_si.[Код товара]
			join @holidays hd on tot.[Год] = hd.[Год] and tot.[Месяц] = hd.[Месяц]
	order by tot.[Год], tot.[Месяц], tot.[Код товара];
--*/
	set @dateStart   = dateadd( MONTH, @periodIter, @dateStart);
	set @dateFinish  = dateadd(day, -1, dateadd( MONTH, @periodIter, @dateStart));
END;

select * from Out_toML_Monthly_item;
select * from Out_toML_Monthly_shop_item;

-- генеририем исходные данные для прогноза на АПРЕЛЬ
-- По Товарам ИТОГО
insert into Out_toML_Monthly_item([Год],[Месяц],[Код товара],[Наличие акций], [Выходные], [Праздники])
select items.[Год], items.[Месяц], items.[Код товара], iif(promo.[Код товара] is null,0,1) as [Наличие акций],
		hd.[Выходные], hd.[Праздники]
from (-- Группируем товар, чтобы составить его список
	select [Год], 4 as [Месяц], [Код товара]
	  from dbo.Out_toML_Monthly_item
	 where [Год] = 2018 and [Месяц] in (1,2,3)
	 GROUP by [Год], [Код товара]
	 ) items left join
	 (-- акции берем такие же, как в феврале
	  select [Код товара]
	    from dbo.Out_toML_Monthly_item
	   where [Год] = 2018 and [Месяц] = 2 and [Наличие акций] > 0
	 ) promo
	 on items.[Код товара] = promo.[Код товара]
	 join @holidays hd on items.[Год] = hd.[Год] and items.[Месяц] = hd.[Месяц]
order by items.[Год], items.[Месяц], items.[Код товара]

-- По ФИЛИАЛАМ, Товарам 
insert into Out_toML_Monthly_shop_item([Год],[Месяц],[Код филиала],[Код товара],[Наличие акций], [Выходные], [Праздники])
select items.[Год], items.[Месяц], items.[Код филиала], items.[Код товара], 
		iif(promo.[Код товара] is null,0,1) as [Наличие акций],
		hd.[Выходные], hd.[Праздники]
from (-- Группируем товар по филиалам за предыдущие месяцы, чтобы составить список товаров для АВС
	select [Год], 4 as [Месяц], [Код филиала], [Код товара]
	  from dbo.Out_toML_Monthly_shop_item
	 where [Год] = 2018 and [Месяц] in (1,2,3)
	 GROUP by [Год], [Код филиала], [Код товара]
	 ) items left join
	 (-- акции берем такие же, как в феврале
	  select [Код филиала], [Код товара]
	    from dbo.Out_toML_Monthly_shop_item
	   where [Год] = 2018 and [Месяц] = 2 and [Наличие акций] > 0
	 ) promo
	 on items.[Код филиала] = promo.[Код филиала] and 
		items.[Код товара] = promo.[Код товара]
	 join @holidays hd on items.[Год] = hd.[Год] and items.[Месяц] = hd.[Месяц]
order by items.[Год], items.[Месяц], items.[Код филиала], items.[Код товара]

/* --проверка соответствия строк ключам таблицы
select COUNT(*)
from Out_toML_Monthly_item
where Месяц = 4

select [Год],[Месяц],[Код товара], COUNT(*)
from Out_toML_Monthly_item
group by [Год],[Месяц],[Код товара]
having COUNT(*)>1

select [Год],[Месяц],[Код филиала],[Код товара], COUNT(*)
from Out_toML_Monthly_shop_item
group by [Год],[Месяц],[Код филиала],[Код товара]
having COUNT(*)>1
*/