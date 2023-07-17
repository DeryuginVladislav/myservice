use myservice
go

create procedure [dbo].[client.edit] (@js nvarchar(max),
									  @rp nvarchar(max) output)
	as
	begin
		set nocount on
		set dateformat day
		begin try
			declare @err		  nvarchar(100),
					@errdesc      nvarchar(100),

					@client_id	uniqueidentifier = json_value(@js, '$.id'),
					@firstname	  nvarchar(20) = json_value(@js, '$.firstname'),
					@lastname	  nvarchar(20) = json_value(@js, '$.lastname'),
					@client_email  nvarchar(64) = json_value(@js, '$.email'),
					@client_phone nvarchar(11) = json_value(@js, '$.phone'),
					@dob date = json_value(@js, '$.dob')

			--проверка на наличие id
			if (@client_id is null)
				begin
					set @err = 'err.client_edit.unset_field'
					set @errdesc = 'Клиент не найден'

					goto err
				end

			--проверка на наличие редактируемых параметров
			if (@firstname is null 
				and @lastname is null
				and @client_email is null
				and @client_phone is null
				and @dob is null)
				begin
					set @err = 'err.client_edit.hasnt_data'
					set @errdesc = 'Отсутствуют данные редактирования'

					goto err
				end

			--проверка на корректность email
			if (@client_email is not null and @client_email not like '%_@_%._%')
				begin
					set @err = 'err.client_edit.invalid_email'
					set @errdesc = 'Некорректный email'

					goto err
				end

			--проверка на корректность имени
			if (@firstname is not null and @firstname like '%[0-9]%')
				begin
					set @err = 'err.client_edit.invalid_firstname'
					set @errdesc = 'Имя некорректно'

					goto err
				end

			--проверка на корректность фамилии
			if (@lastname is not null and @lastname like '%[0-9]%')
				begin
					set @err = 'err.client_edit.invalid_lastname'
					set @errdesc = 'Фамилия некорректна'

					goto err
				end

			--проверка на корректность dob
			if (@dob is not null and @dob > getdate())
				begin
					set @err = 'err.client_edit.invalid_dob'
					set @errdesc = 'Некорректная дата'

					goto err
				end

			--проверка на корректность phone	
			if (@client_phone is not null and @client_phone like '%[^0-9]%')
				begin
					set @err = 'err.client_edit.invalid_phone'
					set @errdesc = 'Некорректный телефон'

					goto err
				end

			--проверка на существование клиента с таким id
			if not exists (select top 1 1 from [dbo].[clients] where [id] = @client_id and [status] = 'Y')
				begin
					set @err = 'err.client_edit.object_not_found'
					set @errdesc = 'Клиент не найден'

					goto err
				end

			--проверка на занятый телефон
			if (@client_phone is not null and exists (select top 1 1 from [dbo].[clients] where [phone] = @client_phone and [status] = 'Y'))
				begin
					set @err = 'err.client_edit.not_unique_phone'
					set @errdesc = 'Телефон уже используется'

					goto err
				end

			--проверка на занятый email
			if (@client_email is not null and exists (select top 1 1 from [dbo].[clients] where [email] = @client_email and [status] = 'Y'))
				begin
					set @err = 'err.client_edit.not_unique_email'
					set @errdesc = 'Email уже используется'

					goto err
				end

			--изменяем клиента
			update [dbo].[clients] 
			set [firstname] = isnull(@firstname, [firstname]),
				[lastname] = isnull(@lastname, [lastname]),
				[email] = isnull(@client_email, [email]),
				[phone] = isnull(@client_phone, [phone]),
				[dob] = isnull(@dob, [dob])
			where [id] = @client_id
		
			--выводим
			set @rp = (select * from [dbo].[clients]
					   where [id] = @client_id
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