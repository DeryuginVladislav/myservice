use myservice
go 

create procedure [dbo].[dish_create] (@js nvarchar(max),
									  @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier,
					@name nvarchar(20) = json_value(@js, '$.name'),
					@restaurant_id uniqueidentifier = json_value(@js, '$.restaurant_id'),
					@description nvarchar(150) = json_value(@js, '$.description'),
					@price decimal(7,2) = json_value(@js, '$.price'),
					@calories int = json_value(@js, '$.calories')

			--проверка обязательных параметров на null
			if (@name is null
				or @restaurant_id is null
				or @price is null)
				begin
					set @err = 'err.dish_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность имени
			if (@name like '%[0-9]%')
				begin
					set @err = 'err.dish_create.invalid_name'
					set @errdesc = 'Имя некорректно'

					goto err
				end

			--проверка на корректность описания
			if (@description is not null 
				and @description not like '%[^0-9]%')
				begin
					set @err = 'err.dish_create.invalid_description'
					set @errdesc = 'Некорректное описание'

					goto err
				end


			--проверка на корректность цены	
			if (@price < 0
				and isnumeric(@price) = 0)
				begin
					set @err = 'err.dish_create.invalid_price'
					set @errdesc = 'Некорректная цена'

					goto err
				end

			--проверка на корректность каллорий
			if (@calories is not null
				and @calories < 0)
				begin
					set @err = 'err.dish_create.invalid_calories'
					set @errdesc = 'Некорректные калории'

					goto err
				end

			--проверка на существование ресторана
			if exists (select 1 
					   from [dbo].[restaurants] 
					   where [id] = @restaurant_id
							and [status] = 'Y')
				begin
					set @err = 'err.dish_create.invalid_restaurant'
					set @errdesc = 'Указанного ресторана не существует'

					goto err
				end

			--проверка на дубликат блюда в ресторане
			if exists (select 1 
					   from [dbo].[dishes] 
					   where [restaurant_id] = @restaurant_id
							and [name] = @name
							and [status] = 'Y')
				begin
					set @err = 'err.dish_create.duplicate'
					set @errdesc = 'Такое блюдо уже существует'

					goto err
				end

		
			--добавляем значения в таблицу
			set @id = newid()
			insert into [dbo].[dishes] ([id], [name], [restaurant_id], [description], [price], [calories])
				values (@id,
						@name,
						@restaurant_id,
						@description,
						@price,
						@calories)
		
			--выводим
			set @rp = (select @id as [id],
							  @name as [name],
							  @restaurant_id as [restaurant_id],
							  @description as [description],
							  @price as [price],
							  @calories as [calories]
					   for json path, without_array_wrapper)

			goto ok

		end try

		begin catch
			set @err = error_number()
			set @errdesc = error_message()

			goto err
		end catch


		err: 
			set @rp = (select 'err' as [status],
							  lower(@err) as [err],
							  @errdesc as [errdesc] 
					   for json path, without_array_wrapper)
			set nocount off
			return

		ok: 
			set @rp = (select 'ok' as [status],
							  json_query(@rp) as [response] 
					   for json path, without_array_wrapper)
			set nocount off
			return

	end