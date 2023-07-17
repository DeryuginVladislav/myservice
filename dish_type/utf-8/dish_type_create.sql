use myservice
go 

create procedure [dbo].[dish_type.create] (@js nvarchar(max),
										   @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@dish_type_id	uniqueidentifier,
					@dish_id_dt uniqueidentifier = json_value(@js, '$.dish_id'),
					@diet_id_dt uniqueidentifier = json_value(@js, '$.diet_id')

			--проверка обязательных параметров на null
			if (@dish_id_dt is null
				or @diet_id_dt is null)
				begin
					set @err = 'err.dish_type_create.unset_field'
					set @errdesc = 'Указаны не все необходимые параметры'

					goto err
				end

			--проверка на существование блюда с таким id
			if not exists (select top 1 1 from [dbo].[dishes] where [id] = @dish_id_dt and [status] = 'Y')
				begin
					set @err = 'err.dish_type_create.dish_not_found'
					set @errdesc = 'Блюдо не найдено'

					goto err
				end

			--проверка на существование диеты
			if not exists (select top 1 1 from [dbo].[diets] where [id] = @diet_id_dt and [status] = 'Y')
				begin
					set @err = 'err.dish_type_create.diet_not_found'
					set @errdesc = 'Диета не найдена'

					goto err
				end


			--проверка на уникальность связи
			if exists (select top 1 1 from [dbo].[dish_type] where [dish_id] = @dish_id_dt and [diet_id] = @diet_id_dt and [status] = 'Y')
				begin
					set @err = 'err.dish_type_create.relation_already_exist'
					set @errdesc = 'Связь блюдо - диета уже существует'

					goto err
				end

		
			--добавляем значения в таблицу
			set @dish_type_id = newid()
			insert into [dbo].[dish_type] ([id], [dish_id], [diet_id])
			values (@dish_type_id,
					@dish_id_dt,
					@diet_id_dt)
		
			--выводим
			set @rp = (select @dish_type_id as [id],
							  @dish_id_dt as [dish_id],
							  @diet_id_dt as [diet_id]
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