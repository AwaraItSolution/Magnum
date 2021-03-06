/*
Признаки:
Год, месяц, Филиал, № филиала, товар, 
Количество выходных,
Количество праздничных дней,
Группа за -2 месяц
Группа за -1 месяц
Наличие акций
*/
declare @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,                -- дата окончания периода расчета
        @periodMonth     int = 3;             -- количество месяцев в периоде расчета

declare @holidays table([Год] int, [Квартал] int, [Месяц] int, [Выходные] int, [Праздники] int, 
PRIMARY KEY CLUSTERED([Год], [Квартал], [Месяц]));
insert into @holidays ([Год], [Квартал], [Месяц], [Выходные], [Праздники]) values(2018,1,1,7,3);
insert into @holidays ([Год], [Квартал], [Месяц], [Выходные], [Праздники]) values(2018,1,2,8,0);
insert into @holidays ([Год], [Квартал], [Месяц], [Выходные], [Праздники]) values(2018,1,3,8,5);
insert into @holidays ([Год], [Квартал], [Месяц], [Выходные], [Праздники]) values(2018,2,4,8,1);
insert into @holidays ([Год], [Квартал], [Месяц], [Выходные], [Праздники]) values(2018,2,5,7,4);
insert into @holidays ([Год], [Квартал], [Месяц], [Выходные], [Праздники]) values(2018,2,6,9,0);

set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))

-- Данные для АВС по всей сети за квартал
select tot.[Год], tot.[Квартал],
       tot.[Код товара],
	   hd.[Выходные], hd.[Праздники], 
	   iif(tot.[Сумма продаж по акции] > 0,1,0) as [Наличие акций],
		abc_si.[Категория, ед.], [Категория, сумма]
  from (select [Год], [Квартал], [Код товара]
				,sum([Кол-во продаж розница])       as [Кол-во продаж розница]
				,sum([Количество продажи по акции])	as [Количество продажи по акции]
				,sum([Сумма продаж розница с НДС])	as [Сумма продаж розница с НДС]
				,sum([Сумма продаж по акции])		as [Сумма продаж по акции]
				,sum([Остаток на конец (ед)])		as [Остаток на конец (ед)]
				,sum([Остаток на конец (тг)])		as [Остаток на конец (тг)]
		  from (
				SELECT year([Дата]) as [Год], datepart(quarter,[Дата]) as [Квартал], month([Дата]) as [Месяц]
				--	    ,[Код филиала]
				--      ,[Отдел],[Группа],[Подгруппа]
					  ,[Код товара]
				--      ,[Товар],[Ед. изм. сокращенная]
					  ,[Кол-во продаж розница]
					  ,[Количество продажи по акции]
					  ,[Сумма продаж розница с НДС]
					  ,[Сумма продаж по акции]
					  ,iif([Остаток на конец (ед)] < 0, 0, [Остаток на конец (ед)]) as [Остаток на конец (ед)]
					  ,iif([Остаток на конец (тг)] < 0, 0, [Остаток на конец (тг)]) as [Остаток на конец (тг)]
				  FROM [ABC_Data].[dbo].[ABC_Data]
				 where [Дата] between @dateStart and @dateFinish
				) pr
		 group by pr.[Год], pr.[Квартал], pr.[Код товара]
	   ) tot join dbo.ABC_Товар abc_si on tot.[Год] = year(abc_si.[Начало периода]) and 
					 tot.[Квартал] = datepart(quarter,abc_si.[Начало периода]) and 
					 tot.[Код товара] = abc_si.[Код товара]
		join (select [Год], [Квартал], sum([Выходные]) as [Выходные], sum([Праздники]) as [Праздники]
				from @holidays hol
			   where year(@dateStart) = hol.[Год] and datepart(quarter, @dateStart) = hol.Квартал
			group by [Год], [Квартал]) hd 
			on tot.[Год] = hd.[Год] and tot.[Квартал] = hd.[Квартал]
order by tot.[Год], tot.[Квартал], tot.[Код товара];

-- Данные для АВС по ФИЛИАЛАМ за квартал
select tot.[Год], tot.[Квартал],
        tot.[Код филиала],
        tot.[Код товара],
		hd.[Выходные], hd.[Праздники], 
		iif(tot.[Сумма продаж по акции] > 0,1,0) as [Наличие акций],
		abc_si.[Категория, ед.], [Категория, сумма]
  from (select [Год], [Квартал], [Код филиала], [Код товара]
				,sum([Кол-во продаж розница])       as [Кол-во продаж розница]
				,sum([Количество продажи по акции])	as [Количество продажи по акции]
				,sum([Сумма продаж розница с НДС])	as [Сумма продаж розница с НДС]
				,sum([Сумма продаж по акции])		as [Сумма продаж по акции]
				,sum([Остаток на конец (ед)])		as [Остаток на конец (ед)]
				,sum([Остаток на конец (тг)])		as [Остаток на конец (тг)]
		  from (
				SELECT year([Дата]) as [Год], datepart(quarter,[Дата]) as [Квартал]
					  ,[Код филиала]
				--      ,[Отдел],[Группа],[Подгруппа]
					  ,[Код товара]
				--      ,[Товар],[Ед. изм. сокращенная]
					  ,[Кол-во продаж розница]
					  ,[Количество продажи по акции]
					  ,[Сумма продаж розница с НДС]
					  ,[Сумма продаж по акции]
					  ,iif([Остаток на конец (ед)] < 0, 0, [Остаток на конец (ед)]) as [Остаток на конец (ед)]
					  ,iif([Остаток на конец (тг)] < 0, 0, [Остаток на конец (тг)]) as [Остаток на конец (тг)]
				  FROM [ABC_Data].[dbo].[ABC_Data]
				 where [Дата] between @dateStart and @dateFinish
				) pr
		 group by pr.[Год], pr.[Квартал], pr.[Код филиала], pr.[Код товара]
	   ) tot join dbo.ABC_Филиал_Товар abc_si 
				on tot.[Год] = year(abc_si.[Начало периода]) and 
					tot.[Квартал] = datepart(quarter, abc_si.[Начало периода]) and 
					tot.[Код филиала] = abc_si.[Код филиала] and tot.[Код товара] = abc_si.[Код товара]
		join (select [Год], [Квартал], sum([Выходные]) as [Выходные], sum([Праздники]) as [Праздники]
				from @holidays hol
			   where year(@dateStart) = hol.[Год] and datepart(quarter, @dateStart) = hol.Квартал
			group by [Год], [Квартал]) hd 
			on tot.[Год] = hd.[Год] and tot.[Квартал] = hd.[Квартал]
order by tot.[Год], tot.[Квартал], tot.[Код филиала], tot.[Код товара]
-----------------------------------------------------------------------------------------------------
-- Данные для ПРОГНОЗА на следующий квартал
-- Берем акции на товары такие же как и в предыдущем квартале, т.к. не знаем точно какие будут
declare @nextQuarter int;
set @nextQuarter = DATEPART(quarter,@dateStart)+1;

select tot.[Год], tot.[Квартал],
       tot.[Код товара],
	   hd.[Выходные], hd.[Праздники], 
	   iif(tot.[Сумма продаж по акции] > 0,1,0) as [Наличие акций]
  from (select [Год], @nextQuarter as [Квартал], [Код товара]
				,sum([Кол-во продаж розница])       as [Кол-во продаж розница]
				,sum([Количество продажи по акции])	as [Количество продажи по акции]
				,sum([Сумма продаж розница с НДС])	as [Сумма продаж розница с НДС]
				,sum([Сумма продаж по акции])		as [Сумма продаж по акции]
				,sum([Остаток на конец (ед)])		as [Остаток на конец (ед)]
				,sum([Остаток на конец (тг)])		as [Остаток на конец (тг)]
		  from (
				SELECT year([Дата]) as [Год], datepart(quarter,[Дата]) as [Квартал], month([Дата]) as [Месяц]
				--	    ,[Код филиала]
				--      ,[Отдел],[Группа],[Подгруппа]
					  ,[Код товара]
				--      ,[Товар],[Ед. изм. сокращенная]
					  ,[Кол-во продаж розница]
					  ,[Количество продажи по акции]
					  ,[Сумма продаж розница с НДС]
					  ,[Сумма продаж по акции]
					  ,iif([Остаток на конец (ед)] < 0, 0, [Остаток на конец (ед)]) as [Остаток на конец (ед)]
					  ,iif([Остаток на конец (тг)] < 0, 0, [Остаток на конец (тг)]) as [Остаток на конец (тг)]
				  FROM [ABC_Data].[dbo].[ABC_Data]
				 where [Дата] between @dateStart and @dateFinish
				) pr
		 group by pr.[Год], pr.[Квартал], pr.[Код товара]
	   ) tot 
		join (select [Год], [Квартал], sum([Выходные]) as [Выходные], sum([Праздники]) as [Праздники]
				from @holidays hol
			   where year(@dateStart) = hol.[Год] and @nextQuarter = hol.Квартал
			group by [Год], [Квартал]) hd 
			on tot.[Год] = hd.[Год] and tot.[Квартал] = hd.[Квартал]
order by tot.[Год], tot.[Квартал], tot.[Код товара];
/*
select RTRIM(SUBSTRING(tot.[Филиал],1,iif(CHARINDEX ('№',tot.[Филиал])=0,LEN(tot.[Филиал]),CHARINDEX ('№',tot.[Филиал])-1))) as [Регион], 
	cast(RTRIM(SUBSTRING(tot.[Филиал],
					iif(CHARINDEX('№',tot.[Филиал])=0,1,CHARINDEX ('№',tot.[Филиал])+1),
					iif(CHARINDEX(' ',tot.[Филиал],CHARINDEX('№',tot.[Филиал]))=0,LEN(tot.[Филиал]),
						 CHARINDEX(' ',tot.[Филиал],CHARINDEX('№',tot.[Филиал]))-CHARINDEX('№',tot.[Филиал])-1)))
		 as int) as [Магазин]
from dbo.Филиал tot
*/