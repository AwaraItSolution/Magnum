--select * into ABC_Филиал_Товар_back from [dbo].[ABC_Филиал_Товар]
select * from ABC_Филиал_Товар
select * from ABC_Филиал_Товар_back

select COUNT(*) from ABC_Филиал_Товар
select COUNT(*) from ABC_Филиал_Товар_back

INSERT INTO [ABC_Data].[dbo].[ABC_Филиал_Товар]
           ([Начало периода]
           ,[Окончание периода]
           ,[Код филиала]
           ,[Код товара]
           ,[Категория, ед.]
           ,[Категория, сумма])
SELECT [Начало периода]
      ,[Окончание периода]
      ,f.[Код филиала]
      ,[Код товара]
      ,case [Категория, ед.] 
		when 'A' then 0
		when 'B' then 1
		when 'C' then 2
	   end as [Категория, ед.]
      ,case [Категория, сумма]
		when 'A' then 0
		when 'B' then 1
		when 'C' then 2
	   end as [Категория, сумма]
  FROM [ABC_Data].[dbo].[ABC_Филиал_Товар_back] abc_b join dbo.Филиал f on abc_b.[Филиал] = f.Филиал
GO


