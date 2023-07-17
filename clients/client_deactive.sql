use myservice
go

create procedure [dbo].[client.deactive] (@js nvarchar(max),
										  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@client_id	uniqueidentifier = json_value(@js, '$.id'),
					@client_status char(1)

			--проверка на наличие id
			if (@client_id is null)
				begin
					set @err = 'err.client_deactive.unset_field'
					set @errdesc = 'Клиент не найден'

					goto err
				end


			select @client_status = [status]
			from [dbo].[clients] 
			where [id] = @client_id

			
			--проверка на существование клиента с таким id
			if (@client_status is null)
				begin
					set @err = 'err.client_deactive.object_not_found'
					set @errdesc = 'Клиент не найден'

					goto err
				end

			--проверка статуса клиента
			if (@client_status = 'N')
				begin
					set @err = 'err.client_deactive.client_already_deactive'
					set @errdesc = 'Клиент уже деактивирован'

					goto err
				end

			--проверка активных броней
			if exists (select top 1 1 from [dbo].[table_bookings] where [client_id] = @client_id and [status] = 'Y')
				begin
					set @err = 'err.client_deactive.client_has_bookings'
					set @errdesc = 'У клиента есть активные брони'

					goto err
				end


			begin transaction

				--изменяем клиента
				update [dbo].[clients] 
				set [status] = 'N'
				where [id] = @client_id and [status] = 'Y'

				--деактивируем его диеты
				update [dbo].[clients_diet]
				set [status] = 'N'
				where [client_id] = @client_id and [status] = 'Y'

			commit transaction


			--выводим
			set @rp = (select @client_id as [id],
							  'N' as [status]
					   for json path, without_array_wrapper)
			
			goto ok

		end try

		begin catch
			rollback transaction

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