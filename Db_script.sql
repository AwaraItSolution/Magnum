USE [ABC_Data]

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
-- новая генерация БД
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Facing]') AND type in (N'U'))
DROP TABLE [dbo].[Facing]
GO

CREATE TABLE [dbo].[Facing](
	[Code Area] [nvarchar](10) NOT NULL,
	[Code Item] [float] NOT NULL,
	[Name Dimension] [nvarchar](20) NOT NULL,
	[Value] [float] NOT NULL,
CONSTRAINT [PK_Facing] PRIMARY KEY CLUSTERED 
(
	[Code Area] ASC,
	[Code Item] asc,
	[Name Dimension] asc
)
) ON [PRIMARY]
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Филиал]') AND type in (N'U'))
DROP TABLE [dbo].[Филиал]
GO
CREATE TABLE [dbo].[Филиал](
	[Код филиала] int NOT NULL IDENTITY(1,1),
	[Филиал]     [nvarchar](50) NOT NULL,
	[Code Area]  nvarchar(10)   NOT NULL,
	CONSTRAINT [UQ_Area$CodeArea] UNIQUE([Code Area]),
    CONSTRAINT [PK_Филиал] PRIMARY KEY CLUSTERED 
	([Код филиала] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
USE [ABC_Data]
GO
CREATE NONCLUSTERED INDEX [IX_Филиал$Филиал] ON [dbo].[Филиал] 
(	[Филиал] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ABC_Data]') AND type in (N'U'))
DROP TABLE [dbo].[ABC_Data]
GO
CREATE TABLE [dbo].[ABC_Data](
	[Дата]       smalldatetime NOT NULL,
	[Код филиала] int NOT NULL,
	[Отдел]      nvarchar(100) NOT NULL,
	[Группа]     nvarchar(100) NOT NULL,
	[Подгруппа]  nvarchar(100) NOT NULL,
	[Код товара] float NOT NULL,
	[Товар]      nvarchar(255) NOT NULL,
	PromoFail_count               tinyint NOT NULL DEFAULT (0),
    PromoFail_amount              tinyint NOT NULL DEFAULT (0),	
	Deficit_count                 tinyint NOT NULL DEFAULT (0),
	[Ед. изм. сокращенная]        nvarchar(100) NULL,
	[Кол-во продаж розница]       decimal(16, 3) NOT NULL,
	[Количество продажи по акции] decimal(16, 3) NOT NULL,
	[Сумма продаж розница с НДС]  money NOT NULL,
	[Сумма продаж по акции]       money NOT NULL,
	[Остаток на конец (ед)]       float NOT NULL,
	[Остаток на конец (тг)]       money NOT NULL,
 CONSTRAINT [PK_ABC] PRIMARY KEY CLUSTERED 
(
	[Дата] ASC,
	[Код филиала] ASC,
	[Отдел] ASC,
	[Группа] ASC,
	[Подгруппа] ASC,
	[Код товара] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ABC_Data$Код филиала] ON [dbo].[ABC_Data] 
(	[Код филиала] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ABC_Data]
ADD CONSTRAINT [FK_ABC_Data$Код филиала] FOREIGN KEY ([Код филиала])     
    REFERENCES [dbo].[Филиал]([Код филиала])     
--    ON DELETE CASCADE    
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ABC_Товар]') AND type in (N'U'))
DROP TABLE [dbo].[ABC_Товар]
GO
CREATE TABLE [dbo].[ABC_Товар](
	[Начало периода] smalldatetime NOT NULL,
	[Окончание периода] smalldatetime NOT NULL,
	[Код товара] float NOT NULL,
	[Категория, ед.] tinyint NULL,
	[Категория, сумма] tinyint NULL,
	[Категория, ед.(прогноз)] tinyint NULL,
	[Категория, сумма(прогноз] tinyint NULL,	
 CONSTRAINT [PK_ABC_Товар] PRIMARY KEY CLUSTERED 
(
	[Начало периода] ASC,
	[Окончание периода] ASC,
	[Код товара] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ABC_Филиал_Товар]') AND type in (N'U'))
DROP TABLE [dbo].[ABC_Филиал_Товар]
GO
CREATE TABLE [dbo].[ABC_Филиал_Товар](
	[Начало периода] smalldatetime NOT NULL,
	[Окончание периода] smalldatetime NOT NULL,
	[Код филиала] int NOT NULL,
	[Код товара] [float] NOT NULL,
	[Категория, ед.] tinyint NULL,
	[Категория, сумма] tinyint NULL,
	[Категория, ед.(прогноз)] tinyint NULL,
	[Категория, сумма(прогноз] tinyint NULL,	
 CONSTRAINT [PK_ABC_Филиал_Товар] PRIMARY KEY CLUSTERED 
(
	[Начало периода] ASC,
	[Окончание периода] ASC,
	[Код филиала] ASC,
	[Код товара] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ABC_Филиал_Товар$Код филиала] ON [dbo].[ABC_Филиал_Товар] 
(	[Код филиала] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ABC_Филиал_Товар]
ADD CONSTRAINT [FK_ABC_Филиал_Товар$Код филиала] FOREIGN KEY ([Код филиала])     
    REFERENCES [dbo].[Филиал]([Код филиала])     
--    ON DELETE CASCADE    
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DefinePromoSale]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_DefinePromoSale]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Попович Е.
-- Create date: 24/05/2018
-- Description:	Определение акционных продаж для последующего их вычета из расчета АВС
-- =============================================
CREATE PROCEDURE dbo.sp_DefinePromoSale
	@dateStart   datetime,     -- дата начала периода расчета
	@periodMonth int    = 1,   -- количество месяцев в периоде расчета
	@promoCoeff  float  = 0.5  -- доля акционных продаж
AS
BEGIN
	SET NOCOUNT ON;
	
	declare @dateFinish  datetime;-- дата окончания периода расчета
	declare @itemTest float       = 54993,                   -- for test
		    @shopTest varchar(50) = 'Алматинский филиал №1'; -- for test

	set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));

-- Удаляем существующий расчет за заданный период
--
   update [dbo].[ABC_Data] set PromoFail_count = 0, PromoFail_amount = 0
   where [Дата] between @dateStart and @dateFinish;
   
    /* Проанализировать акционные продажи товаров в каждой подгруппе в ОДНОМ РЕГИОНЕ(на данный момент РЕГИОН не определен в исходных данных, поэтому не учитывается)
      вне зависимости от КЛАСТЕРА (тоже не определен).
       - Расчитать % акционных продаж товаров каждой подгруппы
       - Если % акционных продаж < 50%, пометить все акционные продажи этого товара, как PromoFail
    */ 
    -- Акции по количеству
	with PromoExceptionCount([Подгруппа], [Код товара]/*, [Доля акционных продаж]*/) as
	(
	 select [Подгруппа], [Код товара]--, sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
									 --    									    sum([Кол-во продаж розница])) as [Доля акционных продаж]
	   from [dbo].[ABC_Data]
	  where [Дата] between @dateStart and @dateFinish
	--and [Филиал] = @shopTest
	group by [Подгруппа], [Код товара]
	 -- оставляем только товары, которые имеют акционные продажи и они составляют менее 50% от общих продаж
	 having  (sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
													 sum([Кол-во продаж розница])) > 0) and 
			 (sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
													 sum([Кол-во продаж розница])) < @promoCoeff)
	)
-- select * from ItemsExceptionABC_Count
-- select * from PromoExceptionCount --where [Код товара] = @item ;	
-- select COUNT(*) from ItemsExceptionABC;
	update [dbo].[ABC_Data] set PromoFail_count = 1
	  from [dbo].[ABC_Data] abc_ex join PromoExceptionCount ex
			 on abc_ex.[Подгруппа] = ex.[Подгруппа] and abc_ex.[Код товара] = ex.[Код товара]
	 where [Дата] between @dateStart and @dateFinish and
	       [Количество продажи по акции] > 0
	print @@rowcount;

	-- Акции по сумме					
	with PromoExceptionAmount([Подгруппа], [Код товара]/*, [Доля акционных продаж]*/) as
	(
	 select [Подгруппа], [Код товара]--, sum([Количество продажи по акции])/iif(sum([Кол-во продаж розница]) = 0, 1,
									 --    									    sum([Кол-во продаж розница])) as [Доля акционных продаж]
	   from [dbo].[ABC_Data]
	  where [Дата] between @dateStart and @dateFinish
	--and [Филиал] = @shopTest
	group by [Подгруппа], [Код товара]
	 -- оставляем только товары которые имеют акционные продажи и они составляют менее 50% от общих продаж
	 having  (sum([Сумма продаж по акции])/iif(sum([Сумма продаж розница с НДС]) = 0, 1,
											   sum([Сумма продаж розница с НДС])) > 0) and 
			 (sum([Сумма продаж по акции])/iif(sum([Сумма продаж розница с НДС]) = 0, 1,
											   sum([Сумма продаж розница с НДС])) < @promoCoeff)
	)
	update [dbo].[ABC_Data] set PromoFail_amount = 1
	  from [dbo].[ABC_Data] abc_ex join PromoExceptionAmount ex
			 on abc_ex.[Подгруппа] = ex.[Подгруппа] and abc_ex.[Код товара] = ex.[Код товара]
	 where [Дата] between @dateStart and @dateFinish and
	       [Сумма продаж по акции] > 0;
	print @@rowcount;
END
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DefineDeficit]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_DefineDeficit]
GO
-- =============================================
-- Author:		Попович Е.
-- Create date: 24.05.2018
-- Description:	Определение дефицита за период. Сейчас дефицит определяется ТОЛЬКО по КОЛИЧЕСТВУ. 
--              Далее можно сделать дефицит для количества и для суммы отдельным полем, как у Promo
-- =============================================
CREATE PROCEDURE sp_DefineDeficit
			@dateStart    datetime,   -- дата начала периода расчета
			@periodMonth  int = 1,    -- количество месяцев в периоде расчета
			@midSaleCoeff float = 0.4 -- Процент средних продаж
AS
BEGIN
	SET NOCOUNT ON;
    declare @dateFinish datetime; -- дата окончания периода расчета
	declare @item float = 117740, -- for test 
            @shop int=4;          --'Алматинский филиал №11',
		
	set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));
	--print @dateFinish;
	
	-- Сброс дефицита за расчитываемый период
	update [dbo].[ABC_Data] set Deficit_count = 0
	where [Дата] between @dateStart and @dateFinish;
	
	-- Определяем дефицит по нулевым продажам, окруженным тоже нулевыми продажами
	with DeficitSales ([Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара]) as (
		select t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара]
				/*, t_now.[Кол-во продаж розница], t_now.[Количество продажи по акции]*/
		  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
				-- проверка того, что предыдущий день, как и текущий без продаж
				on (t_now.[Дата] = dateadd(day,-1,t_yest.[Дата])) and (t_now.[Код филиала] = t_yest.[Код филиала]) and
				   (t_now.[Отдел] = t_yest.[Отдел]) and (t_now.[Группа] = t_yest.[Группа]) and
				   (t_now.[Подгруппа] = t_yest.[Подгруппа]) and (t_now.[Код товара] = t_yest.[Код товара]) and 
				
				   (t_now.[Кол-во продаж розница] = t_yest.[Кол-во продаж розница])
				-- проверка того, что следующий день, как и текущий без продаж
				join [dbo].[ABC_Data] as t_tom
				on (t_now.[Дата] = dateadd(day,1,t_tom.[Дата])) and (t_now.[Код филиала] = t_tom.[Код филиала]) and
				   (t_now.[Отдел] = t_tom.[Отдел]) and (t_now.[Группа] = t_tom.[Группа]) and
				   (t_now.[Подгруппа] = t_tom.[Подгруппа]) and (t_now.[Код товара] = t_tom.[Код товара]) and 

				   (t_now.[Кол-во продаж розница] = t_tom.[Кол-во продаж розница])
		where t_now.[Дата] between @dateStart and @dateFinish and
			   t_now.[Кол-во продаж розница] = 0
		--and t_now.[Код товара] = @item 
		--and t_now.[Код филиала] = @shop
	)
	update [dbo].[ABC_Data] set Deficit_count = 1
	  from [dbo].[ABC_Data] abc_ex join DeficitSales ex
			 on abc_ex.[Дата] = ex.[Дата] and abc_ex.[Код филиала] = ex.[Код филиала] and abc_ex.[Отдел] = ex.[Отдел] and abc_ex.[Группа] = ex.[Группа] and 
				abc_ex.[Подгруппа] = ex.[Подгруппа] and abc_ex.[Код товара] = ex.[Код товара];
	
	-- Промаркировать продажи, как дефицит, у которых Остаток на конец < 1 и по продажи КОЛИЧЕСТВУ < 40% продаж этого товара за ЭТОТ месяц с отброшенным
	-- дефицитом из ПРЕДЫДУЩЕГО этапа
	
	-- Считаем КРИВОЙ дефицит за ТЕКУЩИЙ период ВМЕСТО предыдущего
	with AvgSales([Подгруппа],[Код товара],[Продаж в день, ед.],[Продаж в день, сумма]) as (
		select [Подгруппа], [Код товара], 
			   avg([Кол-во продаж розница])      as [Продаж в день, ед.],
			   avg([Сумма продаж розница с НДС]) as [Продаж в день, сумма]
		  from [dbo].[ABC_Data]
		where [Дата] between @dateStart and @dateFinish and Deficit_count = 0
		--and [Код товара] = @item
		--and [Код филиала] = @shop
		group by [Подгруппа], [Код товара]
	)--select * from AvgSales
	, DeficitSales_Middle([Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара]) as (
		select t_now.[Дата], t_now.[Код филиала], t_now.[Отдел], t_now.[Группа], t_now.[Подгруппа], t_now.[Код товара]/*,[Кол-во продаж розница],[Сумма продаж розница с НДС]*/
		  from [dbo].[ABC_Data] t_now join AvgSales avSl 
				on t_now.[Подгруппа] = avSl.[Подгруппа] and t_now.[Код товара] = avSl.[Код товара]
		 where t_now.[Дата] between @dateStart and @dateFinish and Deficit_count = 0 and 
				t_now.[Остаток на конец (ед)] < 1 and (t_now.[Кол-во продаж розница] < avSl.[Продаж в день, ед.] * @midSaleCoeff) 
		--and t_now.[Код товара] = @item
		--and t_now.[Код филиала] = @shop
	)
	update [dbo].[ABC_Data] set Deficit_count = 1
	  from [dbo].[ABC_Data] abc_ex join DeficitSales_Middle ex
			 on abc_ex.[Дата] = ex.[Дата] and abc_ex.[Код филиала] = ex.[Код филиала] and abc_ex.[Отдел] = ex.[Отдел] and abc_ex.[Группа] = ex.[Группа] and 
				abc_ex.[Подгруппа] = ex.[Подгруппа] and abc_ex.[Код товара] = ex.[Код товара];

END
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CalcABC_ShopItem_count]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_CalcABC_ShopItem_count]
GO
-- =============================================
-- Author:		Попович Е.
-- Create date: 25.05.2018
-- Description:	Расчет АВС по Магазин-Товар по количеству
-- =============================================
CREATE PROCEDURE dbo.sp_CalcABC_ShopItem_count
			@dateStart    datetime,   -- дата начала периода расчета
			@periodMonth  int = 1     -- количество месяцев в периоде расчета
AS
BEGIN
	SET NOCOUNT ON;
	-- Расчет АВС для Филиалов по количеству
	declare @dateFinish  datetime;    -- дата окончания периода расчета
	set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));

	-- for test
	declare @itemTest float       = 54993, 
			@shopTest varchar(50) = 'Алматинский филиал №1';                

	-- чтобы merge не выводил output info
	declare @mergeOut table(descript varchar(20), shop int, item float, cat_count tinyint, cat_amount tinyint);
	    
	-- Удаляем существующий расчет за заданный период
	update dbo.[ABC_Филиал_Товар] set [Категория, ед.] = NULL
	 where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish;

	-- Выбираем продажи за период без промоакций и дефицита
	with ItemsForABC ([Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница]) as (
		select [Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница с НДС]
		  from dbo.ABC_Data
		 where [Дата] between @dateStart and @dateFinish and 
				PromoFail_count = 0 AND Deficit_count = 0
	) -- Товары прогруппированные [Код товара] и взвешенные на сумму общих продаж [Доля продаж]
	, Items ([Код филиала], [Код товара], [Доля продаж]) as (
	select anchor.[Код филиала], anchor.[Код товара], anchor.[Кол-во продаж розница]/iif(ss.shopSum = 0,1,ss.shopSum)
	from (select abc.[Код филиала], abc.[Код товара], cast(SUM(abc.[Кол-во продаж розница]) as float) as [Кол-во продаж розница]
			from ItemsForABC abc
		   group by abc.[Код филиала], abc.[Код товара]
		 ) anchor join 
		 (select subSums.[Код филиала], SUM(subSums.[Кол-во продаж розница]) as shopSum
			from ItemsForABC subSums
		   group by subSums.[Код филиала]
		 ) ss on anchor.[Код филиала] = ss.[Код филиала]
	)-- Сопоставляем суммарной Продаже каждого товара по магазину СУММУ всех продаж по магазину
	, ItemsPartsSubCount([Код филиала], [Код товара], [Доля продаж], [Кол-во товаров]) as (
	select ip.[Код филиала], ip.[Код товара], ip.[Доля продаж], iif(ip1.itm_cnt = 0,1,ip1.itm_cnt)
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
	select anchor.[Код филиала], anchor.[Код товара], anchor.[Кол-во продаж розница]/iif(ss.shopSum=0,1,ss.shopSum) as [Доля продаж], 
			iif(it.shopItems = 0,1,it.shopItems)
	from(-- сумма продаж КАЖДОГО товара из группы "ВС" в каждом магазине
		 select src.[Код филиала], src.[Код товара], cast(SUM(src.[Кол-во продаж розница]) as float) as [Кол-во продаж розница]
		   from ItemsForABC src join ItemsBC bc on (src.[Код филиала] = bc.[Код филиала]) and (src.[Код товара] = bc.[Код товара])
		  group by src.[Код филиала], src.[Код товара]
		 ) anchor join 
		 (-- сумма продаж ВСЕХ товаров группы "ВС" в каждом магазине
		  select subSums.[Код филиала], SUM(subSums.[Кол-во продаж розница]) as shopSum
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
	, ItemsABCbyCount([Начало периода],[Окончание периода],[Код филиала],[Код товара], [Категория, ед.]) as (
	select @dateStart, @dateFinish, [Код филиала], [Код товара], 0 from ItemsA
	union all
	select @dateStart, @dateFinish, [Код филиала], [Код товара], 1 from ItemsB
	union all
	select @dateStart, @dateFinish, [Код филиала], [Код товара], 2 from ItemsC
	)
	merge dbo.[ABC_Филиал_Товар] t
	using ItemsABCbyCount s on t.[Начало периода]= s.[Начало периода] and t.[Окончание периода] = s.[Окончание периода] and 
					 			t.[Код филиала] = s.[Код филиала] and t.[Код товара] = s.[Код товара]
	when matched
		then update set [Категория, ед.] = s.[Категория, ед.]
	when not matched
		then insert ([Начало периода],[Окончание периода],[Код филиала],[Код товара],[Категория, ед.]) 
			 values (s.[Начало периода], s.[Окончание периода], s.[Код филиала], s.[Код товара], s.[Категория, ед.])
	output $action as [action], isnull(Inserted.[Код филиала], Deleted.[Код филиала]) as [Код филиала], 
								isnull(Inserted.[Код товара], Deleted.[Код товара]) as [Код товара], 
								isnull(Inserted.[Категория, ед.], Deleted.[Категория, ед.]) as [Категория, ед.],
								isnull(Inserted.[Категория, сумма], Deleted.[Категория, сумма]) as [Категория, сумма]
	into @mergeOut;
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
END
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CalcABC_ShopItem_amount]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_CalcABC_ShopItem_amount]
GO
-- =============================================
-- Author:		Попович Е.
-- Create date: 25.05.2018
-- Description:	Расчет АВС по Магазин-Товар по сумме
-- =============================================
CREATE PROCEDURE [dbo].[sp_CalcABC_ShopItem_amount]
			@dateStart    datetime,   -- дата начала периода расчета
			@periodMonth  int = 1     -- количество месяцев в периоде расчета
AS
BEGIN
	SET NOCOUNT ON;
	-- Расчет АВС для Филиалов по сумме
	declare @dateFinish  datetime;    -- дата окончания периода расчета
	set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));
	
	-- for test
	declare @itemTest float       = 54993, 
			@shopTest varchar(50) = 'Алматинский филиал №1';                

	-- чтобы merge не выводил output info
	declare @mergeOut table(descript varchar(20), shop int, item float, cat_count tinyint, cat_amount tinyint);
	    
	-- Удаляем существующий расчет за заданный период
	update dbo.[ABC_Филиал_Товар] set [Категория, сумма] = NULL
	 where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish;

	-- Выбираем продажи за период без промоакций и дефицита
	with ItemsForABC ([Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница]) as (
		select [Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница с НДС]
		  from dbo.ABC_Data
		 where [Дата] between @dateStart and @dateFinish and 
				PromoFail_amount = 0 AND Deficit_count = 0
	) -- Группируем Товары по [Код товара] и взвешиваем на сумму общих продаж [Доля продаж]
	, Items ([Код филиала], [Код товара], [Доля продаж]) as (
	select anchor.[Код филиала], anchor.[Код товара], anchor.[Сумма продаж розница]/iif(ss.shopSum = 0,1,ss.shopSum)
	from (select abc.[Код филиала], abc.[Код товара], cast(SUM(abc.[Сумма продаж розница]) as float) as [Сумма продаж розница]
			from ItemsForABC abc
		   group by abc.[Код филиала], abc.[Код товара]
		 ) anchor join 
		 (select subSums.[Код филиала], SUM(subSums.[Сумма продаж розница]) as shopSum
			from ItemsForABC subSums
		   group by subSums.[Код филиала]
		 ) ss on anchor.[Код филиала] = ss.[Код филиала]
	)-- Сопоставляем суммарной Продаже каждого товара по магазину СУММУ всех продаж по магазину
	, ItemsPartsSubCount([Код филиала], [Код товара], [Доля продаж], [Кол-во товаров]) as (
	select ip.[Код филиала], ip.[Код товара], ip.[Доля продаж], iif(ip1.itm_cnt = 0,1,ip1.itm_cnt)
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
			iif(it.shopItems = 0,1,it.shopItems)
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
		then insert ([Начало периода],[Окончание периода],[Код филиала],[Код товара],[Категория, сумма]) 
			 values (s.[Начало периода], s.[Окончание периода], s.[Код филиала], s.[Код товара], s.[Категория, сумма])
	output $action as [action], isnull(Inserted.[Код филиала], Deleted.[Код филиала]) as [Код филиала], 
								isnull(Inserted.[Код товара], Deleted.[Код товара]) as [Код товара], 
								isnull(Inserted.[Категория, ед.], Deleted.[Категория, ед.]) as [Категория, ед.],
								isnull(Inserted.[Категория, сумма], Deleted.[Категория, сумма]) as [Категория, сумма]
	into @mergeOut;

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
END
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CalcABC_Item_count]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_CalcABC_Item_count]
GO
-- =============================================
-- Author:		Попович Е.
-- Create date: 25.05.2018
-- Description:	Расчет АВС по Товару по количеству
-- =============================================
CREATE PROCEDURE [dbo].[sp_CalcABC_Item_count]
			@dateStart    datetime,   -- дата начала периода расчета
			@periodMonth  int = 1     -- количество месяцев в периоде расчета
AS
BEGIN
	SET NOCOUNT ON;
	-- Расчет АВС по КОЛИЧЕСТВУ
	declare @dateFinish  datetime;    -- дата окончания периода расчета
	set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));

	-- for test
	declare @itemTest float       = 54993, 
			@shopTest varchar(50) = 'Алматинский филиал №1';                

	-- чтобы merge не выводил output info
	declare @mergeOut table(descript varchar(20), item float, cat_count tinyint, cat_amount tinyint);

	-- Удаляем существующий расчет за заданный период
	update dbo.[ABC_Товар] set [Категория, ед.] = NULL
	 where [Начало периода] = @dateStart and [Окончание периода] = @dateFinish;
	      
	-- Выбираем продажи за период без промоакций и дефицита
	with ItemsForABC ([Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница]) as (
		select [Дата], [Код филиала], [Отдел], [Группа], [Подгруппа], [Код товара], [Кол-во продаж розница], [Сумма продаж розница с НДС]
		  from dbo.ABC_Data
		 where [Дата] between @dateStart and @dateFinish and 
				PromoFail_count = 0 AND Deficit_count = 0
	) -- Товары прогруппированные [Код товара] и взвешенные на сумму общих продаж
	, Items ([Код товара], [Доля продаж]) as (
		select [Код товара], cast(SUM([Кол-во продаж розница]) as float)/iif((select SUM([Кол-во продаж розница]) from ItemsForABC)=0,1,
																			  (select SUM([Кол-во продаж розница]) from ItemsForABC))
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
		select src.[Код товара], cast(SUM(src.[Кол-во продаж розница]) as float)/iif((select SUM(src1.[Кол-во продаж розница]) 
																						from ItemsForABC src1 join ItemsBC bc1 
																							 on src1.[Код товара] = bc1.[Код товара])=0,1,
																					  (select SUM(src1.[Кол-во продаж розница]) 
																						 from ItemsForABC src1 join ItemsBC bc1 
																							 on src1.[Код товара] = bc1.[Код товара])
																					) as [Доля продаж]
		  from ItemsForABC src join ItemsBC bc on src.[Код товара] = bc.[Код товара]
		group by src.[Код товара]
	)
	, ItemsB([Код товара], [Доля продаж]) as (
		select [Код товара], [Доля продаж]
		  from ItemsBC_pr
		 where [Доля продаж] >= 1./(select count(*) from ItemsBC_pr)
	)
	, ItemsC([Код товара], [Доля продаж]) as (
		select [Код товара], [Доля продаж]
		  from ItemsBC_pr
		 where [Доля продаж] < 1./(select count(*) from ItemsBC_pr)
	)
	, ItemsABCbyCount([Начало периода],[Окончание периода],[Код товара], [Категория, ед.]) as (
		select @dateStart, @dateFinish, [Код товара], 0 from ItemsA
		union all
		select @dateStart, @dateFinish, [Код товара], 1 from ItemsB
		union all
		select @dateStart, @dateFinish, [Код товара], 2 from ItemsC
	)
	merge dbo.[ABC_Товар] t
	using ItemsABCbyCount s on t.[Начало периода]= s.[Начало периода] and t.[Окончание периода] = s.[Окончание периода] and 
				 				t.[Код товара] = s.[Код товара]
	when matched
		then update set [Категория, ед.] = s.[Категория, ед.]
	when not matched
		then insert ([Начало периода],[Окончание периода],[Код товара],[Категория, ед.]) 
			 values (s.[Начало периода], s.[Окончание периода], s.[Код товара], s.[Категория, ед.])
	output $action as [action],	isnull(Inserted.[Код товара], Deleted.[Код товара]) as [Код товара], 
								isnull(Inserted.[Категория, ед.], Deleted.[Категория, ед.]) as [Категория, ед.],
								isnull(Inserted.[Категория, сумма], Deleted.[Категория, сумма]) as [Категория, сумма]
	into @mergeOut;
	--*/
	--select * from PromoException
	--select * from Items
	--select count(*) from Items   -- Кол-во товаров для расчета АВС == 198
	--select SUM([Кол-во продаж розница]) from ItemsForABC where [Код товара] = @itemTest;
	--select * from ItemsGroups;
	--select * from ItemsA --where [Код товара] = @itemTest;
	--select * from ItemsBC;
	--select * from ItemsBC_pr;
	--select * from ItemsB;
	--select * from ItemsC
	--select * from ItemsABCbyCount
END
GO
----------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_CalcABC_Item_amount]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_CalcABC_Item_amount]
GO
-- =============================================
-- Author:		Попович Е.
-- Create date: 25.05.2018
-- Description:	Расчет АВС по Товару по сумме
-- =============================================
CREATE PROCEDURE [dbo].[sp_CalcABC_Item_amount]
			@dateStart    datetime,   -- дата начала периода расчета
			@periodMonth  int = 1     -- количество месяцев в периоде расчета
AS
BEGIN
	SET NOCOUNT ON;

	-- Расчет АВС по сумме
	declare @dateFinish  datetime;    -- дата окончания периода расчета
	set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));

	-- for test
	declare @itemTest float       = 54993, 
			@shopTest varchar(50) = 'Алматинский филиал №1';                

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
								isnull(Inserted.[Категория, сумма], Deleted.[Категория, сумма]) as [Категория, сумма]
	into @mergeOut;
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
END
GO