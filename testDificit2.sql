declare @dateStart   datetime = '2018-01-01', -- ���� ������ ������� �������
        @dateFinish  datetime,                -- ���� ��������� ������� �������
        @dateStartPrev   datetime,			  -- ���� ������ ������� ��������������� �������
        @dateFinishPrev  datetime,			  -- ���� ��������� ������� ��������������� �������
        @periodMonth     int = 1,             -- ���������� ������� � ������� �������
        @promoCoeff      float = 0.5,         -- ���� ��������� ������
        @minPresentStock float = 0,           -- ����������� ��������������� �����. �������� �� ��� �� ���-�� �������
        @minStock        float = 1;           -- ����������� ������� �� ����� ���
set @dateFinish = dateadd(second, -1, dateadd( MONTH, @periodMonth, @dateStart))
set @dateStartPrev = dateadd( MONTH, -@periodMonth, @dateStart);
set @dateFinishPrev= dateadd( MONTH, -@periodMonth, @dateFinish);
-- print @dateFinish
-- print @dateStartPrev
-- print @dateFinishPrev

/* ������ ������� ������� ���������� ���� �� ��������
if (@minStock <= @minPresentStock)
  set @maxOfMinStock = @minPresentStock + 0.000001
else
  set @maxOfMinStock = @minStock;
-- �������� ������, � ������� [������� �� ����� (��)] < 1 ��� <= @minPresentStock ������������ ���������������� ������, ����� ����� ��������� �� �� ������ �������
select [����], [��� �������], [�����], [������], [���������], [��� ������]--, count(*) as [������� �� �������]
  from [dbo].[ABC_Data]
 where [������� �� ����� (��)] < @maxOfMinStock
*/

/*
-- ����������� ��������� ���� ������������� ������. �������� ���������� ����������, ��� (������� + �����)
select t_now.[����], t_now.[��� �������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������]--, t_now.[���-�� ������ �������], t_now.[���������� ������� �� �����]
  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
		-- �������� ����, ��� ���������� ����, ��� � ������� ��� ������
		on (t_now.[��� ������] = t_yest.[��� ������]) and (t_now.[����] = dateadd(day,-1,t_yest.[����])
		   ) and 
		   ((t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = t_yest.[���-�� ������ �������]+t_yest.[���������� ������� �� �����]) and 
		    (t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = 0)) 
		    and t_now.[��� �������] = t_yest.[��� �������]
		-- �������� ����, ��� ��������� ����, ��� � ������� ��� ������
        join [dbo].[ABC_Data] as t_tom
		on (t_now.[��� ������] = t_tom.[��� ������]) and (t_now.[����] = dateadd(day,1,t_tom.[����])
		   ) and 
		   ((t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = t_tom.[���-�� ������ �������]+t_tom.[���������� ������� �� �����]) and 
		    (t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = 0))
		   and t_now.[��� �������] = t_tom.[��� �������]
where t_now.[����] between @dateStart and @dateFinish
--and t_now.[��� ������] = '10721' and t_now.[��� �������] = '����������� ������ �1'
--order by t_now.[����], t_now.[��� �������], t_now.[��� ������]
*/
/*
select [��� ������], sum([���-�� ������ �������]), count(*), AVG([���-�� ������ �������]) as [������� �������] --deficDays.*
  from [dbo].[ABC_Data] deficDays
 where ([����] between @dateStartPrev and @dateFinishPrev) 
   and deficDays.[��� ������] = 137113				-- for test
   and deficDays.[��� �������] = '����������� ������ �1'	-- for test
group by [��� ������]
*/
/*
-- ����� ������� ������� �� ������
select [��� ������],sum([���-�� ������ �������] + [���������� ������� �� �����]) as [����� ���-�� ������]
--				   ,count(*) as [���-�� ���� ������]
  from [dbo].[ABC_Data]
 where [����] between @dateStart and @dateFinish
group by [��� ������]
*/
--II. ����������� ��������
--II.1 ������� ���������� ������, � ������� "������� �� ����� ��� <= ������������ ���������������� ������ ��� ������� �� ����� ��� < 1"
-- ������ ������� ������� ���������� ���� �� �������� ���� ��� ������� 40% �� ������� ������
--/*
select deficDays.[����], deficDays.[��� �������], deficDays.[�����], deficDays.[������], deficDays.[���������], deficDays.[��� ������], 
		deficDays.[���-�� ������ �������], deficDays.[������� �� ����� (��)] --count(*) as [������� �� �������]
  from [dbo].[ABC_Data] deficDays
 where (deficDays.[����] between @dateStart and @dateFinish) and
       ((([������� �� ����� (��)] <= @minPresentStock) or 
         ([������� �� ����� (��)] < 1 and (1=1))
        ) 
     -- /*
       or
        exists( select 1--t_now.[����], t_now.[��� �������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������]
				  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
						-- �������� ����, ��� ���������� ����, ��� � ������� ��� ������
						on (t_now.[����] = dateadd(day,-1,t_yest.[����])) and (t_now.[��� �������] = t_yest.[��� �������]) and
						   (t_now.[�����] = t_yest.[�����]) and (t_now.[������] = t_yest.[������]) and
						   (t_now.[���������] = t_yest.[���������]) and (t_now.[��� ������] = t_yest.[��� ������]) and 
						   
						   (t_now.[���-�� ������ �������] = t_yest.[���-�� ������ �������]) and 
						   (t_now.[���-�� ������ �������] = 0)
						-- �������� ����, ��� ��������� ����, ��� � ������� ��� ������
						join [dbo].[ABC_Data] as t_tom
						on (t_now.[����] = dateadd(day,1,t_tom.[����])) and (t_now.[��� �������] = t_tom.[��� �������]) and
						   (t_now.[�����] = t_tom.[�����]) and (t_now.[������] = t_tom.[������]) and
						   (t_now.[���������] = t_tom.[���������]) and (t_now.[��� ������] = t_tom.[��� ������]) and 

						   (t_now.[���-�� ������ �������] = t_tom.[���-�� ������ �������]) and 
						   (t_now.[���-�� ������ �������] = 0)
				 where 	deficDays.[����] = t_now.[����] and deficDays.[��� �������] = t_now.[��� �������] and deficDays.[�����] = t_now.[�����] and deficDays.[������] = t_now.[������] and 
						deficDays.[���������] = t_now.[���������] and deficDays.[�����] = t_now.[�����]
						-- ������������ ���������� � ����������� ��� ������� �������� ������ ��������
						and t_yest.[����] between @dateStart and @dateFinish 
						and t_tom.[����]  between @dateStart and @dateFinish 
                )
       )
               -- */
   and deficDays.[��� ������] = 117740				-- for test
   and deficDays.[��� �������] = 4--'����������� ������ �11'-- for test
order by deficDays.[����], deficDays.[��� �������], deficDays.[�����], deficDays.[������], deficDays.[���������], deficDays.[��� ������]
--*/

-- ���� ���������� ������ � ���������� �������
/*
;with DeficitDays ([����], [��� �������], [�����], [������], [���������], [��� ������]) as 
(
select [����], [��� �������], [�����], [������], [���������], [��� ������]
  from [dbo].[ABC_Data] deficDays
 where ([����] between @dateStartPrev and @dateFinishPrev) and
        (([������� �� ����� (��)] <= @minPresentStock) or 
         ([������� �� ����� (��)] < @minStock) or
         exists(select t_now.[����], t_now.[��� �������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������]
				  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
				  -- �������� ����, ��� ���������� ����, ��� � ������� ��� ������
						on (t_now.[��� ������] = t_yest.[��� ������]) and (t_now.[����] = dateadd(day,-1,t_yest.[����])
						   ) and 
						   ((t_now.[���-�� ������ �������] = t_yest.[���-�� ������ �������]) and 
							(t_now.[���-�� ������ �������] = 0)) 
							and t_now.[��� �������] = t_yest.[��� �������]
						-- �������� ����, ��� ��������� ����, ��� � ������� ��� ������
						join [dbo].[ABC_Data] as t_tom
						on (t_now.[��� ������] = t_tom.[��� ������]) and (t_now.[����] = dateadd(day,1,t_tom.[����])
						   ) and 
						   ((t_now.[���-�� ������ �������] = t_tom.[���-�� ������ �������]) and 
							(t_now.[���-�� ������ �������] = 0))
						   and t_now.[��� �������] = t_tom.[��� �������]
				 where 	deficDays.[����] = t_now.[����] and deficDays.[��� �������] = t_now.[��� �������] and deficDays.[�����] = t_now.[�����] and deficDays.[������] = t_now.[������] and 
						deficDays.[���������] = t_now.[���������] and deficDays.[�����] = t_now.[�����]
						-- ������������ ���������� � ����������� ��� ������� �������� ������ ��������
						and t_yest.[����] between @dateStartPrev and @dateFinishPrev
						and t_tom.[����]  between @dateStartPrev and @dateFinishPrev
                   )
        )
--   and deficDays.[��� ������] = 137113				-- for test
--   and deficDays.[��� �������] = '����������� ������ �1'	-- for test
)
select abc.[��� ������], avg(abc.[���-�� ������ �������]) as [������� �������, ��.] --abc.* --
  from [dbo].[ABC_Data] abc 
 where (abc.[����] between @dateStartPrev and @dateFinishPrev ) and
		not exists(select 1 
		             from DeficitDays defDays
		            where abc.[����] = defDays.[����] and abc.[��� �������] = defDays.[��� �������] and abc.[�����] = defDays.[�����] and abc.[������] = defDays.[������] and 
		                  abc.[���������] = defDays.[���������] and abc.[��� ������] = defDays.[��� ������]
                  )
--and abc.[��� ������] = 137113                -- for test
--and abc.[��� �������] = '����������� ������ �1'   -- for test
group by abc.[��� ������]
*/