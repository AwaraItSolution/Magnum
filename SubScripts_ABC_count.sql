-- ������ ��� �� ����������
declare @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
        @dateFinish  datetime,                -- ���� ��������� ������� �������
        @periodMonth     int = 1              -- ���������� ������� � ������� �������
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))
--print @dateFinish
declare @itemTest float       = 55015, 
        @shopTest varchar(50) = '����������� ������ �1';                -- for test

-- ����� merge �� ������� output info
declare @mergeOut table(descript varchar(20), item float, cat_count tinyint, cat_amount tinyint);

-- ������� ������������ ������ �� �������� ������
update dbo.[ABC_�����] set [���������, ��.] = NULL
 where [������ �������] = @dateStart and [��������� �������] = @dateFinish;
      
-- �������� ������� �� ������ ��� ���������� � ��������
with ItemsForABC ([����], [��� �������], [�����], [������], [���������], [��� ������], [���-�� ������ �������], [����� ������ �������]) as (
	select [����], [��� �������], [�����], [������], [���������], [��� ������], [���-�� ������ �������], [����� ������ ������� � ���]
	  from dbo.ABC_Data
	 where [����] between @dateStart and @dateFinish and 
			PromoFail_count = 0 AND Deficit_count = 0
) -- ������ ����������������� [��� ������] � ���������� �� ����� ����� ������
, Items ([��� ������], [���� ������]) as (
	select [��� ������], cast(SUM([���-�� ������ �������]) as float)/iif((select SUM([���-�� ������ �������]) from ItemsForABC)=0,1,
																		  (select SUM([���-�� ������ �������]) from ItemsForABC))
	  from ItemsForABC
	group by [��� ������]
) -- ������ ������ � 
, ItemsA([��� ������], [���� ������]) as (
	select [��� ������], [���� ������]
	  from Items
	 where [���� ������] >= 1./(select count(*) from Items)
) -- ������ ������ BC
, ItemsBC([��� ������], [���� ������]) as (
	select [��� ������], [���� ������]
	  from Items
	 where [���� ������] < 1./(select count(*) from Items)
) -- ������ ������ BC c ������������ ������ ������ ������������ ������ ������ ��
, ItemsBC_pr([��� ������], [���� ������]) as (
	select src.[��� ������], cast(SUM(src.[���-�� ������ �������]) as float)/iif((select SUM(src1.[���-�� ������ �������]) 
																				    from ItemsForABC src1 join ItemsBC bc1 
																					     on src1.[��� ������] = bc1.[��� ������])=0,1,
																				  (select SUM(src1.[���-�� ������ �������]) 
																				     from ItemsForABC src1 join ItemsBC bc1 
																					     on src1.[��� ������] = bc1.[��� ������])
																				) as [���� ������]
	  from ItemsForABC src join ItemsBC bc on src.[��� ������] = bc.[��� ������]
	group by src.[��� ������]
)
, ItemsB([��� ������], [���� ������]) as (
	select [��� ������], [���� ������]
	  from ItemsBC_pr
	 where [���� ������] >= 1./(select count(*) from ItemsBC_pr)
)
, ItemsC([��� ������], [���� ������]) as (
	select [��� ������], [���� ������]
	  from ItemsBC_pr
	 where [���� ������] < 1./(select count(*) from ItemsBC_pr)
)
, ItemsABCbyCount([������ �������],[��������� �������],[��� ������], [���������, ��.]) as (
	select @dateStart, @dateFinish, [��� ������], 0 from ItemsA
	union all
	select @dateStart, @dateFinish, [��� ������], 1 from ItemsB
	union all
	select @dateStart, @dateFinish, [��� ������], 2 from ItemsC
)
/*
merge dbo.[ABC_�����] t
using ItemsABCbyCount s on t.[������ �������]= s.[������ �������] and t.[��������� �������] = s.[��������� �������] and 
				 			t.[��� ������] = s.[��� ������]
when matched
	then update set [���������, ��.] = s.[���������, ��.]
when not matched
	then insert ([������ �������],[��������� �������],[��� ������],[���������, ��.]) 
		 values (s.[������ �������], s.[��������� �������], s.[��� ������], s.[���������, ��.])
output $action as [action],	isnull(Inserted.[��� ������], Deleted.[��� ������]) as [��� ������], 
							isnull(Inserted.[���������, ��.], Deleted.[���������, ��.]) as [���������, ��.],
							isnull(Inserted.[���������, �����], Deleted.[���������, �����]) as [���������, �����]
into @mergeOut;
--*/
--select * from PromoException
select * from Items
--select count(*) from Items   -- ���-�� ������� ��� ������� ��� == 198
--select SUM([���-�� ������ �������]) from ItemsForABC where [��� ������] = @itemTest;
--select * from ItemsGroups;
--select * from ItemsA --where [��� ������] = @itemTest;
--select * from ItemsBC;
--select * from ItemsBC_pr;
--select * from ItemsB;
--select * from ItemsC
--select * from ItemsABCbyCount
