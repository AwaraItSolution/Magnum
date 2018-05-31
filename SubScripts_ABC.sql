-- ������� ������������� �������. 
/*
[������] - �������. ��������� ����� 
    ��� ������� ������ � ������ ������� � ������� ������������ ������� ������� � ���� ������ �� ������� ������� ���, 
    ������� ������ ������� �� ����, � ������� ������� �� ��� ��� < 1 � ������� �� ���� ���� ������ ������� ������� �� ���� � �������������� �������, 
    ������� ������ ������� �� ����, � ������� ��� ������. ��� ���� ������� ����� �� ������ �� ���������� � ����������� ���� ���� ����������� 
    �������� ��� ������ �� ���� ��� ������� ���, �� ����������� ���, ������� ������������ � ������ � �� ������ �������, 
*/
declare @dateStart   datetime = '2018-02-01', -- ���� ������ ������� �������
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

declare @itemTest float       = 117740, 
        @shopTest varchar(50) = '����������� ������ �11';                -- for test

--I.
/* ��������� ������� ���� SKU ������ ��������� � ����� �������, ��� ����������� �� ��������, � ������� 0 < %������ < 0.5
   �������� ��� ������, ����� ����� ��������� �� �� ������� ���. � ������ ��������� ������ � ������� ��������� ����� ������ �� ����� � ����� ����� ������ < 0.5
   [���-�� ������ �������] �������� � ���� ������� �� �����
*/
/*
with PromoException([���������], [��� ������], [���� ��������� ������]) as
(
 select [���������], [��� ������], sum([���������� ������� �� �����])/iif(sum([���-�� ������ �������]) = 0, 1,
																		  sum([���-�� ������ �������])) as [���� ��������� ������]
   from [dbo].[ABC_Data]
  where [����] between @dateStart and @dateFinish
group by [���������], [��� ������]
 -- ��������� ������ ������ ������� ����� ��������� ������� � ��� ���������� ����� 50% �� ����� ������
 having  (sum([���������� ������� �� �����])/iif(sum([���-�� ������ �������]) = 0, 1,
    									         sum([���-�� ������ �������])) > 0) and 
		 (sum([���������� ������� �� �����])/iif(sum([���-�� ������ �������]) = 0, 1,
										         sum([���-�� ������ �������])) < @promoCoeff)
)
-- ������ � ������� ��� �� ������� ��������� ������
select [����], [������], [�����], [������], [���������], [��� ������]
  from [dbo].[ABC_Data] abc
 where not exists (select 1
                     from PromoException prmExc
                    where abc.��������� = prmExc.[���������] and abc.[��� ������] = prmExc.[��� ������]
					      -- ���� ����� � �bc ����� ����� �� ������ ���������� � ��� ������ ������ ������ �� ������ ���������� � ��� ���� ������� ���������
                          and abc.[���������� ������� �� �����] > 0
				  ) 
*/
--II. ����������� ��������
--II.1 ������� ���������� ������, � ������� "������� �� ����� ��� <= ������������ ���������������� ������ ��� ������� �� ����� ��� < 1"
-- ������ ������� ������� ���������� ���� �� �������� ���� ��� ������� 40% �� ������� ������
--/*
set @minPresentStock = null;
select [����], [������], [�����], [������], [���������], [��� ������]
  from [dbo].[ABC_Data] deficDays
 where ([����] between @dateStart and @dateFinish) and
        (([������� �� ����� (��)] <= isnull(@minPresentStock, -1000000)) or 
         ([������� �� ����� (��)] < @minStock and (1=1)
         ) or exists(select t_now.[����], t_now.[������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������]
					  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
							-- �������� ����, ��� ���������� ����, ��� � ������� ��� ������
							on (t_now.[��� ������] = t_yest.[��� ������]) and (t_now.[����] = dateadd(day,-1,t_yest.[����])
							   ) and 
							   ((t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = t_yest.[���-�� ������ �������]+t_yest.[���������� ������� �� �����]) and 
								(t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = 0)) 
								and t_now.[������] = t_yest.[������]
							-- �������� ����, ��� ��������� ����, ��� � ������� ��� ������
							join [dbo].[ABC_Data] as t_tom
							on (t_now.[��� ������] = t_tom.[��� ������]) and (t_now.[����] = dateadd(day,1,t_tom.[����])
							   ) and 
							   ((t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = t_tom.[���-�� ������ �������]+t_tom.[���������� ������� �� �����]) and 
								(t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = 0))
							   and t_now.[������] = t_tom.[������]
					 where 	deficDays.[����] = t_now.[����] and deficDays.[������] = t_now.[������] and deficDays.[�����] = t_now.[�����] and deficDays.[������] = t_now.[������] and 
							deficDays.[���������] = t_now.[���������] and deficDays.[�����] = t_now.[�����]
							-- ������������ ���������� � ����������� ��� ������� �������� ������ ��������
							and t_yest.[����] between @dateStart and @dateFinish 
							and t_tom.[����]  between @dateStart and @dateFinish 
                    )
        )
   and deficDays.[��� ������] = @itemTest -- for test
   and deficDays.[������] = @shopTest     -- for test
order by [����]                           -- for test
--*/

-- II.2 ������ ������� ������ ������ �� ���� ������ �� ���� ��������. ������ �������������� �� 

-- ���� ���������� ������ � /����������/  �������
--/*
;with DeficitDays ([����], [������], [�����], [������], [���������], [��� ������]) as 
(
select [����], [������], [�����], [������], [���������], [��� ������]
  from [dbo].[ABC_Data] deficDays
 where ([����] between @dateStartPrev and @dateFinishPrev) and
        (([������� �� ����� (��)] <= isnull(@minPresentStock, -1000000) or 
         ([������� �� ����� (��)] < @minStock)) or
         exists(select t_now.[����], t_now.[������], t_now.[�����], t_now.[������], t_now.[���������], t_now.[��� ������]
				  from [dbo].[ABC_Data] as t_now join [dbo].[ABC_Data] as t_yest 
				  -- �������� ����, ��� ���������� ����, ��� � ������� ��� ������
						on (t_now.[��� ������] = t_yest.[��� ������]) and (t_now.[����] = dateadd(day,-1,t_yest.[����])
						   ) and 
						   ((t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = t_yest.[���-�� ������ �������]+t_yest.[���������� ������� �� �����]) and 
							(t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = 0)) 
							and t_now.[������] = t_yest.[������]
						-- �������� ����, ��� ��������� ����, ��� � ������� ��� ������
						join [dbo].[ABC_Data] as t_tom
						on (t_now.[��� ������] = t_tom.[��� ������]) and (t_now.[����] = dateadd(day,1,t_tom.[����])
						   ) and 
						   ((t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = t_tom.[���-�� ������ �������]+t_tom.[���������� ������� �� �����]) and 
							(t_now.[���-�� ������ �������]+t_now.[���������� ������� �� �����] = 0))
						   and t_now.[������] = t_tom.[������]
				 where 	deficDays.[����] = t_now.[����] and deficDays.[������] = t_now.[������] and deficDays.[�����] = t_now.[�����] and deficDays.[������] = t_now.[������] and 
						deficDays.[���������] = t_now.[���������] and deficDays.[�����] = t_now.[�����]
						-- ������������ ���������� � ����������� ��� ������� �������� ������ ��������
						and t_yest.[����] between @dateStartPrev and @dateFinishPrev
						and t_tom.[����]  between @dateStartPrev and @dateFinishPrev
                   )
        )
   and deficDays.[��� ������] = @itemTest  -- for test
   and deficDays.[������] = @shopTest      -- for test
)
select abc.* --abc.[��� ������], avg(abc.[���-�� ������ �������]) as [������� �������, ��.] 
  from [dbo].[ABC_Data] abc 
 where (abc.[����] between @dateStartPrev and @dateFinishPrev ) and
		not exists(select 1 
		             from DeficitDays defDays
		            where abc.[����] = defDays.[����] and abc.[������] = defDays.[������] and abc.[�����] = defDays.[�����] and abc.[������] = defDays.[������] and 
		                  abc.[���������] = defDays.[���������] and abc.[��� ������] = defDays.[��� ������]
                  )
and abc.[��� ������] = @itemTest  -- for test
and abc.[������] = @shopTest      -- for test
--group by abc.[��� ������]
--*/