-- ������ ��� ��� ������� �� ����������
declare @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
        @dateFinish  datetime,                -- ���� ��������� ������� �������
        @periodMonth     int = 3,             -- ���������� ������� � ������� �������
        @promoCoeff      float = 0.5,         -- ���� ��������� ������
        @minPresentStock float = 0,           -- ����������� ��������������� �����. �������� �� ��� �� ���-�� �������
        @minStock        float = 1;           -- ����������� ������� �� ����� ���
set @dateFinish = dateadd(day, -1, dateadd( MONTH, @periodMonth, @dateStart))
--print @dateFinish
declare @itemTest float       = 55015, 
        @shopTest varchar(50) = '����������� ������ �1';                -- for test

-- ������� ������������ ������ �� �������� ������
delete from dbo.[ABC_�����] where [������ �������] = @dateStart and [��������� �������] = @dateFinish;
     
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
, ItemsForABC ([����], [������], [�����], [������], [���������], [��� ������], [���-�� ������ �������], [����� ������ �������]) as (
-- ������ � ������� ���, ��������� �� ��������� ������ � �������� (��� ��). ����� �������������� ��� �������� [���� ������] ��� ����� BC.
select [����], [������], [�����], [������], [���������], [��� ������], [���-�� ������ �������], [����� ������ ������� � ���]
  from [dbo].[ABC_Data] abc
 where --[������] = @shopTest and  
       not exists (select 1
                     from PromoException prmExc
                    where abc.��������� = prmExc.[���������] and abc.[��� ������] = prmExc.[��� ������]
					      -- ���� ����� � �bc ����� ����� �� ������ ���������� � ��� ������ ������ ������ �� ������ ���������� � ��� ���� ������� ���������
                          and abc.[���������� ������� �� �����] > 0
				  ) 
) -- ������ ����������������� [��� ������] � ���������� �� ����� ����� ������
, Items ([��� ������], [���� ������]) as (
select [��� ������], cast(SUM([���-�� ������ �������]) as float)/(select SUM([���-�� ������ �������]) from ItemsForABC)
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
select src.[��� ������], cast(SUM(src.[���-�� ������ �������]) as float)/(select SUM(src1.[���-�� ������ �������]) 
                                                                            from ItemsForABC src1 join ItemsBC bc1 
                                                                                  on src1.[��� ������] = bc1.[��� ������])
  from ItemsForABC src join ItemsBC bc on src.[��� ������] = bc.[��� ������]
group by src.[��� ������]
)
, ItemsB([��� ������], [���� ������]) as (
select [��� ������], [���� ������]
  from ItemsBC_pr
 where [���� ������] >= 1./(select count(*) from ItemsBC_pr)
), 
ItemsC([��� ������], [���� ������]) as (
select [��� ������], [���� ������]
  from ItemsBC_pr
 where [���� ������] < 1./(select count(*) from ItemsBC_pr)
)
--select * from PromoException
--select * from Items
--select count(*) from Items   -- ���-�� ������� ��� ������� ��� == 198
--select SUM([���-�� ������ �������]) from ItemsForABC where [��� ������] = @itemTest;
--select * from ItemsGroups;
--select * from ItemsA where [��� ������] = @itemTest;
--select * from ItemsBC;
--select * from ItemsBC_pr;
--select * from ItemsB;
--select * from ItemsC
insert into dbo.[ABC_�����] ([������ �������], [��������� �������], [��� ������], [���������, ��.], [���������, �����])
select @dateStart, @dateFinish, [��� ������], 'A', '' from ItemsA
union all
select @dateStart, @dateFinish, [��� ������], 'B', '' from ItemsB
union all
select @dateStart, @dateFinish, [��� ������], 'C', '' from ItemsC;
