declare @item float = 117740, 
        @shop nvarchar(50)=4,--'����������� ������ �11',
        @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
        @dateFinish  datetime,
        @dateStartPrev   datetime,			  -- ���� ������ ������� ��������������� �������
        @dateFinishPrev  datetime,			  -- ���� ��������� ������� ��������������� �������
        @periodMonth int = 1;
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))
set @dateStartPrev = dateadd( MONTH, -@periodMonth, @dateStart);
set @dateFinishPrev= dateadd( MONTH, -@periodMonth, @dateFinish);
 print @dateFinish
-- print @dateStartPrev
-- print @dateFinishPrev  

--select top(10) * from dbo.ABC_Data where [����] between @dateStart and @dateFinish and [������� �� ����� (��)] < 1      
--/*
select [��� ������], sum([���-�� ������ �������]) as [���-�� ������ �������], sum([���������� ������� �� �����]) as [���������� ������� �� �����], COUNT(*)
from dbo.ABC_Data
where [����] between @dateStart and @dateFinish 
and [��� ������] = @item
and [��� �������] = @shop
group by [���������], [��� ������]
--*/
-- ��� ������ �� ������ �� ������
select ����, [��� �������], �����, ������, ���������, [��� ������], �����, [���-�� ������ �������], [���������� ������� �� �����], [������� �� ����� (��)]
from dbo.ABC_Data
where [����] between @dateStart and @dateFinish 
and [��� ������] = @item 
and [��� �������] = @shop
--and (([���������� ������� �� �����] > 0))
--and ([���-�� ������ �������] <> [���������� ������� �� �����])

--/*
select t_now.[����], t_now.[��� �������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������], t_now.[���-�� ������ �������], t_now.[���������� ������� �� �����]
  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
		-- �������� ����, ��� ���������� ����, ��� � ������� ��� ������
		on (t_now.[����] = dateadd(day,-1,t_yest.[����])) and (t_now.[��� �������] = t_yest.[��� �������]) and
		   (t_now.[�����] = t_yest.[�����]) and (t_now.[������] = t_yest.[������]) and
		   (t_now.[���������] = t_yest.[���������]) and (t_now.[��� ������] = t_yest.[��� ������]) and 
		
		   (t_now.[���-�� ������ �������] = isnull(t_yest.[���-�� ������ �������],0))
		-- �������� ����, ��� ��������� ����, ��� � ������� ��� ������
        join [dbo].[ABC_Data] as t_tom
		on (t_now.[����] = dateadd(day,1,t_tom.[����])) and (t_now.[��� �������] = t_tom.[��� �������]) and
		   (t_now.[�����] = t_tom.[�����]) and (t_now.[������] = t_tom.[������]) and
		   (t_now.[���������] = t_tom.[���������]) and (t_now.[��� ������] = t_tom.[��� ������]) and 

		   (t_now.[���-�� ������ �������] = isnull(t_tom.[���-�� ������ �������],0))
where t_now.[����] between @dateStart and @dateFinish and
	   t_now.[���-�� ������ �������] = 0
and t_now.[��� ������] = @item 
and t_now.[��� �������] = @shop
order by t_now.[����], t_now.[��� �������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������]
--*/