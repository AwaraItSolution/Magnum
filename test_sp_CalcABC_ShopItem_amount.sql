declare @item float = 176739,--117740, 
        @shop nvarchar(50) = 4,--'Алматинский филиал №11',
        @dateStart   datetime = '2018-01-01', -- дата начала периода расчета
        @dateFinish  datetime,
        @periodMonth int = 3;
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))        
--/*
exec sp_CalcABC_ShopItem_amount @dateStart   = @dateStart,   -- дата начала периода расчета
								@periodMonth = @periodMonth; -- количество месяцев в периоде расчета
--*/