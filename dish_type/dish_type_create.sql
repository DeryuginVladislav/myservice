use myservice
go 

create procedure [dbo].[dish_type_create] (@js nvarchar(max),
										   @rp nvarchar(max) output)
	as
	begin
		begin try
			set nocount on;
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@id	uniqueidentifier,
					@dish_id uniqueidentifier = json_value(@js, '$.dish_id'),
					@diet_id uniqueidentifier = json_value(@js, '$.diet_id')

			--проверка об€зательных параметров на null
			if (@dish_id is null
				or @diet_id is null)
				begin
					set @err = 'err.dish_type_create.unset_field'
					set @errdesc = '”казаны не все необходимые параметры'

					goto err
				end

			--проверка на существование блюда с таким id
			if not exists (select 1 
						   from [dbo].[dishes] 
						   where [id] = @dish_id and [status] = 'Y')
				begin
					set @err = 'err.dish_type_create.dish_not_found'
					set @errdesc = 'Ѕлюдо с таким id не найдено'

					goto err
				end

			--проверка на существование диеты
			if not exists (select 1 
						   from [dbo].[diets] 
						   where [id] = @diet_id and [status] = 'Y')
				begin
					set @err = 'err.dish_type_create.diet_not_found'
					set @errdesc = 'ƒиета с таким id не найдена'

					goto err
				end


			--проверка на уникальность св€зи
			if exists (select 1 
					   from [dbo].[dish_type] 
					   where [dish_id] = @dish_id
							and [diet_id] = @diet_id
							and [status] = 'Y')
				begin
					set @err = 'err.dish_type_create.relation_already_exist'
					set @errdesc = '“ака€ св€зь уже существует'

					goto err
				end

		
			--добавл€ем значени€ в таблицу
			set @id = newid()
			insert into [dbo].[dish_type] ([id], [dish_id], [diet_id])
				values (@id,
						@dish_id,
						@diet_id)
		
			--выводим
			set @rp = (select @id as [id],
							  @dish_id as [dish_id],
							  @diet_id as [diet_id]
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