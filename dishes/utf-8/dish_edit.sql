use myservice
go

create procedure [dbo].[dish.edit] (@js nvarchar(max),
									@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@dish_id	uniqueidentifier = json_value(@js, '$.id'),
					@dish_name nvarchar(20) = json_value(@js, '$.name'),
					@restaurant_id_d uniqueidentifier,
					@dish_description nvarchar(150) = json_value(@js, '$.description'),
					@price decimal(7,2) = json_value(@js, '$.price'),
					@calories int = json_value(@js, '$.calories')

			--проверка на наличие id
			if (@dish_id is null)
				begin
					set @err = 'err.dish_edit.unset_field'
					set @errdesc = 'Блюдо не найдено'

					goto err
				end

			--проверка на наличие редактируемых параметров
			if (@dish_name is null 
				and @dish_description is null
				and @price is null
				and @calories is null)
				begin
					set @err = 'err.dish_edit.hasnt_data'
					set @errdesc = 'Отсутствуют данные редактирования'

					goto err
				end

			--проверка на корректность названия
			if (@dish_name is not null and @dish_name like '%[0-9]%')
				begin
					set @err = 'err.dish_edit.invalid_name'
					set @errdesc = 'Название блюда некорректно'

					goto err
				end

			--проверка на корректность описания
			if (@dish_description is not null and @dish_description not like '%[^0-9]%')
				begin
					set @err = 'err.dish_edit.invalid_description'
					set @errdesc = 'Некорректное описание'

					goto err
				end


			--проверка на корректность цены	
			if (@price is not null and @price < 0 and @price > 20000)
				begin
					set @err = 'err.dish_edit.invalid_price'
					set @errdesc = 'Некорректная цена'

					goto err
				end

			--проверка на корректность каллорий
			if (@calories is not null and @calories < 0)
				begin
					set @err = 'err.dish_edit.invalid_calories'
					set @errdesc = 'Некорректные калории'

					goto err
				end


			select @restaurant_id_d = [restaurant_id] 
			from [dbo].[dishes] 
			where [id] = @dish_id
				and [status] = 'Y'


			--проверка на существовани блюда с таким id
			if (@restaurant_id_d is null)
				begin
					set @err = 'err.dish_edit.object_not_found'
					set @errdesc = 'Блюдо не найдено'

					goto err
				end

			--проверка на дубликат блюда в ресторане
			if @dish_name is not null
				begin
					if exists (select top 1 1 from [dbo].[dishes] where [restaurant_id] = @restaurant_id_d and [name] = @dish_name and [status] = 'Y')
						begin
							set @err = 'err.dish_edit.duplicate'
							set @errdesc = 'Такое блюдо уже существует'

							goto err
						end
				end

			--изменяем блюдо
			update [dbo].[dishes] 
			set [name] = isnull(@dish_name, [name]),
				[description] = isnull(@dish_description, [description]),
				[price] = isnull(@price, [price]),
				[calories] = isnull(@calories, [calories])
			where [id] = @dish_id
		
			--выводим
			set @rp = (select * from [dbo].[dishes]
					   where [id] = @dish_id
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