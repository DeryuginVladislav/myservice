use myservice
go

create procedure [dbo].[table.deactive] (@js nvarchar(max),
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
					@free_table_id uniqueidentifier,
					@restaurant_id_t uniqueidentifier

			--проверка на наличие id
			if (@table_id is null)
				begin
					set @err = 'err.table_deactive.unset_field'
					set @errdesc = 'Столик не найден'

					goto err
				end


			select @table_status = [status],
				   @restaurant_id_t = [restaurant_id]
			from [dbo].[tables] 
			where [id] = @table_id

			
			--проверка на существование столика с таким id
			if (@table_status is null)
				begin
					set @err = 'err.table_deactive.table_not_found'
					set @errdesc = 'Столик не найден'

					goto err
				end

			--проверка статуса столика
			if (@table_status = 'N')
				begin
					set @err = 'err.table_deactive.table_already_deactive'
					set @errdesc = 'Столик уже деактивирован'

					goto err
				end

			--проверяем на активные брони
			if exists (select top 1 1 from [dbo].[table_bookings] where [table_id] = @table_id and [status] in ('wait_conf', 'confirm'))
				begin
					set @err = 'err.table_deactive.active_bookings_exists'
					set @errdesc = 'У столика есть активные брони'

					goto err
				end

			--деактивируем столик
			update [dbo].[tables]
			set [status] = 'N'
			where [id] = @table_id

			--выводим
			set @rp = (select @table_id as [id],
								'N' as [status]
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