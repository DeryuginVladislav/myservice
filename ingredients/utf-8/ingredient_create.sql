use myservice
go 

create procedure [dbo].[ingredient.create] (@js nvarchar(max),
											@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@ingredient_id	uniqueidentifier,
					@dish_id_i uniqueidentifier = json_value(@js, '$.dish_id'),
					@ingredient_name nvarchar(30) = json_value(@js, '$.name')

			--проверка обязательных параметров на null
			if (@dish_id_i is null
				or @ingredient_name is null)
				begin
					set @err = 'err.ingredient_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность названия
			if (@ingredient_name like '%[0-9]%')
				begin
					set @err = 'err.ingredient_create.invalid_name'
					set @errdesc = 'Название ингредиента некорректно'

					goto err
				end

			--проверка на существование блюда
			if exists (select top 1 1 from [dbo].[dishes] where [id] = @dish_id_i and [status] = 'Y')
				begin
					set @err = 'err.ingredient_create.dish_not_found'
					set @errdesc = 'Блюдо не найдено'

					goto err
				end

			--проверка на дубликат
			if exists (select top 1 1 from [dbo].[ingredients] where [dish_id] = @dish_id_i and [name] = @ingredient_name and [status] = 'Y')
				begin
					set @err = 'err.ingredient_create.duplicate'
					set @errdesc = 'Ингредиент уже существует'

					goto err
				end

		
			--добавляем значения в таблицу
			set @ingredient_id = newid()
			insert into [dbo].[ingredients] ([id], [dish_id], [name])
			values (@ingredient_id,
					@dish_id_i,
					@ingredient_name)
		
			--выводим
			set @rp = (select @ingredient_id as [id],
							  @dish_id_i as [dish_id],
							  @ingredient_name as [name]
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