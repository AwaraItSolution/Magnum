-- ������ ��� ��� ������� �� ����������
declare @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
        @dateFinish  datetime,                -- ���� ��������� ������� �������
        @periodMonth     int = 1,             -- ���������� ������� � ������� �������
        @promoCoeff      float = 0.5,         -- ���� ��������� ������
        @minPresentStock float = 0,           -- ����������� ��������������� �����. �������� �� ��� �� ���-�� �������
        @minStock        float = 1;           -- ����������� ������� �� ����� ���
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))
--print @dateFinish
declare @itemTest float = 54849,--117740, 
        @shopTest int   = 3--4--'����������� ������ �11'
        
/*select * from dbo.������*/

select [����], [��� �������], [��� ������], [���-�� ������ �������], [������� �� ����� (��)], PromoFail_count,PromoFail_amount,Deficit_count, [����� ������ ������� � ���]
  from dbo.ABC_Data
 where [����] between @dateStart and @dateFinish
and [��� �������] = @shopTest 
and [��� ������] = @itemTest;
			
select *--[����], [��� �������], [�����], [������], [���������], [��� ������], [���-�� ������ �������], [����� ������ ������� � ���]
  from dbo.ABC_������_�����
 where [������ �������] = @dateStart and [��������� �������] = @dateFinish 
--and not ([���������, �����] IS NULL)
and [��� �������] = @shopTest 
and [��� ������] = @itemTest;

--/* �������� �������, ������������� �� ���, �� ������� ����������� ���
;with ItemsForABC ([����], [��� �������], [�����], [������], [���������], [��� ������], [���-�� ������ �������], [����� ������ �������]) as (
	select [����], [��� �������], [�����], [������], [���������], [��� ������], [���-�� ������ �������], [����� ������ ������� � ���]
	  from dbo.ABC_Data
	 where [����] between @dateStart and @dateFinish and 
			PromoFail_count = 0 AND Deficit_count = 0
) -- ����������. ���� ������ ������ ������������ ���� ������
, Items ([��� ������], [���� ������]) as (
select [��� ������], cast(SUM([���-�� ������ �������]) as float)/(select SUM([���-�� ������ �������]) from ItemsForABC)
  from ItemsForABC
group by [��� ������]
) -- �����. ���� ������ ������ ������������ ���� ������
, ItemsByAmount ([��� ������], [���� ������]) as (
select [��� ������], cast(SUM([����� ������ �������]) as float)/(select SUM([����� ������ �������]) from ItemsForABC)
  from ItemsForABC
group by [��� ������]
)
, ItemsBC([��� ������], [���� ������]) as (
select [��� ������], [���� ������]
  from Items
 where [���� ������] < 1./(select count(*) from Items)
) -- ������ ������ BC c ������������ ������ ������ ������������ ������ ������ ��
, ItemsBC_pr([��� ������], [���� ������]) as (
select src.[��� ������], cast(SUM(src.[���-�� ������ �������]) as float)/(select SUM(src1.[���-�� ������ �������]) 
                                                                            from ItemsForABC src1 join ItemsBC bc1 
                                                                                  on src1.[��� ������] = bc1.[��� ������])
  from ItemsForABC src join ItemsBC bc on src.[��� ������] = bc.[��� ������]
 where bc.[��� ������] = @itemTest
group by src.[��� ������]
)
, ItemsBCbyAmount([��� ������], [���� ������]) as (
select [��� ������], [���� ������]
  from ItemsByAmount
 where [���� ������] < 1./(select count(*) from ItemsByAmount)
)
, ItemsBC_prByAmount([��� ������], [���� ������]) as (
select src.[��� ������], cast(SUM(src.[����� ������ �������]) as float)/(select SUM(src1.[����� ������ �������]) 
                                                                            from ItemsForABC src1 join ItemsBCbyAmount bc1 
                                                                                  on src1.[��� ������] = bc1.[��� ������])
  from ItemsForABC src join ItemsBCbyAmount bc on src.[��� ������] = bc.[��� ������]
 where bc.[��� ������] = @itemTest
group by src.[��� ������]
) -- ������ ������ BC c ������������ ������ ������ ������������ ������ ������ ��
, ItemsB([��� ������], [���� ������], [���-�� �������], [���������]) as (
select [��� ������], [���� ������], (select count(*) from ItemsBC_pr), 'B'
  from ItemsBC_pr
 where [���� ������] >= 1./(select count(*) from ItemsBC_pr)
)
, ItemsBbyAmount([��� ������], [���� ������], [���-�� �������], [���������]) as (
select [��� ������], [���� ������], (select count(*) from ItemsBC_prByAmount), 'B'
  from ItemsBC_prByAmount
 where [���� ������] >= 1./(select count(*) from ItemsBC_prByAmount)
),
ItemsC([��� ������], [���� ������], [���-�� �������], [���������]) as (
select [��� ������], [���� ������], (select count(*) from ItemsBC_pr), 'C'
  from ItemsBC_pr
 where [���� ������] < 1./(select count(*) from ItemsBC_pr)
),
ItemsCbyAmount([��� ������], [���� ������], [���-�� �������], [���������]) as (
select [��� ������], [���� ������], (select count(*) from ItemsBC_prByAmount), 'C'
  from ItemsBC_prByAmount
 where [���� ������] < 1./(select count(*) from ItemsBC_prByAmount)
)
select '�� ���-��' as [�������], [��� ������], [���� ������], 1./(select count(*) from Items) as [���-�� �������],
		case when [���� ������] > 1./(select count(*) from Items) then 'A'
		else 'BC'
		end as [���������]
  from Items where [��� ������] = @itemTest
UNION ALL
--/*
select '�� �����' as [�������], [��� ������], [���� ������], 1./(select count(*) from Items),
		case when [���� ������] > 1./(select count(*) from Items) then 'A'
		else 'BC'
		end as [���������]
  from ItemsByAmount where [��� ������] = @itemTest
--*/
UNION ALL
select '�� ���-��', [��� ������], [���� ������], [���-�� �������], [���������]
  from ItemsB
UNION ALL  
select '�� �����', [��� ������], [���� ������], [���-�� �������], [���������]
  from ItemsBbyAmount
UNION ALL
select '�� ���-��', [��� ������], [���� ������], [���-�� �������], [���������]
  from ItemsC
UNION ALL  
select '�� �����', [��� ������], [���� ������], [���-�� �������], [���������]
  from ItemsCbyAmount  