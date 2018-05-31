declare @item float = 176739,--117740, 
        @shop nvarchar(50) = 4,--'����������� ������ �11',
        @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
        @dateFinish  datetime,
        @periodMonth int = 1;
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))        
/*
exec sp_DefineDeficit @dateStart   = @dateStart,   -- ���� ������ ������� �������
	                  @periodMonth = @periodMonth; -- ���������� ������� � ������� �������
*/
select [����], [��� �������], [�����], [������], [���������], [��� ������], [���-�� ������ �������], [������� �� ����� (��)], [����� ������ ������� � ���], 
		PromoFail_count, PromoFail_amount, Deficit_count
  from [dbo].[ABC_Data] t_now
 where t_now.[����] between @dateStart and @dateFinish 
--and Deficit_count <> 0
and t_now.[��� ������] = @item
and t_now.[��� �������] = @shop
order by t_now.[����], t_now.[��� �������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������];
/*
with AvgSales([���������],[��� ������],[������ � ����, ��.],[������ � ����, �����]) as (
	select [���������], [��� ������], 
		   avg([���-�� ������ �������])      as [������ � ����, ��.],
		   avg([����� ������ ������� � ���]) as [������ � ����, �����]
	  from [dbo].[ABC_Data]
	where [����] between @dateStart and @dateFinish and [�������] = 0

and [��� ������] = @item
and [��� �������] = @shop

	group by [���������], [��� ������]
)
--select * from AvgSales;
select t_now.[����], t_now.[��� �������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������], [���-�� ������ �������], [����� ������ ������� � ���]
  from [dbo].[ABC_Data] t_now join AvgSales avSl 
		on t_now.[���������] = avSl.[���������] and t_now.[��� ������] = avSl.[��� ������]
 where t_now.[����] between @dateStart and @dateFinish and [�������] = 0 and 
		t_now.[������� �� ����� (��)] < 1 and (t_now.[���-�� ������ �������] < avSl.[������ � ����, ��.] * 0.4) 
and t_now.[��� ������] = @item
and t_now.[��� �������] = @shop
order by t_now.[����], t_now.[��� �������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������]
*/