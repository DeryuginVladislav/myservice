use myservice
go

create procedure [dbo].[ingredient_active] (@js nvarchar(max),
											@rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier = json_value(@js, '$.id'),
					@dish_id uniqueidentifier,
					@name nvarchar(30),
					@status char(1)

			--проверка на наличие id
			if (@id is null)
				begin
					set @err = 'err.ingredient_active.unset_field'
					set @errdesc = 'Не указан id'

					goto err
				end

			select @status = [status],
				   @name = [name],
				   @dish_id = [dish_id]
			from [ingredients]
			where [id] = @id

			--проверка на существование ингредиента с таким id
			if (@status is null)
				begin
					set @err = 'err.ingredient_active.ingredient_not_found'
					set @errdesc = 'Ингредиент с таким id не найден'

					goto err
				end

			--проверка на активный статус
			if (@status = 'Y')
				begin
					set @err = 'err.ingredient_active.ingredient_already_active'
					set @errdesc = 'Ингредиент уже активен'

					goto err
				end

			--проверка на дубликат
			if (exists (select 1 
						from [dbo].[ingredients] 
						where [name] = @name
							and [dish_id] = @dish_id
							and [status] = 'Y'))
				begin
					set @err = 'err.ingredient_active.ingredient_already_exist'
					set @errdesc = 'Ингредиент уже существует'

					goto err
				end

			--меняем статус
			update [dbo].[ingredients] 
			set [status] = 'Y'
			where [id] = @id

			--выводим
			set @rp = (select @id as [id],
							  'Y' as [status]
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