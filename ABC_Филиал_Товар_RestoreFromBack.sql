--select * into ABC_������_�����_back from [dbo].[ABC_������_�����]
select * from ABC_������_�����
select * from ABC_������_�����_back

select COUNT(*) from ABC_������_�����
select COUNT(*) from ABC_������_�����_back

INSERT INTO [ABC_Data].[dbo].[ABC_������_�����]
           ([������ �������]
           ,[��������� �������]
           ,[��� �������]
           ,[��� ������]
           ,[���������, ��.]
           ,[���������, �����])
SELECT [������ �������]
      ,[��������� �������]
      ,f.[��� �������]
      ,[��� ������]
      ,case [���������, ��.] 
		when 'A' then 0
		when 'B' then 1
		when 'C' then 2
	   end as [���������, ��.]
      ,case [���������, �����]
		when 'A' then 0
		when 'B' then 1
		when 'C' then 2
	   end as [���������, �����]
  FROM [ABC_Data].[dbo].[ABC_������_�����_back] abc_b join dbo.������ f on abc_b.[������] = f.������
GO


