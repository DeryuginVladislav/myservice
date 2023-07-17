use [myservice]
go 

--CLIENTS
--CREATE

declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'Пётр' as [firstname],
				  'Петров' as [lastname],
				  'petrov54@gmail.com' as [email],
				  '79290309087' as [phone],
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

set @js = (select	null as [id],
					'79290309087' as [phone],
					null as [email]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'client.get', @js, @rp out

select @rp
select * from [dbo].[clients]

go
-------------------------------------------------------------
--EDIT по id, можно изменить имя, фамилию, номер телефона, email, дату рождения

declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '0957F43C-8E4F-40BE-A2E0-6A03C1D76A40' as [id],
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
--DEACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '0957F43C-8E4F-40BE-A2E0-6A03C1D76A40' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'client.deactive', @js, @rp out

select @rp
select * from [dbo].[clients]

go
-------------------------------------------------------------
--ACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '0957F43C-8E4F-40BE-A2E0-6A03C1D76A40' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'client.active', @js, @rp out

select @rp
select * from [dbo].[clients]

go


-------------------------DIETS---------------------------------
--CREATE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'Сыроедение' as [name],
				  null as [description]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'diet.create', @js, @rp out

select @rp
select * from [dbo].[diets]
go

-------------------------------------------------------------
--GET по id или названию диеты
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select	null as [id],
					'Сыроедение' as [name]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'diet.get', @js, @rp out

select @rp
select * from [dbo].[diets]
go
-------------------------------------------------------------
--EDIT name, description
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '91262F97-5B65-4A8D-839A-A599EDD059DA' as [id],
				  null as [name],
				  'Едят сыр' as [description]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'diet.edit', @js, @rp out

select @rp
select * from [dbo].[diets]
go
-------------------------------------------------------------
--DEACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '073C33FE-C3D2-44D9-B89D-7D01593F2B17' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'diet.deactive', @js, @rp out

select @rp
select * from [dbo].[diets]
go
-------------------------------------------------------------
--ACTIVE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '81B24020-539A-4FB1-9BED-D871C1BFDC2C' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'diet.active', @js, @rp out

select @rp
select * from [dbo].[diets]
go

-------------------------CLIENTS_DIET---------------------------------
--CREATE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '48FA1343-11E8-4343-994F-280F0205C6F0' as [client_id],
				  '91262F97-5B65-4A8D-839A-A599EDD059DA' as [diet_id]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'client_diet.create', @js, @rp out

select @rp
select * from [dbo].[clients_diet]
go
-------------------------------------------------------------
--GET по id, client_id, client_id + diet_id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select null as [id],
				  '48FA1343-11E8-4343-994F-280F0205C6F0' as [client_id]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'client_diet.get', @js, @rp out

select @rp
select * from [dbo].[clients_diet]
go
-------------------------------------------------------------
--DEACTIVE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'B83D8DE9-8780-4743-BCFF-1EC7F40548A2' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'client_diet.deactive', @js, @rp out

select @rp
select * from [dbo].[clients_diet]
go

-------------------------RESTAURANT---------------------------------
--CREATE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'veggie bro' as [name],
				  'Vladimir' as [address],
				  '89290347687' as [phone],
				  'dasdasf@mail.ru' as [email],
				  '12:00' as [work_start],
				  '22:00' as [work_end]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'restaurant.create', @js, @rp out

select @rp
select * from [dbo].[restaurants]
go
-------------------------------------------------------------
--GET по id, name + address, phone, email
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '8780655F-A9B3-43C2-9279-9E69DF745A61' as [id],
				  null as [name],
				  null as [address],
				  null as [phone],
				  null as [email]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'restaurant.get', @js, @rp out

select @rp
select * from [dbo].[restaurants]
go
-------------------------------------------------------------
--EDIT по id, 
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '8780655F-A9B3-43C2-9279-9E69DF745A61' as [id],
				  null as [name],
				  'Владимир Большая Московская' as [address],
				  null as [phone],
				  null as [email],
				  null as [work_start],
				  null as [work_end]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'restaurant.edit', @js, @rp out

select @rp
select * from [dbo].[restaurants]

go
-------------------------------------------------------------
--DEACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '8780655F-A9B3-43C2-9279-9E69DF745A61' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'restaurant.deactive', @js, @rp out

select @rp
select * from [dbo].[restaurants]

go
-------------------------------------------------------------
--ACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '8780655F-A9B3-43C2-9279-9E69DF745A61' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'restaurant.active', @js, @rp out

select @rp
select * from [dbo].[restaurants]

go


-------------------------DISH---------------------------------
--CREATE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'фалафель ролл' as [name],
				  '8780655F-A9B3-43C2-9279-9E69DF745A61' as [restaurant_id],
				  'ролл с фалафелем' as [description],
				  '300' as [price],
				  null as [calories]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'dish.create', @js, @rp out

select @rp
select * from [dbo].[dishes]
go
-------------------------------------------------------------
--GET по id, name + restaurant_id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '6E0D39DD-057E-4FEE-B417-43E0A34BF116' as [id]
				 -- null as [name],
				 -- null as [restaurant_id]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'dish.get', @js, @rp out

select @rp
select * from [dbo].[dishes]
go
-------------------------------------------------------------
--EDIT по id, можно поменять название, описание, цену, каллории
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'DF80FEE3-7EEE-4A36-B1D4-A295BE688BE2' as [id],
				  'Фалафель ролл' as [name],
				  'ролл с фалафелем' as [description],
				  '250' as [price],
				  400 as [calories]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'dish.edit', @js, @rp out

select @rp
select * from [dbo].[dishes]

go
-------------------------------------------------------------
--DEACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'DF80FEE3-7EEE-4A36-B1D4-A295BE688BE2' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'dish.deactive', @js, @rp out

select @rp
select * from [dbo].[dishes]

go

-------------------------DISH_TYPE---------------------------------
--CREATE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '6E0D39DD-057E-4FEE-B417-43E0A34BF116' as [dish_id],
				  '91262F97-5B65-4A8D-839A-A599EDD059DA' as [diet_id]
				  
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'dish_type.create', @js, @rp out

select @rp
select * from [dbo].[dish_type]
go
-------------------------------------------------------------
--GET по id, dish_id + diet_id, diet_id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select null as [id],
				  '6E0D39DD-057E-4FEE-B417-43E0A34BF116' as [dish_id],
				  '91262F97-5B65-4A8D-839A-A599EDD059DA' as [diet_id]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'dish_type.get', @js, @rp out

select @rp
select * from [dbo].[dish_type]
go
-------------------------------------------------------------
--DEACTIVE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '6985D71B-EEBA-4FE9-A6A7-4F1C46B867CE' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'dish_type.deactive', @js, @rp out

select @rp
select * from [dbo].[dish_type]
go


-------------------------INGREDIENT---------------------------------
--CREATE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '6E0D39DD-057E-4FEE-B417-43E0A34BF116' as [dish_id],
				  'фалафель' as [name]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'ingredient.create', @js, @rp out

select @rp
select * from [dbo].[ingredients]
go
-------------------------------------------------------------
--GET по id, name + dish_id, dish_id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select null as [id],
				  null as [name],
				  '6E0D39DD-057E-4FEE-B417-43E0A34BF116' as [dish_id]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'ingredient.get', @js, @rp out

select @rp
select * from [dbo].[ingredients]
go
-------------------------------------------------------------
--EDIT по id, можно поменять name
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '7266BEB8-1EFF-4997-A307-2E834ED43837' as [id],
				  'помидор' as [name]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'ingredient.edit', @js, @rp out

select @rp
select * from [dbo].[ingredients]

go
-------------------------------------------------------------
--DEACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '7266BEB8-1EFF-4997-A307-2E834ED43837' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'ingredient.deactive', @js, @rp out

select @rp
select * from [dbo].[ingredients]

go
-------------------------------------------------------------
--ACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '7266BEB8-1EFF-4997-A307-2E834ED43837' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'ingredient.active', @js, @rp out

select @rp
select * from [dbo].[ingredients]

go

-------------------------TABLE---------------------------------
--CREATE
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select '8780655F-A9B3-43C2-9279-9E69DF745A61' as [restaurant_id],
				  2 as [number],
				  4 as [capacity]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'table.create', @js, @rp out

select @rp
select * from [dbo].[tables]
go
-------------------------------------------------------------
--GET по id, restaurant + number, restaurant_id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select null as [id],
				  '8780655F-A9B3-43C2-9279-9E69DF745A61' as [restaurant_id],
				  null as [number]
		   for json path, without_array_wrapper)

exec [dbo].[ms_api] 'table.get', @js, @rp out

select @rp
select * from [dbo].[tables]
go
-------------------------------------------------------------
--DEACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'A20E6421-CC7A-4757-8DE0-CA76C8733CC3' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'table.deactive', @js, @rp out

select @rp
select * from [dbo].[tables]

go
-------------------------------------------------------------
--ACTIVE по id
declare @js nvarchar(max),
		@rp nvarchar(max)

set @js = (select 'A20E6421-CC7A-4757-8DE0-CA76C8733CC3' as [id] for json path, without_array_wrapper)

exec [dbo].[ms_api] 'table.active', @js, @rp out

select @rp
select * from [dbo].[tables]

go
