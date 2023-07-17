use myservice
go

create procedure [dbo].[ingredient.active] (@js nvarchar(max),
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
					@ingredient_name nvarchar(30),
					@ingredient_status char(1)

			--проверка на наличие id
			if (@ingredient_id is null)
				begin
					set @err = 'err.ingredient_active.unset_field'
					set @errdesc = 'Ингредиент не найден'

					goto err
				end

			select @ingredient_status = [status],
				   @ingredient_name = [name],
				   @dish_id_i = [dish_id]
			from [ingredients]
			where [id] = @ingredient_id

			--проверка на существование ингредиента с таким id
			if (@ingredient_status is null)
				begin
					set @err = 'err.ingredient_active.ingredient_not_found'
					set @errdesc = 'Ингредиент не найден'

					goto err
				end

			--проверка на активный статус
			if (@ingredient_status = 'Y')
				begin
					set @err = 'err.ingredient_active.ingredient_already_active'
					set @errdesc = 'Ингредиент уже активен'

					goto err
				end

			--проверка на существование блюда
			if not exists (select top 1 1 from [dbo].[dishes] where [id] = @dish_id_i and [status] = 'Y')
				begin
					set @err = 'err.ingredient_active.dish_not_found'
					set @errdesc = 'Блюдо не найдено'

					goto err
				end

			--проверка на дубликат
			if exists (select top 1 1 from [dbo].[ingredients] where [name] = @ingredient_name and [dish_id] = @dish_id_i and [status] = 'Y')
				begin
					set @err = 'err.ingredient_active.ingredient_already_exist'
					set @errdesc = 'Ингредиент уже существует'

					goto err
				end

			--меняем статус
			update [dbo].[ingredients] 
			set [status] = 'Y'
			where [id] = @ingredient_id

			--выводим
			set @rp = (select @ingredient_id as [id],
							  'Y' as [status]
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