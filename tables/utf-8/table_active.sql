use myservice
go

create procedure [dbo].[table.active] (@js nvarchar(max),
									   @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@table_id	uniqueidentifier = json_value(@js, '$.id'),
					@table_status char(1),
					@restaurant_id_t uniqueidentifier,
					@number int

			--проверка на наличие id
			if (@table_id is null)
				begin
					set @err = 'err.table_active.unset_field'
					set @errdesc = 'Столик не найден'

					goto err
				end


			select @table_status = [status],
				   @restaurant_id_t = [restaurant_id],
				   @number = [number]
			from [dbo].[tables]
			where [id] = @table_id

			--проверка на существование столика с таким id
			if (@table_status is null)
				begin
					set @err = 'err.table_active.table_not_found'
					set @errdesc = 'Столик не найден'

					goto err
				end

			--проверка на активный статус
			if (@table_status = 'Y')
				begin
					set @err = 'err.table_active.table_already_active'
					set @errdesc = 'Столик уже активен'

					goto err
				end

			--проверка на существование ресторана c таким id
			if not exists (select top 1 1 from [dbo].[restaurants] where [id] = @restaurant_id_t and [status] = 'Y')
				begin
					set @err = 'err.table_active.restaurant_not_found'
					set @errdesc = 'Ресторан не найден'

					goto err
				end

			--проверка на занятость номера столика
			if exists (select top 1 1 from [dbo].[tables] where [restaurant_id] = @restaurant_id_t and [number] = @number and [status] = 'Y')
				begin
					set @err = 'err.table_active.number_already_exist'
					set @errdesc = 'Номер столика занят'

					goto err
				end

			--меняем статус
			update [dbo].[tables] 
			set [status] = 'Y'
			where [id] = @table_id

			--выводим
			set @rp = (select @table_id as [id],
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