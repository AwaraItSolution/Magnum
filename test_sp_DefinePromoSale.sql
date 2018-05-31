declare @item float = 30058,
        @shop nvarchar(50)=3,
        @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,
        @periodMonth int = 1,
		@promoCoeff  float  = 0.5; -- дол€ акционных продаж
	
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));

exec sp_DefinePromoSale	@dateStart   ='2018-01-01', -- дата начала периода расчета
	                    @periodMonth = 1,			-- количество мес€цев в периоде расчета
	                    @promoCoeff  = 0.5 			-- дол€ акционных продаж
	                    
--select COUNT(*) from [dbo].[ABC_Data] where PromoFail <> 0
select *  from [dbo].[ABC_Data] 
where [ƒата] between @dateStart and @dateFinish and [ од товара] = @item;
