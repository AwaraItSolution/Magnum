declare @item float = 176739,--117740, 
        @shop nvarchar(50) = 4,--'����������� ������ �11',
        @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
        @dateFinish  datetime,
        @periodMonth int = 3;
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))        
--/*
exec sp_CalcABC_ShopItem_amount @dateStart   = @dateStart,   -- ���� ������ ������� �������
								@periodMonth = @periodMonth; -- ���������� ������� � ������� �������
--*/