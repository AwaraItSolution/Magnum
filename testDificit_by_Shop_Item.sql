declare @table table(SaleDay smalldatetime, shop varchar(10), item varchar(10), amount int, summa float);
insert into @table values('2018-01-01','AF1','a',2,4)
insert into @table values('2018-01-02','AF1','a',1,2)
insert into @table values('2018-01-03','AF1','a',1,2)
insert into @table values('2018-01-04','AF1','a',3,6)
insert into @table values('2018-01-05','AF1','b',1,2)
insert into @table values('2018-01-06','AF1','b',1,2)
insert into @table values('2018-01-07','AF1','b',1,2)
insert into @table values('2018-01-08','AF1','b',1,2)
insert into @table values('2018-01-09','AF1','c',1,2)
insert into @table values('2018-01-10','AF1','c',1,2)
insert into @table values('2018-01-01','AF2','a',1,2)
insert into @table values('2018-01-02','AF2','a',1,2)
insert into @table values('2018-01-03','AF2','a',1,2)
insert into @table values('2018-01-04','AF2','a',1,2)
insert into @table values('2018-01-05','AF2','b',2,4)
insert into @table values('2018-01-06','AF2','b',2,4)
insert into @table values('2018-01-07','AF2','b',1,2)
insert into @table values('2018-01-08','AF2','b',1,2)
insert into @table values('2018-01-09','AF2','c',8,16)
insert into @table values('2018-01-10','AF2','c',2,4)
select * from @table;

with ItemsParts(shop, item, [���� ������]) as (
select anchor.shop, anchor.item, anchor.amount/ss.shopSum
from(-- ���������� ������ �� �������� � ������� ������� �� ������� ������ � ������ ��������
	 select shop, item, cast(SUM(amount) as float) as amount
	   from @table 
   group by shop, item
	 ) anchor join 
	 (-- ������� ����� ������� �� ��������
	  select shop, SUM(amount) as shopSum
		from @table as subSums
	  group by shop
	 ) ss on anchor.shop = ss.shop
)
, ItemsPartsSubCount(shop, item, [���� ������], [���-�� �������]) as (
select ip.shop, ip.item, ip.[���� ������], ip1.Items
  from ItemsParts ip join
		(select shop, count(*) as Items
		   from ItemsParts
		 group by shop) ip1 on ip.shop = ip1.shop
)
, ItemsA(shop, item, [���������]) as (
select shop, item, [���� ������]
  from ItemsPartsSubCount
 where [���� ������] >= 1./[���-�� �������]
)
, ItemsBC(shop, item, [���� ������]) as (
select shop, item, [���� ������]
  from ItemsPartsSubCount
 where [���� ������] < 1./[���-�� �������]
)
, ItemsBC_pr(shop, item, [���� ������], [���-�� �������]) as (
select anchor.shop, anchor.item, anchor.amount/ss.shopSum as [���� ������], it.shopItems
from(-- ����� ������ ������� ������ �� ������ "��" � ������ ��������
     select src.shop, src.item, cast(SUM(src.amount) as float) as amount
	   from @table src join ItemsBC bc on (src.shop = bc.shop) and (src.item = bc.item)
      group by src.shop, src.item
	 ) anchor join 
	 (-- ����� ������ ���� ������� ������ "��" � ������ ��������
	  select subSums.shop, SUM(subSums.amount) as shopSum
		from @table as subSums join ItemsBC bc1 on (subSums.shop = bc1.shop) and (subSums.item = bc1.item)
	   group by subSums.shop
	 ) ss on anchor.shop = ss.shop join
	 (-- ���-�� ������� ������ "��" � ������ ��������
	  select bc2.shop, count(*) as shopItems
		from ItemsBC bc2 
	  group by bc2.shop 
	 ) it on anchor.shop = it.shop
)
, ItemsB(shop, item, [���������]) as (
select shop, item, [���� ������]
  from ItemsBC_pr 
 where [���� ������] >= 1./[���-�� �������]
)
, ItemsC(shop, item, [���������]) as (
select shop, item, [���� ������]
  from ItemsBC_pr 
 where [���� ������] < 1./[���-�� �������]
)
--select * from ItemsParts
--select * from ItemsPartsSubCount
--select * from ItemsA
--select * from ItemsBC
--select * from ItemsBC_pr
--select * from ItemsB
--select * from ItemsC
select shop,item, 'A' as [���������] from ItemsA
union all
select shop,item, 'B' from ItemsB
union all
select shop,item, 'C' from ItemsC
order by shop, item

/*
, ItemsBC(item, [���� ������]) as (
select item, [���� ������]
  from ItemsParts
 where [���� ������] < 1./(select count(*) from ItemsParts)
)
, ItemBC_pr(item, [���� ������]) as (
select src.item, cast(SUM(src.amount) as float)/(select SUM(src1.amount) from @table src1 join ItemsBC bc1 on src1.item = bc1.item)
  from @table src join ItemsBC bc on src.item = bc.item
group by src.item  
)
, ItemsB(item, [���� ������]) as (
select item, [���� ������]
  from ItemBC_pr
 where [���� ������] >= 1./(select count(*) from ItemBC_pr)
), 
ItemsC(item, [���� ������]) as (
select item, [���� ������]
  from ItemBC_pr
 where [���� ������] < 1./(select count(*) from ItemBC_pr)
)
--select * from ItemsParts
--select * from ItemsA
--select * from ItemsBC
--select * from ItemBC_pr
--select * from ItemsB
--select * from ItemsC
select item, 'A' as [���������] from ItemsA
union all
select item, 'B' from ItemsB
union all
select item, 'C' from ItemsC
*/
/*
-- ����������� ���� �� �������, ������� �������� ����� ��� ������
select t_now.*, t_yest.*, t_tom.*
  from @table as t_now join @table as t_yest 
		-- �������� ����, ��� ���������� ����, ��� � ������� ��� ������
		on (t_now.item = t_yest.item) and (t_now.SaleDay = dateadd(day,-1,t_yest.SaleDay)) and 
			((t_now.amount = t_yest.amount) and (t_now.amount = 0))
		-- �������� ����, ��� ��������� ����, ��� � ������� ��� ������
        join @table as t_tom
		on (t_now.item = t_tom.item) and (t_now.SaleDay = dateadd(day,1,t_tom.SaleDay)) and 
			((t_now.amount = t_tom.amount) and (t_now.amount = 0))


 join
	 (-- ����� ������ ���� ������� ������ "��" � ������ ��������
	  select subSums.shop, SUM(subSums.amount) as shopSum
		from @table as subSums join ItemsBC bc1 on (subSums.shop = bc1.shop) and (subSums.item = bc1.item)
	  group by subSums.shop
	 ) ss on anchor.shop = ss.shop
*/			