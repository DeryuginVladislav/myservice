use myservice
go 

create procedure [dbo].[ingredient_create] (@js nvarchar(max),
											@rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier,
					@dish_id uniqueidentifier = json_value(@js, '$.dish_id'),
					@name nvarchar(30) = json_value(@js, '$.name')

			--проверка обязательных параметров на null
			if (@dish_id is null
				or @name is null)
				begin
					set @err = 'err.ingredient_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на корректность имени
			if (@name like '%[0-9]%')
				begin
					set @err = 'err.ingredient_create.invalid_name'
					set @errdesc = 'Имя некорректно'

					goto err
				end

			--проверка на существование блюда
			if exists (select 1
					  from [dbo].[dishes]
					  where [id] = @dish_id
						and [status] = 'Y')
				begin
					set @err = 'err.ingredient_create.dish_not_found'
					set @errdesc = 'Блюдо не найдено'

					goto err
				end

			--проверка на дубликат
			if exists (select 1
					  from [dbo].[ingredients]
					  where [dish_id] = @dish_id
						and [name] = @name
						and [status] = 'Y')
				begin
					set @err = 'err.ingredient_create.duplicate'
					set @errdesc = 'Ингредиент уже существует'

					goto err
				end

		
			--добавляем значения в таблицу
			set @id = newid()
			insert into [dbo].[ingredients] ([id], [dish_id], [name])
				values (@id,
						@dish_id,
						@name)
		
			--выводим
			set @rp = (select @id as [id],
							  @dish_id as [dish_id],
							  @name as [name]
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