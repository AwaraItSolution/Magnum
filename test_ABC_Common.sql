/*
Если @dateStart = '2018-01-01'
     @periodMonth  = 3, @periodIter   = 3;   То Имеем период : Jan  1 2018 12:00AM - Mar 31 2018 12:00AM
     @periodMonth  = 3, @periodIter   = 1;                     Jan  1 2018 12:00AM - Jan 31 2018 12:00AM
															   Feb  1 2018 12:00AM - Feb 28 2018 12:00AM
															   Mar  1 2018 12:00AM - Mar 31 2018 12:00AM
*/
declare @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
		@dateFinishL datetime,
        @dateFinish  datetime,
        @periodMonth int = 3,                 -- количество месяцев в периоде расчета
        @periodIter  int = 3;                 -- количество месяцев, которые делят общий временной период
set @dateFinishL = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));
set @dateFinish  = dateadd(day, -1, dateadd( MONTH, @periodIter, @dateStart));
--print @dateStart
--print convert(datetime, @dateFinish, 120) 
--print convert(datetime, @dateFinishL, 120)

truncate table dbo.ABC_Товар
truncate table dbo.ABC_Филиал_Товар

WHILE @dateFinish <= @dateFinishL
BEGIN
	print convert(datetime, @dateStart, 120); 
	print convert(datetime, @dateFinish, 120);
	
	-- Определение акционных товаров, которые требуется исключить из расчета АВС в связи с тем, что их доля в общей продаже менее 50%
	exec sp_DefinePromoSale	@dateStart   = @dateStart,
							@periodMonth = @periodIter, -- @periodIter
							@promoCoeff  = 0.5;			-- доля акционных продаж
	-- Определение дефицитных продаж	                    
	exec sp_DefineDeficit   @dateStart   = @dateStart,
							@periodMonth = @periodIter; -- @periodMonth

	-- Расчет АВС: Товар по количеству
	exec sp_CalcABC_Item_count  @dateStart   = @dateStart,  
								@periodMonth = @periodIter;
	-- Расчет АВС: Товар по сумме
	exec sp_CalcABC_Item_amount @dateStart   = @dateStart,  
								@periodMonth = @periodIter;
	-- Расчет АВС: Магазин-Товар по количеству
	exec dbo.sp_CalcABC_ShopItem_count  @dateStart   = @dateStart,  
										@periodMonth = @periodIter;
	-- Расчет АВС: Магазин-Товар по сумме
	exec dbo.sp_CalcABC_ShopItem_amount @dateStart   = @dateStart,  
										@periodMonth = @periodIter;
										
	set @dateStart   = dateadd( MONTH, @periodIter, @dateStart);
	set @dateFinish  = dateadd(day, -1, dateadd( MONTH, @periodIter, @dateStart));
END
