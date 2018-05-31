/*
���� @dateStart = '2018-01-01'
     @periodMonth  = 3, @periodIter   = 3;   �� ����� ������ : Jan  1 2018 12:00AM - Mar 31 2018 12:00AM
     @periodMonth  = 3, @periodIter   = 1;                     Jan  1 2018 12:00AM - Jan 31 2018 12:00AM
															   Feb  1 2018 12:00AM - Feb 28 2018 12:00AM
															   Mar  1 2018 12:00AM - Mar 31 2018 12:00AM
*/
declare @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
		@dateFinishL datetime,
        @dateFinish  datetime,
        @periodMonth int = 3,                 -- ���������� ������� � ������� �������
        @periodIter  int = 3;                 -- ���������� �������, ������� ����� ����� ��������� ������
set @dateFinishL = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart));
set @dateFinish  = dateadd(day, -1, dateadd( MONTH, @periodIter, @dateStart));
--print @dateStart
--print convert(datetime, @dateFinish, 120) 
--print convert(datetime, @dateFinishL, 120)

truncate table dbo.ABC_�����
truncate table dbo.ABC_������_�����

WHILE @dateFinish <= @dateFinishL
BEGIN
	print convert(datetime, @dateStart, 120); 
	print convert(datetime, @dateFinish, 120);
	
	-- ����������� ��������� �������, ������� ��������� ��������� �� ������� ��� � ����� � ���, ��� �� ���� � ����� ������� ����� 50%
	exec sp_DefinePromoSale	@dateStart   = @dateStart,
							@periodMonth = @periodIter, -- @periodIter
							@promoCoeff  = 0.5;			-- ���� ��������� ������
	-- ����������� ���������� ������	                    
	exec sp_DefineDeficit   @dateStart   = @dateStart,
							@periodMonth = @periodIter; -- @periodMonth

	-- ������ ���: ����� �� ����������
	exec sp_CalcABC_Item_count  @dateStart   = @dateStart,  
								@periodMonth = @periodIter;
	-- ������ ���: ����� �� �����
	exec sp_CalcABC_Item_amount @dateStart   = @dateStart,  
								@periodMonth = @periodIter;
	-- ������ ���: �������-����� �� ����������
	exec dbo.sp_CalcABC_ShopItem_count  @dateStart   = @dateStart,  
										@periodMonth = @periodIter;
	-- ������ ���: �������-����� �� �����
	exec dbo.sp_CalcABC_ShopItem_amount @dateStart   = @dateStart,  
										@periodMonth = @periodIter;
										
	set @dateStart   = dateadd( MONTH, @periodIter, @dateStart);
	set @dateFinish  = dateadd(day, -1, dateadd( MONTH, @periodIter, @dateStart));
END
