declare @item float = 176739,--117740, 
        @shop nvarchar(50) = 4,--'����������� ������ �11',
        @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
        @dateFinish  datetime,
        @periodMonth int = 1;
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))        
/*
exec sp_CalcABC_Item_count  @dateStart   = @dateStart,   -- ���� ������ ������� �������
							@periodMonth = @periodMonth; -- ���������� ������� � ������� �������
*/
--truncate table dbo.ABC_�����
select * from dbo.ABC_����� where [������ �������] = @dateStart and [��������� �������] = @dateFinish;
/*
select [��� ������] 
from dbo.ABC_Data 
where [����] between @dateStart and @dateFinish
group by [��� ������]
*/