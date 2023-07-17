use [myservice]
go 

--CLIENTS
--CREATE

declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'Пётр' as [firstname],
				  'Петров' as [lastname],
				  'petrov4@gmail.com' as [email],
				  '79290309687' as [phone],
				  '27.03.1995' as [dob]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'client.create', @js, @rp out

select @rp
select * from [dbo].[clients]
go
-------------------------------------------------------------
--GET

declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '79290309687' as [phone]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'client.get', @js, @rp out

select @rp
select * from [dbo].[clients]

go
-------------------------------------------------------------
--EDIT по id, можно изменить имя, фамилию, номер телефона, email, дату рождения

declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '2BA26C0F-2D37-49D4-B3EF-A9C5CF5844F1' as [id],
				  'Пётруха' as [firstname],
				  'Петровкин' as [lastname],
				  'petrov344@gmail.com' as [email],
				  '79290309587' as [phone],
				  '29.03.1995' as [dob]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'client.edit', @js, @rp out

select @rp
select * from [dbo].[clients]

go
-------------------------------------------------------------
--DEACTIVE

