use myservice
go 

create procedure [dbo].[dish.create] (@js nvarchar(max),
									  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@dish_id	uniqueidentifier,
					@dish_name nvarchar(20) = json_value(@js, '$.name'),
					@restaurant_id_d uniqueidentifier = json_value(@js, '$.restaurant_id'),
					@dish_description nvarchar(150) = json_value(@js, '$.description'),
					@price decimal(7,2) = json_value(@js, '$.price'),
					@calories int = json_value(@js, '$.calories')

			--проверка обязательных параметров на null
			if (@dish_name is null
				or @restaurant_id_d is null
				or @price is null)
				begin
					set @err = 'err.dish_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность названия
			if (@dish_name like '%[0-9]%')
				begin
					set @err = 'err.dish_create.invalid_name'
					set @errdesc = 'Название блюда некорректно'

					goto err
				end

			--проверка на корректность описания
			if (@dish_description is not null and @dish_description not like '%[^0-9]%')
				begin
					set @err = 'err.dish_create.invalid_description'
					set @errdesc = 'Некорректное описание'

					goto err
				end


			--проверка на корректность цены	
			if (@price < 0 and @price > 20000)
				begin
					set @err = 'err.dish_create.invalid_price'
					set @errdesc = 'Некорректная цена'

					goto err
				end

			--проверка на корректность каллорий
			if (@calories is not null and @calories < 0)
				begin
					set @err = 'err.dish_create.invalid_calories'
					set @errdesc = 'Некорректные калории'

					goto err
				end

			--проверка на существование ресторана
			if exists (select top 1 1 from [dbo].[restaurants] where [id] = @restaurant_id_d and [status] = 'Y')
				begin
					set @err = 'err.dish_create.invalid_restaurant'
					set @errdesc = 'Указанного ресторана не существует'

					goto err
				end

			--проверка на дубликат блюда в ресторане
			if exists (select top 1 1 from [dbo].[dishes] where [restaurant_id] = @restaurant_id_d and [name] = @dish_name and [status] = 'Y')
				begin
					set @err = 'err.dish_create.duplicate'
					set @errdesc = 'Такое блюдо уже существует'

					goto err
				end

		
			--добавляем значения в таблицу
			set @dish_id = newid()
			insert into [dbo].[dishes] ([id], [name], [restaurant_id], [description], [price], [calories])
			values (@dish_id,
						@dish_name,
						@restaurant_id_d,
						@dish_description,
						@price,
						@calories)
		
			--выводим
			set @rp = (select @dish_id as [id],
							  @dish_name as [name],
							  @restaurant_id_d as [restaurant_id],
							  @dish_description as [description],
							  @price as [price],
							  @calories as [calories]
					   for json path, without_array_wrapper)

			goto ok

		end try

		begin catch
			set @err = 'err.sys.myservice'
			set @errdesc = error_message()

			goto err
		end catch


	   ok: 
	       set @rp = (select 'ok' [status], json_query(@rp) [response] for json path, without_array_wrapper)
		   return
	   

	   err: 
	       set @rp = (select 'err' [status], lower(@err) [err], @errdesc [errdesc] for json path, without_array_wrapper)
		   return

	end