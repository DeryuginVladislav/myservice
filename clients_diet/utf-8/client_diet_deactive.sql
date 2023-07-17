use myservice
go

create procedure [dbo].[client_diet.deactive] (@js nvarchar(max),
											   @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@client_diet_id	uniqueidentifier = json_value(@js, '$.id'),
					@client_diet_status char(1)

			--проверка на наличие id
			if (@client_diet_id is null)
				begin
					set @err = 'err.client_diet_deactive.unset_field'
					set @errdesc = 'Диета клиента не найдена'

					goto err
				end


			select @client_diet_status = [status]
			from [dbo].[clients_diet] 
			where [id] = @client_diet_id

			
			--проверка на существование связи с таким id
			if (@client_diet_status is null)
				begin
					set @err = 'err.client_diet_deactive.relation_not_found'
					set @errdesc = 'Диета клиента не найдена'

					goto err
				end

			--проверка статуса связи
			if (@client_diet_status = 'N')
				begin
					set @err = 'err.client_diet_deactive.relation_already_deactive'
					set @errdesc = 'Диета клиента уже деактивирована'

					goto err
				end

			--изменяем связь
			update [dbo].[clients_diet] 
			set [status] = 'N'
			where [id] = @client_diet_id and [status] = 'Y'


			--выводим
			set @rp = (select @client_diet_id as [id],
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