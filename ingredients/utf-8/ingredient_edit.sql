use myservice
go

create procedure [dbo].[ingredient.edit] (@js nvarchar(max),
										  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@ingredient_id	uniqueidentifier = json_value(@js, '$.id'),
					@dish_id_i uniqueidentifier,
					@ingredient_name nvarchar(30) = json_value(@js, '$.name')

			--проверка на наличие id
			if (@ingredient_id is null)
				begin
					set @err = 'err.ingredient_edit.unset_field'
					set @errdesc = 'Ингредиент не найден'

					goto err
				end

			--проверка на наличие редактируемых параметров
			if (@ingredient_name is null)
				begin
					set @err = 'err.ingredient_edit.hasnt_data'
					set @errdesc = 'Отсутствуют данные редактирования'

					goto err
				end

			--проверка на корректность имени
			if (@ingredient_name like '%[0-9]%')
				begin
					set @err = 'err.ingredient_edit.invalid_name'
					set @errdesc = 'Имя некорректно'

					goto err
				end


			select @dish_id_i = [dish_id]
			from [dbo].ingredients
			where [id] = @ingredient_id
				and [status] = 'Y'


			--проверка на существование ингредиента с таким id
			if (@dish_id_i is null)
				begin
					set @err = 'err.ingredient_edit.ingredient_not_found'
					set @errdesc = 'Ингредиент не найден'

					goto err
				end

			--проверка на дубликат
			if exists (select 1 from [dbo].[ingredients] where [dish_id] = @dish_id_i and [name] = @ingredient_name and [status] = 'Y')
				begin
					set @err = 'err.ingredient_edit.duplicate'
					set @errdesc = 'Ингредиент уже существует'

					goto err
				end

			--изменяем ингредиент
			update [dbo].[ingredients] 
			set [name] = isnull(@ingredient_name, [name])
			where [id] = @ingredient_id
		
			--выводим
			set @rp = (select * from [dbo].ingredients
					   where [id] = @ingredient_id
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