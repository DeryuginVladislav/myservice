use myservice
go

create procedure [dbo].[client.active] (@js nvarchar(max),
										@rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@client_id	uniqueidentifier = json_value(@js, '$.id'),
					@client_status char(1),
					@client_phone nvarchar(11),
					@client_email nvarchar(64)

			--проверка на  id
			if (@client_id is null)
				begin
					set @err = 'err.client_active.unset_field'
					set @errdesc = 'Клиент не найден'

					goto err
				end

			select @client_status = [status],
				   @client_phone = [phone],
				   @client_email = [email]
			from [clients]
			where [id] = @client_id

			--проверка существует ли клиент с таким id
			if (@client_status is null)
				begin
					set @err = 'err.client_active.client_not_found'
					set @errdesc = 'Клиент не обнаружен'

					goto err
				end

			--проверка на то что клиент уже активен
			if (@client_status = 'Y')
				begin
					set @err = 'err.client_active.client_already_active'
					set @errdesc = 'Клиент уже активен'

					goto err
				end

			--проверка на уникальность телефона
			if exists (select top 1 1 from [dbo].[clients] where [phone] = @client_phone and [status] = 'Y')
				begin
					set @err = 'err.client_active.not_unique_phone'
					set @errdesc = 'Указанный телефон уже используется'

					goto err
				end

			--проверка на уникальность email
			if (@client_email is not null and exists (select top 1 1 from [dbo].[clients] where [email] = @client_email and [status] = 'Y'))
				begin
					set @err = 'err.client_active.not_unique_email'
					set @errdesc = 'Email уже используется'

					goto err
				end

			--изменяем статус клиента
			update [dbo].[clients] 
			set [status] = 'Y'
			where [id] = @client_id

			--выводим
			set @rp = (select @client_id as [id],
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