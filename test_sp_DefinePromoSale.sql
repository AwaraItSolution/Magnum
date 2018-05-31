declare @item float = 30058,
        @shop nvarchar(50)=3,
        @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
        @dateFinish  datetime,
        @periodMonth int = 1,
		@promoCoeff  float  = 0.5; -- ���� ��������� ������
	
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));

exec sp_DefinePromoSale	@dateStart   ='2018-01-01', -- ���� ������ ������� �������
	                    @periodMonth = 1,			-- ���������� ������� � ������� �������
	                    @promoCoeff  = 0.5 			-- ���� ��������� ������
	                    
--select COUNT(*) from [dbo].[ABC_Data] where PromoFail <> 0
select *  from [dbo].[ABC_Data] 
where [����] between @dateStart and @dateFinish and [��� ������] = @item;
