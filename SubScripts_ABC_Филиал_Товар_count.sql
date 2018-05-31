-- ������ ��� ��� �������� �� ����������
declare @dateStart   datetime = '2018-03-01', -- ���� ������ ������� �������
        @dateFinish  datetime,                -- ���� ��������� ������� �������
        @periodMonth     int = 1,             -- ���������� ������� � ������� �������
        @promoCoeff      float = 0.5,         -- ���� ��������� ������
        @minPresentStock float = 0,           -- ����������� ��������������� �����. �������� �� ��� �� ���-�� �������
        @minStock        float = 1;           -- ����������� ������� �� ����� ���
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))

declare @itemTest float       = 54993, 
        @shopTest varchar(50) = '����������� ������ �1';                -- for test

-- ������� ������������ ������ �� �������� ������
--delete from dbo.[ABC_������_�����] where [������ �������] = @dateStart and [��������� �������] = @dateFinish;
     
--/* �������� �������, ������������� �� ���, �� ������� ����������� ���
;with PromoException([���������], [��� ������], [���� ��������� ������]) as
(
 select [���������], [��� ������], sum([���������� ������� �� �����])/iif(sum([���-�� ������ �������]) = 0, 1,
																		  sum([���-�� ������ �������])) as [���� ��������� ������]
   from [dbo].[ABC_Data]
  where [����] between @dateStart and @dateFinish
--and [������] = @shopTest
group by [���������], [��� ������]
 -- ��������� ������ ������ ������� ����� ��������� ������� � ��� ���������� ����� 50% �� ����� ������
 having  (sum([���������� ������� �� �����])/iif(sum([���-�� ������ �������]) = 0, 1,
    									         sum([���-�� ������ �������])) > 0) and 
		 (sum([���������� ������� �� �����])/iif(sum([���-�� ������ �������]) = 0, 1,
										         sum([���-�� ������ �������])) < @promoCoeff)
)
, ItemsForABC ([����], [������], [�����], [������], [���������], [��� ������], [���-�� ������ �������]) as (
-- ������ � ������� ���, ��������� �� ��������� ������ � �������� (��� ��). ����� �������������� ��� �������� [���� ������] ��� ����� BC.
select [����], [������], [�����], [������], [���������], [��� ������], [���-�� ������ �������]
  from [dbo].[ABC_Data] abc
 where --[������] = @shopTest and  
       not exists (select 1
                     from PromoException prmExc
                    where abc.��������� = prmExc.[���������] and abc.[��� ������] = prmExc.[��� ������]
					      -- ���� ����� � �bc ����� ����� �� ������ ���������� � ��� ������ ������ ������ �� ������ ���������� � ��� ���� ������� ���������
                          and abc.[���������� ������� �� �����] > 0
				  ) 
) -- ������ ����������������� [��� ������] � ���������� �� ����� ����� ������ [���� ������]
, Items ([������], [��� ������], [���� ������]) as (
select anchor.[������], anchor.[��� ������], anchor.[���-�� ������ �������]/ss.shopSum
from (select abc.[������], abc.[��� ������], cast(SUM(abc.[���-�� ������ �������]) as float) as [���-�� ������ �������]
	    from ItemsForABC abc
	   group by abc.[������], abc.[��� ������]
	 ) anchor join 
	 (select subSums.[������], SUM(subSums.[���-�� ������ �������]) as shopSum
	    from ItemsForABC subSums
	   group by subSums.[������]
	 ) ss on anchor.[������] = ss.[������]
)-- ������������ ��������� ������� ������� ������ �� �������� ����� ���� ������ ����������
, ItemsPartsSubCount([������], [��� ������], [���� ������], [���-�� �������]) as (
select ip.[������], ip.[��� ������], ip.[���� ������], ip1.itm_cnt
  from Items ip join
		(select [������], count(*) as itm_cnt
		   from Items
		 group by [������]) ip1 on ip.[������] = ip1.[������]
)
-- ������ ������ � 
, ItemsA([������], [��� ������], [���� ������]) as (
select [������], [��� ������], [���� ������]
  from ItemsPartsSubCount
 where [���� ������] >= 1./[���-�� �������]
) -- ������ ������ BC
, ItemsBC([������], [��� ������], [���� ������]) as (
select [������], [��� ������], [���� ������]
  from ItemsPartsSubCount
 where [���� ������] < 1./[���-�� �������]
) -- ������ ������ BC c ������������ ������ ������ ������������ ������ ������ ��
, ItemsBC_pr([������], [��� ������], [���� ������], [���-�� �������]) as (
select anchor.[������], anchor.[��� ������], anchor.[���-�� ������ �������]/iif(ss.shopSum=0,1,ss.shopSum) as [���� ������], 
		it.shopItems
from(-- ����� ������ ������� ������ �� ������ "��" � ������ ��������
     select src.[������], src.[��� ������], cast(SUM(src.[���-�� ������ �������]) as float) as [���-�� ������ �������]
	   from ItemsForABC src join ItemsBC bc on (src.[������] = bc.[������]) and (src.[��� ������] = bc.[��� ������])
      group by src.[������], src.[��� ������]
	 ) anchor join 
	 (-- ����� ������ ���� ������� ������ "��" � ������ ��������
	  select subSums.[������], SUM(subSums.[���-�� ������ �������]) as shopSum
		from ItemsForABC as subSums join ItemsBC bc1 on (subSums.[������] = bc1.[������]) and (subSums.[��� ������] = bc1.[��� ������])
	   group by subSums.[������]
	 ) ss on anchor.[������] = ss.[������] join
	 (-- ���-�� ������� ������ "��" � ������ ��������
	  select bc2.[������], count(*) as shopItems
		from ItemsBC bc2 
	  group by bc2.[������] 
	 ) it on anchor.[������] = it.[������]
)
, ItemsB([������], [��� ������], [���� ������]) as (
select [������], [��� ������], [���� ������]
  from ItemsBC_pr 
 where [���� ������] >= 1./[���-�� �������]
)
, ItemsC([������], [��� ������], [���� ������]) as (
select [������], [��� ������], [���� ������]
  from ItemsBC_pr 
 where [���� ������] < 1./[���-�� �������]
)
--select * from ItemsForABC
--select * from Items
--select * from ItemsPartsSubCount
--select * from PromoException
--select count(*) from Items   -- ���-�� ������� ��� ������� ��� == 198
--select SUM([���-�� ������ �������]) from ItemsForABC where [��� ������] = @itemTest;
--select * from ItemsA where [��� ������] = @itemTest;
--select * from ItemsBC;
--select * from ItemsBC_pr;
--select * from ItemsB;
--select * from ItemsC
--order by [������], [��� ������]

insert into dbo.[ABC_������_�����] ([������ �������], [��������� �������], [������], [��� ������], [���������, ��.], [���������, �����])
select @dateStart, @dateFinish, [������], [��� ������], 'A', '' from ItemsA
union all
select @dateStart, @dateFinish, [������], [��� ������], 'B', '' from ItemsB
union all
select @dateStart, @dateFinish, [������], [��� ������], 'C', '' from ItemsC;
